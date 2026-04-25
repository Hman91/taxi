"""
Translate-on-delivery with PostgreSQL cache (`translations` table).

All vendor calls go through here per rules.md. Store originals only on `messages`;
cache rows keyed by (message_id, target_language).
"""
from __future__ import annotations

import logging
from concurrent.futures import ThreadPoolExecutor, TimeoutError as FuturesTimeout
from typing import Any, Dict, Optional

from flask import current_app
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from ..extensions import db
from .. import db as db_module
from ..models import Translation

log = logging.getLogger(__name__)

_executor = ThreadPoolExecutor(max_workers=4, thread_name_prefix="taxi_translate")


def _langs_equivalent(a: str, b: str) -> bool:
    x = (a or "").strip().lower().replace("_", "-")
    y = (b or "").strip().lower().replace("_", "-")
    if not x or not y:
        return True
    if x == y:
        return True
    return x.split("-", 1)[0] == y.split("-", 1)[0]


def _provider_name() -> str:
    try:
        return str(current_app.config.get("TRANSLATION_PROVIDER", "google")).lower()
    except RuntimeError:
        return "google"


def _timeout_seconds() -> float:
    try:
        return float(current_app.config.get("TRANSLATION_TIMEOUT_SECONDS", 5.0))
    except RuntimeError:
        return 5.0


def _map_google_target(code: str) -> str:
    c = (code or "en").strip().lower().replace("_", "-")
    if len(c) > 10:
        c = c[:10]
    aliases = {
        "zh": "zh-CN",
        "zh-cn": "zh-CN",
        "zh-tw": "zh-TW",
    }
    return aliases.get(c, c)


def _call_google(text: str, source_lang: str, target_lang: str) -> str:
    from deep_translator import GoogleTranslator

    tgt = _map_google_target(target_lang)
    src = (source_lang or "").strip() or "auto"
    if _langs_equivalent(src, tgt):
        return text
    if src != "auto":
        src = _map_google_target(src)
    return GoogleTranslator(source=src, target=tgt).translate(text)


def _translate_worker(text: str, source_lang: str, target_lang: str, provider: str) -> str:
    """Runs in a thread — must not touch Flask context."""
    if provider in ("none", "stub", "off", "disabled"):
        return text
    if provider in ("google", "deep_translator", "deep-translator"):
        try:
            return _call_google(text, source_lang, target_lang)
        except Exception as e:
            log.warning("Google translation failed: %s", e)
            return text
    log.warning("Unknown TRANSLATION_PROVIDER=%s; returning original", provider)
    return text


def get_or_translate(message_id: int, text: str, source_lang: str, target_lang: str) -> str:
    """Return text in target_lang, using DB cache or vendor; never raises."""
    if not text:
        return text
    if _langs_equivalent(source_lang, target_lang):
        return text

    tgt = (target_lang or "en").strip() or "en"
    if len(tgt) > 10:
        tgt = tgt[:10]

    row = db.session.scalars(
        select(Translation).where(
            Translation.message_id == message_id,
            Translation.target_language == tgt,
        )
    ).first()
    if row is not None:
        return row.translated_text

    provider = _provider_name()
    timeout = _timeout_seconds()
    fut = _executor.submit(_translate_worker, text, source_lang, tgt, provider)
    try:
        out = fut.result(timeout=timeout)
    except FuturesTimeout:
        log.warning("Translation timed out after %ss", timeout)
        fut.cancel()
        out = text
    except Exception as e:
        log.warning("Translation worker error: %s", e)
        out = text

    t = Translation(message_id=message_id, target_language=tgt, translated_text=out)
    db.session.add(t)
    try:
        db.session.commit()
    except IntegrityError:
        db.session.rollback()
        row = db.session.scalars(
            select(Translation).where(
                Translation.message_id == message_id,
                Translation.target_language == tgt,
            )
        ).first()
        if row is not None:
            return row.translated_text
    return out


def enrich_message_for_viewer(msg: Dict[str, Any], viewer_user_id: int) -> Dict[str, Any]:
    """
    Add display_text (and translated_text when different) for a recipient or sender.
    Senders always see their own original string.
    """
    mid = int(msg.get("message_id") or msg["id"])
    original = msg.get("original_text") or ""
    src_lang = (msg.get("original_language") or "en").strip() or "en"
    sender = int(msg.get("sender_id") or msg.get("sender_user_id") or 0)

    base = {**msg, "message_id": mid}

    if viewer_user_id == sender:
        return {
            **base,
            "translated_text": None,
            "display_text": original,
        }

    viewer = db_module.user_by_id(viewer_user_id)
    tgt = "en"
    if viewer is not None:
        tgt = (viewer.get("preferred_language") or "en").strip() or "en"
    if len(tgt) > 10:
        tgt = tgt[:10]

    if _langs_equivalent(src_lang, tgt):
        return {
            **base,
            "translated_text": None,
            "display_text": original,
        }

    translated = get_or_translate(mid, original, src_lang, tgt)
    return {
        **base,
        "translated_text": translated if translated != original else None,
        "display_text": translated,
    }


def enrich_message_for_target_lang(
    msg: Dict[str, Any], target_lang: Optional[str]
) -> Dict[str, Any]:
    """Admin read path: optional fixed target language (no user row)."""
    mid = int(msg.get("message_id") or msg["id"])
    original = msg.get("original_text") or ""
    src_lang = (msg.get("original_language") or "en").strip() or "en"
    base = {**msg, "message_id": mid}
    if not target_lang or not str(target_lang).strip():
        return {
            **base,
            "translated_text": None,
            "display_text": original,
        }
    tgt = str(target_lang).strip()[:10]
    if _langs_equivalent(src_lang, tgt):
        return {
            **base,
            "translated_text": None,
            "display_text": original,
        }
    translated = get_or_translate(mid, original, src_lang, tgt)
    return {
        **base,
        "translated_text": translated if translated != original else None,
        "display_text": translated,
    }
