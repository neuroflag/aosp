#
# Copyright 2014 The Android Open-Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# First lunching is R, api_level is 30
PRODUCT_SHIPPING_API_LEVEL := 30

# Device tree overlays fragment files
PRODUCT_DTBO_TEMPLATE := $(LOCAL_PATH)/dt-overlay.in
PRODUCT_DTBO_TEMPLATE += $(LOCAL_PATH)/roc-rk3568-pc.in

PRODUCT_COPY_FILES += \
	$(LOCAL_PATH)/roc-rk3568-pc.prop:/vendor/dto_prop/roc-rk3568-pc.prop

PRODUCT_SDMMC_DEVICE := fe2b0000.dwmmc
PRODUCT_KERNEL_CONFIG := firefly_defconfig android-11.config rk356x.config

PRODUCT_COPY_FILES += \
	$(LOCAL_PATH)/libquectel-ril/ql-ril.conf:system/etc/ql-ril.conf \

include device/rockchip/common/build/rockchip/DynamicPartitions.mk
include device/rockchip/rk356x/rk3568_firefly_roc_pc_se/BoardConfig.mk
include device/rockchip/common/BoardConfig.mk
$(call inherit-product, device/rockchip/rk356x/device.mk)
$(call inherit-product, device/rockchip/common/device.mk)
$(call inherit-product, frameworks/native/build/tablet-10in-xhdpi-2048-dalvik-heap.mk)

DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/../overlay

PRODUCT_CHARACTERISTICS := tablet

PRODUCT_NAME := rk3568_firefly_roc_pc_se
PRODUCT_DEVICE := rk3568_firefly_roc_pc_se
PRODUCT_BRAND := Firefly
PRODUCT_MODEL := ROC-RK3568-PC-SE
PRODUCT_MANUFACTURER := T-CHIP
PRODUCT_FIREFLY_NAME := HDMI
PRODUCT_AAPT_PREF_CONFIG := mdpi
#
## add Rockchip properties
#
PRODUCT_PROPERTY_OVERRIDES += vendor.hwc.device.primary=HDMI-A
PRODUCT_PROPERTY_OVERRIDES += ro.sf.lcd_density=280
PRODUCT_PROPERTY_OVERRIDES += ro.wifi.sleep.power.down=true

PRODUCT_PROPERTY_OVERRIDES += persist.usb.mode=otg

PRODUCT_PROPERTY_OVERRIDES += ro.net.eth_primary=eth1
PRODUCT_PROPERTY_OVERRIDES += ro.net.eth_aux=eth0
PRODUCT_PROPERTY_OVERRIDES += persist.dhcpserver.enable=1

#for 3G/4G modem dongle support
BOARD_HAVE_DONGLE := false
#BOARD_HAS_RK_4G_MODEM := true

PRODUCT_COPY_FILES += \
	$(LOCAL_PATH)/init.rk3568_firefly_roc_pc_se.rc:vendor/etc/init/init.rk3568_firefly_roc_pc_se.rc \
	$(LOCAL_PATH)/gps/u-blox.conf:system/etc/u-blox.conf \

PRODUCT_PROPERTY_OVERRIDES += ro.config.media_vol_default=9

PRODUCT_PACKAGES += \
	rkCamera2
