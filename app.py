import json
import time
import urllib.parse
from datetime import datetime, time

import pandas as pd
import streamlit as st
import streamlit.components.v1 as components
from deep_translator import GoogleTranslator


def inject_app_styles():
    st.markdown(
        """
        <style>
        /* Plain text on yellow background = red (alerts & dark panels excluded below) */
        :root {
            --taxi-text: #b91c1c;
            --taxi-text-strong: #991b1b;
            --taxi-text-soft: #c2410c;
        }
        html, body, [data-testid="stAppViewContainer"] {
            font-family: "Segoe UI", "Noto Sans Arabic", "Tajawal", system-ui, sans-serif;
        }
        .stApp {
            background: linear-gradient(165deg, #fffef8 0%, #fff3b8 28%, #ffe14d 55%, #ffd000 100%) !important;
            background-attachment: fixed !important;
            color: var(--taxi-text) !important;
        }
        /* Main column: override Streamlit light-theme grey/white text */
        section[data-testid="stMain"],
        section[data-testid="stMain"] .block-container {
            color: var(--taxi-text) !important;
        }
        section[data-testid="stMain"] p,
        section[data-testid="stMain"] li,
        section[data-testid="stMain"] .stMarkdown,
        section[data-testid="stMain"] [data-testid="stMarkdown"] p,
        section[data-testid="stMain"] [data-testid="stMarkdown"] span,
        section[data-testid="stMain"] [data-testid="stMarkdown"] li {
            color: var(--taxi-text) !important;
        }
        section[data-testid="stMain"] strong {
            color: var(--taxi-text-strong) !important;
        }
        /* Widget labels (selectbox, text input, radio group title, etc.) */
        [data-testid="stWidgetLabel"] p,
        [data-testid="stWidgetLabel"] span,
        label[data-testid="stWidgetLabel"] {
            color: var(--taxi-text-strong) !important;
            font-weight: 600 !important;
        }
        /* Radio / role selector — label text was nearly invisible */
        [data-testid="stRadio"] label,
        [data-testid="stRadio"] [data-baseweb="radio"] label,
        [data-testid="stRadio"] div[role="radiogroup"] label {
            color: var(--taxi-text-strong) !important;
        }
        [data-testid="stRadio"] > div {
            gap: 0.4rem !important;
            flex-wrap: wrap !important;
            justify-content: center !important;
            padding: 0.5rem 0.25rem;
            background: rgba(255,255,255,0.72) !important;
            border-radius: 14px;
            border: 1px solid rgba(139, 20, 40, 0.28);
        }
        /* Tabs */
        button[data-baseweb="tab"],
        [data-baseweb="tab"] {
            color: var(--taxi-text) !important;
        }
        [data-baseweb="tab"][aria-selected="true"] {
            color: var(--taxi-text-strong) !important;
            font-weight: 700 !important;
        }
        [data-baseweb="tab-list"] {
            gap: 0.35rem !important;
            background: rgba(255,255,255,0.72) !important;
            border-radius: 12px !important;
            padding: 0.35rem !important;
            border: 1px solid rgba(139, 20, 40, 0.2) !important;
        }
        /* Captions & small text */
        [data-testid="stCaption"],
        [data-testid="stCaption"] p,
        .stCaption,
        div[data-testid="stCaptionContainer"] {
            color: var(--taxi-text-soft) !important;
            opacity: 1 !important;
        }
        /* Subheaders */
        [data-testid="stHeader"] {
            background: rgba(255, 248, 210, 0.55);
            backdrop-filter: blur(8px);
        }
        h1, h2, h3 {
            letter-spacing: -0.02em;
            color: var(--taxi-text-strong) !important;
        }
        /* White on dark cards (must beat section … p / h1 rules below) */
        section[data-testid="stMain"] .taxi-dark-panel,
        section[data-testid="stMain"] .taxi-dark-panel * {
            color: #ffffff !important;
        }
        section[data-testid="stSidebar"] {
            background: linear-gradient(180deg, rgba(255,255,255,0.97), rgba(255, 243, 180, 0.92)) !important;
            border-right: 1px solid rgba(180, 140, 0, 0.22);
            box-shadow: 4px 0 24px rgba(0,0,0,0.06);
            color: var(--taxi-text-strong) !important;
        }
        section[data-testid="stSidebar"] p,
        section[data-testid="stSidebar"] span,
        section[data-testid="stSidebar"] label {
            color: var(--taxi-text-strong) !important;
        }
        section[data-testid="stSidebar"] .block-container {
            padding-top: 1.5rem;
        }
        .main .block-container {
            padding-top: 1.75rem;
            padding-bottom: 2.5rem;
            max-width: 52rem;
        }
        hr {
            margin: 1.25rem 0 !important;
            border: none !important;
            border-top: 1px solid rgba(120, 90, 0, 0.22) !important;
        }
        button[kind="primary"] {
            background: linear-gradient(180deg, #2a2a2a, #141414) !important;
            color: #ffffff !important;
            border: none !important;
            border-radius: 12px !important;
            box-shadow: 0 6px 18px rgba(0,0,0,0.18) !important;
            font-weight: 600 !important;
        }
        /* Primary label is often a <p>; section[data-testid="stMain"] p { red } wins unless we raise specificity */
        section[data-testid="stMain"] .stButton > button[kind="primary"],
        section[data-testid="stMain"] .stButton > button[kind="primary"] *,
        section[data-testid="stMain"] button[kind="primary"],
        section[data-testid="stMain"] button[kind="primary"] *,
        section[data-testid="stSidebar"] .stButton > button[kind="primary"],
        section[data-testid="stSidebar"] .stButton > button[kind="primary"] *,
        section[data-testid="stSidebar"] button[kind="primary"],
        section[data-testid="stSidebar"] button[kind="primary"] *,
        section[data-testid="stMain"] [data-testid="baseButton-primary"],
        section[data-testid="stMain"] [data-testid="baseButton-primary"] *,
        section[data-testid="stSidebar"] [data-testid="baseButton-primary"],
        section[data-testid="stSidebar"] [data-testid="baseButton-primary"] * {
            color: #ffffff !important;
        }
        .stButton > button:not([kind="primary"]) {
            border-radius: 12px !important;
        }
        [data-testid="stDataFrame"] {
            border-radius: 14px !important;
            overflow: hidden !important;
            box-shadow: 0 6px 22px rgba(0,0,0,0.1) !important;
            border: 1px solid rgba(180, 140, 0, 0.18) !important;
        }
        div[data-testid="stExpander"] details {
            border-radius: 12px !important;
            border: 1px solid rgba(180, 140, 0, 0.2) !important;
            background: rgba(255,255,255,0.5) !important;
            color: var(--taxi-text) !important;
        }
        div[data-testid="stExpander"] p,
        div[data-testid="stExpander"] span {
            color: var(--taxi-text) !important;
        }
        /* Chat / metric text */
        [data-testid="stChatMessage"] p,
        [data-testid="stMetricValue"],
        [data-testid="stMetricLabel"] {
            color: var(--taxi-text-strong) !important;
        }
        /* Catch-all for markdown blocks (Streamlit build differences) */
        .block-container [data-testid="stMarkdown"] p,
        .block-container [data-testid="stMarkdown"] span {
            color: var(--taxi-text) !important;
        }
        /* Links on yellow (not primary download / app links that are dark buttons) */
        section[data-testid="stMain"] a:not([href^="tel:"]):not([data-testid="baseButton-primary"]),
        section[data-testid="stSidebar"] a:not([data-testid="baseButton-primary"]) {
            color: var(--taxi-text-strong) !important;
        }
        /* st.success / st.info / st.warning / st.error: own backgrounds — keep Streamlit colors */
        div[data-testid="stAlert"],
        div[data-testid="stAlert"] p,
        div[data-testid="stAlert"] span,
        div[data-testid="stAlert"] div {
            color: revert !important;
        }
        </style>
        """,
        unsafe_allow_html=True,
    )


