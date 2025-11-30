import Foundation
import Vision
import UIKit
import CoreImage

/// Service for performing OCR on images using Vision framework
@MainActor
class OCRService {
    
    // MARK: - Configuration
    
    /// Recognition level for OCR
    enum RecognitionLevel {
        case fast
        case accurate
        
        var visionLevel: VNRequestTextRecognitionLevel {
            switch self {
            case .fast:
                return .fast
            case .accurate:
                return .accurate
            }
        }
    }
    
    /// Supported languages for OCR
    static let supportedLanguages = ["ar", "en"]
    
    // MARK: - Properties
    
    private let recognitionLevel: RecognitionLevel
    private let languages: [String]
    private let normalizeNumbers: Bool
    private let numbersToArabic: Bool
    
    // MARK: - Initialization
    
    init(recognitionLevel: RecognitionLevel = .accurate,
         languages: [String] = supportedLanguages,
         normalizeNumbers: Bool = true,
         numbersToArabic: Bool = false) {
        self.recognitionLevel = recognitionLevel
        self.languages = languages
        self.normalizeNumbers = normalizeNumbers
        self.numbersToArabic = numbersToArabic
    }
    
    // MARK: - OCR Methods
    
    /// Perform OCR on an image
    /// - Parameter image: The image to process
    /// - Returns: OCRResult with recognized text and metadata
    func recognizeText(in image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await recognizeText(in: cgImage)
    }
    
    /// Perform OCR on a CGImage
    /// - Parameter cgImage: The image to process
    /// - Returns: OCRResult with recognized text and metadata
    func recognizeText(in cgImage: CGImage) async throws -> OCRResult {
        return try await withCheckedThrowingContinuation { continuation in
            // Create text recognition request
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                do {
                    let result = try self.processObservations(observations)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            // Configure request
            request.recognitionLevel = recognitionLevel.visionLevel
            request.recognitionLanguages = languages
            request.usesLanguageCorrection = true
            
            // Perform request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error))
            }
        }
    }
    
    /// Perform OCR on image data
    /// - Parameter data: Image data
    /// - Returns: OCRResult with recognized text and metadata
    func recognizeText(in data: Data) async throws -> OCRResult {
        guard let image = UIImage(data: data) else {
            throw OCRError.invalidImage
        }
        
        return try await recognizeText(in: image)
    }
    
    // MARK: - Processing
    
    private func processObservations(_ observations: [VNRecognizedTextObservation]) throws -> OCRResult {
        guard !observations.isEmpty else {
            throw OCRError.noTextFound
        }
        
        var textLines: [String] = []
        var boxes: [CGRect] = []
        var confidences: [Double] = []
        var allDetectedLanguages: Set<String> = []
        
        // Process each observation
        for observation in observations {
            // Get top candidate
            guard let candidate = observation.topCandidates(1).first else {
                continue
            }
            
            // Get text
            var text = candidate.string
            
            // Normalize text
            text = TextNormalizer.normalize(text, numbersToArabic: numbersToArabic)
            
            // Detect languages in this text
            let detectedLangs = TextNormalizer.detectLanguages(text)
            allDetectedLanguages.formUnion(detectedLangs)
            
            // Add to results
            textLines.append(text)
            boxes.append(observation.boundingBox)
            confidences.append(Double(candidate.confidence))
        }
        
        // Combine text lines
        let combinedText = textLines.joined(separator: "\n")
        
        // Calculate overall confidence
        let overallConfidence = confidences.isEmpty ? 0.0 : confidences.reduce(0, +) / Double(confidences.count)
        
        return OCRResult(
            text: combinedText,
            boxes: boxes,
            confidence: overallConfidence,
            regionConfidences: confidences,
            detectedLanguages: Array(allDetectedLanguages)
        )
    }
    
    // MARK: - Batch Processing
    
    /// Perform OCR on multiple images
    /// - Parameter images: Array of images to process
    /// - Returns: Array of OCRResults
    func recognizeText(in images: [UIImage]) async throws -> [OCRResult] {
        var results: [OCRResult] = []
        
        for image in images {
            let result = try await recognizeText(in: image)
            results.append(result)
        }
        
        return results
    }
    
    // MARK: - Utility Methods
    
    /// Check if a language is supported
    static func isLanguageSupported(_ languageCode: String) -> Bool {
        return supportedLanguages.contains(languageCode)
    }
    
    /// Get all supported languages
    static func getAllSupportedLanguages() -> [String] {
        return supportedLanguages
    }
}

// MARK: - OCR Error

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    case recognitionFailed(Error)
    case unsupportedLanguage(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format or corrupted image data"
        case .noTextFound:
            return "No text was found in the image"
        case .recognitionFailed(let error):
            return "Text recognition failed: \(error.localizedDescription)"
        case .unsupportedLanguage(let lang):
            return "Language '\(lang)' is not supported. Supported languages: \(OCRService.supportedLanguages.joined(separator: ", "))"
        }
    }
}
