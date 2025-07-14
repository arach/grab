import SwiftUI
import AppKit

struct CaptureEditorView: View {
    let capture: Capture
    let onAction: (CaptureEditorAction) -> Void
    
    @State private var image: NSImage?
    @State private var annotations: [Annotation] = []
    @State private var currentTool: DrawingTool = .select
    @State private var isDrawing = false
    @State private var currentPath: Path = Path()
    @State private var startPoint: CGPoint = .zero
    @State private var visionResult: VisionResult?
    @State private var showVisionOverlay = false
    @State private var commandText = ""
    @State private var isCommandMode = false
    @FocusState private var commandFieldFocused: Bool
    @State private var canvasSize: CGSize = .zero
    @State private var selectedAnnotationId: UUID?
    @State private var isDragging = false
    @State private var dragOffset: CGSize = .zero
    @State private var currentColor: Color = .red
    @State private var resizeHandle: ResizeHandle? = nil
    @State private var initialAnnotationBounds: CGRect = .zero
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                // Select tool (separate from drawing tools)
                ToolButton(
                    icon: DrawingTool.select.icon,
                    tool: .select,
                    currentTool: $currentTool,
                    shortcut: DrawingTool.select.shortcut
                )
                
                Divider()
                    .frame(height: 30)
                    .padding(.horizontal, 8)
                
                // Drawing tools
                HStack(spacing: 8) {
                    ForEach(DrawingTool.allCases, id: \.self) { tool in
                        if tool != .select {
                            ToolButton(
                                icon: tool.icon,
                                tool: tool,
                                currentTool: $currentTool,
                                shortcut: tool.shortcut
                            )
                        }
                    }
                }
                
                Divider()
                    .frame(height: 30)
                
                // Color picker
                HStack(spacing: 6) {
                    ForEach([Color.red, Color.blue, Color.green, Color.yellow, Color.orange, Color.purple], id: \.self) { color in
                        ColorPickerButton(color: color, isSelected: currentColor == color) {
                            currentColor = color
                            updateSelectedAnnotationColor(color)
                        }
                    }
                }
                
                Spacer()
                
                // Command mode toggle
                Button(action: { 
                    isCommandMode = true
                    commandFieldFocused = true
                }) {
                    Image(systemName: "command.square")
                        .help("Command Mode (/)") 
                }
                .buttonStyle(.plain)
                
                // Vision toggle
                Button(action: { showVisionOverlay.toggle() }) {
                    Image(systemName: showVisionOverlay ? "eye.fill" : "eye")
                        .help("Toggle Vision Detection")
                }
                .buttonStyle(.plain)
                .keyboardShortcut("v", modifiers: [])
                
                // Actions
                Button("Cancel") {
                    onAction(.cancel)
                }
                .keyboardShortcut("q", modifiers: [])
                .opacity(isCommandMode ? 0 : 1) // Hide when in command mode to let command mode handle Q
                