# ==========================================
# 1. إعدادات النظام وتوافق الهاتف
# ==========================================
st.set_page_config(page_title="Taxi Pro Tunisia 🇹🇳", page_icon="🚕", layout="centered")
inject_app_styles()

# ==========================================
# 2. تهيئة قواعد البيانات السحابية (الذاكرة)
# ==========================================
if 'chat_history' not in st.session_state: st.session_state.chat_history = []
if 'db_trips' not in st.session_state: st.session_state.db_trips = pd.DataFrame(columns=['Date', 'Driver', 'Route', 'Fare', 'Commission', 'Source', 'Rating'])
if 'commission_rate' not in st.session_state: st.session_state.commission_rate = 10.0  
# جدول كامل: (انطلاق، وصول، كم، سعر أساس DT) — مصدر واحد للمسافات والتعريفة
# الـ 4 الأسطر الأولى كانت معرفة سابقاً؛ الباقي تقديرات معقولة للعرض (قابلة للتعديل في لوحة المالك)
def _passenger_build_fares_and_dist_from_table():
    _rows = [
        ("مطار قرطاج", "الحمامات", 82.0, 120.0),
        ("مطار قرطاج", "سوسة", 125.0, 155.0),
        ("مطار قرطاج", "القنطاوي", 118.0, 148.0),
        ("مطار قرطاج", "نابل", 115.0, 145.0),
        ("مطار النفيضة", "الحمامات", 55.0, 85.0),
        ("مطار النفيضة", "سوسة", 28.0, 70.0),
        ("مطار النفيضة", "القنطاوي", 35.0, 78.0),
        ("مطار النفيضة", "نابل", 98.0, 128.0),
        ("مطار المنستير", "الحمامات", 48.0, 72.0),
        ("مطار المنستير", "سوسة", 25.0, 55.0),
        ("مطار المنستير", "القنطاوي", 22.0, 40.0),
        ("مطار المنستير", "نابل", 90.0, 118.0),
        ("وسط سوسة", "الحمامات", 38.0, 62.0),
        ("وسط سوسة", "سوسة", 8.0, 35.0),
        ("وسط سوسة", "القنطاوي", 12.0, 38.0),
        ("وسط سوسة", "نابل", 76.0, 80.0),
    ]
    fares, dists = {}, {}
    for s, e, km, price in _rows:
        key = f"{s} ➡️ {e}"
        fares[key] = float(price)
        dists[key] = float(km)
    return fares, dists


PASSENGER_FARES_DEFAULT, PASSENGER_ROUTE_DISTANCE_KM = _passenger_build_fares_and_dist_from_table()

if "fares_db" not in st.session_state:
    st.session_state.fares_db = dict(PASSENGER_FARES_DEFAULT)
else:
    for _k, _v in PASSENGER_FARES_DEFAULT.items():
        if _k not in st.session_state.fares_db:
            st.session_state.fares_db[_k] = _v

if "route_distance_km" not in st.session_state:
    st.session_state.route_distance_km = dict(PASSENGER_ROUTE_DISTANCE_KM)
else:
    for _k, _v in PASSENGER_ROUTE_DISTANCE_KM.items():
        if _k not in st.session_state.route_distance_km:
            st.session_state.route_distance_km[_k] = _v

