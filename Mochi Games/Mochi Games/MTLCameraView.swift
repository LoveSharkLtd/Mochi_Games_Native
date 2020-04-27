//
//  MTLCameraView.swift
//  Mochi Games
//
//  Created by Sam Weekes on 4/27/20.
//  Copyright © 2020 Sam Weekes. All rights reserved.
//

import Foundation
import CoreMedia
import Metal
import MetalKit

class MTLCameraView : MTKView {
    
    var pixelBuffer : CVPixelBuffer? {
        didSet {
            syncQueue.sync {
                internalPixelBuffer = pixelBuffer
            }
        }
    }
    
    private var internalPixelBuffer : CVPixelBuffer?
    
    var formatDescription : CMFormatDescription? {
        didSet {
            syncQueue.sync {
                internalformatDescription = formatDescription
            }
        }
    }
    
    private var internalformatDescription : CMFormatDescription?
    private let syncQueue = DispatchQueue(label: "Camera Preview Sync Queue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    private let dataOutputQueue = DispatchQueue(label: "VideoDataQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    private var textureCache : CVMetalTextureCache?
    private var textureWidth : Int = 0
    private var textureHeight : Int = 0
    
    private var sampler : MTLSamplerState!
    private var renderPipelineState : MTLRenderPipelineState!
    private var commandQueue : MTLCommandQueue?
    
    private var vertexCoordBuffer : MTLBuffer!
    private var textCoordBuffer: MTLBuffer!
    
    
    private var internalBounds : CGRect!
    private var internalRotation: Rotation = .rotate90Degrees
    private var internalMirroring: Bool = true
    private var textureMirroring = false
    private var textureRotation: Rotation = .rotate90Degrees
    private var textureTranform: CGAffineTransform?
    
    enum Rotation: Int {
        case rotate0Degrees
        case rotate90Degrees
        case rotate180Degrees
        case rotate270Degrees
    }
    
    var mirroring = true {
        didSet {
            syncQueue.sync { internalMirroring = mirroring }
        }
    }
    
    var rotation: Rotation = .rotate0Degrees {
        didSet {
            syncQueue.sync { internalRotation = rotation }
        }
    }
    
    
    
    private var videoFilterOn : Bool = false
    private var videoFilter: FilterRenderer?
    
    public func toggleFiltering() {
        videoFilterOn = !videoFilterOn
        
        print("!! - filter? - \(videoFilterOn)")
        let filteringEnabled = videoFilterOn
        
        let _filter = RosyMetalRenderer()
        
        if filteringEnabled {
            let filterDescription = _filter.description
        }
        
        // Enable/disable the video filter.
        dataOutputQueue.async {
            if filteringEnabled {
                self.videoFilter = _filter
            } else {
                if let filter = self.videoFilter {
                    filter.reset()
                }
                self.videoFilter = nil
            }
        }
        
    }
    
    
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        setup()
    }
    
    func setup() {
        device = MTLCreateSystemDefaultDevice()
        configureMetal()
        createTextureCache()
        colorPixelFormat = .bgra8Unorm
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func configureMetal() {
        if device == nil {
            device = MTLCreateSystemDefaultDevice()
        }
        
        let defaultLibrary = device!.makeDefaultLibrary()!
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        pipelineDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "vertexPassThrough")
        pipelineDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: "fragmentPassThrough")
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        
        sampler = device?.makeSamplerState(descriptor: samplerDescriptor)
        
        do {
            renderPipelineState = try device!.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            // error can't make mtl view pipeline state
        }
        
