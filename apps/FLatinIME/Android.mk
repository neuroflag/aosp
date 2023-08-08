###############################################################################
# PinyinIME
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := FLatinIME
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_TAGS := optional
LOCAL_BUILT_MODULE_STEM := package.apk
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_CERTIFICATE := shared
LOCAL_OVERRIDES_PACKAGES := LatinIME BoxLatinIME 
LOCAL_SRC_FILES := $(LOCAL_MODULE).apk
ifeq ($(strip $(TARGET_ARCH)), arm)
LOCAL_PREBUILT_JNI_LIBS := \
    lib/arm/libjni_latinime.so
else ifeq ($(strip $(TARGET_ARCH)), arm64)
LOCAL_PREBUILT_JNI_LIBS := \
    lib/arm64/libjni_latinime.so
endif

include $(BUILD_PREBUILT)