if 'drivers_db' not in st.session_state:
    st.session_state.drivers_db = {
        "98123456": {"name": "خليل (سائق 1)", "pin": "1234", "wallet": 20.0, "location": "مطار النفيضة"},
        "50111222": {"name": "أحمد (سائق 2)", "pin": "0000", "wallet": 15.0, "location": "مطار قرطاج"}
    }

if 'live_requests' not in st.session_state: st.session_state.live_requests = []


def passenger_route_segments(route_key: str):
    """يعيد (منطقة الانطلاق، الوجهة) من مفتاح المسار."""
    parts = route_key.split("➡️")
    a = parts[0].strip() if parts else ""
    b = parts[1].strip() if len(parts) > 1 else ""
    return a, b


def passenger_estimated_km(route_key: str) -> float:
    km_map = st.session_state.get("route_distance_km", PASSENGER_ROUTE_DISTANCE_KM)
    if route_key in km_map:
        return float(km_map[route_key])
    return float(PASSENGER_ROUTE_DISTANCE_KM.get(route_key, 0.0))


def passenger_build_route_key(start: str, end: str) -> str:
    return f"{start.strip()} ➡️ {end.strip()}"


def passenger_find_route_key(fares_db: dict, start: str, end: str):
    """مفتاح المسار الفعلي في التعريفة (يطابق حتى لو اختلفت مسافات بسيطة)."""
    s0, e0 = start.strip(), end.strip()
    candidate = passenger_build_route_key(s0, e0)
    if candidate in fares_db:
        return candidate
    for k in fares_db:
        a, b = passenger_route_segments(k)
        if a.strip() == s0 and b.strip() == e0:
            return k
    return None


def passenger_unique_starts_ends(fares_db: dict):
    """استخراج قوائم منفصلة لنقاط الانطلاق والوجهة من مفاتيح المسارات."""
    starts, ends = set(), set()
    for k in fares_db:
        a, b = passenger_route_segments(k)
        if a:
            starts.add(a.strip())
        if b:
            ends.add(b.strip())
    return sorted(starts), sorted(ends)


def passenger_valid_ends_for_start(fares_db: dict, start: str):
    """الوجهات المتاحة فعلياً لنقطة انطلاق (مسارات موجودة في التعريفة)."""
    out = []
    s0 = start.strip()
    for k in fares_db:
        a, b = passenger_route_segments(k)
        if a.strip() == s0 and b:
            out.append(b.strip())
    return sorted(set(out))


def calculate_fare(base_fare: float):
    """من المنطق القديم: زيادة ليل 50% بين 21:00 و 05:00."""
    current_hour = datetime.now().hour
    is_night = current_hour >= 21 or current_hour < 5
    final_price = base_fare * 1.5 if is_night else base_fare
    return final_price, is_night


TN_INBOUND_AIRPORTS = ("مطار النفيضة", "مطار قرطاج", "مطار المنستير")


def build_inbound_flights_today():
    """رحلات وهمية قادمة إلى تونس اليوم؛ مرتبة حسب وقت الوصول المتوقع."""
    today = datetime.now().date()
    # (رقم، مطار المغادرة، وقت الإقلاع نصّي، وقت الوصول اليوم، مطار الوصول بتونس)
    raw = [
        ("TB101", "Paris Orly", "05:40", time(8, 15), "مطار النفيضة"),
        ("TU214", "Brussels", "06:10", time(8, 40), "مطار قرطاج"),
        ("AF987", "Paris CDG", "06:30", time(9, 5), "مطار المنستير"),
        ("LH442", "Frankfurt", "07:00", time(9, 30), "مطار النفيضة"),
        ("BA893", "London Gatwick", "07:15", time(10, 0), "مطار قرطاج"),
        ("TK663", "Istanbul", "08:00", time(10, 30), "مطار النفيضة"),
        ("AZ876", "Rome Fiumicino", "08:30", time(10, 55), "مطار المنستير"),
        ("LH123", "Munich", "09:00", time(11, 35), "مطار قرطاج"),
        ("AF234", "Lyon", "09:45", time(12, 10), "مطار النفيضة"),
        ("SN567", "Brussels", "10:00", time(12, 30), "مطار المنستير"),
        ("U2456", "London Stansted", "11:00", time(14, 0), "مطار قرطاج"),
        ("QR901", "Doha", "12:00", time(15, 0), "مطار النفيضة"),
        ("EM778", "Marseille", "13:00", time(15, 35), "مطار المنستير"),
        ("LH889", "Frankfurt", "14:00", time(16, 30), "مطار قرطاج"),
        ("TO321", "Paris Orly", "15:00", time(17, 30), "مطار النفيضة"),
        ("BA112", "London Heathrow", "16:00", time(18, 45), "مطار قرطاج"),
        ("TK664", "Istanbul", "17:00", time(19, 30), "مطار المنستير"),
        ("AF445", "Paris CDG", "18:00", time(20, 30), "مطار النفيضة"),
        ("LH556", "Frankfurt", "19:00", time(21, 30), "مطار قرطاج"),
        ("TU789", "Madrid", "20:00", time(22, 30), "مطار المنستير"),
    ]
    out = []
    for flight, src, dep_str, arr_time, tgt in raw:
        if tgt not in TN_INBOUND_AIRPORTS:
            continue
        arr_dt = datetime.combine(today, arr_time)
        out.append(
            {
                "flight": flight,
                "source_airport": src,
                "start_flight_time": dep_str,
                "expected_arrival": arr_dt.strftime("%Y-%m-%d %H:%M"),
                "target_airport": tgt,
            }
        )
    out.sort(key=lambda r: r["expected_arrival"])
    return out


