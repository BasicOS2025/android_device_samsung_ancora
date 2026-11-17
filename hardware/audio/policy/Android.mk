LOCAL_PATH := $(call my-dir)

# qcom_target.mk selects a custom policy for legacy ALSA targets. Keep the
# legacy primary HAL while providing Oreo's standard policy manager factory.
ifeq ($(USE_CUSTOM_AUDIO_POLICY),1)
include $(CLEAR_VARS)
LOCAL_MODULE := libaudiopolicymanager
LOCAL_SRC_FILES := AudioPolicyFactory.cpp
LOCAL_SHARED_LIBRARIES := libaudiopolicymanagerdefault
LOCAL_STATIC_LIBRARIES := libaudiopolicycomponents
LOCAL_C_INCLUDES := \
    frameworks/av/services/audiopolicy \
    frameworks/av/services/audiopolicy/common/include \
    frameworks/av/services/audiopolicy/engine/interface
LOCAL_CFLAGS := -Wall -Werror
LOCAL_MULTILIB := $(AUDIOSERVER_MULTILIB)
include $(BUILD_SHARED_LIBRARY)
endif
