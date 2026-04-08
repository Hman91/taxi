import streamlit as st
import pandas as pd
import urllib.parse
from datetime import datetime
import time
from deep_translator import GoogleTranslator
import streamlit.components.v1 as components

# ==========================================
# 1. إعدادات النظام وتوافق الهاتف
# ==========================================
st.set_page_config(page_title="Taxi Pro Tunisia 🇹🇳", page_icon="🚕", layout="centered")

# ==========================================
# 2. تهيئة قواعد البيانات السحابية (الذاكرة)
# ==========================================
if 'chat_history' not in st.session_state: st.session_state.chat_history = []
if 'db_trips' not in st.session_state: st.session_state.db_trips = pd.DataFrame(columns=['Date', 'Driver', 'Route', 'Fare', 'Commission', 'Source', 'Rating'])
if 'commission_rate' not in st.session_state: st.session_state.commission_rate = 10.0  
if 'fares_db' not in st.session_state: 
    st.session_state.fares_db = {
        "مطار قرطاج ➡️ الحمامات": 120.0, 
        "مطار النفيضة ➡️ سوسة": 70.0, 
        "مطار المنستير ➡️ القنطاوي": 40.0, 
        "وسط سوسة ➡️ نابل": 80.0
    }

if 'drivers_db' not in st.session_state:
    st.session_state.drivers_db = {
        "98123456": {"name": "خليل (سائق 1)", "pin": "1234", "wallet": 20.0, "location": "مطار النفيضة"},
        "50111222": {"name": "أحمد (سائق 2)", "pin": "0000", "wallet": 15.0, "location": "مطار قرطاج"}
    }

if 'live_requests' not in st.session_state: st.session_state.live_requests = [] 

# ==========================================
# 3. نظام اللغات والترجمة الفورية (8 لغات)
# ==========================================
lang_codes = {
    "الدارجة 🇹🇳": "ar", "English 🇬🇧": "en", "Français 🇫🇷": "fr", 
    "Deutsch 🇩🇪": "de", "Italiano 🇮🇹": "it", "Español 🇪🇸": "es", 
    "Русский 🇷🇺": "ru", "中文 🇨🇳": "zh-CN"
}
lang_choice = st.sidebar.selectbox("🌐 لغتك / Language:", list(lang_codes.keys()))
current_lang_code = lang_codes[lang_choice]

