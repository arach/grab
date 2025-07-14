import Vision
import AppKit
import CoreGraphics

struct VisionResult {
    let texts: [DetectedText]
    let rectangles: [DetectedRectangle]
    let uiElements: [DetectedUIElement]
}

struct DetectedUIElement {
    let boundingBox: CGRect
    let type: UIElementType
    let confidence: Float
}

enum UIElementType {
    case button
    case menu
    case textField
    case unknown
}

struct DetectedText {
    let text: String
    let boundingBox: CGRect
    let confidence: Float
}

struct DetectedRectangle {
    let boundingBox: CGRect
    let confidence: Float
}

class VisionAnalyzer {
    static let shared = VisionAnalyzer()
    
    private init() {}
    
    func analyze(image: NSImage, completion: @escaping (VisionResult?) -> Void) {
        // Check minimum size requirements for Vision Framework
        guard image.size.width > 10 && image.size.height > 10 else {
            print("⚠️ Image too small for Vision analysis: \(image.size)")
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        var detectedTexts: [DetectedText] = []
        var detectedRectangles: [DetectedRectangle] = []
        
        // Text detection request
        let textRequest = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("⚠️ Text detection error: \(error)")
                return
            }
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            for observation in observations {
                if let topCandidate = observation.topCandidates(1).first {
                    let text = DetectedText(
                        text: topCandidate.string,
                        boundingBox: observation.boundingBox,
                        confidence: topCandidate.confidence
                    )
                    detectedTexts.append(text)
                }
            }
        }
        textRequest.recognitionLevel = .accurate
        
        // Rectangle detection request
        let rectangleRequest = VNDetectRectanglesRequest { request, error in
            if let error = error {
                print("⚠️ Rectangle detection error: \(error)")
                return
            }
            guard let observations = request.results as? [VNRectangleObservation] else { return }
            
            for observation in observations {
                let rectangle = DetectedRectangle(
                    boundingBox: observation.boundingBox,
                    confidence: observation.confidence
                )
                detectedRectangles.append(rectangle)
            }
        }
        rectangleRequest.minimumConfidence = 0.3  // Lower threshold for UI elements
        rectangleRequest.maximumObservations = 50  // More observations for complex UIs
        
        // Execute requests
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([textRequest, rectangleRequest])
                
                // Post-process to find UI elements based on text and rectangle patterns
                let uiElements = self.detectUIElements(from: detectedTexts, and: detectedRectangles)
                
                let result = VisionResult(
                    texts: detectedTexts,
                    rectangles: detectedRectangles,
                    uiElements: uiElements
                )
                
                DispatchQueue.main.async {
                    completion(result)
                }
            } catch {
                print("Vision error: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    // Detect UI elements from text and rectangles
    private func detectUIElements(from texts: [DetectedText], and rectangles: [DetectedRectangle]) -> [DetectedUIElement] {
        var uiElements: [DetectedUIElement] = []
        
        // Find buttons (text within rectangles)
        for text in texts {
            for rect in rectangles {
                if isTextInsideRectangle(text: text, rectangle: rect) {
                    let element = DetectedUIElement(
                        boundingBox: rect.boundingBox,
                        type: determineUIType(text: text.text),
                        confidence: (text.confidence + rect.confidence) / 2
                    )
                    uiElements.append(element)
                    break
                }
            }
        }
        
        // Find menu items (small rectangles with text)
        for rect in rectangles {
            let aspectRatio = rect.boundingBox.width / rect.boundingBox.height
            if aspectRatio > 2 && rect.boundingBox.height < 0.1 { // Likely menu item
                let element = DetectedUIElement(
                    boundingBox: rect.boundingBox,
                    type: .menu,
                    confidence: rect.confidence
                )
                uiElements.append(element)
            }
        }
        
        return uiElements
    }
    
    private func isTextInsideRectangle(text: DetectedText, rectangle: DetectedRectangle) -> Bool {
        let textCenter = CGPoint(
            x: text.boundingBox.midX,
            y: text.boundingBox.midY
        )
        return rectangle.boundingBox.contains(textCenter)
    }
    
    private func determineUIType(text: String) -> UIElementType {
        let lowercased = text.lowercased()
        
        if lowercased.contains("button") || lowercased.count < 20 {
            return .button
        } else if lowercased.contains("menu") || lowercased.contains("file") || lowercased.contains("edit") || lowercased.contains("view") {
            return .menu
        } else if lowercased.contains("search") || lowercased.contains("enter") {
            return .textField
        }
        
        return .unknown
    }
    
    // Helper function to convert Vision coordinates to view coordinates
    static func convertVisionRect(_ visionRect: CGRect, to viewSize: CGSize) -> CGRect {
        // Vision uses bottom-left origin with normalized coordinates (0-1)
        // SwiftUI uses top-left origin
        return CGRect(
            x: visionRect.minX * viewSize.width,
            y: (1 - visionRect.maxY) * viewSize.height,
            width: visionRect.width * viewSize.width,
            height: visionRect.height * viewSize.height
        )
    }
}

// Extension to make it easier to find elements by text
extension VisionResult {
    func findText(containing query: String) -> DetectedText? {
        return texts.first { text in
            text.text.lowercased().contains(query.lowercased())
        }
    }
    
    func findTextExact(_ query: String) -> DetectedText? {
        return texts.first { text in
            text.text.lowercased() == query.lowercased()
        }
    }
    
    func findNearestRectangle(to point: CGPoint, in viewSize: CGSize) -> DetectedRectangle? {
        var nearestRect: DetectedRectangle?
        var minDistance = CGFloat.greatestFiniteMagnitude
        
        for rectangle in rectangles {
            let rect = VisionAnalyzer.convertVisionRect(rectangle.boundingBox, to: viewSize)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let distance = sqrt(pow(center.x - point.x, 2) + pow(center.y - point.y, 2))
            
            if distance < minDistance {
                minDistance = distance
                nearestRect = rectangle
            }
        }
        
        return nearestRect
    }
}