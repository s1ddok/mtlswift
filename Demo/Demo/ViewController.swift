//
//  ViewController.swift
//  Demo
//
//  Created by Andrey Volodin on 25.06.2020.
//  Copyright © 2020 Andrey Volodin. All rights reserved.
//

import Cocoa
import Alloy

class ViewController: NSViewController {

    var processor: TextureProcessor!
    var contrastEffect: Float = 1.0 {
        didSet {
            try! self.update()
        }
    }
    var saturationEffect: Float = 1.0 {
        didSet {
            try! self.update()
        }
    }
    var shouldSharpen: Bool = false {
        didSet {
            try! self.update()
        }
    }
    var inputTexture: MTLTexture!
    
    @IBOutlet weak var imageView: NSImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let context = try! MTLContext()
        self.processor = try! .init(context: context)
        let kittenImage = NSImage(named: "kittens")!
        
        let kittenTexture = try! context.texture(from: kittenImage.cgImage(forProposedRect: nil,
                                                                           context: nil,
                                                                           hints: nil)!,
                                                 srgb: false)
        self.inputTexture = kittenTexture
        
        self.imageView.image = kittenImage
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func contrastSliderChanged(_ sender: NSSlider) {
        self.contrastEffect = sender.floatValue
    }
    
    @IBAction func saturationSliderChanged(_ sender: NSSlider) {
        self.saturationEffect = sender.floatValue
    }
    
    @IBAction func sharpenToggled(_ sender: NSButton) {
        self.shouldSharpen = sender.state == .on
    }
    
    private func update() throws {
        let processedTexture = try self.processor.process(texture: self.inputTexture,
                                                          contrast: self.contrastEffect,
                                                          saturation: self.saturationEffect,
                                                          sharpen: self.shouldSharpen)
        
        self.imageView.image = try processedTexture.image()
    }
    
}

