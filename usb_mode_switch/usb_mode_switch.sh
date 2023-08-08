#!/system/bin/sh

FILE_USB_MODE="/sys/devices/platform/fe8a0000.usb2-phy/otg_mode"
MODE=$(getprop persist.usb.mode)

if [ -z "$MODE" ];then
    MODE="host"
fi

if [ -e "$FILE_USB_MODE" ];then
    echo  "$MODE" > "$FILE_USB_MODE"
fi