@st.cache_data(show_spinner=False, ttl=3600)
def translate(text, target_lang):
    if target_lang == 'ar': return text
    try: return GoogleTranslator(source='auto', target=target_lang).translate(text)
    except: return text 

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
    st.markdown(f"<h2 style='text-align: center; color: #FFD700;'>✈️ {translate('حجز تاكسي VIP', current_lang_code)}</h2>", unsafe_allow_html=True)
    
    my_active_requests = [r for r in st.session_state.live_requests if r['status'] in ['pending', 'accepted']]
    
    t1, t2, t3 = st.tabs([translate("🚕 الرحلة", current_lang_code), translate("💬 المحادثة", current_lang_code), translate("⚙️ الإعدادات", current_lang_code)])
    
    with t1:
        if len(my_active_requests) == 0:
            route = st.selectbox(translate("اختر مسارك:", current_lang_code), options=list(st.session_state.fares_db.keys()), format_func=lambda x: translate(x, current_lang_code))
            current_price = st.session_state.fares_db[route]
            pickup_zone = route.split("➡️")[0].strip()
            
            promo_code = st.text_input(translate("كود التخفيض (إن وجد):", current_lang_code))
            if promo_code == "WELCOME26":
                current_price = current_price * 0.8  
                st.success(translate("🎉 تم تفعيل التخفيض بنسبة 20%!", current_lang_code))
            
            st.markdown(f"<div style='background:#1e1e1e; color:#FFD700; padding:15px; border-radius:10px; text-align:center; margin-bottom:15px;'><h1 style='margin:0;'>{current_price:.1f} DT</h1></div>", unsafe_allow_html=True)
            
            if st.button(translate("🚀 اطلب التاكسي الآن", current_lang_code), use_container_width=True, type="primary"):
                new_req = {
                    'id': int(time.time()), 'route': route, 'pickup_zone': pickup_zone, 
                    'price': current_price, 'status': 'pending', 'driver_name': '', 'source': 'App'
                }
                st.session_state.live_requests.append(new_req)
                st.success(translate("تم إرسال طلبك للسائقين القريبين منك...", current_lang_code))
                time.sleep(1.5)
                st.rerun()
                
        else:
            current_req = my_active_requests[-1]
            st.info(f"{translate('مسارك:', current_lang_code)} {current_req['route']}")
            
            if current_req['status'] == 'pending':
                st.warning(translate("⏳ جاري البحث عن سيارة في منطقتك... يرجى الانتظار.", current_lang_code))
                if st.button("🔄 " + translate("تحديث الحالة", current_lang_code)): st.rerun()
            elif current_req['status'] == 'accepted':
                st.success(translate("✅ تم التأكيد!", current_lang_code) + f" السائق [{current_req['driver_name']}] في الطريق إليك.")
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
        st.markdown(f'<a href="tel:+21600000000"><button style="width:100%; background:red; color:white; border:none; padding:10px; border-radius:5px;">📞 {translate("اتصل بالإدارة فوراً", current_lang_code)}</button></a>', unsafe_allow_html=True)
        st.divider()
        st.write(translate("⭐ تقييم السائق:", current_lang_code))
        stars = st.feedback("stars")
        if stars is not None: st.toast(translate("شكراً على تقييمك!", current_lang_code))
        st.divider()
        if st.button("🗑️ " + translate("حذف حسابي نهائياً", current_lang_code)):
            st.warning(translate("تم مسح بياناتك من النظام.", current_lang_code))
        with st.expander("📄 " + translate("شروط الاستخدام وسياسة الخصوصية", current_lang_code)):
            st.markdown(f"<small><b>1. GDPR:</b> {translate('بياناتك الشخصية وموقعك الجغرافي محمية.', current_lang_code)}<br><b>2. Pricing:</b> {translate('الأسعار المعروضة نهائية وثابتة ولا توجد رسوم خفية.', current_lang_code)}</small>", unsafe_allow_html=True)

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
    
    if st.button("تسجيل الدخول"):
        if phone_input in st.session_state.drivers_db and st.session_state.drivers_db[phone_input]['pin'] == pin_input:
            st.session_state.logged_in_driver = phone_input
        else:
            st.error(translate("❌ بيانات الدخول خاطئة!", current_lang_code))
            
    if 'logged_in_driver' in st.session_state and st.session_state.logged_in_driver in st.session_state.drivers_db:
        driver_phone = st.session_state.logged_in_driver
        driver_data = st.session_state.drivers_db[driver_phone]
        
        st.success(f"{translate('مرحباً', current_lang_code)} {driver_data['name']} | رصيدك: {driver_data['wallet']:.3f} DT")
        st.warning("🛡️ " + translate("نظام تتبع الموقع محمي. يمنع استخدام تطبيقات تزييف الموقع (Fake GPS).", current_lang_code))

        components.html("""
            <script>
                if (Notification.permission !== "granted") { Notification.requestPermission(); }
                function triggerAlert() {
                    if (Notification.permission === "granted") {
                        new Notification('🚕 Taxi Pro', { body: 'يوجد طلبات جديدة!', vibrate: [200, 100, 200] });
                    }
                }
                setTimeout(triggerAlert, 3000);
            </script>
        """, height=0)

        locations = ["مطار قرطاج", "مطار النفيضة", "مطار المنستير", "وسط سوسة", "الحمامات", "نابل"]
        new_location = st.selectbox("📍 موقعك الجغرافي الحالي:", locations, index=locations.index(driver_data['location']) if driver_data['location'] in locations else 0)
        st.session_state.drivers_db[driver_phone]['location'] = new_location
        
        d1, d2, d3 = st.tabs([translate("📡 الرادار", current_lang_code), translate("💳 المحفظة", current_lang_code), translate("💬 المحادثة", current_lang_code)])
        
        with d1:
            if driver_data['wallet'] < -5.0:
                st.error(translate("❌ رصيدك سلبي! اشحن محفظتك لتلقي الطلبات.", current_lang_code))
            else:
                if st.button("🔄 " + translate("تحديث الرادار", current_lang_code)): st.rerun()
                
                pending_reqs = [r for r in st.session_state.live_requests if r['status'] == 'pending' and r['pickup_zone'] == new_location]
                my_active = [r for r in st.session_state.live_requests if r['status'] == 'accepted' and r['driver_name'] == driver_data['name']]
                
                if len(my_active) > 0:
                    active_ride = my_active[0]
                    guest_info = f" (الضيف: {active_ride['guest_name']})" if 'guest_name' in active_ride else ""
                    st.warning(f"🚨 رحلة جارية: {active_ride['route']}{guest_info}")
                    
                    if st.button("🏁 إنهاء الرحلة وتسجيل العمولة", type="primary", use_container_width=True):
                        calc_comm = active_ride['price'] * (st.session_state.commission_rate / 100)
                        st.session_state.drivers_db[driver_phone]['wallet'] -= calc_comm
                        ride_source = active_ride.get('source', 'App') 
                        new_trip = pd.DataFrame([[datetime.now().strftime("%Y-%m-%d %H:%M"), driver_data['name'], active_ride['route'], active_ride['price'], calc_comm, ride_source, 5]], columns=['Date', 'Driver', 'Route', 'Fare', 'Commission', 'Source', 'Rating'])
                        st.session_state.db_trips = pd.concat([st.session_state.db_trips, new_trip], ignore_index=True)
                        active_ride['status'] = 'completed'
                        st.session_state.chat_history = [] 
                        st.success(f"تم خصم {calc_comm:.3f} DT.")
                        time.sleep(1.5)
                        st.rerun()
                    
                    if st.button("⚠️ إلغاء الرحلة (عطب طارئ)", type="secondary", use_container_width=True):
                        active_ride['status'] = 'pending'
                        active_ride['driver_name'] = ''
                        st.session_state.chat_history = [] 
                        st.error("تم التخلي عن الرحلة وإعادتها للرادار.")
                        time.sleep(1.5)
                        st.rerun()
                        
                elif len(pending_reqs) > 0:
                    st.error("🔔 " + translate("يوجد طلبات جديدة في منطقتك!", current_lang_code))
                    for req in pending_reqs:
                        g_name = f" | الضيف: {req['guest_name']}" if 'guest_name' in req else ""
                        st.info(f"📍 {req['route']} | 💰 {req['price']} DT{g_name}")
                        if st.button("✅ قبول الرحلة", key=req['id']):
                            req['status'] = 'accepted'
                            req['driver_name'] = driver_data['name']
                            st.rerun()
                else:
                    st.write(translate("لا يوجد طلبات في منطقتك حالياً.", current_lang_code))

        with d2:
            st.markdown(f"### 💳 رصيدك الحالي: *{driver_data['wallet']:.3f} DT*")
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
    op_pw = st.text_input("كلمة السر للموظف:", type="password")
    if op_pw == "Op2026":
        st.success("✅ مرحباً بك في غرفة العمليات.")
        t1, t2, t3 = st.tabs(["🛰️ الطلبات الحية", "👤 إدارة السائقين", "📑 سجل الرحلات"])
        
        with t1:
            pending_reqs = [r for r in st.session_state.live_requests if r['status'] == 'pending']
            if len(pending_reqs) == 0: st.info("لا توجد طلبات معلقة.")
            for req in pending_reqs: st.warning(f"الرحلة: {req['route']} | المنطقة: {req['pickup_zone']} | السعر: {req['price']} DT")
                
        with t2:
            cc1, cc2, cc3 = st.columns(3)
            new_phone = cc1.text_input("رقم الهاتف:")
            new_name = cc2.text_input("اسم السائق:")
            new_pin = cc3.text_input("كود الدخول:")
            if st.button("➕ إنشاء حساب", type="primary"):
                st.session_state.drivers_db[new_phone] = {"name": new_name, "pin": new_pin, "wallet": 0.0, "location": "وسط سوسة"}
                st.success("تمت الإضافة بنجاح!")
            
            st.divider()
            s_phone = st.selectbox("اختر السائق لشحن الرصيد:", list(st.session_state.drivers_db.keys()), format_func=lambda x: st.session_state.drivers_db[x]['name'])
            amount = st.number_input("المبلغ المقبوض (DT):", min_value=1.0, value=10.0)
            if st.button("💰 شحن الرصيد"):
                st.session_state.drivers_db[s_phone]['wallet'] += amount
                st.success(f"تم الشحن بنجاح.")
                
        with t3:
            if not st.session_state.db_trips.empty:
                safe_df = st.session_state.db_trips.drop(columns=['Commission'])
                st.dataframe(safe_df, use_container_width=True)
            else:
                st.write("لا توجد رحلات منجزة بعد.")

