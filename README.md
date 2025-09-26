# English

# NSFWDetectorKit

A small Swift Package wrapping a Core ML model for **NSFW (Not Safe For Work)** content detection.  
👉 It allows you to classify images as **explicit (unsafe)** or **safe** based on a configurable threshold.

---

## 📦 Installation (SPM)

1. Xcode → **File ▸ Add Packages…**  
2. Repository URL:
   ```
   https://github.com/mehmettirpan/NSFWDetectorKit.git
   ```
3. Dependency Rule: *Up to Next Major Version* (recommended)  
4. Import codes:
   ```swift
   import NSFWDetectorKit
   ```

---

## ⚙️ Requirements
- iOS 15.0+  
- Xcode 15+  
- Swift 5.9+  
- Core ML model file included: `NSFWDetector.mlpackage`

---

## 🚀 Usage

### Classify with UIImage
```swift
import NSFWDetectorKit

let image: UIImage = ... // e.g. from photo library

CoreMLNSFWScanner.shared.classify(image) { result in
    switch result {
    case .success(let (score, labels)):
        print("NSFW probability =", score)
        print("All labels =", labels)
    case .failure(let error):
        print("Error:", error)
    }
}
```

### Classify with Threshold
```swift
let threshold: Float = 0.20 // adjust as you wish

CoreMLNSFWScanner.shared.classify(image, threshold: threshold) { result in
    switch result {
    case .success(let (blocked, score, labels)):
        print("NSFW probability =", score)
        print("Blocked? =", blocked ? "❌ Not allowed" : "✅ Allowed")
    case .failure(let error):
        print("Error:", error)
    }
}
```

### Classify with CGImage (UIKit-free)
```swift
let cg: CGImage = ...
CoreMLNSFWScanner.shared.classify(
    cgImage: cg,
    orientation: .up
) { result in
    switch result {
    case .success(let (score, labels)):
        print("NSFW probability =", score)
        print("Labels =", labels)
    case .failure(let error):
        print("Error:", error)
    }
}
```

---

## 📝 Notes
- `score` range: `0 and below` (safe) → `1.0` (explicit).  
- The threshold is entirely up to your application:
  - **0.20** → strict (blocks most borderline content)
  - **0.50** → balanced
  - **0.80** → lenient  
- It is recommended to run an additional control mechanism in the range **0.15–0.60** to catch borderline cases.
- Performance depends on device hardware (Apple Neural Engine accelerates).

---

### 🔎 Threshold Recommendation
- Model outputs may sometimes produce values below 0.0. Treat any value **< 0.0** as `0.0` (safe).  
- In testing, a **threshold of 0.20** gave the best balance:
  - `< 0.20` → Safe (publishable)
  - `≥ 0.20` → Explicit (should be blocked)
- You can experiment with different thresholds depending on your use case.

---

## 📂 Project Structure
```
Package.swift
Sources/NSFWDetectorKit/
 ├── CoreMLNSFWScanner.swift
 ├── NSFWDetectorKit.swift
 └── NSFWDetector.mlpackage
```

---

## 📄 License
MIT — see [LICENSE](LICENSE).

# Türkçe

# NSFWDetectorKit

Core ML tabanlı bir **NSFW (Müstehcen İçerik)** tespit modeli saran küçük bir Swift Paketi.  
👉 Görselleri, ayarlanabilir bir eşik değerine göre **müstehcen (yayınlanamaz)** veya **güvenli (yayınlanabilir)** olarak sınıflandırmanıza olanak sağlar.

---

## 📦 Kurulum (SPM)

1. Xcode → **File ▸ Add Packages…**  
2. Depo URL'si:
   ```
   https://github.com/mehmettirpan/NSFWDetectorKit.git
   ```
3. Bağımlılık Kuralı: *Up to Next Major Version* (önerilir)  
4. Koddaki import:
   ```swift
   import NSFWDetectorKit
   ```

---

## ⚙️ Gereksinimler
- iOS 15.0+  
- Xcode 15+  
- Swift 5.9+  
- Core ML model dosyası dahil: `NSFWDetector.mlpackage`

---

## 🚀 Kullanım

### UIImage ile Sınıflandırma
```swift
import NSFWDetectorKit

let image: UIImage = ... // örn. fotoğraf kütüphanesinden

CoreMLNSFWScanner.shared.classify(image) { result in
    switch result {
    case .success(let (score, labels)):
        print("NSFW olasılığı =", score)
        print("Tüm etiketler =", labels)
    case .failure(let error):
        print("Hata:", error)
    }
}
```

### Eşik Değeri ile Sınıflandırma
```swift
let threshold: Float = 0.20 // istediğiniz gibi ayarlayın

CoreMLNSFWScanner.shared.classify(image, threshold: threshold) { result in
    switch result {
    case .success(let (blocked, score, labels)):
        print("NSFW olasılığı =", score)
        print("Engellendi mi? =", blocked ? "❌ İzin verilmedi" : "✅ İzin verildi")
    case .failure(let error):
        print("Hata:", error)
    }
}
```

### CGImage ile Sınıflandırma (UIKit gerektirmez)
```swift
let cg: CGImage = ...
CoreMLNSFWScanner.shared.classify(
    cgImage: cg,
    orientation: .up
) { result in
    switch result {
    case .success(let (score, labels)):
        print("NSFW olasılığı =", score)
        print("Etiketler =", labels)
    case .failure(let error):
        print("Hata:", error)
    }
}
```

---

## 📝 Notlar
- `score` aralığı: `0 ve altı` (güvenli) → `1.0` (müstehcen).  
- Eşik tamamen uygulamaya bağlıdır:
  - **0.20** → sıkı (borderline içeriklerin çoğunu engeller)
  - **0.50** → dengeli
  - **0.80** → esnek  
- **0.15–0.60** aralığında ek bir kontrol mekanizması çalıştırılması sınırdaki durumları yakalamak için önerilir.
- Performans cihaz donanımına bağlıdır (Apple Neural Engine hızlandırır).

### 🔎 Eşik Önerisi
- Model çıktıları bazen 0.0'ın altında değerler üretebilir. Herhangi bir **< 0.0** değeri `0.0` (güvenli) olarak değerlendirin.  
- Testlerde, **0.20 eşik değeri** en iyi dengeyi sağladı:
  - `< 0.20` → Güvenli (yayınlanabilir)
  - `≥ 0.20` → Müstehcen (engellenmeli)
- İhtiyacınıza göre farklı eşik değerleri deneyebilirsiniz.

---

## 📂 Proje Yapısı
```
Package.swift
Sources/NSFWDetectorKit/
 ├── CoreMLNSFWScanner.swift
 ├── NSFWDetectorKit.swift
 └── NSFWDetector.mlpackage
```

---

## 📄 Lisans
MIT — bkz. [LICENSE](LICENSE).
