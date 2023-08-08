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
PRODUCT_DTBO_TEMPLATE := $(LOCAL_PATH)/dt-overlay.in
PRODUCT_SDMMC_DEVICE := fe2b0000.dwmmc
PRODUCT_KERNEL_CONFIG := firefly_defconfig android-11.config rk356x.config

include device/rockchip/common/build/rockchip/DynamicPartitions.mk
include device/rockchip/rk356x/rk3566_firefly_aiojd4/BoardConfig.mk
include device/rockchip/common/BoardConfig.mk
$(call inherit-product, device/rockchip/rk356x/device.mk)
$(call inherit-product, device/rockchip/common/device.mk)
$(call inherit-product, frameworks/native/build/tablet-10in-xhdpi-2048-dalvik-heap.mk)

DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/../overlay

PRODUCT_CHARACTERISTICS := tablet

PRODUCT_NAME := rk3566_firefly_aiojd4
PRODUCT_DEVICE := rk3566_firefly_aiojd4
PRODUCT_BRAND := Firefly
PRODUCT_MODEL := AIO-3566JD4
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

#for gnss
BOARD_HAS_GPS := false

PRODUCT_COPY_FILES += \
   device/rockchip/rk356x/rk3566_firefly_aiojd4/init.rk3566_firefly_aiojd4.rc:vendor/etc/init/init.rk3566_firefly_aiojd4.rc\
   device/rockchip/rk356x/rk3566_firefly_aiojd4/gps/u-blox.conf:system/etc/u-blox.conf

PRODUCT_PACKAGES += \
	rkCamera2
