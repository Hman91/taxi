import streamlit as st
import pandas as pd
import urllib.parse
from datetime import datetime
import time
from deep_translator import GoogleTranslator

# ==========================================
# 1. إعدادات النظام
# ==========================================
st.set_page_config(page_title="Taxi Pro Tunisia 🇹🇳", page_icon="🚕", layout="centered")

# ==========================================
# 2. تهيئة قواعد البيانات السحابية (الجزء الجديد)
# ==========================================
if 'chat_history' not in st.session_state: st.session_state.chat_history = []
if 'db_trips' not in st.session_state: st.session_state.db_trips = pd.DataFrame(columns=['Date', 'Driver', 'Route', 'Fare', 'Commission'])
if 'commission_rate' not in st.session_state: st.session_state.commission_rate = 10.0  
if 'fares_db' not in st.session_state: 
    st.session_state.fares_db = {"مطار قرطاج ➡️ الحمامات": 120.0, "مطار النفيضة ➡️ سوسة": 70.0, "مطار المنستير ➡️ القنطاوي": 40.0, "وسط سوسة ➡️ نابل": 80.0}

# 🔴 الجديد: قاعدة بيانات السائقين (حسابات فردية)
if 'drivers_db' not in st.session_state:
    st.session_state.drivers_db = {
        "98123456": {"name": "خليل (سائق 1)", "pin": "1234", "wallet": 20.0},
        "50111222": {"name": "أحمد (سائق 2)", "pin": "0000", "wallet": -2.0}
    }

# 🔴 الجديد: رادار الطلبات الحية (Live Dispatching)
if 'live_requests' not in st.session_state:
    st.session_state.live_requests = [] # يخزن الطلبات هكذا: {'id': 1, 'route': '...', 'price': 40, 'status': 'pending', 'driver': ''}

# ==========================================
# 3. نظام اللغات والترجمة الفورية
# ==========================================
lang_codes = {"الدارجة 🇹🇳": "ar", "English 🇬🇧": "en", "Français 🇫🇷": "fr", "Deutsch 🇩🇪": "de"}
lang_choice = st.sidebar.selectbox("🌐 لغتك / Language:", list(lang_codes.keys()))
current_lang_code = lang_codes[lang_choice]

@st.cache_data(show_spinner=False, ttl=3600)
def translate(text, target_lang):
    if target_lang == 'ar': return text
    try: return GoogleTranslator(source='auto', target=target_lang).translate(text)
    except: return text 

# ==========================================
# 4. محرك البوابات
# ==========================================
roles = ["Passenger", "Driver", "Admin HQ"]
role = st.radio(translate("بوابة الدخول:", current_lang_code), options=roles, format_func=lambda x: translate(x, current_lang_code), horizontal=True)
st.divider()

