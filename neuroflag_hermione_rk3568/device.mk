PRODUCT_SHIPPING_API_LEVEL := 30
PRODUCT_DTBO_TEMPLATE := device/rockchip/rk356x/rk3568_r/dt-overlay.in
PRODUCT_SDMMC_DEVICE := fe2b0000.dwmmc
PRODUCT_KERNEL_CONFIG := firefly_defconfig android-11.config rk356x.config firefly_wifi.config

include device/rockchip/common/build/rockchip/DynamicPartitions.mk
include device/neuroflag/neuroflag_hermione_rk3568/BoardConfig.mk
include device/rockchip/common/BoardConfig.mk
$(call inherit-product, device/rockchip/rk356x/device.mk)
$(call inherit-product, device/rockchip/common/device.mk)
$(call inherit-product, frameworks/native/build/tablet-10in-xhdpi-2048-dalvik-heap.mk)

PRODUCT_CHARACTERISTICS := tablet

PRODUCT_NAME := neuroflag_hermione_rk3568
PRODUCT_DEVICE := neuroflag_hermione_rk3568
PRODUCT_BRAND := Neuroflag
PRODUCT_MODEL := Hermione-RK3568
PRODUCT_MANUFACTURER := Neuroflag
PRODUCT_AAPT_PREF_CONFIG := mdpi

PRODUCT_PROPERTY_OVERRIDES += vendor.hwc.device.primary=LVDS
PRODUCT_PROPERTY_OVERRIDES += vendor.hwc.device.extend=HDMI-A
PRODUCT_PROPERTY_OVERRIDES += ro.sf.lcd_density=160
PRODUCT_PROPERTY_OVERRIDES += persist.sys.rotation.einit=90
PRODUCT_PROPERTY_OVERRIDES += ro.wifi.sleep.power.down=true
PRODUCT_PROPERTY_OVERRIDES += persist.usb.show=1
PRODUCT_PROPERTY_OVERRIDES += ro.net.eth_primary=eth1
PRODUCT_PROPERTY_OVERRIDES += ro.net.eth_aux=eth0
PRODUCT_PROPERTY_OVERRIDES += persist.dhcpserver.enable=1

BOARD_HAVE_DONGLE := true
BOARD_HAS_GPS := false

PRODUCT_COPY_FILES += device/rockchip/rk356x/rk3568_firefly_itx_3568q/idc/ILITEK_ILITEK-TP.idc:system/usr/idc/ILITEK_ILITEK-TP.idc
PRODUCT_COPY_FILES += device/neuroflag/apps/ron-driver/prebuilt/arm64-v8a/ron-driver-server:vendor/bin/ron-driver-server
PRODUCT_COPY_FILES += device/neuroflag/apps/ron-driver/prebuilt/arm64-v8a/ron-driver-client:vendor/bin/ron-driver-client
PRODUCT_COPY_FILES += device/neuroflag/neuroflag_hermione_rk3568/init.neuroflag_hermione_rk3568.rc:vendor/etc/init/init.neuroflag_hermione_rk3568.rc
PRODUCT_COPY_FILES += device/neuroflag/neuroflag_hermione_rk3568/ueventd.rc:odm/ueventd.rc
