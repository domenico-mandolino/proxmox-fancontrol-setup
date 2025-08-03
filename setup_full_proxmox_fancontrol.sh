#!/usr/bin/env bash
set -e

echo "[1/8] Nettoyage et mise à jour du système..."
sed -i 's/^deb/#deb/g' /etc/apt/sources.list.d/pve-enterprise.list 2>/dev/null || true
rm -f /etc/apt/sources.list.d/*
apt update
apt -y upgrade
apt -y dist-upgrade
apt -y autoremove

echo "[2/8] Installation de fancontrol et dépendances..."
apt install -y lm-sensors fancontrol

echo "[3/8] Chargement du module nct6775..."
echo "nct6775" >> /etc/modules
modprobe nct6775 || true

echo "[4/8] Détection dynamique du hwmon lié à nct677x..."
HWMON=$(for d in /sys/class/hwmon/hwmon*; do
  if grep -q "nct677" "$d/name"; then echo "$d"; break; fi
done)

if [ -z "$HWMON" ]; then
  echo "Aucun capteur nct677x détecté. Abandon."
  exit 1
fi

echo "Module détecté : $HWMON"

echo "[5/8] Arrêt de fancontrol si actif et suppression PID..."
systemctl stop fancontrol || true
rm -f /var/run/fancontrol.pid

echo "🛠[6/8] Passage des PWM en mode manuel et vitesse moyenne..."
for i in 1 2 3 4 5; do
  if [ -f "$HWMON/pwm${i}_enable" ]; then
    echo 1 > "$HWMON/pwm${i}_enable"
    echo 128 > "$HWMON/pwm${i}"
    echo "pwm$i activé"
  fi
done

echo "[7/8] Création dynamique de /etc/fancontrol..."
cat > /etc/fancontrol <<EOF
INTERVAL=5
DEVNAME=$(basename "$HWMON")
DEVPATH=$HWMON
EOF

for i in 2 4; do
  if [ -f "$HWMON/pwm$i" ]; then
    echo "FCTEMPS=$HWMON/pwm$i=$HWMON/temp1_input" >> /etc/fancontrol
    echo "FCFANS=$HWMON/pwm$i=$HWMON/fan${i}_input" >> /etc/fancontrol
    echo "MINTEMP=$HWMON/pwm$i=25" >> /etc/fancontrol
    echo "MAXTEMP=$HWMON/pwm$i=60" >> /etc/fancontrol
    echo "MINSTART=$HWMON/pwm$i=100" >> /etc/fancontrol
    echo "MINSTOP=$HWMON/pwm$i=80" >> /etc/fancontrol
  fi
done

echo "[8/8] Activation et lancement de fancontrol..."
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable fancontrol
systemctl restart fancontrol

echo "Installation complète et fonctionnelle. Reboot conseillé."
