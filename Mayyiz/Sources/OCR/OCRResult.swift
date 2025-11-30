import Foundation
import CoreGraphics

/// Result of OCR text recognition
struct OCRResult: Equatable {
    /// Recognized text (normalized)
    let text: String
    
    /// Bounding boxes for each recognized text region
    let boxes: [CGRect]
    
    /// Overall confidence score (0.0 to 1.0)
    let confidence: Double
    
    /// Individual confidence scores for each text region
    let regionConfidences: [Double]
    
    /// Language codes detected
    let detectedLanguages: [String]
    
    init(text: String,
         boxes: [CGRect] = [],
         confidence: Double = 0.0,
         regionConfidences: [Double] = [],
         detectedLanguages: [String] = []) {
        self.text = text
        self.boxes = boxes
        self.confidence = confidence
        self.regionConfidences = regionConfidences
        self.detectedLanguages = detectedLanguages
    }
    
    /// Check if confidence meets a threshold
    func meetsConfidenceThreshold(_ threshold: Double) -> Bool {
        return confidence >= threshold
    }
    
    /// Get text regions with their bounding boxes
    var textRegions: [(text: String, box: CGRect, confidence: Double)] {
        let textLines = text.components(separatedBy: "\n")
        let count = min(textLines.count, boxes.count, regionConfidences.count)
        
        var regions: [(String, CGRect, Double)] = []
        for i in 0..<count {
            regions.append((textLines[i], boxes[i], regionConfidences[i]))
        }
        return regions
    }
}

// MARK: - Codable Conformance

extension OCRResult: Codable {
    enum CodingKeys: String, CodingKey {
        case text, boxes, confidence, regionConfidences, detectedLanguages
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        confidence = try container.decode(Double.self, forKey: .confidence)
        regionConfidences = try container.decode([Double].self, forKey: .regionConfidences)
        detectedLanguages = try container.decode([String].self, forKey: .detectedLanguages)
        
        // Decode CGRect array
        let boxData = try container.decode([[String: Double]].self, forKey: .boxes)
        boxes = boxData.map { dict in
            CGRect(
                x: dict["x"] ?? 0,
                y: dict["y"] ?? 0,
                width: dict["width"] ?? 0,
                height: dict["height"] ?? 0
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(regionConfidences, forKey: .regionConfidences)
        try container.encode(detectedLanguages, forKey: .detectedLanguages)
        
        // Encode CGRect array
        let boxData = boxes.map { rect in
            [
                "x": Double(rect.origin.x),
                "y": Double(rect.origin.y),
                "width": Double(rect.width),
                "height": Double(rect.height)
            ]
        }
        try container.encode(boxData, forKey: .boxes)
    }
}
