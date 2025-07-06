# 🛰️ Tunnel Watchdog Multi (برای Rathole و Backhaul)

این اسکریپت یک سیستم مانیتورینگ هوشمند برای نظارت دائمی بر تانل‌های **Rathole** یا **Backhaul** است که از چندین سرور (IP:PORT) پشتیبانی می‌کند و در صورت اختلال، تانل را به‌صورت خودکار ری‌استارت می‌کند.

## ✅ امکانات:
- تشخیص خودکار نوع تانل (Rathole یا Backhaul)
- شناسایی خودکار فایل کانفیگ `.toml` از پردازش در حال اجرا
- گرفتن لیست چند IP:PORT از کاربر (فقط بار اول)
- بررسی دسترسی هر سرور با:
  - `ping`
  - `nc` (تست TCP)
  - `curl` (تست پاسخ HTTP)
- در صورت قطعی:
  - توقف تانل فعلی
  - اجرای مجدد باینری همراه با کانفیگ
- ساخت و فعال‌سازی خودکار systemd برای اجرای دائمی

---

## 🚀 نصب سریع

### ✅ نصب نسخه چندسروره (multi)

اگر چند تا IP:PORT داری و می‌خوای همه با هم مانیتور بشن:

```bash
bash <(curl -s https://raw.githubusercontent.com/naseh42/tunnel_watchdog/main/tunnel_watchdog_multi.sh)


### ✅

##  ✅ نصب نسخه ساده (تک‌سرور Rathole)

اگر فقط یه سرور داری و با Rathole کار می‌کنی:

bash <(curl -s https://raw.githubusercontent.com/naseh42/tunnel_watchdog/main/rathole_watchdog.sh)
