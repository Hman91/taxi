import streamlit as st
import pandas as pd
import numpy as np
import urllib.parse
from datetime import datetime
import time

# ==========================================
# 1. إعدادات النظام الأساسية
# ==========================================
st.set_page_config(page_title="Taxi Pro Tunisia 🇹🇳", page_icon="🚕", layout="wide")

# تهيئة قاعدة البيانات السحابية (محاكاة لـ Google Sheets لتفادي الأخطاء قبل ربط الـ API)
if 'db_trips' not in st.session_state:
    st.session_state.db_trips = pd.DataFrame(columns=['Date', 'Driver', 'Route', 'Fare', 'Commission', 'Type', 'Status'])
if 'driver_ratings' not in st.session_state: 
    st.session_state.driver_ratings = []
if 'admin_profit' not in st.session_state: 
    st.session_state.admin_profit = 0.0

# تعريفة المطارات الثابتة (All Inclusive)
fares_db = {
    "مطار قرطاج (TUN) -> نابل / الحمامات": 120.0,
    "مطار قرطاج (TUN) -> سوسة / القنطاوي": 160.0,
    "مطار النفيضة (NBE) -> الحمامات": 80.0,
    "مطار النفيضة (NBE) -> سوسة": 70.0,
    "مطار المنستير (MIR) -> سوسة / القنطاوي": 40.0,
    "مطار المنستير (MIR) -> نابل / الحمامات": 150.0
}

# ==========================================
# 2. محرك القوانين التونسية والتسعيرة
# ==========================================
def calculate_fare(base_fare):
    current_hour = datetime.now().hour
    # زيادة الليل 50% من 21:00 حتى 05:00
    is_night = current_hour >= 21 or current_hour < 5
    final_price = base_fare * 1.5 if is_night else base_fare
    return final_price, is_night

def calculate_gps_fare(distance_km):
    # تعريفة الكيلومتر التقريبية
    PRISE_EN_CHARGE = 1.000 
    PRIX_PAR_KM = 1.200 
    base_fare = PRISE_EN_CHARGE + (distance_km * PRIX_PAR_KM)
    return calculate_fare(base_fare)

# ==========================================
# 3. القائمة الجانبية (Navigation)
# ==========================================
st.sidebar.title("🚕 Taxi Pro System")
lang = st.sidebar.radio("اللغة / Langue", ["الدارجة 🇹🇳", "English 🇬🇧", "Français 🇫🇷"])
role = st.sidebar.selectbox("الدخول بصفتي / Login as:", 
    ["🌍 الحريف (Passenger)", "👤 السائق (Driver)", "🏢 حساب الشركات (B2B)", "🎧 الموظف (Operator)", "👑 المالك (Owner)"])

# ==========================================
# 👑 4. لوحة المالك (The CEO Dashboard)
# ==========================================
if role == "👑 المالك (Owner)":
    st.header("💰 مركز القيادة والتحكم (HQ)")
    pw = st.text_input("كلمة السر الإدارية:", type="password")
    
    if pw == "NabeulGold2026":
        col1, col2, col3 = st.columns(3)
        total_profit = st.session_state.db_trips['Commission'].sum()
        col1.metric("أرباح الشركة (DT)", f"{total_profit:.3f}")
        col2.metric("إجمالي الرحلات", len(st.session_state.db_trips))
        
        avg_rate = sum(st.session_state.driver_ratings)/len(st.session_state.driver_ratings) if st.session_state.driver_ratings else 5.0
        col3.metric("معدل رضا الحرفاء", f"{avg_rate:.1f} ⭐")
        
        st.divider()
        st.subheader("📑 الخزنة السحابية (سجل الرحلات)")
        st.dataframe(st.session_state.db_trips, use_container_width=True)
        if st.button("📥 تحميل التقرير (Excel)"):
            st.success("تم تصدير التقرير بنجاح للمحاسب.")
    elif pw: st.error("❌ وصول مرفوض.")

# ==========================================
# 👤 5. لوحة السائق (Driver Portal)
# ==========================================
elif role == "👤 السائق (Driver)":
    st.header("🚕 بوابة السائق المحترف")
    driver_code = st.text_input("الكود السري للسائق:", type="password")
    
    if driver_code == "Driver2026":
        t1, t2, t3 = st.tabs(["📡 رادار الرحلات", "🛡️ الدرع القانوني", "💰 إنهاء الرحلة"])
        with t1:
            st.info("✈️ رادار المطارات: طائرة باريس تصل النفيضة 18:45")
        with t2:
            st.warning("⚠️ VOUCHER VIP #TP2026 - ترخيص نقل سياحي نشط.")
        with t3:
            route = st.text_input("المسار المنفذ:")
            price = st.number_input("سعر الرحلة المقبوض (DT):", min_value=0.0, value=20.0)
            trip_type = st.radio("نوع الدفع:", ["كاش / بطاقة", "فاتورة شركة (B2B)"])
            
            if st.button("🏁 إنهاء وخلاص العمولة (10%)"):
                comm = price * 0.10
                new_trip = pd.DataFrame([[datetime.now().strftime("%Y-%m-%d %H:%M"), "سائق نشط", route, price, comm, trip_type, "Done"]], 
                                     columns=['Date', 'Driver', 'Route', 'Fare', 'Commission', 'Type', 'Status'])
                st.session_state.db_trips = pd.concat([st.session_state.db_trips, new_trip], ignore_index=True)
                st.balloons()
                st.success("✅ تم تسجيل الرحلة في الخزنة السحابية!")
    elif driver_code: st.error("❌ كود غير صحيح.")

