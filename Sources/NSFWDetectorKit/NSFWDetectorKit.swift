/**
 NSFWDetectorKit
 ----------------
 A small Swift Package that wraps a Core ML NSFW detection model.

 Bu paket, Core ML tabanlı bir NSFW (müstehcen içerik) tespit modelini sarmalar.
 Kullanıcıya çıplaklık / müstehcenlik ihtimalini döndürür.
 */

import Foundation
import CoreML
@preconcurrency import Vision
#if canImport(UIKit)
import UIKit
#endif

/**
 CoreMLNSFWScanner
 ------------------
 - English: Provides APIs to classify images (UIImage / CGImage) as explicit (NSFW) or safe (SFW).
 - Türkçe: Görselleri (UIImage / CGImage) müstehcen (NSFW) veya güvenli (SFW) olarak sınıflandırmak için API sağlar.
 */
@MainActor
public final class CoreMLNSFWScanner {
    public static let shared = CoreMLNSFWScanner()
    private let vnModel: VNCoreMLModel
    private var explicitKey: String

    private init() {
        // Varsayılan etiket adı (modelden otomatik keşfedilecek)
        self.explicitKey = "explicit"

        do {
            let bundle = Bundle.module

            // Önce .mlpackage (ML Program) dene; yoksa .mlmodelc’ye düş
            if let url = bundle.url(forResource: "NSFWDetector", withExtension: "mlpackage") {
                let ml = try MLModel(contentsOf: url)
                self.vnModel = try VNCoreMLModel(for: ml)
                if #available(iOS 11.0, macOS 11.0, tvOS 11.0, watchOS 4.0, *) {
                    self.inferExplicitKey(from: ml)
                }
            } else if let url = bundle.url(forResource: "NSFWDetector", withExtension: "mlmodelc") {
                let ml = try MLModel(contentsOf: url)
                self.vnModel = try VNCoreMLModel(for: ml)
                if #available(iOS 11.0, macOS 11.0, tvOS 11.0, watchOS 4.0, *) {
                    self.inferExplicitKey(from: ml)
                }
            } else {
                fatalError("NSFWDetector model not found (.mlpackage or .mlmodelc) in package resources")
            }
        } catch {
            fatalError("Failed to load CoreML model: \(error)")
        }
    }

    @available(iOS 11.0, macOS 11.0, tvOS 11.0, watchOS 4.0, *)
    private func inferExplicitKey(from ml: MLModel) {
        // Modelin classLabels listesinden explicit etiket adını otomatik bul
        guard let labels = ml.modelDescription.classLabels as? [String] else { return }
        let lowered = Set(labels.map { $0.lowercased() })
        func pick(_ cands: [String], fallback: String) -> String {
            for c in cands { if lowered.contains(c) { return c } }
            return fallback
        }
        self.explicitKey = pick(["explicit","nsfw","adult","porn"], fallback: self.explicitKey)
    }

    /**
     Classify CGImage
     ----------------
     - English: Runs the Core ML model on a CGImage and returns the NSFW probability and all label probabilities.
     - Türkçe: CGImage üzerinde Core ML modelini çalıştırır, NSFW (müstehcenlik) olasılığını ve tüm etiket olasılıklarını döndürür.
     */
    public func classify(cgImage cg: CGImage,
                         orientation: CGImagePropertyOrientation = .up,
                         completion: @escaping (Result<(Float, [String: Float]), Error>) -> Void) {

        let request = VNCoreMLRequest(model: vnModel) { req, err in
            if let err = err {
                completion(.failure(err)); return
            }
            guard let results = req.results as? [VNClassificationObservation],
                  !results.isEmpty else {
                completion(.failure(NSError(domain: "NSFW", code: -2,
                                            userInfo: [NSLocalizedDescriptionKey: "No results"])))
                return
            }

            // Sonuçları sözlüğe dök (lowercased anahtarlarla)
            var labelProbs: [String: Float] = [:]
            results.forEach { labelProbs[$0.identifier.lowercased()] = $0.confidence }

            // explicit anahtarını kullanarak NSFW olasılığı
            var pExplicit = labelProbs[self.explicitKey] ?? 0

            // Etiket ismi farklıysa basit bir yedek: en yüksek 2 etiketten “explicit” ismine bakan heuristik
            if pExplicit == 0 {
                let sorted = labelProbs.sorted { $0.value > $1.value }
                if sorted.count >= 2 {
                    if sorted[0].key.contains("explicit") || sorted[0].key.contains("nsfw") || sorted[0].key.contains("porn") {
                        pExplicit = sorted[0].value
                    } else if sorted[1].key.contains("explicit") || sorted[1].key.contains("nsfw") || sorted[1].key.contains("porn") {
                        pExplicit = sorted[1].value
                    }
                }
            }

            completion(.success((pExplicit, labelProbs)))
        }

        // Python’daki PIL resize (square, aspect korunmadan) ile en uyumlu ayar
        request.imageCropAndScaleOption = .scaleFill
        request.usesCPUOnly = false  // ANE/GPU’ya izin ver

        // EXIF yönünü koru
        let handler = VNImageRequestHandler(
            cgImage: cg,
            orientation: orientation,
            options: [:]
        )

        do { try handler.perform([request]) }
        catch { completion(.failure(error)) }
    }

    /**
     Classify with Threshold
     -----------------------
     - English: Same as classify(cgImage:), but applies a user-provided threshold and returns a boolean `blocked` decision.
     - Türkçe: classify(cgImage:) ile aynı, fakat kullanıcı tarafından verilen bir eşik uygular ve boolean `blocked` (yayınlanamaz) sonucunu döndürür.
     */
    public func classify(cgImage cg: CGImage,
                         orientation: CGImagePropertyOrientation = .up,
                         threshold: Float,
                         completion: @escaping (Result<(blocked: Bool, score: Float, labels: [String: Float]), Error>) -> Void) {
        self.classify(cgImage: cg, orientation: orientation) { result in
            switch result {
            case .success(let (nsfw, labels)):
                let blocked = nsfw >= threshold
                completion(.success((blocked: blocked, score: nsfw, labels: labels)))
            case .failure(let e):
                completion(.failure(e))
            }
        }
    }