# ==========================================
# 3. نظام اللغات والترجمة الفورية (8 لغات)
# ==========================================
lang_codes = {
    "الدارجة 🇹🇳": "ar", "English 🇬🇧": "en", "Français 🇫🇷": "fr",
    "Deutsch 🇩🇪": "de", "Italiano 🇮🇹": "it", "Español 🇪🇸": "es",
    "Русский 🇷🇺": "ru", "中文 🇨🇳": "zh-CN",
}


@st.cache_data(show_spinner=False, ttl=3600)
def translate(text, target_lang):
    if target_lang == "ar":
        return text
    try:
        return GoogleTranslator(source="auto", target=target_lang).translate(text)
    except Exception:
        return text


def render_inbound_flights_block(lang_code):
    st.subheader(translate("✈️ وصولات اليوم — تونس (بيانات تجريبية)", lang_code))
    rows = build_inbound_flights_today()
    df = pd.DataFrame(rows)
    if not df.empty:
        df = df.rename(
            columns={
                "flight": translate("رقم الرحلة", lang_code),
                "source_airport": translate("مطار المغادرة", lang_code),
                "start_flight_time": translate("وقت الإقلاع", lang_code),
                "expected_arrival": translate("الوصول المتوقع (اليوم)", lang_code),
                "target_airport": translate("مطار الوصول (تونس)", lang_code),
            }
        )
        st.dataframe(df, use_container_width=True, hide_index=True)
    st.caption(
        translate(
            "هذه قائمة تجريبية للعرض فقط وليست مرتبطة بأنظمة المطارات.",
            lang_code,
        )
    )


if "last_lang_code" not in st.session_state:
    st.session_state.last_lang_code = "ar"
_lang_keys = list(lang_codes.keys())
_prev_sel = st.session_state.get("lang_choice_sidebar")
_lang_idx = _lang_keys.index(_prev_sel) if _prev_sel in lang_codes else 0
lang_choice = st.sidebar.selectbox(
    translate("🌐 لغتك / Language:", st.session_state.last_lang_code),
    _lang_keys,
    index=_lang_idx,
    key="lang_choice_sidebar",
)
current_lang_code = lang_codes[lang_choice]
st.session_state.last_lang_code = current_lang_code

# ==========================================
# 4. محرك البوابات (5 بوابات متكاملة)
# ==========================================
roles = ["Passenger", "Driver", "Corporate B2B", "Operator", "Admin HQ"]
role = st.radio(translate("بوابة الدخول:", current_lang_code), options=roles, format_func=lambda x: translate(x, current_lang_code), horizontal=True)
st.divider()

