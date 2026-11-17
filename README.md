# Samsung Galaxy W (ancora) device tree — LineageOS 15.1

Android 8.1 için ön uyarlama. **Tam ROM derlemesi ve cihazda boot testi yapılmadı.**

Tam LineageOS `lineage-15.1` kaynak ağacında bu depoyu `device/samsung/ancora` yoluna yerleştirin.

Vendor ağacı: [BasicOS2025/android_vendor_samsung_ancora — lineage-15.1](https://github.com/BasicOS2025/android_vendor_samsung_ancora/tree/lineage-15.1), hedef yol: `vendor/samsung/ancora`.

Kernel (`kernel/samsung/msm7x30-common`, `ancora_defconfig`) ve Oreo uyumlu msm7x30 grafik/ses/medya kaynakları ayrıca gereklidir. Eski kamera API'si ve modem için radio HIDL uyarlaması tamamlanmalıdır. Bu depo çalışan veya flashlanabilir ROM olduğu iddiasını taşımaz.

Eksikler giderildikten sonra ürün seçimi:

```sh
source build/envsetup.sh
lunch lineage_ancora-userdebug
mka bacon
```

Bu komutlar doğrulanmış bir derleme sonucu değildir. Bilinen engeller, bağımlılıklar ve değişiklikler için [PORTING-8.1.md](PORTING-8.1.md) belgesine bakın. Belge birleşik device+vendor paketini de anlatır; paket köküne ait `tools/check-port.py` gibi yollar bu ayrı device deposunda bulunmaz.

`legacy-cm12/`, eski yapılandırmaların referans arşividir; aktif ürün tarafından kullanılmaz. Orijinal cihaz bilgileri ve lisans notları [README](README) ve [NOTICE.cm](NOTICE.cm) dosyalarında korunmuştur.

Yapılan doğrulama: birleşik kaynak paketinin yerel dosya yolları ve XML kontrolleri geçti. Kernel/HAL/SELinux derlemesi ve donanım testleri yapılmadı.
