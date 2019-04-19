//
//  ImageShaders.metal
//  Escher
//
//  Created by 徐 东 on 2019/4/18.
//  Copyright © 2019 DXLab. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// Include header shared between this Metal shader code and C code executing Metal API commands
#import "ShaderTypes.h"

// Vertex shader outputs and per-fragment inputs. Includes clip-space position and vertex outputs
//  interpolated by rasterizer and fed to each fragment generated by clip-space primitives.
typedef struct
{
    // The [[position]] attribute qualifier of this member indicates this value is
    // the clip space position of the vertex when this structure is returned from
    // the vertex shader
    float4 position [[position]];
    
    // Since this member does not have a special attribute qualifier, the rasterizer
    // will interpolate its value with values of other vertices making up the triangle
    // and pass that interpolated value to the fragment shader for each fragment in
    // that triangle.
    float2 textureCoordinate;
    
} TextureRasterizerData;

// Vertex Function
vertex TextureRasterizerData
vertexShader(uint vertexID [[ vertex_id ]],
             constant EHTextureVertex *vertexArray [[ buffer(EHVertexInputIndexVertices) ]],
             constant vector_uint2 *viewportSizePointer  [[ buffer(EHVertexInputIndexViewportSize) ]])

{
    
    TextureRasterizerData out;
    
    // Index into the array of positions to get the current vertex.
    //   Positions are specified in pixel dimensions (i.e. a value of 100 is 100 pixels from
    //   the origin)
    float2 pixelSpacePosition = vertexArray[vertexID].position.xy;
    
    // Get the viewport size and cast to float.
    float2 viewportSize = float2(*viewportSizePointer);
    
    // To convert from positions in pixel space to positions in clip-space,
    //  divide the pixel coordinates by half the size of the viewport.
    // Z is set to 0.0 and w to 1.0 because this is 2D sample.
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = pixelSpacePosition / (viewportSize / 2.0);
    
    // Pass the input textureCoordinate straight to the output RasterizerData. This value will be
    //   interpolated with the other textureCoordinate values in the vertices that make up the
    //   triangle.
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    
    return out;
}

// Fragment function
fragment float4
samplingRGBxBGRShader(TextureRasterizerData in [[stage_in]],
               texture2d<half> colorTexture [[ texture(EHTextureIndexBaseColor) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    
    // Sample the texture to obtain a color
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    
    // return the color of the texture
    return float4(colorSample[2], colorSample[1], colorSample[0], colorSample[3]);
}

typedef struct
{
    // The [[position]] attribute of this member indicates that this value is the clip space
    // position of the vertex when this structure is returned from the vertex function
    float4 clipSpacePosition [[position]];
    
    // Since this member does not have a special attribute, the rasterizer interpolates
    // its value with the values of the other triangle vertices and then passes
    // the interpolated value to the fragment shader for each fragment in the triangle
    float4 color;
    
} ShapeRasterizerData;

vertex ShapeRasterizerData
shapeVertexShader(uint vertexID [[vertex_id]],
             constant EHColorVertex *vertices [[buffer(EHVertexInputIndexVertices)]],
             constant vector_uint2 *viewportSizePointer [[buffer(EHVertexInputIndexViewportSize)]])
{
    ShapeRasterizerData out;
    
    // Initialize our output clip space position
    out.clipSpacePosition = vector_float4(0.0, 0.0, 0.0, 1.0);
    
    // Index into our array of positions to get the current vertex
    //   Our positions are specified in pixel dimensions (i.e. a value of 100 is 100 pixels from
    //   the origin)
    float2 pixelSpacePosition = vertices[vertexID].position.xy;
    
    // Dereference viewportSizePointer and cast to float so we can do floating-point division
    vector_float2 viewportSize = vector_float2(*viewportSizePointer);
    
    // The output position of every vertex shader is in clip-space (also known as normalized device
    //   coordinate space, or NDC).   A value of (-1.0, -1.0) in clip-space represents the
    //   lower-left corner of the viewport whereas (1.0, 1.0) represents the upper-right corner of
    //   the viewport.
    
    // Calculate and write x and y values to our clip-space position.  In order to convert from
    //   positions in pixel space to positions in clip-space, we divide the pixel coordinates by
    //   half the size of the viewport.
    out.clipSpacePosition.xy = pixelSpacePosition / (viewportSize / 2.0);
    
    // Pass our input color straight to our output color.  This value will be interpolated
    //   with the other color values of the vertices that make up the triangle to produce
    //   the color value for each fragment in our fragment shader
    out.color = vertices[vertexID].color;
    
    return out;
}

// Fragment function
fragment float4 shapeFragmentShader(ShapeRasterizerData in [[stage_in]])
{
    // We return the color we just set which will be written to our color attachment.
    return in.color;
}

