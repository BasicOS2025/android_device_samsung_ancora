# GitHub Actions ile ROM derleme

`.github/workflows/build-rom.yml`, **Ancora LineageOS 15.1 ROM** adlı elle
başlatılabilir bir derleme sağlar. Ubuntu 22.04 üzerinde Java 8 ve Python 2
hazırlar; LineageOS 15.1 kaynakları ile device/vendor/kernel ağaçlarını indirir
ve `lunch lineage_ancora-userdebug`, ardından `make bacon` çalıştırır.

Bir derleme hatasında aynı runner, `lineage-15.1` dalına gelecek düzeltmeyi
10 dakika bekler. Yeni commit aynı geçmişin devamıysa device ağacını yalnızca
fast-forward ile günceller ve kaynakları baştan indirmeden yeniden dener.
En fazla 10 deneme yapılır. Her denemenin hatası check annotations alanına,
ayrıntılı logu artifact'a kaydedilir. Kernel/vendor revizyonları sabit kalır.

Bu, hâlihazırda doğrulanmış bir ROM derlemesi değildir. Device ağacındaki eski
msm7x30 kamera/grafik/ses/medya bağımlılıklarının portlanması gerekebilir;
kaynak indirme, derleme ortamı veya bağımlılık hataları loglarda görünür.

Actions çalışmasının sonunda:

- Başarılı derlemede `ancora-lineage-15.1-rom-N` artifact'ı gerçek OTA ZIP'ini,
  SHA-256 değerlerini ve kullanılan kaynak commit'lerini içerir.
- `ancora-build-logs-N`, başarı/hata durumunda tanılama kayıtlarını saklar.
- Artifact'lar 14 gün saklanır. Actions çalışma sayfasındaki **Artifacts**
  bölümünden GitHub hesabıyla indirilebilir.

Bu bir GitHub Release yayınlamaz; kaynak ZIP'i veya kernel dosyasını ROM diye
paketlemez. `collect-rom.py` sadece Android boot başlığı, sistem payload'ı ve
Ancora OTA metadata'sı bulunan derleme çıktısını toplar. ROM'un derlenmesi,
cihazda açılış ve donanım testlerinin yapıldığı anlamına gelmez.

Workflow runner'ındaki temizlik adımı yalnızca geçici GitHub runner yazılımlarını
siler. Script yerel çalışma klasörüne uygulanmak üzere tasarlanmamıştır.

Kaynaklar sığmazsa runner'da daha fazla disk veya uygun bir self-hosted runner
gerekir. İş başındaki 50 GiB kontrolü yalnızca denemeye başlama alt sınırıdır;
başarılı senkronizasyon/derleme için yeterlilik garantisi değildir.
