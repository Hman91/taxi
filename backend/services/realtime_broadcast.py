"""Push ride status updates to Socket.IO user rooms (thin wrapper over `socketio`)."""
from __future__ import annotations

from typing import Any, Dict, Iterable, Optional

from .. import db as db_module
from ..extensions import socketio


def _localize_event_message(event: str, lang: str, fallback: str) -> str:
    code = (lang or "en").strip().lower()
    if code.startswith("ar"):
        ar_map = {
            "ride_request_sent": "تم إرسال طلب رحلة جديد من راكب.",
            "ride_taken_by_other_driver": "تم قبول هذا الطلب من قبل سائق آخر.",
            "ride_cancelled_by_passenger": "ألغى الراكب الطلب.",
            "driver_near_pickup": "السائق قريب من نقطة الالتقاط.",
            "ride_accepted": "تم قبول طلبك من قبل سائق.",
            "ride_completed": "تم إكمال الرحلة.",
            "ride_started": "بدأت الرحلة.",
            "ride_cancelled": "تم إلغاء الرحلة.",
        }
        return ar_map.get(event, fallback)
    if code.startswith("fr"):
        fr_map = {
            "ride_request_sent": "Une nouvelle demande de course a ete envoyee par un passager.",
            "ride_taken_by_other_driver": "Cette demande a ete acceptee par un autre chauffeur.",
            "ride_cancelled_by_passenger": "Le passager a annule la demande.",
            "driver_near_pickup": "Le chauffeur est proche du point de prise en charge.",
            "ride_accepted": "Un chauffeur a accepte votre demande.",
            "ride_completed": "La course est terminee.",
            "ride_started": "La course a commence.",
            "ride_cancelled": "La course a ete annulee.",
        }
        return fr_map.get(event, fallback)
    if code.startswith("de"):
        de_map = {
            "ride_request_sent": "Eine neue Fahrtanfrage wurde von einem Fahrgast gesendet.",
            "ride_taken_by_other_driver": "Diese Anfrage wurde von einem anderen Fahrer angenommen.",
            "ride_cancelled_by_passenger": "Der Fahrgast hat die Anfrage storniert.",
            "driver_near_pickup": "Der Fahrer ist in der Naehe des Abholpunkts.",
            "ride_accepted": "Ein Fahrer hat Ihre Anfrage angenommen.",
            "ride_completed": "Die Fahrt ist abgeschlossen.",
            "ride_started": "Die Fahrt hat begonnen.",
            "ride_cancelled": "Die Fahrt wurde storniert.",
        }
        return de_map.get(event, fallback)
    if code.startswith("es"):
        es_map = {
            "ride_request_sent": "Un pasajero envio una nueva solicitud de viaje.",
            "ride_taken_by_other_driver": "Esta solicitud fue aceptada por otro conductor.",
            "ride_cancelled_by_passenger": "El pasajero cancelo la solicitud.",
            "driver_near_pickup": "El conductor esta cerca del punto de recogida.",
            "ride_accepted": "Un conductor acepto tu solicitud.",
            "ride_completed": "El viaje ha finalizado.",
            "ride_started": "El viaje ha comenzado.",
            "ride_cancelled": "El viaje fue cancelado.",
        }
        return es_map.get(event, fallback)
    if code.startswith("it"):
        it_map = {
            "ride_request_sent": "Un passeggero ha inviato una nuova richiesta di corsa.",
            "ride_taken_by_other_driver": "Questa richiesta e stata accettata da un altro autista.",
            "ride_cancelled_by_passenger": "Il passeggero ha annullato la richiesta.",
            "driver_near_pickup": "L'autista e vicino al punto di prelievo.",
            "ride_accepted": "Un autista ha accettato la tua richiesta.",
            "ride_completed": "La corsa e completata.",
            "ride_started": "La corsa e iniziata.",
            "ride_cancelled": "La corsa e stata annullata.",
        }
        return it_map.get(event, fallback)
    if code.startswith("ru"):
        ru_map = {
            "ride_request_sent": "Пассажир отправил новый запрос на поездку.",
            "ride_taken_by_other_driver": "Этот запрос принял другой водитель.",
            "ride_cancelled_by_passenger": "Пассажир отменил запрос.",
            "driver_near_pickup": "Водитель рядом с местом подачи.",
            "ride_accepted": "Водитель принял ваш запрос.",
            "ride_completed": "Поездка завершена.",
            "ride_started": "Поездка началась.",
            "ride_cancelled": "Поездка отменена.",
        }
        return ru_map.get(event, fallback)
    if code.startswith("zh"):
        zh_map = {
            "ride_request_sent": "乘客发送了新的行程请求。",
            "ride_taken_by_other_driver": "该请求已被其他司机接单。",
            "ride_cancelled_by_passenger": "乘客已取消该请求。",
            "driver_near_pickup": "司机已接近上车点。",
            "ride_accepted": "有司机已接受您的请求。",
            "ride_completed": "行程已完成。",
            "ride_started": "行程已开始。",
            "ride_cancelled": "行程已取消。",
        }
        return zh_map.get(event, fallback)
    return fallback


