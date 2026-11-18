LOCAL_PATH:= $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE_PATH := $(TARGET_OUT_SHARED_LIBRARIES)/hw
LOCAL_MODULE := camera.$(TARGET_BOARD_PLATFORM)

LOCAL_MODULE_TAGS := optional

LOCAL_SRC_FILES := cameraHAL.cpp compat/Overlay.cpp
LOCAL_C_INCLUDES := $(TOP)/frameworks/native/include $(LOCAL_PATH)/compat/include
LOCAL_C_INCLUDES += system/libhidl/transport/include \
                    system/libhidl/base/include

LOCAL_C_INCLUDES += $(call project-path-for,qcom-display)/libgralloc \
                    system/media/camera/include

LOCAL_SHARED_LIBRARIES := liblog libutils libcutils libbinder
LOCAL_SHARED_LIBRARIES += libui libhardware libcamera_client
LOCAL_SHARED_LIBRARIES += libseccameraadaptor
LOCAL_PRELINK_MODULE := false

include $(BUILD_SHARED_LIBRARY)
