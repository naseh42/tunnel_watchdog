# 🛡️ Tunnel Watchdog Scripts

این مخزن شامل دو اسکریپت حرفه‌ای برای پایش تونل‌های ارتباطی است:

- `rathole_watchdog.sh` : مانیتورینگ چند سرور با پروتکل TLS از طریق رتهول  
- `backhaul_watchdog.sh` : مانیتور تونل مستقل بک‌هال بین دو VPS برای عبور از فیلترینگ

هر اسکریپت از طریق systemd اجرا شده و هر ۹۰ ثانیه کیفیت اتصال‌ها را پایش می‌کند؛ در صورت قطع یا افت کیفیت، سرویس مربوطه به‌صورت امن ری‌استارت می‌شود.

---

## 🔧 نصب و استفاده

### ⚙️ نصب `rathole_watchdog.sh`

```bash
# دانلود اسکریپت
wget https://raw.githubusercontent.com/naseh42/tunnel_watchdog/main/rathole_watchdog.sh -O /root/rathole_watchdog.sh

# اجازهٔ اجرایی به فایل
chmod +x /root/rathole_watchdog.sh

# اجرای منوی تنظیمات
/root/rathole_watchdog.sh
```

💬 گزینه [1] را انتخاب کن تا:
- تعداد سرورها را تعریف کنی  
- IP و پورت‌های TLS را وارد کنی  
- سرویس systemd ساخته شود

📁 لاگ‌ها ذخیره می‌شوند در:
```bash
cat /var/log/rathole_watchdog.log
```

---

### 📡 نصب `backhaul_watchdog.sh`

```bash
# دانلود اسکریپت بک‌هال
wget https://raw.githubusercontent.com/naseh42/tunnel_watchdog/main/backhaul_watchdog.sh -O /root/backhaul_watchdog.sh

# اجازهٔ اجرایی به فایل
chmod +x /root/backhaul_watchdog.sh

# اجرای منو
/root/backhaul_watchdog.sh
```

💬 گزینه [1] را انتخاب کن تا:
- IP:PORT بک‌هال‌ها را وارد کنی  
- فایل کانفیگ ساخته شود  
- سرویس `backhaul_watchdog.service` ساخته و فعال شود

📁 لاگ‌ها ذخیره می‌شوند در:
```bash
cat /var/log/backhaul_watchdog.log
```

---

## 🧪 تست‌هایی که هر دو اسکریپت انجام می‌دهند

- اتصال TLS با openssl
- بررسی TCP با netcat
- تست Ping برای latency
- تست HTTP/Curl برای پاسخ‌گویی

در صورت خرابی یا پینگ بالا:
- سرویس با `systemctl restart` به‌صورت خودکار ری‌استارت می‌شود  
- عملیات فقط در بازه cooldown (۵ دقیقه) انجام می‌شود تا ری‌استارت پشت‌سر‌هم رخ ندهد

---

## 🛠️ مدیریت سرویس‌ها

```bash
# بررسی وضعیت سرویس‌ها
systemctl status rathole_watchdog.service
systemctl status backhaul_watchdog.service

# ری‌استارت دستی سرویس‌ها
systemctl restart rathole_watchdog.service
systemctl restart backhaul_watchdog.service

# توقف و غیرفعال‌سازی سرویس‌ها
systemctl stop rathole_watchdog.service
systemctl disable rathole_watchdog.service

systemctl stop backhaul_watchdog.service
systemctl disable backhaul_watchdog.service
```

---

## 👨‍💻 توسعه‌دهنده

ساخته شده با عشق توسط [@nxnx65](https://github.com/naseh42)  
برای پیشنهاد ارتقا، گزارش باگ، یا مشارکت تو توسعه، خوشحال می‌شیم که در Issues یا Pull Request مشارکت کنی 🌱
