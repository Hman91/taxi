"""
Streamlit prototype — 8 languages (AR, EN, FR, DE, ZH, IT, ES, RU) via deep-translator.
"""
import time
import urllib.parse
from datetime import datetime

import numpy as np
import pandas as pd
import streamlit as st
from deep_translator import GoogleTranslator

# ==========================================
# 1. إعدادات النظام الأساسية
# ==========================================
st.set_page_config(page_title="Taxi Pro Tunisia 🇹🇳", page_icon="🚕", layout="wide")

if "db_trips" not in st.session_state:
    st.session_state.db_trips = pd.DataFrame(
        columns=["Date", "Driver", "Route", "Fare", "Commission", "Type", "Status"]
    )
if "driver_ratings" not in st.session_state:
    st.session_state.driver_ratings = []
if "admin_profit" not in st.session_state:
    st.session_state.admin_profit = 0.0

fares_db = {
    "مطار قرطاج (TUN) -> نابل / الحمامات": 120.0,
    "مطار قرطاج (TUN) -> سوسة / القنطاوي": 160.0,
    "مطار النفيضة (NBE) -> الحمامات": 80.0,
    "مطار النفيضة (NBE) -> سوسة": 70.0,
    "مطار المنستير (MIR) -> سوسة / القنطاوي": 40.0,
    "مطار المنستير (MIR) -> نابل / الحمامات": 150.0,
}

LANG_OPTIONS = [
    ("ar", "العربية 🇹🇳"),
    ("en", "English 🇬🇧"),
    ("fr", "Français 🇫🇷"),
    ("de", "Deutsch 🇩🇪"),
    ("zh-CN", "中文 🇨🇳"),
    ("it", "Italiano 🇮🇹"),
    ("es", "Español 🇪🇸"),
    ("ru", "Русский 🇷🇺"),
]

ROLES = [
    ("passenger", "🌍 الحريف (Passenger)"),
    ("driver", "👤 السائق (Driver)"),
    ("b2b", "🏢 حساب الشركات (B2B)"),
    ("operator", "🎧 الموظف (Operator)"),
    ("owner", "👑 المالك (Owner)"),
]
ROLE_LABEL = dict(ROLES)


@st.cache_data(show_spinner=False, ttl=3600)
def tr_cached(text: str, lang_code: str) -> str:
    if not text or lang_code == "ar":
        return text
    try:
        return GoogleTranslator(source="auto", target=lang_code).translate(text)
    except Exception:
        return text


def calculate_fare(base_fare):
    current_hour = datetime.now().hour
    is_night = current_hour >= 21 or current_hour < 5
    final_price = base_fare * 1.5 if is_night else base_fare
    return final_price, is_night


def calculate_gps_fare(distance_km):
    PRISE_EN_CHARGE = 1.000
    PRIX_PAR_KM = 1.200
    base_fare = PRISE_EN_CHARGE + (distance_km * PRIX_PAR_KM)
    return calculate_fare(base_fare)


# ==========================================
# Sidebar: language + role
# ==========================================
lang_labels = [x[1] for x in LANG_OPTIONS]
_default_lang = st.session_state.get("ui_lang_label", lang_labels[0])
_idx = lang_labels.index(_default_lang) if _default_lang in lang_labels else 0
picked = st.sidebar.selectbox(
    "اللغة / Language",
    lang_labels,
    index=_idx,
    key="sidebar_lang_select",
)
st.session_state.ui_lang_label = picked
lang_code = next(code for code, lab in LANG_OPTIONS if lab == picked)


def tr(text: str) -> str:
    return tr_cached(text, lang_code)


st.sidebar.title(tr("🚕 Taxi Pro System"))
role_key = st.sidebar.selectbox(
    tr("الدخول بصفتي / Login as:"),
    options=[r[0] for r in ROLES],
    format_func=lambda k: tr(ROLE_LABEL[k]),
)

