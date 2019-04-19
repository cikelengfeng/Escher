//
//  EHSingleChildRenderBox.m
//  Escher
//
//  Created by 徐 东 on 2019/4/18.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import "EHSingleChildRenderBox.h"
#import "EHRenderBoxInternal.h"
#import "EHRenderEngine.h"
#import "ShaderTypes.h"

@interface EHSingleChildRenderBox ()

@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<MTLBuffer> vertices;
@property (nonatomic, assign) int verticesCount;

@end

@implementation EHSingleChildRenderBox

- (instancetype)initWithSize:(EHLayoutSizeBox *)size
{
    self = [super init];
    if (self) {
        super.size = size;
        id<MTLLibrary> defaultLibrary = [[EHRenderEngine sharedInstance].device newDefaultLibrary];
        id<MTLFunction> vertexProgram = [defaultLibrary newFunctionWithName:@"shapeVertexShader"];
        id<MTLFunction> fragmentProgram = [defaultLibrary newFunctionWithName:@"shapeFragmentShader"];
        MTLRenderPipelineDescriptor *pipelineStateDesc = [MTLRenderPipelineDescriptor new];
        pipelineStateDesc.vertexFunction = vertexProgram;
        pipelineStateDesc.fragmentFunction = fragmentProgram;
        pipelineStateDesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        NSError *error;
        _pipelineState = [[EHRenderEngine sharedInstance].device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:&error];
        
    }
    return self;
}

- (void)setTriangle
{
    EHColorVertex quadVertices[] =
    {
        // 2D positions,    RGBA colors
        { {  self.pixelSize.width / 2,  -self.pixelSize.height / 2 }, { 1, 0, 0, 1 } },
        { { -self.pixelSize.width / 2,  -self.pixelSize.height / 2 }, { 1, 0, 0, 1 } },
        { {    0,   self.pixelSize.height / 2 }, { 1, 0, 0, 1 } },
        { {  self.pixelSize.width * 3 / 2,  -self.pixelSize.height / 2 }, { 1, 0, 0, 1 } },
        { {  self.pixelSize.width / 2,  -self.pixelSize.height / 2 }, { 1, 0, 0, 1 } },
        { {  self.pixelSize.width,   self.pixelSize.height / 2 }, { 1, 0, 0, 1 } },
    };
    
    // Create a vertex buffer, and initialize it with the quadVertices array
    self.vertices = [[EHRenderEngine sharedInstance].device newBufferWithBytes:quadVertices
                                                                        length:sizeof(quadVertices)
                                                                       options:MTLResourceStorageModeShared];
    // Calculate the number of vertices by dividing the byte length by the size of each vertex
    self.verticesCount = sizeof(quadVertices) / sizeof(EHColorVertex);
    self.dirty = YES;
}

- (void)setOffset:(EHPoint)offset
{
    _offset = offset;
    self.child.dirty = YES;
}

- (void)renderInContext:(EHRenderContext *)context
{
    if (self.dirty) {
        id<MTLRenderCommandEncoder> renderEncoder = context.encoder;
        
        // Set the region of the drawable to draw into.
        
        [renderEncoder setViewport:(MTLViewport){context.targetRectInPixel.origin.x, context.targetRectInPixel.origin.y, self.pixelSize.width, self.pixelSize.height, -1.0, 1.0 }];
        
        [renderEncoder setRenderPipelineState:self.pipelineState];
        [renderEncoder setVertexBuffer:self.vertices
                                offset:0
                               atIndex:EHVertexInputIndexVertices];
        
        vector_uint2 size = {
            self.pixelSize.width,
            self.pixelSize.height
        };
        [renderEncoder setVertexBytes:&size
                               length:sizeof(size)
                              atIndex:EHVertexInputIndexViewportSize];
        
        // Draw the triangles.
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:self.verticesCount];
        
    }
    EHRect rect = (EHRect) {self.offset, self.size.width - self.offset.x, self.size.height - self.offset.y};
    EHRenderContext *childContext = [[EHRenderContext alloc] initWithCanvas:context.canvas encoder:context.encoder targetRect:rect];
    [self.child renderInContext:childContext];
}

@end