# ==========================================
# 🏢 6. بوابة الشركات والنزل (B2B)
# ==========================================
elif role == "🏢 حساب الشركات (B2B)":
    st.header("💼 بوابة الشركات والنزل (Taxi Pro Corporate)")
    comp_pw = st.text_input("كود الشركة (مثال: نزل المرادي):", type="password")
    
    if comp_pw == "Biz2026":
        st.success("✅ متصل بنظام الفوترة الشهري.")
        emp_name = st.text_input("اسم الموظف أو الضيف الـ VIP:")
        dest = st.text_input("إلى أين؟")
        if st.button("🚀 طلب سيارة على حساب الشركة"):
            st.info("✅ السائق في الطريق. سيتم تسجيل التكلفة في فاتورة آخر الشهر.")
            
        st.divider()
        st.subheader("📊 استهلاك الشهر الحالي")
        st.metric("المبلغ المستحق (DT)", "450.000")
        st.button("📥 تحميل الفاتورة (PDF)")

# ==========================================
# 🌍 7. واجهة الحريف (Passenger UI)
# ==========================================
elif role == "🌍 الحريف (Passenger)":
    st.markdown("<h1 style='text-align: center;'>🇹🇳 Taxi Pro VIP</h1>", unsafe_allow_html=True)
    
    t_fixed, t_gps, t_sos = st.tabs(["✈️ رحلات المطارات", "🗺️ مسار مخصص (GPS)", "🚨 طوارئ ومفقودات"])
    
    # --- قسم المطارات ---
    with t_fixed:
        route_choice = st.selectbox("اختار المسار / Select Route:", list(fares_db.keys()))
        base_p = fares_db[route_choice]
        final_p, is_night = calculate_fare(base_p)
        
        st.markdown(f"""
            <div style="background:#222; color:#FFD700; padding:15px; border-radius:10px; text-align:center; border:2px solid #FFD700;">
                <h1 style="margin:0;">{final_p:.3f} DT</h1>
                <small>✅ All Inclusive (أمتعة + طريق سيارة)</small>
            </div>
        """, unsafe_allow_html=True)
        if is_night: st.error("🌙 +50% Night Fare Applied")
        
        pay_method = st.radio("الدفع / Payment:", ["💵 Cash", "💳 Card (TPE)"])
        
        col1, col2 = st.columns(2)
        with col1:
            if st.button("🚀 Book Airport Transfer", use_container_width=True):
                with st.spinner("Finding VIP Driver..."):
                    time.sleep(2)
                    st.success("✅ Driver is on the way! (Code: 🍎)")
        with col2:
            msg = urllib.parse.quote(f"Booking: {route_choice} | Price: {final_p} DT | Pay: {pay_method}")
            st.markdown(f'<a href="https://wa.me/21600000000?text={msg}" target="_blank"><button style="width:100%; background:#25D366; color:white; border:none; padding:7px; border-radius:5px;">💬 WhatsApp</button></a>', unsafe_allow_html=True)

    # --- قسم الـ GPS ---
    with t_gps:
        dep = st.text_input("📍 نقطة الانطلاق / From:")
        arr = st.text_input("🏁 الوجهة / To:")
        if dep and arr:
            # محاكاة لـ Google Maps
            dist_km = np.random.uniform(2.0, 20.0) 
            g_price, g_night = calculate_gps_fare(dist_km)
            
            st.info(f"📏 Estimated Distance: {dist_km:.1f} KM")
            st.success(f"💰 Estimated Fare: {g_price:.3f} DT")
            if st.button("🚀 Request Ride"):
                st.success("✅ GPS Request sent to nearby drivers.")
                st.map(pd.DataFrame({'lat': [35.82539], 'lon': [10.63699]}), zoom=13) # خريطة سوسة

    # --- قسم الطوارئ ---
    with t_sos:
        st.error("🚨 هل فقدت شيئاً في السيارة أو تحتاج لمساعدة عاجلة؟")
        st.write("مركز خدمة العملاء يعمل 24/7.")
        st.markdown('<a href="tel:+21600000000"><button style="width:100%; background:red; color:white; border:none; padding:10px;">📞 اتصل بالإدارة فوراً</button></a>', unsafe_allow_html=True)

    # --- نظام التقييم (يظهر دائماً للحريف) ---
    st.divider()
    st.write("⭐ **قيم تجربتك الأخيرة / Rate your last ride:**")
    stars = st.feedback("stars")
    if stars is not None:
        st.session_state.driver_ratings.append(stars + 1)
        st.toast("Thank you for your feedback! 🙏")

# ==========================================
# 🎧 8. لوحة الموظف (Call Center Operator)
# ==========================================
elif role == "🎧 الموظف (Operator)":
    st.header("🎧 مركز النداء والمراقبة (Dispatch)")
    st.info("✅ نظام الواتساب متصل. لا توجد حجوزات معلقة.")
    st.dataframe(st.session_state.db_trips)
