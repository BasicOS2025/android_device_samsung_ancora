LOCAL_PATH := $(call my-dir)

ANCORA_GPS_DIR_LIST := $(LOCAL_PATH)/libloc_api-rpc/
ANCORA_GPS_DIR_LIST += $(LOCAL_PATH)/libloc_api/

#call the subfolders
include $(addsuffix Android.mk, $(ANCORA_GPS_DIR_LIST))
