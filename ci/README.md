# GitHub Actions ile ROM derleme

`.github/workflows/build-rom.yml`, **Ancora LineageOS 15.1 ROM** adlı elle
başlatılabilir bir derleme sağlar. Ubuntu 22.04 üzerinde Java 8 ve Python 2
hazırlar; LineageOS 15.1 kaynakları ile device/vendor/kernel ağaçlarını indirir
ve `lunch lineage_ancora-userdebug`, ardından `make bacon` çalıştırır.

Bir derleme hatasında aynı runner, `lineage-15.1` dalına gelecek düzeltmeyi
10 dakika bekler. Yeni commit aynı geçmişin devamıysa device ağacını yalnızca
fast-forward ile günceller ve kaynakları baştan indirmeden yeniden dener.
En fazla 20 deneme yapılır. Her denemenin hatası check annotations alanına,
ayrıntılı logu artifact'a kaydedilir. Kernel/vendor revizyonları sabit kalır.

Her denemeden önce ARM WebView APK'sı Git LFS üzerinden hazırlanır. APK'nın
manifestte sabitlenen Git revizyonundaki SHA-256 değeri, boyutu ve ZIP bütünlüğü
doğrulanır; LFS işaretçi metni yanlışlıkla APK olarak imzalama adımına verilmez.

Ücretsiz standart public Ubuntu runner profili en fazla 4 paralel derleme işi,
16 GB toplam RAM ve 360 dakika çalışma süresidir. Jack için 16 GB runner'da
4 GiB heap ayrılır; daha küçük makinelerde heap ve paralellik otomatik azaltılır.
Kaynak senkronizasyonu CPU sayısının iki katı bağlantı kullanır (en fazla 8).
ccache 8 GiB'a kadar büyür; başlangıçta 70 GiB'tan az boş alan varsa 4 GiB'a
düşer. Sıkıştırma ve derleyici içerik kontrolü, farklı çalışmalardaki önbellek
kullanımını destekler. Kullanım istatistikleri her denemede loga yazılır.

Ücretli/larger runner veya ek depolama satın alınmaz. Depodaki varsayılan
10 GB cache sınırı artırılmaz; eski snapshot'ların tahliyesini GitHub yönetir.
Kaynak: https://docs.github.com/en/actions/reference/runners/github-hosted-runners
ve https://docs.github.com/en/actions/reference/limits

Yalnızca yapılandırma güncelleniyorsa commit mesajındaki `[skip ci]` yeni bir
push derlemesi oluşturmaz. Devam eden çalışma iptal edilmez. Bu profil ayarları
bir sonraki workflow çalışmasında yüklenir; çalışan shell'in ayarlarını değiştirmez.

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
