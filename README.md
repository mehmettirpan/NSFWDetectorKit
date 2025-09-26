

# NSFWDetectorKit

A small Swift Package wrapping a Core ML model for **NSFW (Not Safe For Work)** content detection.  
👉 It allows you to classify images as **explicit (unsafe)** or **safe** based on a configurable threshold.

Bu Swift Package, Core ML tabanlı bir **NSFW (müstehcen içerik)** tespit modelini sarar.  
👉 Görselleri **müstehcen (yayınlanamaz)** veya **güvenli (yayınlanabilir)** olarak sınıflandırmanıza olanak tanır.

---

## 📦 Installation (SPM)

1. Xcode → **File ▸ Add Packages…**  
2. Repository URL:
   ```
   https://github.com/mehmettirpan/NSFWDetectorKit.git
   ```
3. Dependency Rule: *Up to Next Major Version* (önerilir)  
4. Kodda import:
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
- `score` aralığı: `0.0` (güvenli) → `1.0` (müstehcen).  
- Eşik tamamen uygulamaya bağlıdır:
  - **0.20** → sıkı (borderline içeriklerin çoğunu engeller)
  - **0.50** → dengeli
  - **0.80** → esnek  
- Performans cihaz donanımına bağlıdır (Apple Neural Engine hızlandırır).

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