//
//  ShaderTypes.h
//  Escher
//
//  Created by 徐 东 on 2019/4/18.
//  Copyright © 2019 DXLab. All rights reserved.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

// Buffer index values shared between shader and C code to ensure Metal shader buffer inputs match
//   Metal API buffer set calls
typedef enum EHVertexInputIndex
{
    EHVertexInputIndexVertices     = 0,
    EHVertexInputIndexViewportSize = 1,
} EHVertexInputIndex;

// Texture index values shared between shader and C code to ensure Metal shader buffer inputs match
//   Metal API texture set calls
typedef enum EHTextureIndex
{
    EHTextureIndexBaseColor = 0,
} EHTextureIndex;

//  This structure defines the layout of each vertex in the array of vertices set as an input to the
//    Metal vertex shader.  Since this header is shared between the .metal shader and C code,
//    you can be sure that the layout of the vertex array in the code matches the layout that
//    the vertex shader expects

typedef struct
{
    // Positions in pixel space. A value of 100 indicates 100 pixels from the origin/center.
    vector_float2 position;
    
    // 2D texture coordinate
    vector_float2 textureCoordinate;
} EHTextureVertex;

typedef struct
{
    // Positions in pixel space
    // (e.g. a value of 100 indicates 100 pixels from the center)
    vector_float2 position;
    
    // Floating-point RGBA colors
    vector_float4 color;
} EHColorVertex;


#endif /* ShaderTypes_h */
