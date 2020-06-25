//
//  Shaders.metal
//  Demo
//
//  Created by Andrey Volodin on 25.06.2020.
//  Copyright © 2020 Andrey Volodin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// mtlswift can actually work without this but it acts as the indicator of user code, otherwise we will have to parse all of the AST of metal stdlib and other libraries
namespace mtlswift {}

// MARK: Function constants
constant bool deviceSupportsNonuniformThreadgroups [[function_constant(0)]];
constant bool shouldKeepAlpha [[function_constant(1)]];
constant float intensity [[function_constant(2)]];

constant float3 luminanceWeighting = float3(0.2125, 0.7154, 0.0721);

/// mtlswift:dispatch:optimal(0):over:output
/// mtlswift:swiftParameteterType:effect:Float
kernel void saturation(texture2d<float, access::read> input [[ texture(0) ]],
                       texture2d<float, access::write> output [[ texture(1) ]],
                       constant float& effect [[ buffer(0) ]],
                       ushort2 position [[ thread_position_in_grid ]])
{
    if (!deviceSupportsNonuniformThreadgroups) {
        const ushort outputWidth = output.get_width();
        const ushort outputHeight = output.get_height();
        
        if (position.x >= outputWidth || position.y >= outputHeight) {
            return;
        }
    }
    
    float4 color = input.read(position);

    float luminance = dot(color.rgb, luminanceWeighting);

    
    float4 resultColor;
    if (shouldKeepAlpha) {
        resultColor = float4(mix(float3(luminance), color.rgb, effect), color.a);
    } else {
        resultColor = float4(mix(float3(luminance), color.rgb, effect), 1.0);
    }
    
    output.write(resultColor, position);
}


/// mtlswift:dispatch:optimal(0):over:output
/// mtlswift:swiftParameteterType:effect:Float
kernel void contrast(texture2d<float, access::read> input [[ texture(0) ]],
                     texture2d<float, access::write> output [[ texture(1) ]],
                     constant float& effect [[ buffer(0) ]],
                     ushort2 position [[ thread_position_in_grid ]])
{
    if (!deviceSupportsNonuniformThreadgroups) {
        const ushort outputWidth = output.get_width();
        const ushort outputHeight = output.get_height();
        
        if (position.x >= outputWidth || position.y >= outputHeight) {
            return;
        }
    }
    
    float4 color = input.read(position);
    
    float4 resultColor;
    
    if (shouldKeepAlpha) {
        resultColor = float4(((color.rgb - float3(0.5)) * effect + float3(0.5)), color.a);
    } else {
        resultColor = float4(((color.rgb - float3(0.5)) * effect + float3(0.5)), 1.0);
    }
    output.write(resultColor, position);
}

/// mtlswift:swiftName:Sharpening
/// mtlswift:swiftParameterName:blurredInput:blurred
/// mtlswift:dispatch:optimal(0):over:output
kernel void sharpen(texture2d<float, access::read> input [[ texture(0) ]],
                    texture2d<float, access::read> blurredInput [[ texture(1) ]],
                    texture2d<float, access::write> output [[ texture(2) ]],
                    ushort2 position [[ thread_position_in_grid ]])
{
    if (!deviceSupportsNonuniformThreadgroups) {
        const ushort outputWidth = output.get_width();
        const ushort outputHeight = output.get_height();
        
        if (position.x >= outputWidth || position.y >= outputHeight) {
            return;
        }
    }
    
    float4 color = input.read(position);
    float4 blurredColor = blurredInput.read(position);
    
    float4 resultColor = float4(fma(intensity, color.rgb - blurredColor.rgb, blurredColor.rgb), shouldKeepAlpha ? color.a : 1.0f);
    
    output.write(resultColor, position);
}

/// mtlswift:ignore
kernel void dummy() {}
