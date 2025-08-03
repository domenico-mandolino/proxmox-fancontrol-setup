#!/usr/bin/env bash
set -e

echo "Arrêt de fancontrol s'il tourne..."
systemctl stop fancontrol || true
rm -f /var/run/fancontrol.pid

echo "Chargement du module nct6775..."
modprobe nct6775 || true

echo "Détection de hwmon du module nct677x..."
HWMON=$(for d in /sys/class/hwmon/hwmon*; do
  if grep -q "nct677" "$d/name"; then echo "$d"; break; fi
done)

if [ -z "$HWMON" ]; then
  echo "Aucun capteur nct677x trouvé."
  exit 1
fi

echo "Module trouvé : $HWMON"

echo "Activation des pwm en mode manuel..."
for i in 1 2 3 4 5; do
  if [ -f "$HWMON/pwm${i}_enable" ]; then
    echo 1 > "$HWMON/pwm${i}_enable"
    echo 128 > "$HWMON/pwm${i}"  # Vitesse moyenne
    echo "pwm$i activé"
  fi
done

echo "Création de la configuration fancontrol..."
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

echo "Redémarrage du service fancontrol..."
systemctl enable fancontrol
systemctl restart fancontrol

echo "Configuration automatique terminée. Les ventilateurs sont gérés."