        commandQueue = device!.makeCommandQueue()
    }
    
    func createTextureCache() {
        var newTextureCache: CVMetalTextureCache?
        
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device!, nil, &newTextureCache) == kCVReturnSuccess {
            textureCache = newTextureCache
        } else {
            // error can't make cache
        }
    }
    
    
    private func setupTransform(width: Int, height: Int, mirroring: Bool, rotation: Rotation) {
        var scaleX: Float = 1.0
        var scaleY: Float = 1.0
        var resizeAspect: Float = 1.0
        
        internalBounds = self.bounds
        textureWidth = width
        textureHeight = height
        textureMirroring = mirroring
        textureRotation = rotation
        
        if textureWidth > 0 && textureHeight > 0 {
            switch textureRotation {
            case .rotate0Degrees, .rotate180Degrees:
                scaleX = Float(internalBounds.width / CGFloat(textureWidth))
                scaleY = Float(internalBounds.height / CGFloat(textureHeight))
                
            case .rotate90Degrees, .rotate270Degrees:
                scaleX = Float(internalBounds.width / CGFloat(textureHeight))
                scaleY = Float(internalBounds.height / CGFloat(textureWidth))
            }
        }
        // Resize aspect ratio.
        resizeAspect = min(scaleX, scaleY)
        
        if scaleX < scaleY {
            scaleX = scaleY / scaleX // 1.0
            scaleY = 1.0 // scaleX / scaleY
        } else {
            scaleY = scaleX / scaleY // 1.0
            scaleX = 1.0 // scaleY / scaleX
        }
        
        if textureMirroring {
            scaleX *= -1.0
        }
        
        // Vertex coordinate takes the gravity into account.
        let vertexData: [Float] = [
            -scaleX, -scaleY, 0.0, 1.0,
            scaleX, -scaleY, 0.0, 1.0,
            -scaleX, scaleY, 0.0, 1.0,
            scaleX, scaleY, 0.0, 1.0
        ]
        vertexCoordBuffer = device!.makeBuffer(bytes: vertexData, length: vertexData.count * MemoryLayout<Float>.size, options: [])
        
        // Texture coordinate takes the rotation into account.
        var textData: [Float]
        switch textureRotation {
        case .rotate0Degrees:
            textData = [
                0.0, 1.0,
                1.0, 1.0,
                0.0, 0.0,
                1.0, 0.0
            ]
            
        case .rotate180Degrees:
            textData = [
                1.0, 0.0,
                0.0, 0.0,
                1.0, 1.0,
                0.0, 1.0
            ]
            
        case .rotate90Degrees:
            textData = [
                1.0, 1.0,
                1.0, 0.0,
                0.0, 1.0,
                0.0, 0.0
            ]
            
        case .rotate270Degrees:
            textData = [
                0.0, 0.0,
                0.0, 1.0,
                1.0, 0.0,
                1.0, 1.0
            ]
        }
        textCoordBuffer = device?.makeBuffer(bytes: textData, length: textData.count * MemoryLayout<Float>.size, options: [])
        
        // Calculate the transform from texture coordinates to view coordinates
        var transform = CGAffineTransform.identity
        if textureMirroring {
            transform = transform.concatenating(CGAffineTransform(scaleX: -1, y: 1))
            transform = transform.concatenating(CGAffineTransform(translationX: CGFloat(textureWidth), y: 0))
        }
        
        switch textureRotation {
        case .rotate0Degrees:
            transform = transform.concatenating(CGAffineTransform(rotationAngle: CGFloat(0)))
            
        case .rotate180Degrees:
            transform = transform.concatenating(CGAffineTransform(rotationAngle: CGFloat(Double.pi)))
            transform = transform.concatenating(CGAffineTransform(translationX: CGFloat(textureWidth), y: CGFloat(textureHeight)))
            
        case .rotate90Degrees:
            transform = transform.concatenating(CGAffineTransform(rotationAngle: CGFloat(Double.pi) / 2))
            transform = transform.concatenating(CGAffineTransform(translationX: CGFloat(textureHeight), y: 0))
            
        case .rotate270Degrees:
            transform = transform.concatenating(CGAffineTransform(rotationAngle: 3 * CGFloat(Double.pi) / 2))
            transform = transform.concatenating(CGAffineTransform(translationX: 0, y: CGFloat(textureWidth)))
        }
        
        transform = transform.concatenating(CGAffineTransform(scaleX: CGFloat(resizeAspect), y: CGFloat(resizeAspect)))
        let tranformRect = CGRect(origin: .zero, size: CGSize(width: textureWidth, height: textureHeight)).applying(transform)
        let xShift = (internalBounds.size.width - tranformRect.size.width) / 2
        let yShift = (internalBounds.size.height - tranformRect.size.height) / 2
        transform = transform.concatenating(CGAffineTransform(translationX: xShift, y: yShift))
        textureTranform = transform.inverted()
    }
    
    override func draw(_ rect: CGRect) {
        var pixelBuffer : CVPixelBuffer?
        
        var mirroring = false
        var rotation: Rotation = .rotate0Degrees

        syncQueue.sync {
            pixelBuffer = internalPixelBuffer
            mirroring = internalMirroring
            rotation = internalRotation
        }
        
        if videoFilterOn {
            var finalVideoPixelBuffer = pixelBuffer
            if let filter = videoFilter {
                if !filter.isPrepared {
                    /*
                     outputRetainedBufferCountHint is the number of pixel buffers the renderer retains. This value informs the renderer
                     how to size its buffer pool and how many pixel buffers to preallocate. Allow 3 frames of latency to cover the dispatch_async call.
                     */
                    filter.prepare(with: self.internalformatDescription!, outputRetainedBufferCountHint: 3)
                }
                
                // Send the pixel buffer through the filter
                guard let filteredBuffer = filter.render(pixelBuffer: finalVideoPixelBuffer!) else {
                    print("Unable to filter video buffer")
                    return
                }
                
                internalPixelBuffer = filteredBuffer
            }
            
        }
        
        guard let drawable = currentDrawable, let currentRenderPassDescriptor = currentRenderPassDescriptor, let previewPixelBuffer = pixelBuffer else {
                return
        }
        
        let width = CVPixelBufferGetWidth(previewPixelBuffer)
        let height = CVPixelBufferGetHeight(previewPixelBuffer)
        
        if textureCache == nil { createTextureCache() }
        
        var cvTextureOut : CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache!, previewPixelBuffer, nil, .bgra8Unorm, width, height, 0, &cvTextureOut)
        
        guard let cvTexture = cvTextureOut, let texture = CVMetalTextureGetTexture(cvTexture) else {
            // error = can't make texture
            CVMetalTextureCacheFlush(textureCache!, 0)
            return
        }
        
        if texture.width != textureWidth ||
            texture.height != textureHeight ||
            self.bounds != internalBounds ||
            mirroring != textureMirroring ||
            rotation != textureRotation {
            setupTransform(width: texture.width, height: texture.height, mirroring: mirroring, rotation: rotation)
        }
        
        guard let commandQueue = commandQueue else {
            // error - can't create metal command q
            CVMetalTextureCacheFlush(textureCache!, 0)
            return
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            // error - cant make command buffer
            CVMetalTextureCacheFlush(textureCache!, 0)
            return
        }
        
        guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: currentRenderPassDescriptor) else {
            // error - cant make encoder
            CVMetalTextureCacheFlush(textureCache!, 0)
            return
        }
        
        commandEncoder.label = "Preview display"
        commandEncoder.setRenderPipelineState(renderPipelineState!)
        commandEncoder.setVertexBuffer(vertexCoordBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(textCoordBuffer, offset: 0, index: 1)
        commandEncoder.setFragmentTexture(texture, index: 0)
        commandEncoder.setFragmentSamplerState(sampler, index: 0)
        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        commandEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
    }
}

