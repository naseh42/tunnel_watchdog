#!/bin/bash

echo -e "\e[1;35m✨ سیستم مانیتورینگ هوشمند Rathole / Backhaul\e[0m"
echo -e "\e[1;36m✅ تهیه شده توسط @nxnx65\e[0m"

CONF_FILE="/root/tunnel_watchdog.conf"
CHECK_INTERVAL=60

# تشخیص تانل و فایل کانفیگ
detect_tunnel() {
  if pgrep -f "rathole" >/dev/null; then
    BIN_PATH=$(pgrep -af rathole | head -n1 | awk '{print $2}')
    TUNNEL_NAME="Rathole"
  elif pgrep -f "backhaul" >/dev/null; then
    BIN_PATH=$(pgrep -af backhaul | head -n1 | awk '{print $2}')
    TUNNEL_NAME="Backhaul"
  else
    echo -e "\e[1;31m❌ هیچ تانلی پیدا نشد. لطفاً ابتدا تانل را اجرا کن.\e[0m"
    exit 1
  fi

  # پیدا کردن فایل کانفیگ
  CONFIG_FILE=$(pgrep -af "$BIN_PATH" | grep -oP '\S+\.toml' | head -n1)

  # اگر پیدا نشد و بک‌هاله، تو مسیرهای مرسوم هم بگرد
  if [ "$TUNNEL_NAME" == "Backhaul" ] && [ -z "$CONFIG_FILE" ]; then
    for path in /root/backhaul /etc/backhaul /root /etc; do
      CONFIG_FILE=$(find "$path" -maxdepth 1 -name "*.toml" 2>/dev/null | head -n1)
      [ -n "$CONFIG_FILE" ] && break
    done
  fi

  if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "\e[1;31m⚠️ فایل کانفیگ یافت نشد: $CONFIG_FILE\e[0m"
    exit 1
  fi
}

detect_tunnel
echo -e "\e[1;34m📌 تانل: $TUNNEL_NAME → فایل کانفیگ: $CONFIG_FILE\e[0m"

# گرفتن آدرس‌ها از کاربر
if [ ! -f "$CONF_FILE" ]; then
  echo -e "\e[1;33m📥 آدرس IP:PORT وارد کن. برای پایان 'end' تایپ کن:\e[0m"
  > "$CONF_FILE"
  while true; do
    read -p "🔹 IP:PORT → " line
    [ "$line" == "end" ] && break
    echo "$line" >> "$CONF_FILE"
  done
fi

# ایجاد systemd (فقط بار اول)
SERVICE_FILE="/etc/systemd/system/tunnel_watchdog_multi.service"
if [ ! -f "$SERVICE_FILE" ]; then
  echo -e "\e[1;34m🛠 در حال ساخت systemd...\e[0m"
  cat <<EOF | sudo tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=Tunnel Watchdog برای Rathole / Backhaul
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash /root/tunnel_watchdog.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable tunnel_watchdog_multi.service
  echo -e "\e[1;32m✅ سرویس فعال شد\e[0m"
fi

# اجرای حلقه بررسی
while true; do
  echo -e "\n\e[1;36m🧪 بررسی اتصال‌ها...\e[0m"
  while IFS= read -r endpoint; do
    IP=$(echo "$endpoint" | cut -d: -f1)
    PORT=$(echo "$endpoint" | cut -d: -f2)

    nc -z -w 3 "$IP" "$PORT" >/dev/null 2>&1
    NC_RESULT=$?

    ping -c 1 -W 2 "$IP" >/dev/null 2>&1
    PING_RESULT=$?

    CURL_RESULT=$(curl -s --connect-timeout 3 "http://$IP:$PORT")
    CURL_CODE=$?

    if [ $NC_RESULT -eq 0 ]; then
      echo -e "\e[1;32m✅ $IP:$PORT در دسترس است (پینگ: OK، Curl: $CURL_CODE)\e[0m"
    else
      echo -e "\e[1;31m❌ اتصال به $IP:$PORT قطع است.\e[0m"
      echo -e "\e[0;37m📡 Curl: $CURL_RESULT (کد $CURL_CODE)\e[0m"

      if [ $PING_RESULT -ne 0 ]; then
        echo -e "\e[1;31m🛑 پینگ نیز شکست خورده!\e[0m"
      else
        echo -e "\e[1;33m⚠️ پینگ موفق ولی TCP/HTTP پاسخ نمی‌دهد.\e[0m"
      fi

      echo -e "\e[1;34m🔁 تلاش برای ری‌استارت تانل ($TUNNEL_NAME)...\e[0m"
      pkill -f "$BIN_PATH"
      sleep 2

      nohup "$BIN_PATH" "$CONFIG_FILE" >/dev/null 2>&1 &
      sleep 5

      # دوباره تشخیص بده مسیر باینری درست شد یا نه
      detect_tunnel
      echo -e "\e[1;32m✔️ تانل مجدداً راه‌اندازی شد ($TUNNEL_NAME)\e[0m"
    fi
  done < "$CONF_FILE"
  sleep "$CHECK_INTERVAL"
done