# ==========================================
# 🌍 5. واجهة الحريف
# ==========================================
if role == "Passenger":
    st.markdown(
        f"<div style='text-align:center; margin-bottom:0.5rem;'>"
        f"<span style='display:inline-block; padding:0.35rem 1rem; border-radius:999px; "
        f"background:rgba(255,255,255,0.72); border:1px solid rgba(139,20,40,0.28); "
        f"font-size:0.85rem; color:#991b1b; font-weight:600;'>Taxi Pro Tunisia</span></div>"
        f"<h2 style='text-align:center; margin:0.25rem 0 0.75rem; font-weight:700; "
        f"color:#b91c1c; text-shadow:0 1px 0 rgba(255,255,255,0.65);'>"
        f"✈️ {translate('حجز تاكسي VIP', current_lang_code)}</h2>",
        unsafe_allow_html=True,
    )
    
    my_active_requests = [r for r in st.session_state.live_requests if r['status'] in ['pending', 'accepted']]
    
    t1, t2, t3 = st.tabs([translate("🚕 الرحلة", current_lang_code), translate("💬 المحادثة", current_lang_code), translate("⚙️ الإعدادات", current_lang_code)])
    
    with t1:
        if len(my_active_requests) == 0:
            _fd = st.session_state.fares_db
            _starts, _ = passenger_unique_starts_ends(_fd)
            col_from, col_to = st.columns(2)
            with col_from:
                sel_start = st.selectbox(
                    translate("📍 نقطة الانطلاق:", current_lang_code),
                    options=_starts,
                    format_func=lambda x: translate(x, current_lang_code),
                    key="passenger_sel_start",
                )
            _valid_ends = passenger_valid_ends_for_start(_fd, sel_start)
            with col_to:
                if _valid_ends:
                    sel_end = st.selectbox(
                        translate("🏁 الوجهة:", current_lang_code),
                        options=_valid_ends,
                        format_func=lambda x: translate(x, current_lang_code),
                        key=f"passenger_sel_end__{sel_start}",
                    )
                else:
                    sel_end = ""
                    st.caption(translate("—", current_lang_code))

            route = passenger_find_route_key(_fd, sel_start, sel_end) if _valid_ends else None
            route_ok = route is not None

            if not _valid_ends:
                st.error(
                    translate(
                        "لا توجد وجهات معرّفة لهذا الانطلاق في التعريفة. راجع لوحة المالك.",
                        current_lang_code,
                    )
                )
            elif not route_ok:
                st.warning(
                    translate(
                        "لا يوجد مسار مسعّر لهذه النقاط في التعريفة. أضف المسار من لوحة المالك.",
                        current_lang_code,
                    )
                )
            else:
                base_tariff = float(_fd[route])
                promo_code = st.text_input(translate("كود التخفيض (إن وجد):", current_lang_code))
                price_after_promo = base_tariff * 0.8 if promo_code == "WELCOME26" else base_tariff
                if promo_code == "WELCOME26":
                    st.success(translate("🎉 تم تفعيل التخفيض بنسبة 20%!", current_lang_code))

                estimated_price, is_night = calculate_fare(price_after_promo)
                _est_km = passenger_estimated_km(route)

                st.markdown(
                    f"**{translate('📏 المسافة التقريبية:', current_lang_code)}** ~**{_est_km:.1f}** "
                    f"{translate('كم', current_lang_code)}"
                )
                st.markdown(
                    f"**{translate('💰 السعر التقديري (شامل):', current_lang_code)}** "
                    f"**{estimated_price:.2f} DT**"
                )
                if is_night:
                    st.error(translate("🌙 +50% تعريفة ليلية مطبقة (21:00–05:00).", current_lang_code))
                st.caption(translate("✅ السعر شامل الأمتعة والمسار (تقدير وفق التعريفة الحالية).", current_lang_code))

                st.markdown(
                    f"<div class='taxi-dark-panel' style='background:linear-gradient(145deg,#252525 0%,#121212 100%); color:#ffffff; "
                    f"padding:18px 20px; border-radius:16px; text-align:center; margin-bottom:18px; "
                    f"box-shadow:0 12px 32px rgba(0,0,0,0.2); border:2px solid rgba(255,215,0,0.45);'>"
                    f"<h1 style='margin:0; font-size:2.1rem; letter-spacing:-0.03em; color:#ffffff;'>{estimated_price:.2f} DT</h1>"
                    f"<small style='opacity:0.92; color:#ffffff;'>{translate('تقدير نهائي للعرض', current_lang_code)}</small></div>",
                    unsafe_allow_html=True,
                )

                pay_method = st.radio(
                    translate("طريقة الدفع:", current_lang_code),
                    [translate("💵 كاش", current_lang_code), translate("💳 بطاقة (TPE)", current_lang_code)],
                    horizontal=True,
                )

                bc1, bc2, bc3 = st.columns(3)
                with bc1:
                    if st.button(
                        translate("🚀 اطلب عبر التطبيق", current_lang_code),
                        use_container_width=True,
                        type="primary",
                        key="passenger_order_app_btn",
                    ):
                        new_req = {
                            "id": int(time.time()),
                            "route": route,
                            "pickup_zone": sel_start.strip(),
                            "price": estimated_price,
                            "status": "pending",
                            "driver_name": "",
                            "source": "App",
                        }
                        st.session_state.live_requests.append(new_req)
                        st.success(translate("تم إرسال طلبك للسائقين القريبين منك...", current_lang_code))
                        time.sleep(1.5)
                        st.rerun()
                with bc2:
                    _phone = "+21600000000"
                    st.markdown(
                        f'<a href="tel:{_phone}" target="_self" style="text-decoration:none;">'
                        f'<button type="button" style="width:100%; cursor:pointer; background:linear-gradient(180deg,#3b82f6,#2563eb); '
                        f'color:white; border:none; padding:12px 10px; border-radius:12px; font-weight:600; '
                        f'box-shadow:0 6px 16px rgba(37,99,235,0.35);">'
                        f"📞 {translate('اتصل بطاكسي', current_lang_code)}</button></a>",
                        unsafe_allow_html=True,
                    )
                with bc3:
                    _wa = urllib.parse.quote(
                        f"{translate('حجز Taxi Pro:', current_lang_code)} {route} | "
                        f"{translate('السعر التقديري:', current_lang_code)} {estimated_price:.2f} DT | "
                        f"{translate('الدفع:', current_lang_code)} {pay_method}"
                    )
                    st.markdown(
                        f'<a href="https://wa.me/{_phone.replace("+", "")}?text={_wa}" target="_blank" style="text-decoration:none;">'
                        f'<button type="button" style="width:100%; cursor:pointer; background:linear-gradient(180deg,#25d366,#16a34a); '
                        f'color:white; border:none; padding:12px 10px; border-radius:12px; font-weight:600; '
                        f'box-shadow:0 6px 16px rgba(22,163,74,0.35);">'
                        f"💬 {translate('واتساب', current_lang_code)}</button></a>",
                        unsafe_allow_html=True,
                    )
                
        else:
            current_req = my_active_requests[-1]
            _r = current_req["route"]
            _pk, _dz = passenger_route_segments(_r)
            _ekm = passenger_estimated_km(_r)
            st.info(f"{translate('مسارك:', current_lang_code)} {translate(_r, current_lang_code)}")
            st.caption(
                f"{translate('من:', current_lang_code)} {translate(_pk, current_lang_code)} → "
                f"{translate('إلى:', current_lang_code)} {translate(_dz, current_lang_code)}"
            )
            if _ekm > 0:
                st.markdown(
                    f"**{translate('📏 المسافة التقريبية بين نقطة الانطلاق والوجهة:', current_lang_code)}** "
                    f"~**{_ekm:.1f}** {translate('كم', current_lang_code)}"
                )
            else:
                st.caption(translate("المسافة التقريبية غير متوفرة لهذا المسار.", current_lang_code))

            if current_req['status'] == 'pending':
                st.warning(translate("⏳ جاري البحث عن سيارة في منطقتك... يرجى الانتظار.", current_lang_code))
                if st.button("🔄 " + translate("تحديث الحالة", current_lang_code)): st.rerun()
            elif current_req['status'] == 'accepted':
                st.success(
                    f"{translate('✅ تم التأكيد!', current_lang_code)} "
                    f"{translate('السائق', current_lang_code)} [{current_req['driver_name']}] "
                    f"{translate('في الطريق إليك.', current_lang_code)}"
                )
                st.download_button("🧾 " + translate("تحميل الفاتورة (PDF)", current_lang_code), data="Receipt Data Mock", file_name="taxi_pro_receipt.pdf")
            
            st.divider()
            if st.button("❌ " + translate("إلغاء الرحلة", current_lang_code), type="secondary", use_container_width=True):
                current_req['status'] = 'cancelled'
                st.warning(translate("تم إلغاء الطلب بنجاح.", current_lang_code))
                time.sleep(1)
                st.rerun()

    with t2:
        chat_container = st.container(height=250)
        with chat_container:
            for msg in st.session_state.chat_history:
                t_msg = translate(msg["text"], current_lang_code)
                if msg["role"] == "passenger": st.chat_message("user", avatar="🌍").write(t_msg)
                else: st.chat_message("assistant", avatar="🚕").write(t_msg)
        if prompt := st.chat_input(translate("اكتب رسالتك (ستُترجم آلياً)...", current_lang_code)):
            st.session_state.chat_history.append({"role": "passenger", "text": prompt})
            st.rerun()
            
    with t3:
        st.error(translate("🚨 زر الطوارئ المباشر", current_lang_code))
        st.markdown(
            f'<a href="tel:+21600000000" style="text-decoration:none;"><button type="button" style="width:100%; cursor:pointer; '
            f"background:linear-gradient(180deg,#ef4444,#b91c1c); color:white; border:none; padding:12px; border-radius:12px; "
            f"font-weight:600; box-shadow:0 6px 18px rgba(185,28,28,0.35);"
            f'">📞 {translate("اتصل بالإدارة فوراً", current_lang_code)}</button></a>',
            unsafe_allow_html=True,
        )
        st.divider()
        st.write(translate("⭐ تقييم السائق:", current_lang_code))
        stars = st.feedback("stars")
        if stars is not None: st.toast(translate("شكراً على تقييمك!", current_lang_code))
        st.divider()
        if st.button("🗑️ " + translate("حذف حسابي نهائياً", current_lang_code)):
            st.warning(translate("تم مسح بياناتك من النظام.", current_lang_code))
        with st.expander("📄 " + translate("شروط الاستخدام وسياسة الخصوصية", current_lang_code)):
            st.markdown(
                f"<small><b>1. {translate('حماية البيانات (GDPR):', current_lang_code)}</b> "
                f"{translate('بياناتك الشخصية وموقعك الجغرافي محمية.', current_lang_code)}<br>"
                f"<b>2. {translate('التسعيرة:', current_lang_code)}</b> "
                f"{translate('الأسعار المعروضة نهائية وثابتة ولا توجد رسوم خفية.', current_lang_code)}</small>",
                unsafe_allow_html=True,
            )

