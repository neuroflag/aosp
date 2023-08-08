#
# Copyright (c) 2020 Rockchip Electronics Co., Ltd
#
PRODUCT_PACKAGES += \
    displayd \
    libion

PRODUCT_PACKAGES += \
    RockchipPinnerService

# Disable partial updates
PRODUCT_PROPERTY_OVERRIDES += \
    debug.hwui.use_partial_updates=false

BOARD_SEPOLICY_DIRS += vendor/rockchip/hardware/interfaces/neuralnetworks/1.0/default/sepolicy
PRODUCT_PACKAGES += \
    public.libraries-rockchip \
    librknn_api_android \
    rknn_server \
    librknnhal_bridge.rockchip \
    rockchip.hardware.neuralnetworks@1.0-impl \
    rockchip.hardware.neuralnetworks@1.0-service

$(call inherit-product-if-exists, vendor/rockchip/common/npu/npu.mk)
$(call inherit-product-if-exists, vendor/firefly/firefly.mk)

BOARD_SEPOLICY_DIRS += device/rockchip/rk356x/sepolicy_vendor
TARGET_SYSTEM_PROP += device/rockchip/rk356x/rk356x.prop
# enable this for support f2fs with data partion
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := ext4

# used for fstab_generator, sdmmc controller address

# for firefly multidevices_boot
PRODUCT_BOOT_DEVICE := fe310000.sdhci,usbhost/fd000000.dwc3/xhci-hcd.5.auto,fd880000.usb,fd800000.usb,fe2b0000.dwmmc,fc800000.sata,3c0800000.pcie,3c0000000.pcie

# This ensures the needed build tools are available.
# TODO: make non-linux builds happy with external/f2fs-tool; system/extras/f2fs_utils
ifeq ($(HOST_OS),linux)
  TARGET_USERIMAGES_USE_F2FS := false
endif

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/init.recovery.rk30board.rc:recovery/root/init.recovery.rk30board.rc \
    vendor/rockchip/common/bin/$(TARGET_ARCH)/busybox:recovery/root/sbin/busybox \

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/init.rk356x.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.rk356x.rc \
    $(LOCAL_PATH)/wake_lock_filter.xml:system/etc/wake_lock_filter.xml \
    $(LOCAL_PATH)/package_performance.xml:$(TARGET_COPY_OUT_ODM)/etc/package_performance.xml \
    $(TARGET_DEVICE_DIR)/media_profiles_default.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_profiles_V1_0.xml\

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.opengles.aep.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.opengles.aep.xml

# copy xml files for Vulkan features.
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.vulkan.compute-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.compute-0.xml \
    frameworks/native/data/etc/android.hardware.vulkan.level-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.level-0.xml \
    frameworks/native/data/etc/android.hardware.vulkan.level-1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.level-1.xml \
    frameworks/native/data/etc/android.hardware.vulkan.version-1_0_3.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version-1_0_3.xml \
    frameworks/native/data/etc/android.hardware.vulkan.version-1_1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version-1_1.xml \
    frameworks/native/data/etc/android.software.vulkan.deqp.level-2019-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.vulkan.deqp.level-2019-03-01.xml \
    frameworks/native/data/etc/android.software.vulkan.deqp.level-2020-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.vulkan.deqp.level-2020-03-01.xml

# Get the long list of APNs
PRODUCT_COPY_FILES += vendor/rockchip/common/phone/etc/apns-full-conf.xml:system/etc/apns-conf.xml
PRODUCT_COPY_FILES += vendor/rockchip/common/phone/etc/spn-conf.xml:system/etc/spn-conf.xml
PRODUCT_PROPERTY_OVERRIDES += \
    ro.vendor.sdkversion = $(CURRENT_SDK_VERSION) \
    vendor.gralloc.disable_afbc = 0

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/public.libraries.txt:vendor/etc/public.libraries.txt

#For RK3568 EC20
PRODUCT_PACKAGES += rild

PRODUCT_COPY_FILES += \
	$(LOCAL_PATH)/libquectel-ril/arm64-v8a/libquectel-ril.so:vendor/lib64/libquectel-ril.so \
	$(LOCAL_PATH)/libquectel-ril/arm64-v8a/chat:system/bin/chat \
	$(LOCAL_PATH)/libquectel-ril/arm64-v8a/ip-up:system/bin/ip-up \
	$(LOCAL_PATH)/libquectel-ril/arm64-v8a/ip-down:system/bin/ip-down \
	$(LOCAL_PATH)/libquectel-ril/ql-ril.conf:system/etc/ql-ril.conf \
	$(LOCAL_PATH)/apns-conf.xml:system/etc/apns-conf.xml

#
# add Rockchip properties here
#
PRODUCT_PROPERTY_OVERRIDES += \
                ro.ril.ecclist=112,911 \
                ro.opengles.version=196610 \
                wifi.interface=wlan0 \
                ro.telephony.default_network=9 \
                rild.libpath=/vendor/lib64/libquectel-ril.so \
                rild.libargs=-d /dev/ttyUSB0 \
                ro.audio.monitorOrientation=true \
                debug.nfc.fw_download=false \
                debug.nfc.se=false \
                vendor.hwc.compose_policy=1 \
                sys.wallpaper.rgb565=0 \
                sf.power.control=2073600 \
                sys.rkadb.root=0 \
                ro.sf.fakerotation=false \
                ro.tether.denied=false \
                sys.resolution.changed=false \
                ro.default.size=100 \
                ro.product.usbfactory=rockchip_usb \
                wifi.supplicant_scan_interval=15 \
                ro.factory.tool=0 \
                ro.kernel.android.checkjni=0 \
                ro.build.shutdown_timeout=6 \
                persist.enable_task_snapshots=false \
                ro.vendor.frameratelock=true

#GPS GNSS HAL
PRODUCT_PACKAGES += \
	android.hardware.gnss@1.0-impl \
	android.hardware.gnss@1.0-service

PRODUCT_COPY_FILES += \
	device/rockchip/rk356x/gps/lib64/gps.default.so:vendor/lib64/hw/gps.default.so \
	device/rockchip/rk356x/gps/lib/gps.default.so:vendor/lib/hw/gps.default.so \
	frameworks/native/data/etc/android.hardware.location.gps.xml:vendor/etc/permissions/android.hardware.location.gps.xml

########################################################
# this product has GPS or not
# ########################################################
ifeq ($(strip $(BOARD_HAS_GPS)),true)
PRODUCT_PROPERTY_OVERRIDES += \
	ro.factory.hasGPS=true
else
PRODUCT_PROPERTY_OVERRIDES += \
	ro.factory.hasGPS=false
endif

# usb camera
PRODUCT_PROPERTY_OVERRIDES += persist.sys.uvc.facing=front

#
#add for camera aiq2.0
#
PRODUCT_PACKAGES += \
	rkaiq_tool_server \
	rkaiq_3A_server
PRODUCT_COPY_FILES += \
	external/camera_engine_rkaiq/rkisp2x_tuner/reset_camera.sh:$(TARGET_COPY_OUT_VENDOR)/etc/camera/reset_camera.sh
