//
//  TextureProcessor.swift
//  Demo
//
//  Created by Andrey Volodin on 25.06.2020.
//  Copyright © 2020 Andrey Volodin. All rights reserved.
//

import Alloy
import MetalPerformanceShaders

class TextureProcessor {
    let context: MTLContext
    
    let contrast: Contrast
    let saturation: Saturation
    let gaussianBlur: MPSImageGaussianBlur
    let sharpen: Sharpening
    
    init(context: MTLContext) throws {
        self.context = context
        
        let library = try context.library(for: Self.self)
        self.contrast = try .init(library: library, shouldKeepAlpha: true)
        self.saturation = try .init(library: library, shouldKeepAlpha: true)
        
        self.gaussianBlur = .init(device: context.device, sigma: 10.0)
        self.gaussianBlur.edgeMode = .clamp
        
        self.sharpen = try .init(library: library, shouldKeepAlpha: true, intensity: 2.0)
    }
    
    func process(texture: MTLTexture, contrast: Float, saturation: Float, sharpen: Bool) throws -> MTLTexture {
        let resultTexture = try texture.matchingTexture(usage: [.shaderRead, .shaderWrite],
                                                        storage: .managed)
        
        let temporaryDescriptor = texture.descriptor
        temporaryDescriptor.usage = [.shaderRead, .shaderWrite]
        temporaryDescriptor.storageMode = .private
        
        try self.context.scheduleAndWait { commandBuffer in
            defer {
                commandBuffer.blit { encoder in
                    encoder.synchronize(resource: resultTexture)
                }
            }
            
            let temporaryImage1 = MPSTemporaryImage(commandBuffer: commandBuffer,
                                                    textureDescriptor: temporaryDescriptor)
            self.contrast(input: texture,
                          output: temporaryImage1.texture,
                          effect: contrast,
                          in: commandBuffer)
            
            let temporaryImage2 = MPSTemporaryImage(commandBuffer: commandBuffer,
                                                    textureDescriptor: temporaryDescriptor)
            self.saturation(input: temporaryImage1.texture,
                            output: sharpen ? temporaryImage2.texture : resultTexture,
                            effect: saturation,
                            in: commandBuffer)
            
            temporaryImage1.readCount = 0
            
            guard sharpen else {
                temporaryImage2.readCount = 0
                return
            }
            
            let blurredImage = MPSTemporaryImage(commandBuffer: commandBuffer,
                                                 textureDescriptor: temporaryDescriptor)
            self.gaussianBlur(sourceTexture: temporaryImage2.texture,
                              destinationTexture: blurredImage.texture,
                              in: commandBuffer)
            
            self.sharpen(input: temporaryImage2.texture,
                         blurred: blurredImage.texture,
                         output: resultTexture,
                         in: commandBuffer)
            
            temporaryImage2.readCount = 0
            blurredImage.readCount = 0
        }
        
        return resultTexture
    }
}