# ==========================================
# Owner
# ==========================================
if role_key == "owner":
    st.header(tr("💰 مركز القيادة والتحكم (HQ)"))
    pw = st.text_input(tr("كلمة السر الإدارية:"), type="password")

    if pw == "NabeulGold2026":
        col1, col2, col3 = st.columns(3)
        total_profit = st.session_state.db_trips["Commission"].sum()
        col1.metric(tr("أرباح الشركة (DT)"), f"{total_profit:.3f}")
        col2.metric(tr("إجمالي الرحلات"), len(st.session_state.db_trips))

        avg_rate = (
            sum(st.session_state.driver_ratings) / len(st.session_state.driver_ratings)
            if st.session_state.driver_ratings
            else 5.0
        )
        col3.metric(tr("معدل رضا الحرفاء"), f"{avg_rate:.1f} ⭐")

        st.divider()
        st.subheader(tr("📑 الخزنة السحابية (سجل الرحلات)"))
        st.dataframe(st.session_state.db_trips, use_container_width=True)
        if st.button(tr("📥 تحميل التقرير (Excel)")):
            st.success(tr("تم تصدير التقرير بنجاح للمحاسب."))
    elif pw:
        st.error(tr("❌ وصول مرفوض."))

# ==========================================
# Driver
# ==========================================
elif role_key == "driver":
    st.header(tr("🚕 بوابة السائق المحترف"))
    driver_code = st.text_input(tr("الكود السري للسائق:"), type="password")

    if driver_code == "Driver2026":
        t1, t2, t3 = st.tabs(
            [
                tr("📡 رادار الرحلات"),
                tr("🛡️ الدرع القانوني"),
                tr("💰 إنهاء الرحلة"),
            ]
        )
        with t1:
            st.info(tr("✈️ رادار المطارات: طائرة باريس تصل النفيضة 18:45"))
        with t2:
            st.warning(tr("⚠️ VOUCHER VIP #TP2026 - ترخيص نقل سياحي نشط."))
        with t3:
            route = st.text_input(tr("المسار المنفذ:"))
            price = st.number_input(tr("سعر الرحلة المقبوض (DT):"), min_value=0.0, value=20.0)
            trip_type = st.radio(
                tr("نوع الدفع:"),
                [tr("كاش / بطاقة"), tr("فاتورة شركة (B2B)")],
            )

            if st.button(tr("🏁 إنهاء وخلاص العمولة (10%)")):
                comm = price * 0.10
                new_trip = pd.DataFrame(
                    [
                        [
                            datetime.now().strftime("%Y-%m-%d %H:%M"),
                            tr("سائق نشط"),
                            route,
                            price,
                            comm,
                            trip_type,
                            "Done",
                        ]
                    ],
                    columns=["Date", "Driver", "Route", "Fare", "Commission", "Type", "Status"],
                )
                st.session_state.db_trips = pd.concat(
                    [st.session_state.db_trips, new_trip], ignore_index=True
                )
                st.balloons()
                st.success(tr("✅ تم تسجيل الرحلة في الخزنة السحابية!"))
    elif driver_code:
        st.error(tr("❌ كود غير صحيح."))

# ==========================================
# B2B
# ==========================================
elif role_key == "b2b":
    st.header(tr("💼 بوابة الشركات والنزل (Taxi Pro Corporate)"))
    comp_pw = st.text_input(tr("كود الشركة (مثال: نزل المرادي):"), type="password")

    if comp_pw == "Biz2026":
        st.success(tr("✅ متصل بنظام الفوترة الشهري."))
        emp_name = st.text_input(tr("اسم الموظف أو الضيف الـ VIP:"))
        dest = st.text_input(tr("إلى أين؟"))
        if st.button(tr("🚀 طلب سيارة على حساب الشركة")):
            st.info(tr("✅ السائق في الطريق. سيتم تسجيل التكلفة في فاتورة آخر الشهر."))

        st.divider()
        st.subheader(tr("📊 استهلاك الشهر الحالي"))
        st.metric(tr("المبلغ المستحق (DT)"), "450.000")
        st.button(tr("📥 تحميل الفاتورة (PDF)"))