# ==========================================
# 🏢 6. بوابة الفنادق والشركات (B2B)
# ==========================================
elif role == "Corporate B2B":
    st.header("💼 " + translate("بوابة النزل والشركات (B2B)", current_lang_code))
    comp_pw = st.text_input(translate("كود النزل أو الشركة (مثال: Hotel2026):", current_lang_code), type="password")
    
    if comp_pw == "Hotel2026":
        st.success(translate("✅ متصل بنظام الفنادق (عمولتك 5% مضمونة على كل رحلة).", current_lang_code))
        col1, col2 = st.columns(2)
        guest_name = col1.text_input(translate("اسم الضيف (VIP):", current_lang_code))
        room_number = col2.text_input(translate("رقم الغرفة:", current_lang_code))
        
        route = st.selectbox(translate("اختر مسار الضيف:", current_lang_code), options=list(st.session_state.fares_db.keys()), format_func=lambda x: translate(x, current_lang_code))
        current_price = st.session_state.fares_db[route]
        st.info(f"💰 {translate('السعر الثابت للضيف:', current_lang_code)} {current_price:.1f} DT")
        
        if st.button(translate("🚀 طلب سيارة للضيف الآن", current_lang_code), type="primary", use_container_width=True):
            if guest_name:
                pickup_zone = route.split("➡️")[0].strip()
                new_req = {
                    'id': int(time.time()), 'route': route, 'pickup_zone': pickup_zone,
                    'price': current_price, 'status': 'pending', 'driver_name': '',
                    'guest_name': guest_name, 'source': comp_pw 
                }
                st.session_state.live_requests.append(new_req)
                st.success(translate("✅ تم إرسال الطلب! عمولتك مضمونة.", current_lang_code))
                time.sleep(2)
                st.rerun()
            else:
                st.error(translate("⚠️ الرجاء إدخال اسم الضيف لتأكيد الحجز.", current_lang_code))