# ==========================================
# 🌍 5. واجهة الحريف (طلب حقيقي ومتابعة)
# ==========================================
if role == "Passenger":
    st.markdown(f"<h2 style='text-align: center; color: #FFD700;'>✈️ {translate('حجز تاكسي VIP', current_lang_code)}</h2>", unsafe_allow_html=True)
    
    # البحث عن طلبات الحريف الحالية
    my_active_requests = [r for r in st.session_state.live_requests if r['status'] in ['pending', 'accepted']]
    
    if len(my_active_requests) == 0:
        # واجهة الطلب (لا يوجد طلب حالي)
        route = st.selectbox(translate("اختر مسارك:", current_lang_code), options=list(st.session_state.fares_db.keys()), format_func=lambda x: translate(x, current_lang_code))
        current_price = st.session_state.fares_db[route]
        
        st.markdown(f"<div style='background:#1e1e1e; color:#FFD700; padding:15px; border-radius:10px; text-align:center; margin-bottom:15px;'><h1 style='margin:0;'>{current_price:.1f} DT</h1></div>", unsafe_allow_html=True)
        
        if st.button(translate("🚀 اطلب التاكسي الآن", current_lang_code), use_container_width=True, type="primary"):
            new_req = {
                'id': int(time.time()), 
                'route': route, 
                'price': current_price, 
                'status': 'pending', 
                'driver_name': ''
            }
            st.session_state.live_requests.append(new_req)
            st.success(translate("تم إرسال طلبك للسائقين...", current_lang_code))
            time.sleep(1)
            st.rerun()
            
    else:
        # واجهة متابعة الطلب
        current_req = my_active_requests[-1]
        st.info(f"{translate('مسارك:', current_lang_code)} {current_req['route']}")
        
        if current_req['status'] == 'pending':
            st.warning(translate("⏳ جاري البحث عن سيارة... يرجى الانتظار.", current_lang_code))
            if st.button("🔄 " + translate("تحديث الحالة", current_lang_code)):
                st.rerun()
        elif current_req['status'] == 'accepted':
            st.success(translate("✅ تم التأكيد!", current_lang_code) + f" السائق [{current_req['driver_name']}] في الطريق إليك.")
            
            st.markdown(f"#### 💬 {translate('تحدث مع السائق', current_lang_code)}")
            chat_container = st.container(height=200)
            with chat_container:
                for msg in st.session_state.chat_history:
                    if msg["role"] == "passenger": st.chat_message("user").write(translate(msg["text"], current_lang_code))
                    else: st.chat_message("assistant", avatar="🚕").write(translate(msg["text"], current_lang_code))
            if prompt := st.chat_input("رسالتك..."):
                st.session_state.chat_history.append({"role": "passenger", "text": prompt})
                st.rerun()

# ==========================================
# 👤 6. واجهة السائق (حساب فردي + رادار حي)
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
            
    # إذا كان السائق مسجلاً للدخول
    if 'logged_in_driver' in st.session_state and st.session_state.logged_in_driver in st.session_state.drivers_db:
        driver_phone = st.session_state.logged_in_driver
        driver_data = st.session_state.drivers_db[driver_phone]
        
        st.success(f"{translate('مرحباً', current_lang_code)} {driver_data['name']} | رصيدك: {driver_data['wallet']:.3f} DT")
        
        d1, d2, d3 = st.tabs([translate("📡 الرادار", current_lang_code), translate("💳 المحفظة", current_lang_code), translate("💬 المحادثة", current_lang_code)])
        
        with d1:
            if driver_data['wallet'] < -5.0:
                st.error(translate("❌ رصيدك سلبي! اشحن محفظتك لتلقي الطلبات.", current_lang_code))
            else:
                if st.button("🔄 " + translate("تحديث الرادار", current_lang_code)): st.rerun()
                
                # جلب الطلبات المعلقة (Pending)
                pending_reqs = [r for r in st.session_state.live_requests if r['status'] == 'pending']
                # جلب الرحلة الحالية المقبولة من هذا السائق
                my_active = [r for r in st.session_state.live_requests if r['status'] == 'accepted' and r['driver_name'] == driver_data['name']]
                
                if len(my_active) > 0:
                    # السائق عنده رحلة يخدم فيها توة
                    active_ride = my_active[0]
                    st.warning(f"🚨 رحلة جارية: {active_ride['route']} ({active_ride['price']} DT)")
                    
                    dest = urllib.parse.quote(active_ride['route'].split("➡️")[-1].strip())
                    gmaps_link = f"http://maps.google.com/?q={dest}"
                    st.markdown(f'<a href="{gmaps_link}" target="_blank"><button style="width:100%; background:#4285F4; color:white; padding:10px; border-radius:5px; border:none;">📍 افتح GPS</button></a>', unsafe_allow_html=True)
                    
                    if st.button("🏁 إنهاء الرحلة وتسجيل العمولة", type="primary", use_container_width=True):
                        calc_comm = active_ride['price'] * (st.session_state.commission_rate / 100)
                        # خصم من رصيد السائق الفردي
                        st.session_state.drivers_db[driver_phone]['wallet'] -= calc_comm
                        # تسجيل في الإدارة
                        new_trip = pd.DataFrame([[datetime.now().strftime("%Y-%m-%d %H:%M"), driver_data['name'], active_ride['route'], active_ride['price'], calc_comm]], columns=['Date', 'Driver', 'Route', 'Fare', 'Commission'])
                        st.session_state.db_trips = pd.concat([st.session_state.db_trips, new_trip], ignore_index=True)
                        # حذف الطلب من اللايف
                        active_ride['status'] = 'completed'
                        st.session_state.chat_history = [] # مسح الشات
                        st.success(f"تم خصم {calc_comm:.3f} DT بنجاح.")
                        time.sleep(1)
                        st.rerun()
                        
                elif len(pending_reqs) > 0:
                    # يوجد طلبات جديدة في الشارع
                    st.error("🔔 " + translate("يوجد طلبات جديدة!", current_lang_code))
                    for req in pending_reqs:
                        st.info(f"📍 {req['route']} | 💰 {req['price']} DT")
                        if st.button("✅ قبول الرحلة", key=req['id']):
                            req['status'] = 'accepted'
                            req['driver_name'] = driver_data['name']
                            st.rerun()
                else:
                    st.write(translate("لا يوجد طلبات حالياً. أنتظر...", current_lang_code))

        with d2:
            st.markdown(f"### 💳 رصيدك: *{driver_data['wallet']:.3f} DT*")
            recharge = st.selectbox("اختر المبلغ:", [10.0, 20.0, 50.0])
            if st.button("🔄 شحن (D17)", type="primary"):
                st.session_state.drivers_db[driver_phone]['wallet'] += recharge
                st.success("✅ تم الشحن!")
                time.sleep(1)
                st.rerun()
                
        with d3:
            for msg in st.session_state.chat_history:
                if msg["role"] == "passenger": st.chat_message("user", avatar="🌍").write(msg["text"])
                else: st.chat_message("assistant", avatar="🚕").write(msg["text"])
            if prompt := st.chat_input("رسالة..."):
                st.session_state.chat_history.append({"role": "driver", "text": prompt})
                st.rerun()

