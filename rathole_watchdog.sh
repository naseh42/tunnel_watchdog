#!/bin/bash

CONFIG_PATH="/root/rathole_watchdog.conf"
SERVICE_FILE="/etc/systemd/system/rathole_watchdog.service"
LOG_FILE="/var/log/rathole_watchdog.log"
MODE="$1"

RED='\e[91m'; GREEN='\e[92m'; YELLOW='\e[93m'; CYAN='\e[96m'; MAGENTA='\e[95m'; BOLD='\e[1m'; NC='\e[0m'

# ======================== منو ========================
if [ "$MODE" != "run" ]; then
  clear

# 🎨 Style
BOLD='\e[1m'; NC='\e[0m'  # Reset
RED='\e[91m'; GREEN='\e[92m'; YELLOW='\e[93m'
BLUE='\e[94m'; MAGENTA='\e[95m'; CYAN='\e[96m'; GRAY='\e[90m'

# 🔷 Header
echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║ 🔧  Developed by ${YELLOW}${BOLD}@nxnx65${CYAN}${BOLD} – Rathole Watchdog Control Panel         ║${NC}"
echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════════════════╝${NC}"

# 🗂️ Menu Options
echo -e "${GREEN}${BOLD}"
printf "│ ${MAGENTA}%-54s${NC} ${YELLOW}${BOLD}%6s${NC} │\n" "Initial setup (add servers and ports)" "[1]"
printf "│ ${CYAN}%-54s${NC} ${YELLOW}${BOLD}%6s${NC} │\n" "Edit configuration file" "[2]"
printf "│ ${BLUE}%-54s${NC} ${YELLOW}${BOLD}%6s${NC} │\n" "Restart watchdog service" "[3]"
printf "│ ${RED}%-54s${NC} ${YELLOW}${BOLD}%6s${NC} │\n" "Delete service and config files" "[4]"
printf "│ ${GRAY}%-54s${NC} ${YELLOW}${BOLD}%6s${NC} │\n" "Exit menu" "[0]"
echo -e "${NC}"

# 🟦 Footer
echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════════════════╝${NC}"

# 🖋️ Prompt
read -p "$(echo -e ${MAGENTA}${BOLD}👉 Select an option by number: ${NC})" choice

  case "$choice" in
    1)
      echo "🖥️ چند سرور می‌خوای تعریف کنی؟ (عدد وارد کن):"
      read -r SERVER_COUNT
      echo "SERVER_COUNT=$SERVER_COUNT" > "$CONFIG_PATH"

      for ((i=1; i<=SERVER_COUNT; i++)); do
        echo "💡 IP سرور شماره $i:"
        read -r IP
        echo "🔐 تا ۳ پورت TLS برای سرور $i (با فاصله وارد کن):"
        read -r PORTS
        echo "SERVER_${i}_IP=$IP" >> "$CONFIG_PATH"
        echo "SERVER_${i}_PORTS=\"$PORTS\"" >> "$CONFIG_PATH"
      done

      if [ -f "$SERVICE_FILE" ]; then
        systemctl stop rathole_watchdog.service
        systemctl disable rathole_watchdog.service
        rm -f "$SERVICE_FILE"
      fi

      echo "🛠️ ساخت سرویس systemd..."
      cat <<EOF | tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=Rathole Multi-TLS Watchdog
After=network.target

[Service]
ExecStart=/bin/bash /root/rathole_watchdog.sh run
Restart=always
RestartSec=30
Type=simple

[Install]
WantedBy=multi-user.target
EOF

      systemctl daemon-reload
      systemctl enable rathole_watchdog.service
      systemctl start rathole_watchdog.service
      echo "✅ سرویس فعال شد."
      echo "♻️ ریبوت برای اجرا..."
      sleep 2
      reboot
      ;;
    2)
      nano "$CONFIG_PATH"
      sleep 2
      reboot
      ;;
    3)
      systemctl restart rathole_watchdog.service
      echo "✅ سرویس ریستارت شد." >> "$LOG_FILE"
      ;;
    4)
      systemctl stop rathole_watchdog.service
      systemctl disable rathole_watchdog.service
      rm -f "$SERVICE_FILE" "$CONFIG_PATH"
      systemctl daemon-reload
      echo "✅ حذف کامل انجام شد." >> "$LOG_FILE"
      ;;
    0)
      echo "👋 خروج از منو."; exit 0 ;;
    *)
      echo "❌ گزینه نامعتبر بود."; exit 1 ;;
  esac

  exit 0
fi

# ======================== حالت اجرای systemd ========================
source "$CONFIG_PATH"
RESTART_COOLDOWN=300
LAST_RESTART=0

check_tls() {
  echo | timeout 5 openssl s_client -connect "$1:$2" -servername "$1" -verify_quiet 2>/dev/null | grep -q "Verify return code: 0"
}

check_latency() {
  local latency
  latency=$(ping -c 2 -W 2 "$1" | awk -F'/' '/avg/ {print $5}')
  latency="${latency%.*}"
  [ -z "$latency" ] && latency=9999
  if (( latency > 1000 )); then return 1; else return 0; fi
}

check_curl_delay() {
  local delay
  delay=$(curl -o /dev/null -s -w '%{time_total}' --max-time 5 "https://$1:$2")
  delay="${delay%.*}"
  [ -z "$delay" ] && delay=999
  if (( delay > 3 )); then return 1; else return 0; fi
}

while true; do
  TIME_NOW=$(date '+%Y-%m-%d %H:%M:%S')
  source "$CONFIG_PATH"
  ANY_FAIL=0

  for ((i=1; i<=SERVER_COUNT; i++)); do
    eval IP=\$SERVER_${i}_IP
    eval PORTS=\$SERVER_${i}_PORTS

    for PORT in $PORTS; do
      check_tls "$IP" "$PORT"
      [ $? -ne 0 ] && echo "$TIME_NOW ❌ TLS خطا در $IP:$PORT" >> "$LOG_FILE" && ANY_FAIL=1

      nc -z -w 3 "$IP" "$PORT"
      [ $? -ne 0 ] && echo "$TIME_NOW ❌ TCP خطا در $IP:$PORT" >> "$LOG_FILE" && ANY_FAIL=1

      check_latency "$IP"
      [ $? -ne 0 ] && echo "$TIME_NOW ⏳ پینگ بالا در $IP" >> "$LOG_FILE" && ANY_FAIL=1

      check_curl_delay "$IP" "$PORT"
      [ $? -ne 0 ] && echo "$TIME_NOW 🐌 تأخیر زیاد در CURL برای $IP:$PORT" >> "$LOG_FILE" && ANY_FAIL=1
    done
  done

  CURRENT_TIME=$(date +%s)
  if (( ANY_FAIL == 1 )); then
    if (( CURRENT_TIME - LAST_RESTART >= RESTART_COOLDOWN )); then
      echo "$TIME_NOW 🔁 ریستارت Rathole به دلیل کیفیت نامناسب" >> "$LOG_FILE"
      systemctl restart rathole.service
      LAST_RESTART=$CURRENT_TIME
    else
      echo "$TIME_NOW ⏳ وقفه فعال بعد ریستارت قبلی." >> "$LOG_FILE"
    fi
  fi

  sleep 90
done