# ==========================================
# 👤 7. واجهة السائق
# ==========================================
elif role == "Driver":
    st.markdown(f"### 👤 {translate('تسجيل دخول السائق', current_lang_code)}")
    col1, col2 = st.columns(2)
    phone_input = col1.text_input(translate("رقم الهاتف:", current_lang_code))
    pin_input = col2.text_input(translate("الكود السري (PIN):", current_lang_code), type="password")
    
    if st.button(translate("تسجيل الدخول", current_lang_code)):
        if phone_input in st.session_state.drivers_db and st.session_state.drivers_db[phone_input]['pin'] == pin_input:
            st.session_state.logged_in_driver = phone_input
        else:
            st.error(translate("❌ بيانات الدخول خاطئة!", current_lang_code))
            
    if 'logged_in_driver' in st.session_state and st.session_state.logged_in_driver in st.session_state.drivers_db:
        driver_phone = st.session_state.logged_in_driver
        driver_data = st.session_state.drivers_db[driver_phone]
        
        st.success(
            f"{translate('مرحباً', current_lang_code)} {driver_data['name']} | "
            f"{translate('رصيدك:', current_lang_code)} {driver_data['wallet']:.3f} DT"
        )
        st.warning("🛡️ " + translate("نظام تتبع الموقع محمي. يمنع استخدام تطبيقات تزييف الموقع (Fake GPS).", current_lang_code))

        _js_title = json.dumps(translate("🚕 Taxi Pro", current_lang_code))
        _js_body = json.dumps(translate("يوجد طلبات جديدة!", current_lang_code))
        components.html(
            f"""
            <script>
                if (Notification.permission !== "granted") {{ Notification.requestPermission(); }}
                function triggerAlert() {{
                    if (Notification.permission === "granted") {{
                        new Notification({_js_title}, {{ body: {_js_body}, vibrate: [200, 100, 200] }});
                    }}
                }}
                setTimeout(triggerAlert, 3000);
            </script>
            """,
            height=0,
        )

        locations = ["مطار قرطاج", "مطار النفيضة", "مطار المنستير", "وسط سوسة", "الحمامات", "نابل"]
        new_location = st.selectbox(
            translate("📍 موقعك الجغرافي الحالي:", current_lang_code),
            locations,
            index=locations.index(driver_data["location"]) if driver_data["location"] in locations else 0,
            format_func=lambda x: translate(x, current_lang_code),
        )
        st.session_state.drivers_db[driver_phone]['location'] = new_location
        
        d0, d1, d2, d3 = st.tabs(
            [
                translate("✈️ وصولات اليوم", current_lang_code),
                translate("📡 الرادار", current_lang_code),
                translate("💳 المحفظة", current_lang_code),
                translate("💬 المحادثة", current_lang_code),
            ]
        )

        with d0:
            render_inbound_flights_block(current_lang_code)

        with d1:
            if driver_data['wallet'] < -5.0:
                st.error(translate("❌ رصيدك سلبي! اشحن محفظتك لتلقي الطلبات.", current_lang_code))
            else:
                if st.button("🔄 " + translate("تحديث الرادار", current_lang_code)): st.rerun()
                
                pending_reqs = [r for r in st.session_state.live_requests if r['status'] == 'pending' and r['pickup_zone'] == new_location]
                my_active = [r for r in st.session_state.live_requests if r['status'] == 'accepted' and r['driver_name'] == driver_data['name']]
                
                if len(my_active) > 0:
                    active_ride = my_active[0]
                    guest_info = ""
                    if "guest_name" in active_ride:
                        guest_info = f" ({translate('الضيف:', current_lang_code)} {active_ride['guest_name']})"
                    st.warning(
                        f"🚨 {translate('رحلة جارية:', current_lang_code)} "
                        f"{translate(active_ride['route'], current_lang_code)}{guest_info}"
                    )

                    if st.button(translate("🏁 إنهاء الرحلة وتسجيل العمولة", current_lang_code), type="primary", use_container_width=True):
                        calc_comm = active_ride['price'] * (st.session_state.commission_rate / 100)
                        st.session_state.drivers_db[driver_phone]['wallet'] -= calc_comm
                        ride_source = active_ride.get('source', 'App') 
                        new_trip = pd.DataFrame([[datetime.now().strftime("%Y-%m-%d %H:%M"), driver_data['name'], active_ride['route'], active_ride['price'], calc_comm, ride_source, 5]], columns=['Date', 'Driver', 'Route', 'Fare', 'Commission', 'Source', 'Rating'])
                        st.session_state.db_trips = pd.concat([st.session_state.db_trips, new_trip], ignore_index=True)
                        active_ride['status'] = 'completed'
                        st.session_state.chat_history = []
                        st.success(f"{translate('تم خصم', current_lang_code)} {calc_comm:.3f} DT.")
                        time.sleep(1.5)
                        st.rerun()

                    if st.button(translate("⚠️ إلغاء الرحلة (عطب طارئ)", current_lang_code), type="secondary", use_container_width=True):
                        active_ride['status'] = 'pending'
                        active_ride['driver_name'] = ''
                        st.session_state.chat_history = []
                        st.error(translate("تم التخلي عن الرحلة وإعادتها للرادار.", current_lang_code))
                        time.sleep(1.5)
                        st.rerun()
                        
                elif len(pending_reqs) > 0:
                    st.error("🔔 " + translate("يوجد طلبات جديدة في منطقتك!", current_lang_code))
                    for req in pending_reqs:
                        g_name = ""
                        if "guest_name" in req:
                            g_name = f" | {translate('الضيف:', current_lang_code)} {req['guest_name']}"
                        st.info(
                            f"📍 {translate(req['route'], current_lang_code)} | 💰 {req['price']} DT{g_name}"
                        )
                        if st.button(translate("✅ قبول الرحلة", current_lang_code), key=req['id']):
                            req['status'] = 'accepted'
                            req['driver_name'] = driver_data['name']
                            st.rerun()
                else:
                    st.write(translate("لا يوجد طلبات في منطقتك حالياً.", current_lang_code))

        with d2:
            st.markdown(
                f"### 💳 {translate('رصيدك الحالي:', current_lang_code)} *{driver_data['wallet']:.3f} DT*"
            )
            st.write(translate("لشحن الرصيد، يرجى التوجه لمكاتبنا أو الدفع للمشرف عبر D17.", current_lang_code))
            
        with d3:
            chat_container = st.container(height=250)
            with chat_container:
                for msg in st.session_state.chat_history:
                    t_msg = translate(msg["text"], current_lang_code)
                    if msg["role"] == "passenger": st.chat_message("user", avatar="🌍").write(t_msg)
                    else: st.chat_message("assistant", avatar="🚕").write(t_msg)
            if prompt := st.chat_input(translate("رسالة للحريف...", current_lang_code)):
                st.session_state.chat_history.append({"role": "driver", "text": prompt})
                st.rerun()

