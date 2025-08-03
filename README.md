# proxmox-fancontrol-setup

# Auto FanControl for Proxmox (nct677x)

Configuration **automatisée, rapide et robuste** de la régulation des ventilateurs PWM pour les systèmes Linux/Proxmox avec les capteurs **Nuvoton nct6775 / nct6779**.

---

## Objectif

Ce script permet de :
- Charger le module capteur `nct6775`
- Détecter dynamiquement le bon hwmon
- Passer les ventilateurs en mode manuel
- Générer automatiquement un fichier `fancontrol` valide
- Activer et démarrer le service `fancontrol` au boot
- Fonctionner sans interaction manuelle (sans `pwmconfig`)

---

## Pré-requis

- Proxmox VE (ou toute distrib Linux basée sur Debian)
- Un chip **nct6775 / nct6779** détecté par `sensors`
- `lm-sensors`, `fancontrol` installés

```bash
apt update && apt install -y lm-sensors fancontrol
