#add for ota update
ifeq ($(strip $(DEVICE_VERSION)),)
PRODUCT_PROPERTY_OVERRIDES += \
	ro.product.version=1.0

FIREFLY_VERSION :=Android11.0/V1.0
else
PRODUCT_PROPERTY_OVERRIDES += \
	ro.product.version=$(DEVICE_VERSION)

FIREFLY_VERSION :=Android11.0/V$(DEVICE_VERSION)
endif

FIREFLY_GIT_SHA := $(shell git -C $(LOCAL_PATH) rev-parse --short=12 HEAD 2>/dev/null)
PRODUCT_PROPERTY_OVERRIDES += \
	ro.firefly.build.fingerprint=$(TARGET_PRODUCT)/$(FIREFLY_VERSION).$(shell date +%y%m%d%H%M)/$(FIREFLY_GIT_SHA)

$(call inherit-product-if-exists, vendor/firefly/root/su.mk)

$(call inherit-product-if-exists, vendor/firefly/usb_mode_switch/usb_mode_switch.mk)

$(call inherit-product-if-exists, vendor/firefly/apps/apps.mk)

$(call inherit-product-if-exists, vendor/firefly/bin/bin.mk)

## keylayout
$(call inherit-product-if-exists, vendor/firefly/keyboards/common.mk)