# ==========================================
# 👑 9. لوحة المالك (Admin HQ)
# ==========================================
elif role == "Admin HQ":
    admin_pw = st.text_input("كلمة السر للمالك (CEO):", type="password")
    if admin_pw == "NabeulGold2026":
        t1, t2, t3 = st.tabs(["💰 الخزنة والأرباح", "⚙️ الإعدادات", "🏨 حسابات النزل (B2B)"])
        
        with t1:
            total_profit = st.session_state.db_trips['Commission'].sum() if not st.session_state.db_trips.empty else 0.0
            c1, c2 = st.columns(2)
            c1.metric("المرابيح الصافية للشركة (DT)", f"{total_profit:.3f}")
            c2.metric("إجمالي الرحلات", len(st.session_state.db_trips))
            st.dataframe(st.session_state.db_trips, use_container_width=True)
            
        with t2:
            st.session_state.commission_rate = st.slider("نسبة العمولة المقتطعة (%):", 1.0, 30.0, st.session_state.commission_rate, 1.0)
            st.divider()
            updated_fares = {}
            for r_name, c_fare in st.session_state.fares_db.items():
                updated_fares[r_name] = st.number_input(r_name, value=float(c_fare), step=5.0)
            if st.button("💾 حفظ التعديلات", type="primary"):
                st.session_state.fares_db = updated_fares
                st.success("✅ تم تحديث الأسعار!")
                
        with t3:
            if not st.session_state.db_trips.empty:
                b2b_trips = st.session_state.db_trips[st.session_state.db_trips['Source'] != 'App']
                if not b2b_trips.empty:
                    b2b_summary = b2b_trips.groupby('Source').agg(Total_Rides=('Date', 'count'), Total_Revenue=('Fare', 'sum')).reset_index()
                    b2b_summary['Hotel_Commission_5% (DT)'] = b2b_summary['Total_Revenue'] * 0.05
                    b2b_summary.rename(columns={'Source': 'كود النزل / الشركة', 'Total_Rides': 'عدد الرحلات', 'Total_Revenue': 'مجموع الدخل (DT)'}, inplace=True)
                    st.dataframe(b2b_summary, use_container_width=True)
                else:
                    st.write("لم تقم الفنادق بأي حجوزات حتى الآن.")
            else:
                st.write("الجدول المالي فارغ.")