def _emit_to_user(user_id: int, payload: Dict[str, Any]) -> None:
    user = db_module.user_by_id(int(user_id)) or {}
    lang = str(user.get("preferred_language") or "en")
    event = str(payload.get("event") or "")
    msg = str(payload.get("message") or "")
    patched = dict(payload)
    if event and msg:
        patched["message"] = _localize_event_message(event, lang, msg)
    socketio.emit("ride_status", patched, room=f"user:{int(user_id)}")


def emit_driver_wallet(user_id: int, payload: Dict[str, Any]) -> None:
    socketio.emit("driver_wallet", payload, room=f"user:{int(user_id)}")

def emit_owner_alert(payload: Dict[str, Any]) -> None:
    for uid in db_module.list_user_ids_by_role("owner"):
        user = db_module.user_by_id(int(uid)) or {}
        lang = str(user.get("preferred_language") or "en").strip().lower()
        msg = str(payload.get("message") or "")
        if payload.get("event") == "driver_wallet_depleted":
            amount = int(payload.get("required_topup_dt") or 100)
            if lang.startswith("ar"):
                msg = (
                    f"محفظة السائق فارغة. يجب عليه دفع {amount} د.ت للمالك عبر المشغل."
                )
            elif lang.startswith("fr"):
                msg = (
                    f"Le portefeuille du chauffeur est vide. "
                    f"Il doit payer {amount} DT au proprietaire via l'operateur."
                )
        socketio.emit("owner_alert", {**payload, "message": msg}, room=f"user:{int(uid)}")


def broadcast_ride_update(
    ride: Dict[str, Any],
    *,
    event: str = "ride_status_changed",
    message: Optional[str] = None,
) -> None:
    """Notify passenger and assigned driver (if any) with latest ride JSON."""
    payload = {"ride": ride, "event": event}
    if message:
        payload["message"] = message
    _emit_to_user(int(ride["user_id"]), payload)
    did = ride.get("driver_id")
    if did is not None:
        d = db_module.driver_by_id(int(did))
        if d is not None:
            _emit_to_user(int(d["user_id"]), payload)


def notify_dispatch_offer(ride: Dict[str, Any], driver_user_ids: Iterable[int]) -> None:
    payload = {
        "event": "ride_request_sent",
        "ride": ride,
        "message": "Passenger sent a new ride request.",
    }
    for uid in driver_user_ids:
        _emit_to_user(int(uid), payload)


def notify_dispatch_taken(
    ride: Dict[str, Any],
    *,
    accepted_driver_user_id: int,
    other_driver_user_ids: Iterable[int],
) -> None:
    payload = {
        "event": "ride_taken_by_other_driver",
        "ride": ride,
        "message": "This request was accepted by another driver.",
        "accepted_driver_user_id": int(accepted_driver_user_id),
        # Alias kept for client compatibility with older handlers.
        "driver_id": int(accepted_driver_user_id),
    }
    for uid in other_driver_user_ids:
        if int(uid) == int(accepted_driver_user_id):
            continue
        _emit_to_user(int(uid), payload)


def notify_dispatch_cancelled(
    ride: Dict[str, Any],
    *,
    driver_user_ids: Iterable[int],
) -> None:
    payload = {
        "event": "ride_cancelled_by_passenger",
        "ride": ride,
        "message": "Passenger cancelled the request.",
    }
    for uid in driver_user_ids:
        _emit_to_user(int(uid), payload)


def notify_passenger_driver_near_pickup(ride: Dict[str, Any], *, current_zone: str) -> None:
    payload = {
        "event": "driver_near_pickup",
        "ride": ride,
        "current_zone": current_zone,
        "message": "Driver is near your pickup point.",
    }
    _emit_to_user(int(ride["user_id"]), payload)
