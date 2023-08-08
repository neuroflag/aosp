###############################################################################
# RKDeviceTest
LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)
LOCAL_MODULE := FDeviceTest
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_TAGS := optional
LOCAL_BUILT_MODULE_STEM := package.apk
LOCAL_DEX_PREOPT := nostripping
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_PRIVILEGED_MODULE := true
LOCAL_CERTIFICATE :=  platform
LOCAL_OVERRIDES_PACKAGES := DeviceTest RKDeviceTest
include vendor/firefly/apps/filter-apps.mk
LOCAL_SRC_FILES := $(LOCAL_MODULE).apk
LOCAL_MULTILIB := 32
#LOCAL_REQUIRED_MODULES :=
#JNI_LIBS :=
#$(foreach FILE,$(shell find $(LOCAL_PATH)/lib/ -name *.so), $(eval JNI_LIBS += $(FILE)))
#LOCAL_PREBUILT_JNI_LIBS := $(subst $(LOCAL_PATH),,$(JNI_LIBS))

include $(BUILD_PREBUILT)
