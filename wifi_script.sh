wifi auto connect script
#!/bin/sh

############################################
# CAR CLUSTER FAST AUTO START SCRIPT
# Board : OKT507-C
############################################

exec > /root/startup_log.txt 2>&1

echo "======================================="
echo "        CAR CLUSTER FAST STARTUP       "
echo "======================================="

date

########################################
# 1. WAIT FOR FRAMEBUFFER
########################################

echo "[1] Waiting for framebuffer..."

COUNT=0
while [ ! -e /dev/fb0 ]
do
    sleep 0.1
    COUNT=$((COUNT+1))
    [ $COUNT -gt 30 ] && break
done

echo "Framebuffer ready"

########################################
# 2. WAIT FOR INPUT DEVICE
########################################

echo "[2] Waiting for input subsystem..."

COUNT=0
while [ ! -e /dev/input/event0 ]
do
    sleep 0.1
    COUNT=$((COUNT+1))
    [ $COUNT -gt 20 ] && break
done

echo "Input system ready"

########################################
# 3. DISABLE FRAMEBUFFER CONSOLE
########################################

echo "[3] Disabling framebuffer console..."

echo 0 > /sys/class/vtconsole/vtcon1/bind 2>/dev/null

########################################
# 4. SET QT ENVIRONMENT
########################################

echo "[4] Setting QT environment..."

export QT_QPA_PLATFORM=linuxfb
export QT_QPA_FB_DEVICE=/dev/fb0
export QT_QPA_PLATFORM_PLUGIN_PATH=/usr/lib/qt/plugins
export QT_QPA_FONTDIR=/usr/lib/fonts
export XDG_RUNTIME_DIR=/tmp/runtime-root

########################################
# 5. START WIFI + INTERNET TIME (BACKGROUND)
########################################

echo "[5] Starting WiFi..."

(
IFACE=wlan0
CONF_FILE=/root/wifi_remote.conf

COUNT=0
while [ ! -d /sys/class/net/$IFACE ]
do
    sleep 0.2
    COUNT=$((COUNT+1))
    [ $COUNT -gt 15 ] && exit
done

ip link set $IFACE up

killall wpa_supplicant 2>/dev/null

wpa_supplicant -B -i $IFACE -c $CONF_FILE

udhcpc -i $IFACE

ntpd -q -p pool.ntp.org 2>/dev/null

hwclock -w

echo "WiFi + Internet ready"

) &

########################################
# 6. FIREBASE CONNECTION (BACKGROUND)
########################################

echo "[6] Connecting to Firebase..."

(
curl -k -m 5 https://edge-data-filtering-default-rtdb.asia-southeast1.firebasedatabase.app/.json >/dev/null
echo "Firebase connection done"
) &

########################################
# 7. START CAR CLUSTER
########################################

echo "[7] Starting Car Cluster..."

cd /root

killall car_cluster_Mar05 2>/dev/null

./car_cluster_Mar05 &

########################################
# 8. LOG START TIME
########################################

echo "[8] Cluster launched at:"
date

echo "=========== STARTUP FINISHED =========="
