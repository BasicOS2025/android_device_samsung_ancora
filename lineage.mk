# Android 8.1 / LineageOS 15.1 development product.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)
$(call inherit-product, device/samsung/ancora/full_ancora.mk)

PRODUCT_NAME := lineage_ancora
PRODUCT_DEVICE := ancora
PRODUCT_BRAND := samsung
PRODUCT_MANUFACTURER := samsung
PRODUCT_MODEL := GT-I8150
PRODUCT_GMS_CLIENTID_BASE := android-samsung
