# 🛡️ Tunnel Watchdog Scripts

این مخزن شامل دو اسکریپت حرفه‌ای برای مانیتورینگ تونل‌های ارتباطی با تست‌های چندگانه، لاگ‌گیری دقیق، و ریستارت امن سرویس‌ها است:

- `rathole_watchdog.sh` : مانیتورینگ چند سرور با TLS از طریق رتهول  
- `backhaul_watchdog.sh` : پایش تونل بک‌هال بین دو VPS برای عبور از فیلترینگ

هر اسکریپت با systemd اجرا شده و هر ۹۰ ثانیه کیفیت اتصال‌ها را پایش می‌کند. در صورت خرابی یا افت کیفیت، سرویس مربوطه به‌صورت کنترل‌شده ری‌استارت می‌شود.

---

## 🔧 نصب و راه‌اندازی

### ⚙️ نصب سریع `rathole_watchdog.sh`

```bash
bash <(curl -s https://raw.githubusercontent.com/naseh42/tunnel_watchdog/main/rathole_watchdog.sh)
```

✅ پس از اجرای منو:
- گزینه [1] را انتخاب کن
- تعداد سرورها و IP:PORT های TLS را وارد کن
- سرویس `rathole_watchdog.service` ساخته و فعال می‌شود

📁 مشاهده لاگ‌ها:
```bash
cat /var/log/rathole_watchdog.log
```

---

### 📡 نصب سریع `backhaul_watchdog.sh`

```bash
bash <(curl -s https://raw.githubusercontent.com/naseh42/tunnel_watchdog/main/bachaul_watchdog.sh)
```

✅ پس از اجرای منو:
- گزینه [1] را انتخاب کن
- IP:PORT بک‌هال‌ها را وارد کن
- سرویس `backhaul_watchdog.service` ساخته و فعال می‌شود

📁 مشاهده لاگ‌ها:
```bash
cat /var/log/backhaul_watchdog.log
```

---

## 🧪 تست‌هایی که هر اسکریپت انجام می‌دهد

- TLS handshake با openssl  
- بررسی TCP socket با netcat  
- تست ping برای latency و دسترسی  
- تست پاسخ‌گویی HTTP با curl  

در صورت خطا:
- سرویس با `systemctl restart` به‌صورت ایمن ری‌استارت می‌شود  
- سیستم cooldown از ری‌استارت‌های مکرر جلوگیری می‌کند (۵ دقیقه)

---

## 🛠️ مدیریت سرویس‌ها

```bash
# بررسی وضعیت
systemctl status rathole_watchdog.service
systemctl status backhaul_watchdog.service

# ری‌استارت دستی
systemctl restart rathole_watchdog.service
systemctl restart backhaul_watchdog.service

# توقف و غیرفعال‌سازی
systemctl stop rathole_watchdog.service
systemctl disable rathole_watchdog.service

systemctl stop backhaul_watchdog.service
systemctl disable backhaul_watchdog.service
```

---

## 👨‍💻 توسعه‌دهنده

ساخته‌شده با ❤️ توسط [@nxnx65](https://github.com/naseh42)  
برای گزارش باگ، پیشنهاد ارتقا، یا ارسال Pull Request خوشحال می‌شیم که کنارمون باشی 🚀
