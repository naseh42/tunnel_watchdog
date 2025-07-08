#!/bin/bash

CONFIG_FILE="/root/backhaul_watchdog.conf"
SERVICE_FILE="/etc/systemd/system/backhaul_watchdog.service"
LOG_FILE="/var/log/backhaul_watchdog.log"
MODE="$1"

BOLD='\e[1m'; NC='\e[0m'
RED='\e[91m'; GREEN='\e[92m'; YELLOW='\e[93m'
BLUE='\e[94m'; MAGENTA='\e[95m'; CYAN='\e[96m'; GRAY='\e[90m'

# ======================== Menu ========================
if [ "$MODE" != "run" ]; then
  clear
  echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}${BOLD}║ 🔧  Developed by ${YELLOW}${BOLD}@nxnx65${CYAN}${BOLD} – Backhaul Watchdog Control Panel        ║${NC}"
  echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════════════════╝${NC}"
  echo -e "${GREEN}${BOLD}"
  printf "│ ${MAGENTA}%-54s${NC} ${YELLOW}${BOLD}%6s${NC} │\n" "Initial setup (add endpoints)" "[1]"
  printf "│ ${CYAN}%-54s${NC} ${YELLOW}${BOLD}%6s${NC} │\n" "Edit configuration file" "[2]"
  printf "│ ${BLUE}%-54s${NC} ${YELLOW}${BOLD}%6s${NC} │\n" "Restart watchdog service" "[3]"
  printf "│ ${RED}%-54s${NC} ${YELLOW}${BOLD}%6s${NC} │\n" "Remove service and config file" "[4]"
  printf "│ ${GRAY}%-54s${NC} ${YELLOW}${BOLD}%6s${NC} │\n" "Exit menu" "[0]"
  echo -e "${NC}"
  echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════════════════╝${NC}"
  read -p "$(echo -e ${MAGENTA}${BOLD}👉 Select an option by number: ${NC})" choice

  case "$choice" in
    1)
      echo "# Format: IP:PORT" > "$CONFIG_FILE"
      echo "💡 How many endpoints do you want to monitor?"
      read -r COUNT
      for ((i=1; i<=COUNT; i++)); do
        read -p "🔹 Enter endpoint $i (IP:PORT): " line
        echo "$line" >> "$CONFIG_FILE"
      done

      echo -e "${BLUE}🛠 Creating systemd service...${NC}"
      cat <<EOF | tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=Backhaul Watchdog Service
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash /root/backhaul_watchdog.sh run
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
      systemctl daemon-reload
      systemctl enable backhaul_watchdog.service
      systemctl start backhaul_watchdog.service
      echo -e "${GREEN}✅ Service started successfully.${NC}"
      sleep 2
      reboot
      ;;
    2)
      nano "$CONFIG_FILE"
      sleep 2
      reboot
      ;;
    3)
      systemctl restart backhaul_watchdog.service
      echo "$(date '+%Y-%m-%d %H:%M:%S') Watchdog service restarted manually" >> "$LOG_FILE"
      ;;
    4)
      systemctl stop backhaul_watchdog.service
      systemctl disable backhaul_watchdog.service
      rm -f "$SERVICE_FILE" "$CONFIG_FILE"
      systemctl daemon-reload
      echo "$(date '+%Y-%m-%d %H:%M:%S') Watchdog removed" >> "$LOG_FILE"
      ;;
    0)
      echo "👋 Exiting menu."; exit 0 ;;
    *) echo "❌ Invalid option."; exit 1 ;;
  esac
  exit 0
fi

# ======================== Monitoring ========================
RESTART_COOLDOWN=300
LAST_RESTART=0

check_tls() {
  echo | timeout 5 openssl s_client -connect "$1:$2" -servername "$1" -verify_quiet 2>/dev/null | grep -q "Verify return code: 0"
}

check_tcp() {
  nc -z -w 3 "$1" "$2" >/dev/null 2>&1
}

check_ping() {
  ping -c 2 -W 2 "$1" >/dev/null 2>&1
}

check_curl() {
  PROTO="http"
  [[ "$2" == "443" || "$2" == "2053" ]] && PROTO="https"
  curl -s --connect-timeout 3 "$PROTO://$1:$2" >/dev/null
}

while true; do
  while IFS= read -r line; do
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ "$line" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]] || continue

    IP="${line%%:*}"
    PORT="${line##*:}"
    TIME_NOW=$(date '+%Y-%m-%d %H:%M:%S')

    FAIL=0
    check_tls "$IP" "$PORT" || { echo "$TIME_NOW ❌ TLS failed for $IP:$PORT" >> "$LOG_FILE"; FAIL=1; }
    check_tcp "$IP" "$PORT" || { echo "$TIME_NOW ❌ TCP failed for $IP:$PORT" >> "$LOG_FILE"; FAIL=1; }
    check_ping "$IP" || { echo "$TIME_NOW ❌ Ping failed for $IP" >> "$LOG_FILE"; FAIL=1; }
    check_curl "$IP" "$PORT" || { echo "$TIME_NOW ❌ Curl failed for $IP:$PORT" >> "$LOG_FILE"; FAIL=1; }

    if (( FAIL )); then
      CURRENT_TIME=$(date +%s)
      if (( CURRENT_TIME - LAST_RESTART >= RESTART_COOLDOWN )); then
        if systemctl is-active --quiet backhaul.service; then
          echo "$TIME_NOW 🔁 Restarting backhaul via systemctl" >> "$LOG_FILE"
          systemctl restart backhaul.service
          echo "$TIME_NOW ✔️ Backhaul restarted" >> "$LOG_FILE"
        else
          echo "$TIME_NOW ⚠️ Backhaul service not active, cannot restart" >> "$LOG_FILE"
        fi
        LAST_RESTART=$CURRENT_TIME
      else
        echo "$TIME_NOW ⏳ Cooldown active, restart skipped" >> "$LOG_FILE"
      fi
    else
      echo "$TIME_NOW ✅ Connection OK for $IP:$PORT" >> "$LOG_FILE"
    fi
  done < "$CONFIG_FILE"
  sleep 90
done