# ==========================================
# 👑 7. لوحة الإدارة (إضافة السائقين ومراقبة السوق)
# ==========================================
elif role == "Admin HQ":
    admin_pw = st.text_input("كلمة السر للمالك:", type="password")
    if admin_pw == "NabeulGold2026":
        t1, t2 = st.tabs(["📊 الإحصائيات والسوق", "👤 إدارة السائقين والمحافظ"])
        
        with t1:
            total_profit = st.session_state.db_trips['Commission'].sum()
            c1, c2 = st.columns(2)
            c1.metric("أرباح الشركة (DT)", f"{total_profit:.3f}")
            c2.metric("عدد الرحلات", len(st.session_state.db_trips))
            st.dataframe(st.session_state.db_trips, use_container_width=True)
            
            st.divider()
            st.session_state.commission_rate = st.slider("نسبة العمولة (%):", 1.0, 30.0, st.session_state.commission_rate, 1.0)
            
        with t2:
            st.subheader("إضافة سائق جديد للمنظومة")
            cc1, cc2, cc3 = st.columns(3)
            new_phone = cc1.text_input("رقم الهاتف (الآيدي):")
            new_name = cc2.text_input("اسم السائق:")
            new_pin = cc3.text_input("كود PIN السري:")
            
            if st.button("➕ إنشاء حساب للسائق", type="primary"):
                if new_phone and new_name and new_pin:
                    st.session_state.drivers_db[new_phone] = {"name": new_name, "pin": new_pin, "wallet": 0.0}
                    st.success(f"تمت إضافة {new_name} بنجاح!")
            
            st.divider()
            st.subheader("محافظ السائقين (Solde)")
            # عرض أرصدة السائقين في جدول
            drivers_list = []
            for phone, data in st.session_state.drivers_db.items():
                drivers_list.append({"الهاتف": phone, "الاسم": data['name'], "الرصيد (DT)": data['wallet']})
            st.dataframe(pd.DataFrame(drivers_list), use_container_width=True)