                Button("Save") {
                    saveAnnotatedImage()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                // Dark gradient background like other Grab windows
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.95),
                        Color.black.opacity(0.85)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Canvas
            GeometryReader { geometry in
                ZStack {
                    // Original image
                    if let image = image {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                    }
                    
                    // Vision overlay
                    if showVisionOverlay, let visionResult = visionResult {
                        VisionOverlay(
                            visionResult: visionResult,
                            imageSize: image?.size ?? .zero,
                            viewSize: geometry.size
                        )
                        .allowsHitTesting(false)
                    }
                    
                    // Annotations overlay
                    Canvas { context, size in
                        // Draw saved annotations
                        for annotation in annotations {
                            drawAnnotation(annotation, in: context)
                            
                            // Draw selection handles if selected
                            if annotation.id == selectedAnnotationId {
                                drawSelectionHandles(for: annotation, in: context)
                            }
                        }
                        
                        // Draw current annotation being created
                        if isDrawing && currentTool != .select {
                            context.stroke(currentPath, with: .color(currentColor), lineWidth: 2)
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .contentShape(Rectangle())
                    .onAppear {
                        canvasSize = geometry.size
                    }
                    .onChange(of: geometry.size) { newSize in
                        canvasSize = newSize
                    }
                    .onDragGesture(
                        onStart: { location in
                            startDrawing(at: location)
                        },
                        onDrag: { location in
                            continueDrawing(to: location)
                        },
                        onEnd: { location in
                            finishDrawing(at: location)
                        }
                    )
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            
            // Command input bar
            if isCommandMode {
                HStack {
                    Image(systemName: "command")
                        .foregroundColor(.secondary)
                    
                    TextField("Type command: arrow to button, circle the menu, etc.", text: $commandText)
                        .textFieldStyle(.plain)
                        .focused($commandFieldFocused)
                        .onSubmit {
                            executeCommand()
                        }
                    
                    Button("Cancel") {
                        isCommandMode = false
                        commandText = ""
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .onAppear {
            loadImage()
        }
        .onDeleteCommand {
            deleteSelectedAnnotation()
        }
    }
    
    private func loadImage() {
        let capturesDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Grab/captures")
        let imagePath = capturesDirectory.appendingPathComponent(capture.filename)
        
        if let loadedImage = NSImage(contentsOf: imagePath) {
            image = loadedImage
            
            // Run Vision analysis
            VisionAnalyzer.shared.analyze(image: loadedImage) { result in
                DispatchQueue.main.async { [self] in
                    self.visionResult = result
                }
            }
        }
    }
    
    private func startDrawing(at point: CGPoint) {
        if currentTool == .select {
            // First check if clicking on a resize handle
            if let selectedId = selectedAnnotationId,
               let annotation = annotations.first(where: { $0.id == selectedId }) {
                let bounds = annotation.bounds()
                let handleSize: CGFloat = 8
                
                // Check each resize handle
                for handle in [ResizeHandle.topLeft, .topRight, .bottomLeft, .bottomRight] {
                    if handle.getHandleRect(for: bounds, handleSize: handleSize).contains(point) {
                        resizeHandle = handle
                        initialAnnotationBounds = bounds
                        return
                    }
                }
            }
            
            // Then check if clicking on an annotation
            selectedAnnotationId = nil
            resizeHandle = nil
            for annotation in annotations.reversed() {
                if annotation.contains(point: point) {
                    selectedAnnotationId = annotation.id
                    isDragging = true
                    dragOffset = CGSize(
                        width: point.x - annotation.startPoint.x,
                        height: point.y - annotation.startPoint.y
                    )
                    break
                }
            }
        } else {
            isDrawing = true
            startPoint = point
            currentPath = Path()
            
            switch currentTool {
            case .arrow, .rectangle, .circle:
                // These will be drawn on drag
                break
            case .text:
                // TODO: Show text input
                break
            case .select:
                break
            }
        }
    }
    
    private func continueDrawing(to point: CGPoint) {
        // Ensure points are within canvas bounds
        guard canvasSize.width > 0, canvasSize.height > 0 else { return }
        
        let clampedPoint = CGPoint(
            x: max(0, min(point.x, canvasSize.width)),
            y: max(0, min(point.y, canvasSize.height))
        )
        
        if currentTool == .select {
            if let selectedId = selectedAnnotationId {
                if let handle = resizeHandle {
                    // Resize the selected annotation
                    if let index = annotations.firstIndex(where: { $0.id == selectedId }) {
                        resizeAnnotation(at: index, with: handle, to: clampedPoint)
                    }
                } else if isDragging {
                    // Move the selected annotation
                    if let index = annotations.firstIndex(where: { $0.id == selectedId }) {
                        let dx = clampedPoint.x - dragOffset.width - annotations[index].startPoint.x
                        let dy = clampedPoint.y - dragOffset.height - annotations[index].startPoint.y
                        annotations[index].startPoint.x += dx
                        annotations[index].startPoint.y += dy
                        annotations[index].endPoint.x += dx
                        annotations[index].endPoint.y += dy
                    }
                }
            }
        } else if currentTool != .select {
            currentPath = Path()
            
            switch currentTool {
            case .arrow:
                drawArrow(from: startPoint, to: clampedPoint, in: &currentPath)
            case .rectangle:
                currentPath.addRect(CGRect(
                    x: min(startPoint.x, clampedPoint.x),
                    y: min(startPoint.y, clampedPoint.y),
                    width: abs(clampedPoint.x - startPoint.x),
                    height: abs(clampedPoint.y - startPoint.y)
                ))
            case .circle:
                let radius = min(
                    sqrt(pow(clampedPoint.x - startPoint.x, 2) + pow(clampedPoint.y - startPoint.y, 2)),
                    max(canvasSize.width, canvasSize.height) / 2
                )
                currentPath.addEllipse(in: CGRect(
                    x: startPoint.x - radius,
                    y: startPoint.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
            case .text, .select:
                break
            }
        }
    }
    
    private func finishDrawing(at point: CGPoint) {
        if currentTool == .select {
            isDragging = false
            resizeHandle = nil
        } else {
            isDrawing = false
            
            // Don't create annotation if points are too close
            if abs(point.x - startPoint.x) > 2 || abs(point.y - startPoint.y) > 2 {
                let annotation = Annotation(
                    id: UUID(),
                    tool: currentTool,
                    startPoint: startPoint,
                    endPoint: point,
                    color: currentColor,
                    text: nil
                )
                
                annotations.append(annotation)
            }
            currentPath = Path()
        }
    }
    
    private func resizeAnnotation(at index: Int, with handle: ResizeHandle, to point: CGPoint) {
        let annotation = annotations[index]
        
        switch annotation.tool {
        case .rectangle:
            switch handle {
            case .topLeft:
                annotations[index].startPoint = point
            case .topRight:
                annotations[index].startPoint.y = point.y
                annotations[index].endPoint.x = point.x
            case .bottomLeft:
                annotations[index].startPoint.x = point.x
                annotations[index].endPoint.y = point.y
            case .bottomRight:
                annotations[index].endPoint = point
            }
            
        case .circle:
            // For circles, resize by adjusting the radius
            let center = annotation.startPoint
            let dx = point.x - center.x
            let dy = point.y - center.y
            let newRadius = sqrt(dx * dx + dy * dy)
            
            // Update endpoint to maintain circle shape
            switch handle {
            case .topLeft:
                annotations[index].endPoint = CGPoint(x: center.x - newRadius, y: center.y - newRadius)
            case .topRight:
                annotations[index].endPoint = CGPoint(x: center.x + newRadius, y: center.y - newRadius)
            case .bottomLeft:
                annotations[index].endPoint = CGPoint(x: center.x - newRadius, y: center.y + newRadius)
            case .bottomRight:
                annotations[index].endPoint = CGPoint(x: center.x + newRadius, y: center.y + newRadius)
            }
            
        case .arrow:
            // For arrows, only resize the endpoint based on handle
            switch handle {
            case .topLeft, .bottomLeft:
                annotations[index].startPoint = point
            case .topRight, .bottomRight:
                annotations[index].endPoint = point
            }
            
        case .text, .select:
            break
        }
    }
    
    private func drawArrow(from start: CGPoint, to end: CGPoint, in path: inout Path) {
        // Draw line
        path.move(to: start)
        path.addLine(to: end)
        
        // Calculate arrowhead
        let angle = atan2(end.y - start.y, end.x - start.x)
        let arrowLength: CGFloat = 20
        let arrowAngle: CGFloat = .pi / 6
        
        let arrowPoint1 = CGPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        let arrowPoint2 = CGPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )
        
        path.move(to: end)
        path.addLine(to: arrowPoint1)
        path.move(to: end)
        path.addLine(to: arrowPoint2)
    }
    
    private func drawAnnotation(_ annotation: Annotation, in context: GraphicsContext) {
        var path = Path()
        
        switch annotation.tool {
        case .arrow:
            drawArrow(from: annotation.startPoint, to: annotation.endPoint, in: &path)
        case .rectangle:
            path.addRect(CGRect(
                x: min(annotation.startPoint.x, annotation.endPoint.x),
                y: min(annotation.startPoint.y, annotation.endPoint.y),
                width: abs(annotation.endPoint.x - annotation.startPoint.x),
                height: abs(annotation.endPoint.y - annotation.startPoint.y)
            ))
        case .circle:
            let radius = sqrt(pow(annotation.endPoint.x - annotation.startPoint.x, 2) + 
                            pow(annotation.endPoint.y - annotation.startPoint.y, 2))
            path.addEllipse(in: CGRect(
                x: annotation.startPoint.x - radius,
                y: annotation.startPoint.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
        case .text:
            // TODO: Draw text
            break
        case .select:
            break
        }
        
        if annotation.tool == .rectangle && annotation.color == .yellow.opacity(0.5) {
            // Fill for highlights
            context.fill(path, with: .color(annotation.color))
        } else {
            // Stroke for normal shapes
            let strokeWidth: CGFloat = annotation.id == selectedAnnotationId ? 3 : 2
            context.stroke(path, with: .color(annotation.color), lineWidth: strokeWidth)
        }
    }
    
    private func drawSelectionHandles(for annotation: Annotation, in context: GraphicsContext) {
        let bounds = annotation.bounds()
        let handleSize: CGFloat = 8
        let handleColor = Color.white
        let handleStrokeColor = Color.blue
        
        // Draw selection bounds
        var boundsPath = Path()
        boundsPath.addRect(bounds.insetBy(dx: -2, dy: -2))
        context.stroke(boundsPath, with: .color(.blue.opacity(0.5)), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
        
        // Corner handles
        let handles = [
            CGPoint(x: bounds.minX, y: bounds.minY), // Top-left
            CGPoint(x: bounds.maxX, y: bounds.minY), // Top-right
            CGPoint(x: bounds.minX, y: bounds.maxY), // Bottom-left
            CGPoint(x: bounds.maxX, y: bounds.maxY), // Bottom-right
        ]
        
        for handle in handles {
            var handlePath = Path()
            handlePath.addRoundedRect(in: CGRect(
                x: handle.x - handleSize/2,
                y: handle.y - handleSize/2,
                width: handleSize,
                height: handleSize
            ), cornerSize: CGSize(width: 2, height: 2))
            
            // Add shadow effect
            context.drawLayer { ctx in
                ctx.addFilter(.shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1))
                ctx.fill(handlePath, with: .color(handleColor))
            }
            context.stroke(handlePath, with: .color(handleStrokeColor), lineWidth: 1.5)
        }
    }
    
    private func updateSelectedAnnotationColor(_ color: Color) {
        guard let selectedId = selectedAnnotationId else { return }
        if let index = annotations.firstIndex(where: { $0.id == selectedId }) {
            annotations[index].color = color
        }
    }
    
    private func deleteSelectedAnnotation() {
        guard let selectedId = selectedAnnotationId else { return }
        annotations.removeAll { $0.id == selectedId }
        selectedAnnotationId = nil
    }
    
    private func saveAnnotatedImage() {
        guard let image = image else { return }
        
        // Create a new image with annotations
        let imageSize = image.size
        let scale = NSScreen.main?.backingScaleFactor ?? 1.0
        
        guard imageSize.width > 0 && imageSize.height > 0 else {
            print("❌ Invalid image size for saving: \(imageSize)")
            return
        }
        
        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(imageSize.width * scale),
            pixelsHigh: Int(imageSize.height * scale),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { 
            print("❌ Failed to create bitmap representation")
            return 
        }
        
        bitmapRep.size = imageSize
        
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        
        guard let context = NSGraphicsContext(bitmapImageRep: bitmapRep) else {
            print("❌ Failed to create graphics context")
            return
        }
        
        NSGraphicsContext.current = context
        
        // Draw original image
        image.draw(at: .zero, from: NSRect(origin: .zero, size: imageSize), operation: .copy, fraction: 1.0)
        
        // Draw annotations
        let cgContext = context.cgContext
        cgContext.setLineCap(.round)
        cgContext.setLineJoin(.round)
        
        for annotation in annotations {
            drawAnnotationToCGContext(annotation, in: cgContext)
        }
        
        // Ensure context is flushed
        cgContext.flush()
        
        // Create final image
        let annotatedImage = NSImage(size: imageSize)
        annotatedImage.addRepresentation(bitmapRep)
        
        // Call action on main thread
        DispatchQueue.main.async {
            onAction(.save(annotatedImage))
        }
    }
    
    private func drawAnnotationToCGContext(_ annotation: Annotation, in context: CGContext) {
        context.saveGState()
        defer { context.restoreGState() }
        
        // Convert SwiftUI Color to CGColor
        let nsColor = NSColor(annotation.color)
        context.setStrokeColor(nsColor.cgColor)
        context.setLineWidth(2.0)
        
        switch annotation.tool {
        case .arrow:
            // Draw line
            context.move(to: annotation.startPoint)
            context.addLine(to: annotation.endPoint)
            context.strokePath()
            
            // Draw arrowhead
            let angle = atan2(annotation.endPoint.y - annotation.startPoint.y, 
                            annotation.endPoint.x - annotation.startPoint.x)
            let arrowLength: CGFloat = 20
            let arrowAngle: CGFloat = .pi / 6
            
            let arrowPoint1 = CGPoint(
                x: annotation.endPoint.x - arrowLength * cos(angle - arrowAngle),
                y: annotation.endPoint.y - arrowLength * sin(angle - arrowAngle)
            )
            let arrowPoint2 = CGPoint(
                x: annotation.endPoint.x - arrowLength * cos(angle + arrowAngle),
                y: annotation.endPoint.y - arrowLength * sin(angle + arrowAngle)
            )
            
            context.move(to: annotation.endPoint)
            context.addLine(to: arrowPoint1)
            context.move(to: annotation.endPoint)
            context.addLine(to: arrowPoint2)
            context.strokePath()
            
        case .rectangle:
            let rect = CGRect(
                x: min(annotation.startPoint.x, annotation.endPoint.x),
                y: min(annotation.startPoint.y, annotation.endPoint.y),
                width: abs(annotation.endPoint.x - annotation.startPoint.x),
                height: abs(annotation.endPoint.y - annotation.startPoint.y)
            )
            
            if annotation.color == .yellow.opacity(0.5) {
                // Fill for highlights
                var alpha: CGFloat = 0
                nsColor.getWhite(nil, alpha: &alpha)
                context.setFillColor(nsColor.withAlphaComponent(0.5).cgColor)
                context.fill(rect)
            } else {
                // Stroke for normal rectangles
                context.stroke(rect)
            }
            
        case .circle:
            let radius = sqrt(pow(annotation.endPoint.x - annotation.startPoint.x, 2) + 
                            pow(annotation.endPoint.y - annotation.startPoint.y, 2))
            let rect = CGRect(
                x: annotation.startPoint.x - radius,
                y: annotation.startPoint.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            context.strokeEllipse(in: rect)
            
        case .text:
            // TODO: Implement text drawing
            break
            
        case .select:
            // Select tool is not drawn
            break
        }
    }
    
    private func executeCommand() {
        guard !commandText.isEmpty, visionResult != nil else {
            isCommandMode = false
            commandText = ""
            return
        }
        
        let command = commandText.lowercased()
        
        // Parse command patterns
        if command.contains("arrow to") {
            let target = command.replacingOccurrences(of: "arrow to", with: "").trimmingCharacters(in: .whitespaces)
            drawArrowToElement(matching: target)
        } else if command.contains("circle") {
            let target = command.replacingOccurrences(of: "circle", with: "")
                .replacingOccurrences(of: "the", with: "")
                .trimmingCharacters(in: .whitespaces)
            circleElement(matching: target)
        } else if command.contains("highlight") {
            let target = command.replacingOccurrences(of: "highlight", with: "").trimmingCharacters(in: .whitespaces)
            highlightElement(matching: target)
        } else if command.contains("box") || command.contains("rectangle") {
            let target = command.replacingOccurrences(of: "box", with: "")
                .replacingOccurrences(of: "rectangle", with: "")
                .replacingOccurrences(of: "the", with: "")
                .trimmingCharacters(in: .whitespaces)
            boxElement(matching: target)
        }
        
        // Clear command mode
        isCommandMode = false
        commandText = ""
    }
    
    private func drawArrowToElement(matching query: String) {
        guard let element = findElement(matching: query),
              image != nil else { return }
        
        // Get view size from stored canvas size
        let viewSize = canvasSize.width > 0 ? canvasSize : CGSize(width: 800, height: 600)
        
        // Convert element bounds to view coordinates
        let elementRect = VisionAnalyzer.convertVisionRect(element.boundingBox, to: viewSize)
        
        // Draw arrow from center to element
        let centerPoint = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        let targetPoint = CGPoint(x: elementRect.midX, y: elementRect.midY)
        
        let annotation = Annotation(
            id: UUID(),
            tool: .arrow,
            startPoint: centerPoint,
            endPoint: targetPoint,
            color: currentColor,
            text: nil
        )
        
        annotations.append(annotation)
    }
    
    private func circleElement(matching query: String) {
        guard let element = findElement(matching: query),
              image != nil else { return }
        
        let viewSize = canvasSize.width > 0 ? canvasSize : CGSize(width: 800, height: 600)
        let elementRect = VisionAnalyzer.convertVisionRect(element.boundingBox, to: viewSize)
        
        let center = CGPoint(x: elementRect.midX, y: elementRect.midY)
        let radius = max(elementRect.width, elementRect.height) / 2 + 10
        
        let annotation = Annotation(
            id: UUID(),
            tool: .circle,
            startPoint: center,
            endPoint: CGPoint(x: center.x + radius, y: center.y),
            color: currentColor,
            text: nil
        )
        
        annotations.append(annotation)
    }
    
    private func highlightElement(matching query: String) {
        guard let element = findElement(matching: query),
              image != nil else { return }
        
        let viewSize = canvasSize.width > 0 ? canvasSize : CGSize(width: 800, height: 600)
        let elementRect = VisionAnalyzer.convertVisionRect(element.boundingBox, to: viewSize)
        
        // Create a rectangle with some padding
        let padding: CGFloat = 5
        let topLeft = CGPoint(x: elementRect.minX - padding, y: elementRect.minY - padding)
        let bottomRight = CGPoint(x: elementRect.maxX + padding, y: elementRect.maxY + padding)
        
        let annotation = Annotation(
            id: UUID(),
            tool: .rectangle,
            startPoint: topLeft,
            endPoint: bottomRight,
            color: .yellow.opacity(0.5),
            text: nil
        )
        
        annotations.append(annotation)
    }
    
    private func boxElement(matching query: String) {
        guard let element = findElement(matching: query),
              image != nil else { return }
        
        let viewSize = canvasSize.width > 0 ? canvasSize : CGSize(width: 800, height: 600)
        let elementRect = VisionAnalyzer.convertVisionRect(element.boundingBox, to: viewSize)
        
        let annotation = Annotation(
            id: UUID(),
            tool: .rectangle,
            startPoint: CGPoint(x: elementRect.minX, y: elementRect.minY),
            endPoint: CGPoint(x: elementRect.maxX, y: elementRect.maxY),
            color: currentColor,
            text: nil
        )
        
        annotations.append(annotation)
    }
    
    private func findElement(matching query: String) -> (boundingBox: CGRect, type: String)? {
        // First try to find exact text match
        if let textMatch = visionResult?.findTextExact(query) {
            return (boundingBox: textMatch.boundingBox, type: "text")
        }
        
        // Then try partial text match
        if let textMatch = visionResult?.findText(containing: query) {
            return (boundingBox: textMatch.boundingBox, type: "text")
        }
        
        // Try to find UI elements by type
        if let uiElement = visionResult?.uiElements.first(where: { element in
            switch element.type {
            case .button:
                return query.contains("button")
            case .menu:
                return query.contains("menu")
            case .textField:
                return query.contains("field") || query.contains("input")
            default:
                return false
            }
        }) {
            return (boundingBox: uiElement.boundingBox, type: "ui")
        }
        
        // If no match, try to find the nearest rectangle
        if let rect = visionResult?.rectangles.first {
            return (boundingBox: rect.boundingBox, type: "rectangle")
        }
        
        return nil
    }
}

// Drawing models
enum DrawingTool: CaseIterable {
    case select
    case arrow
    case circle
    case rectangle
    case text
    
    var icon: String {
        switch self {
        case .select: return "cursorarrow"
        case .arrow: return "arrow.up.left"
        case .circle: return "circle"
        case .rectangle: return "rectangle"
        case .text: return "textformat"
        }
    }
    
    var shortcut: String? {
        switch self {
        case .select: return "v"
        case .arrow: return "a"
        case .circle: return "c"
        case .rectangle: return "r"
        case .text: return "t"
        }
    }
}

enum ResizeHandle {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    
    func getHandleRect(for bounds: CGRect, handleSize: CGFloat) -> CGRect {
        let halfSize = handleSize / 2
        switch self {
        case .topLeft:
            return CGRect(x: bounds.minX - halfSize, y: bounds.minY - halfSize, width: handleSize, height: handleSize)
        case .topRight:
            return CGRect(x: bounds.maxX - halfSize, y: bounds.minY - halfSize, width: handleSize, height: handleSize)
        case .bottomLeft:
            return CGRect(x: bounds.minX - halfSize, y: bounds.maxY - halfSize, width: handleSize, height: handleSize)
        case .bottomRight:
            return CGRect(x: bounds.maxX - halfSize, y: bounds.maxY - halfSize, width: handleSize, height: handleSize)
        }
    }
}

struct Annotation: Identifiable {
    let id: UUID
    var tool: DrawingTool
    var startPoint: CGPoint
    var endPoint: CGPoint
    var color: Color
    var text: String?
    var isSelected: Bool = false
    
    func bounds() -> CGRect {
        switch tool {
        case .arrow:
            let minX = min(startPoint.x, endPoint.x) - 10
            let minY = min(startPoint.y, endPoint.y) - 10
            let maxX = max(startPoint.x, endPoint.x) + 10
            let maxY = max(startPoint.y, endPoint.y) + 10
            return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        case .rectangle:
            return CGRect(
                x: min(startPoint.x, endPoint.x),
                y: min(startPoint.y, endPoint.y),
                width: abs(endPoint.x - startPoint.x),
                height: abs(endPoint.y - startPoint.y)
            )
        case .circle:
            let radius = sqrt(pow(endPoint.x - startPoint.x, 2) + pow(endPoint.y - startPoint.y, 2))
            return CGRect(
                x: startPoint.x - radius,
                y: startPoint.y - radius,
                width: radius * 2,
                height: radius * 2
            )
        case .text:
            // TODO: Calculate text bounds
            return CGRect(x: startPoint.x, y: startPoint.y, width: 100, height: 30)
        case .select:
            return .zero
        }
    }
    
    func contains(point: CGPoint) -> Bool {
        return bounds().contains(point)
    }
}

// Tool button component
struct ToolButton: View {
    let icon: String
    let tool: DrawingTool
    @Binding var currentTool: DrawingTool
    let shortcut: String?
    @State private var isHovered = false
    
    init(icon: String, tool: DrawingTool, currentTool: Binding<DrawingTool>, shortcut: String? = nil) {
        self.icon = icon
        self.tool = tool
        self._currentTool = currentTool
        self.shortcut = shortcut
    }
    
    var body: some View {
        Button(action: { currentTool = tool }) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(currentTool == tool ? .white : .primary)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(backgroundFill)
                            .shadow(color: shadowColor, radius: currentTool == tool ? 2 : 0, x: 0, y: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: 1)
                    )
                
                if let shortcut = shortcut {
                    Text(shortcut.uppercased())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .keyboardShortcut(KeyEquivalent(Character(shortcut ?? " ")), modifiers: shortcut != nil ? [] : [.command])
        .help("\(tool == .select ? "Select" : icon.capitalized) Tool (\(shortcut?.uppercased() ?? ""))")
    }
    
    private var backgroundFill: Color {
        if currentTool == tool {
            return Color.accentColor
        } else if isHovered {
            return Color.gray.opacity(0.2)
        } else {
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        if currentTool == tool {
            return Color.accentColor.opacity(0.8)
        } else if isHovered {
            return Color.gray.opacity(0.3)
        } else {
            return Color.gray.opacity(0.2)
        }
    }
    
    private var shadowColor: Color {
        currentTool == tool ? Color.accentColor.opacity(0.5) : Color.black.opacity(0.1)
    }
}

// Color picker button component
struct ColorPickerButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 28, height: 28)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                        .scaleEffect(isSelected ? 1.0 : 0.8)
                        .animation(.easeInOut(duration: 0.1), value: isSelected)
                )
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: isSelected ? color.opacity(0.5) : Color.black.opacity(0.2), 
                       radius: isSelected ? 4 : 2, 
                       x: 0, y: 1)
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// Vision overlay to show detected elements
struct VisionOverlay: View {
    let visionResult: VisionResult
    let imageSize: CGSize
    let viewSize: CGSize
    
    var body: some View {
        Canvas { context, size in
            // Calculate scale factor
            let scaleX = size.width / imageSize.width
            let scaleY = size.height / imageSize.height
            let scale = min(scaleX, scaleY)
            
            let scaledWidth = imageSize.width * scale
            let scaledHeight = imageSize.height * scale
            let offsetX = (size.width - scaledWidth) / 2
            let offsetY = (size.height - scaledHeight) / 2
            
            // Draw detected text regions
            for text in visionResult.texts {
                let rect = VisionAnalyzer.convertVisionRect(text.boundingBox, to: CGSize(width: scaledWidth, height: scaledHeight))
                let adjustedRect = CGRect(
                    x: rect.minX + offsetX,
                    y: rect.minY + offsetY,
                    width: rect.width,
                    height: rect.height
                )
                
                context.stroke(
                    Path(roundedRect: adjustedRect, cornerRadius: 2),
                    with: .color(.blue.opacity(0.8)),
                    lineWidth: 1
                )
                
                // Draw text label
                let textPoint = CGPoint(x: adjustedRect.minX + adjustedRect.width/2, y: adjustedRect.minY - 10)
                context.draw(
                    Text(text.text).font(.caption2).foregroundColor(.white),
                    at: textPoint
                )
            }
            
            // Draw detected UI elements
            for element in visionResult.uiElements {
                let rect = VisionAnalyzer.convertVisionRect(element.boundingBox, to: CGSize(width: scaledWidth, height: scaledHeight))
                let adjustedRect = CGRect(
                    x: rect.minX + offsetX,
                    y: rect.minY + offsetY,
                    width: rect.width,
                    height: rect.height
                )
                
                let color: Color = {
                    switch element.type {
                    case .button: return .orange
                    case .menu: return .purple
                    case .textField: return .cyan
                    case .unknown: return .gray
                    }
                }()
                
                context.stroke(
                    Path(roundedRect: adjustedRect, cornerRadius: 4),
                    with: .color(color.opacity(0.8)),
                    lineWidth: 2
                )
            }
            
            // Draw remaining rectangles (not identified as UI elements)
            for rectangle in visionResult.rectangles {
                // Skip if already drawn as UI element
                let isUIElement = visionResult.uiElements.contains { element in
                    element.boundingBox == rectangle.boundingBox
                }
                if isUIElement { continue }
                
                let rect = VisionAnalyzer.convertVisionRect(rectangle.boundingBox, to: CGSize(width: scaledWidth, height: scaledHeight))
                let adjustedRect = CGRect(
                    x: rect.minX + offsetX,
                    y: rect.minY + offsetY,
                    width: rect.width,
                    height: rect.height
                )
                
                context.stroke(
                    Path(roundedRect: adjustedRect, cornerRadius: 2),
                    with: .color(.green.opacity(0.4)),
                    style: StrokeStyle(lineWidth: 1, dash: [5, 5])
                )
            }
        }
    }
}

// Custom drag gesture
extension View {
    func onDragGesture(
        onStart: @escaping (CGPoint) -> Void,
        onDrag: @escaping (CGPoint) -> Void,
        onEnd: @escaping (CGPoint) -> Void
    ) -> some View {
        self.gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if value.translation.width == 0 && value.translation.height == 0 {
                        onStart(value.location)
                    } else {
                        onDrag(value.location)
                    }
                }
                .onEnded { value in
                    onEnd(value.location)
                }
        )
    }
}