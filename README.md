# 🛰️ Tunnel Watchdog (نسخه Multi و Rathole ساده)

این اسکریپت یک سیستم مانیتورینگ هوشمند برای نظارت دائمی بر تانل‌های **Rathole** یا **Backhaul** است.  
دو نسخه دارد:

1. نسخه‌ی **چندسروره (multi)** مناسب برای مانیتور هم‌زمان چند IP:PORT
2. نسخه‌ی **تک‌سرور (simple)** برای مانیتور یک تانل Rathole

---

## ✅ امکانات نسخه Multi:

- تشخیص خودکار نوع تانل (Rathole یا Backhaul)
- شناسایی خودکار فایل کانفیگ `.toml` از پردازش در حال اجرا
- گرفتن لیست چند IP:PORT از کاربر (فقط بار اول)
- بررسی دسترسی سرورها با:
  - `ping`
  - `nc` (تست TCP)
  - `curl` (تست پاسخ HTTP)
- در صورت قطعی:
  - توقف تانل فعلی
  - اجرای مجدد باینری همراه با کانفیگ
- ساخت و فعال‌سازی خودکار systemd برای اجرای دائمی

---

## 🔧 نصب سریع

### 🧩 نسخه چندسروره (multi)
اگر چند تا IP:PORT داری و می‌خوای همه با هم مانیتور بشن:

```bash
bash <(curl -s https://raw.githubusercontent.com/naseh42/tunnel_watchdog/main/tunnel_watchdog_multi.sh)
```

---

### 🧩 نسخه تک‌سروره (simple Rathole)
اگر فقط یک سرور داری و می‌خوای فقط یک تانل Rathole رو مانیتور کنی:

``
```bash
bash <(curl -s https://raw.githubusercontent.com/naseh42/tunnel_watchdog/main/rathole_watchdog.sh)
```

---

---

## 📦 سورس‌کد:
[github.com/naseh42/tunnel_watchdog](https://github.com/naseh42/tunnel_watchdog)
