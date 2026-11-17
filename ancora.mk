# Copyright (C) 2012 The CyanogenMod Project
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

DEVICE_PATH := device/samsung/ancora
PRODUCT_FULL_TREBLE_OVERRIDE := false

DEVICE_PACKAGE_OVERLAYS += $(DEVICE_PATH)/overlay

# This device is hdpi
PRODUCT_AAPT_CONFIG := normal hdpi
PRODUCT_AAPT_PREF_CONFIG := hdpi

# Boot animation
TARGET_SCREEN_HEIGHT := 800
TARGET_SCREEN_WIDTH := 480

# Bootsplash image
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/ARIESVE.rle:root/ARIESVE.rle

# Support files
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/handheld_core_hardware.xml:system/etc/permissions/handheld_core_hardware.xml \
    frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:system/etc/permissions/android.hardware.camera.flash-autofocus.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:system/etc/permissions/android.hardware.camera.front.xml \
    frameworks/native/data/etc/android.hardware.telephony.gsm.xml:system/etc/permissions/android.hardware.telephony.gsm.xml \
    frameworks/native/data/etc/android.hardware.location.gps.xml:system/etc/permissions/android.hardware.location.gps.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:system/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:system/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:system/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:system/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:system/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.ethernet.xml:system/etc/permissions/android.hardware.ethernet.xml

# Media configuration
PRODUCT_COPY_FILES += \
    frameworks/av/media/libstagefright/data/media_codecs_google_audio.xml:system/etc/media_codecs_google_audio.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_telephony.xml:system/etc/media_codecs_google_telephony.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_video.xml:system/etc/media_codecs_google_video.xml \
    $(DEVICE_PATH)/media/media_codecs.xml:system/etc/media_codecs.xml \
    $(DEVICE_PATH)/media/media_profiles.xml:system/etc/media_profiles.xml

# Audio configuration
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/audio_policy.conf:system/etc/audio_policy.conf

# Ramdisk
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/rootdir/init.qcom.rc:root/init.qcom.rc \
    $(DEVICE_PATH)/rootdir/init.qcom.usb.rc:root/init.qcom.usb.rc \
    $(DEVICE_PATH)/rootdir/ueventd.qcom.rc:root/ueventd.qcom.rc \
    $(DEVICE_PATH)/rootdir/fstab.qcom:root/fstab.qcom \
    $(DEVICE_PATH)/recovery/twrp.fstab:recovery/root/etc/twrp.fstab

# Wifi calibration
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/nvram_net.txt:system/vendor/firmware/nvram_net.txt

# Wifi
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/wpa_supplicant_overlay.conf:system/etc/wifi/wpa_supplicant_overlay.conf

# MAC adress tool
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/prebuilt/get_macaddrs:system/bin/get_macaddrs

# Input device calibration files
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/sec_touchscreen.idc:system/usr/idc/sec_touchscreen.idc

# Keylayouts
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/keylayout/sec_jack.kl:system/usr/keylayout/sec_jack.kl \
    $(DEVICE_PATH)/keylayout/sec_key.kl:system/usr/keylayout/sec_key.kl \
    $(DEVICE_PATH)/keylayout/sec_power_key.kl:system/usr/keylayout/sec_power_key.kl \
    $(DEVICE_PATH)/keylayout/sec_touchscreen.kl:system/usr/keylayout/sec_touchscreen.kl

# GPS config
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/gps/etc/gps.conf:system/etc/gps.conf

PRODUCT_PACKAGES += \
    camera.msm7x30 \
    copybit.msm7x30 \
    gralloc.msm7x30 \
    hwcomposer.msm7x30 \
    memtrack.msm7x30 \
    gps.msm7x30 \
    lights.msm7x30 \
    power.msm7x30 \
    audio.primary.msm7x30 \
    audio.a2dp.default \
    audio.usb.default \
    libaudio-resampler \
    libaudioparameter \
    libgenlock

PRODUCT_PACKAGES += \
    libmm-omxcore \
    libOmxCore \
    libOmxVenc \
    libOmxVdec \
    libstagefrighthw \
    libc2dcolorconvert

PRODUCT_PACKAGES += \
    badblocks \
    e2fsck \
    mke2fs \
    mke2fs.conf \
    resize2fs \
    tune2fs

PRODUCT_PACKAGES += \
    fsck.f2fs \
    mkfs.f2fs

PRODUCT_PACKAGES += \
    libexifa \
    libjpega

# IPv6 tethering
PRODUCT_PACKAGES += \
    ebtables \
    ethertypes

# Charger images
PRODUCT_PACKAGES += \
    charger_res_images

# WPA supplicant
PRODUCT_PACKAGES += \
    wificond \
    hostapd \
    libwpa_client \
    wpa_supplicant \
    wpa_supplicant.conf

PRODUCT_LOCALES := en_GB tr_TR

# ART
PRODUCT_PROPERTY_OVERRIDES += \
    dalvik.vm.dex2oat-flags=--no-watch-dog

$(call inherit-product, vendor/samsung/ancora/device-vendor.mk)
$(call inherit-product-if-exists, hardware/broadcom/wlan/bcmdhd/firmware/bcm4329/device-bcm.mk)
$(call inherit-product, frameworks/native/build/phone-hdpi-512-dalvik-heap.mk)
$(call inherit-product, build/target/product/go_defaults.mk)
$(call inherit-product, $(DEVICE_PATH)/hidl.mk)

# HIDL infrastructure and charger. Legacy accelerated codecs still need a port.
PRODUCT_PACKAGES += \
    android.hidl.base@1.0 \
    android.hidl.manager@1.0 \
    android.hidl.memory@1.0-impl \
    android.hidl.allocator@1.0-service \
    libhidltransport \
    libhwbinder \
    libstagefright_softomx \
    charger