# ==========================================
# Passenger
# ==========================================
elif role_key == "passenger":
    st.markdown(
        "<h1 style='text-align: center;'>🇹🇳 Taxi Pro VIP</h1>",
        unsafe_allow_html=True,
    )

    t_fixed, t_gps, t_sos = st.tabs(
        [
            tr("✈️ رحلات المطارات"),
            tr("🗺️ مسار مخصص (GPS)"),
            tr("🚨 طوارئ ومفقودات"),
        ]
    )

    with t_fixed:
        route_choice = st.selectbox(
            tr("اختار المسار / Select Route:"),
            list(fares_db.keys()),
        )
        base_p = fares_db[route_choice]
        final_p, is_night = calculate_fare(base_p)

        st.markdown(
            f"""
            <div style="background:#222; color:#FFD700; padding:15px; border-radius:10px; text-align:center; border:2px solid #FFD700;">
                <h1 style="margin:0;">{final_p:.3f} DT</h1>
                <small>✅ All Inclusive (أمتعة + طريق سيارة)</small>
            </div>
            """,
            unsafe_allow_html=True,
        )
        if is_night:
            st.error(tr("🌙 +50% Night Fare Applied"))

        pay_method = st.radio(tr("الدفع / Payment:"), [tr("💵 Cash"), tr("💳 Card (TPE)")])

        col1, col2 = st.columns(2)
        with col1:
            if st.button(tr("🚀 Book Airport Transfer"), use_container_width=True):
                with st.spinner(tr("Finding VIP Driver...")):
                    time.sleep(2)
                    st.success(tr("✅ Driver is on the way! (Code: 🍎)"))
        with col2:
            msg = urllib.parse.quote(
                f"Booking: {route_choice} | Price: {final_p} DT | Pay: {pay_method}"
            )
            st.markdown(
                f'<a href="https://wa.me/21600000000?text={msg}" target="_blank">'
                f'<button style="width:100%; background:#25D366; color:white; border:none; padding:7px; border-radius:5px;">'
                f"💬 WhatsApp</button></a>",
                unsafe_allow_html=True,
            )

    with t_gps:
        dep = st.text_input(tr("📍 نقطة الانطلاق / From:"))
        arr = st.text_input(tr("🏁 الوجهة / To:"))
        if dep and arr:
            dist_km = np.random.uniform(2.0, 20.0)
            g_price, g_night = calculate_gps_fare(dist_km)

            st.info(f"📏 {tr('Estimated distance')}: {dist_km:.1f} {tr('KM')}")
            st.success(f"💰 {tr('Estimated fare')}: {g_price:.3f} DT")
            if st.button(tr("🚀 Request Ride")):
                st.success(tr("✅ GPS Request sent to nearby drivers."))
                st.map(
                    pd.DataFrame({"lat": [35.82539], "lon": [10.63699]}),
                    zoom=13,
                )

    with t_sos:
        st.error(tr("🚨 هل فقدت شيئاً في السيارة أو تحتاج لمساعدة عاجلة؟"))
        st.write(tr("مركز خدمة العملاء يعمل 24/7."))
        st.markdown(
            '<a href="tel:+21600000000"><button style="width:100%; background:red; color:white; border:none; padding:10px;">'
            + tr("📞 اتصل بالإدارة فوراً")
            + "</button></a>",
            unsafe_allow_html=True,
        )

    st.divider()
    st.write(tr("⭐ **قيم تجربتك الأخيرة / Rate your last ride:**"))
    stars = st.feedback("stars")
    if stars is not None:
        st.session_state.driver_ratings.append(stars + 1)
        st.toast(tr("Thank you for your feedback! 🙏"))

# ==========================================
# Operator
# ==========================================
elif role_key == "operator":
    st.header(tr("🎧 مركز النداء والمراقبة (Dispatch)"))
    st.info(tr("✅ نظام الواتساب متصل. لا توجد حجوزات معلقة."))
    st.dataframe(st.session_state.db_trips)