#if canImport(UIKit)
    /**
     UIKit Convenience - Classify UIImage
     -----------------------------------
     - English: Convenience method for UIKit callers to classify a UIImage and get NSFW probability and label probabilities.
     - Türkçe: UIKit kullanıcıları için UIImage üzerinde sınıflandırma yapıp NSFW olasılığı ve etiket olasılıklarını döndürür.
     */
    public func classify(_ image: UIImage,
                         completion: @escaping (Result<(Float, [String: Float]), Error>) -> Void) {
        guard let cg = image.cgImage else {
            completion(.failure(NSError(domain: "NSFW", code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid image"])))
            return
        }
        let ori = CGImagePropertyOrientation(image.imageOrientation)
        self.classify(cgImage: cg, orientation: ori, completion: completion)
    }

    /**
     UIKit Convenience with Threshold - Classify UIImage
     --------------------------------------------------
     - English: Convenience method for UIKit callers to classify a UIImage with threshold and get boolean blocked decision.
     - Türkçe: UIKit kullanıcıları için UIImage üzerinde eşikli sınıflandırma yaparak boolean blocked (yayınlanamaz) sonucunu döndürür.
     */
    public func classify(_ image: UIImage,
                         threshold: Float,
                         completion: @escaping (Result<(blocked: Bool, score: Float, labels: [String: Float]), Error>) -> Void) {
        guard let cg = image.cgImage else {
            completion(.failure(NSError(domain: "NSFW", code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid image"])))
            return
        }
        let ori = CGImagePropertyOrientation(image.imageOrientation)
        self.classify(cgImage: cg, orientation: ori, threshold: threshold, completion: completion)
    }
#endif
}

#if canImport(UIKit)
extension CGImagePropertyOrientation {
    init(_ ui: UIImage.Orientation) {
        switch ui {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
#endif