# ==========================================
# 🎧 8. واجهة الموظف (Operator)
# ==========================================
elif role == "Operator":
    op_pw = st.text_input(translate("كلمة السر للموظف:", current_lang_code), type="password")
    if op_pw == "Op2026":
        st.success(translate("✅ مرحباً بك في غرفة العمليات.", current_lang_code))
        t0, t1, t2, t3 = st.tabs(
            [
                translate("✈️ وصولات اليوم", current_lang_code),
                translate("🛰️ الطلبات الحية", current_lang_code),
                translate("👤 إدارة السائقين", current_lang_code),
                translate("📑 سجل الرحلات", current_lang_code),
            ]
        )

        with t0:
            render_inbound_flights_block(current_lang_code)

        with t1:
            pending_reqs = [r for r in st.session_state.live_requests if r["status"] == "pending"]
            if len(pending_reqs) == 0:
                st.info(translate("لا توجد طلبات معلقة.", current_lang_code))
            for req in pending_reqs:
                st.warning(
                    f"{translate('الرحلة:', current_lang_code)} {translate(req['route'], current_lang_code)} | "
                    f"{translate('المنطقة:', current_lang_code)} {translate(req['pickup_zone'], current_lang_code)} | "
                    f"{translate('السعر:', current_lang_code)} {req['price']} DT"
                )

        with t2:
            cc1, cc2, cc3 = st.columns(3)
            new_phone = cc1.text_input(translate("رقم الهاتف:", current_lang_code))
            new_name = cc2.text_input(translate("اسم السائق:", current_lang_code))
            new_pin = cc3.text_input(translate("كود الدخول:", current_lang_code))
            if st.button(translate("➕ إنشاء حساب", current_lang_code), type="primary"):
                st.session_state.drivers_db[new_phone] = {
                    "name": new_name,
                    "pin": new_pin,
                    "wallet": 0.0,
                    "location": "وسط سوسة",
                }
                st.success(translate("تمت الإضافة بنجاح!", current_lang_code))

            st.divider()
            s_phone = st.selectbox(
                translate("اختر السائق لشحن الرصيد:", current_lang_code),
                list(st.session_state.drivers_db.keys()),
                format_func=lambda x: st.session_state.drivers_db[x]["name"],
            )
            amount = st.number_input(
                translate("المبلغ المقبوض (DT):", current_lang_code),
                min_value=1.0,
                value=10.0,
            )
            if st.button(translate("💰 شحن الرصيد", current_lang_code)):
                st.session_state.drivers_db[s_phone]["wallet"] += amount
                st.success(translate("تم الشحن بنجاح.", current_lang_code))

        with t3:
            if not st.session_state.db_trips.empty:
                safe_df = st.session_state.db_trips.drop(columns=["Commission"])
                st.dataframe(safe_df, use_container_width=True)
            else:
                st.write(translate("لا توجد رحلات منجزة بعد.", current_lang_code))

# ==========================================
# 👑 9. لوحة المالك (Admin HQ)
# ==========================================
elif role == "Admin HQ":
    admin_pw = st.text_input(translate("كلمة السر للمالك (CEO):", current_lang_code), type="password")
    if admin_pw == "NabeulGold2026":
        t0, t1, t2, t3 = st.tabs(
            [
                translate("✈️ وصولات اليوم", current_lang_code),
                translate("💰 الخزنة والأرباح", current_lang_code),
                translate("⚙️ الإعدادات", current_lang_code),
                translate("🏨 حسابات النزل (B2B)", current_lang_code),
            ]
        )

        with t0:
            render_inbound_flights_block(current_lang_code)

        with t1:
            total_profit = (
                st.session_state.db_trips["Commission"].sum()
                if not st.session_state.db_trips.empty
                else 0.0
            )
            c1, c2 = st.columns(2)
            c1.metric(translate("المرابيح الصافية للشركة (DT)", current_lang_code), f"{total_profit:.3f}")
            c2.metric(translate("إجمالي الرحلات", current_lang_code), len(st.session_state.db_trips))
            st.dataframe(st.session_state.db_trips, use_container_width=True)

        with t2:
            st.session_state.commission_rate = st.slider(
                translate("نسبة العمولة المقتطعة (%):", current_lang_code),
                1.0,
                30.0,
                st.session_state.commission_rate,
                1.0,
            )
            st.divider()
            updated_fares = {}
            for r_name, c_fare in st.session_state.fares_db.items():
                updated_fares[r_name] = st.number_input(
                    translate(r_name, current_lang_code),
                    value=float(c_fare),
                    step=5.0,
                    key=f"fare_edit_{r_name}",
                )
            if st.button(translate("💾 حفظ التعديلات", current_lang_code), type="primary"):
                st.session_state.fares_db = updated_fares
                st.success(translate("✅ تم تحديث الأسعار!", current_lang_code))

        with t3:
            if not st.session_state.db_trips.empty:
                b2b_trips = st.session_state.db_trips[st.session_state.db_trips["Source"] != "App"]
                if not b2b_trips.empty:
                    b2b_summary = b2b_trips.groupby("Source").agg(
                        Total_Rides=("Date", "count"),
                        Total_Revenue=("Fare", "sum"),
                    ).reset_index()
                    b2b_summary["Hotel_Commission_5% (DT)"] = b2b_summary["Total_Revenue"] * 0.05
                    b2b_summary.rename(
                        columns={
                            "Source": translate("كود النزل / الشركة", current_lang_code),
                            "Total_Rides": translate("عدد الرحلات", current_lang_code),
                            "Total_Revenue": translate("مجموع الدخل (DT)", current_lang_code),
                            "Hotel_Commission_5% (DT)": translate("عمولة النزل 5% (DT)", current_lang_code),
                        },
                        inplace=True,
                    )
                    st.dataframe(b2b_summary, use_container_width=True)
                else:
                    st.write(translate("لم تقم الفنادق بأي حجوزات حتى الآن.", current_lang_code))
            else:
                st.write(translate("الجدول المالي فارغ.", current_lang_code))