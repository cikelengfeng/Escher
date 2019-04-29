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
@property (nonatomic, assign) EHPoint dirtyOffset;

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
        _alpha = 1;
        
        _backgroundColor = EHColorMake(0, 0, 0, 1);
        [self remakeVertices];
    }
    return self;
}

- (void)setBackgroundColor:(EHColor)backgroundColor
{
    if (EHColorEqual(_backgroundColor, backgroundColor)) {
        return;
    }
    _backgroundColor = backgroundColor;
    [self remakeVertices];
    self.dirty = YES;
}

- (void)remakeVertices
{
    const vector_float4 color = {self.backgroundColor.red / 255.f, self.backgroundColor.green / 255.f, self.backgroundColor.blue / 255.f, self.backgroundColor.alpha / 255.f};
    const EHColorVertex quadVertices[] =
    {
        // 2D positions,    RGBA colors
        { {  self.pixelSize.width / 2,  -self.pixelSize.height / 2 }, color },//右下角
        { { -self.pixelSize.width / 2,  -self.pixelSize.height / 2 }, color },//左下角
        { { -self.pixelSize.width / 2,   self.pixelSize.height / 2 }, color },//左上角
        
        { { -self.pixelSize.width / 2,   self.pixelSize.height / 2 }, color },//左上角
        { {  self.pixelSize.width / 2,   self.pixelSize.height / 2 }, color },//右上角
        { {  self.pixelSize.width / 2,  -self.pixelSize.height / 2 }, color },//右下角
    };
    
    // Create a vertex buffer, and initialize it with the quadVertices array
    self.vertices = [[EHRenderEngine sharedInstance].device newBufferWithBytes:quadVertices
                                                                        length:sizeof(quadVertices)
                                                                       options:MTLResourceStorageModeShared];
    self.verticesCount = sizeof(quadVertices) / sizeof(EHColorVertex);
}

- (void)setOffset:(EHPoint)offset
{
    if (self.child.dirty == NO) {
        self.dirtyOffset = _offset;
        self.child.dirty = YES;
    }
    _offset = offset;
}

- (void)setDirty:(BOOL)dirty
{
    super.dirty = dirty;
    if (dirty == NO) {
        self.child.dirty = NO;
    }
}

- (EHRect)dirtyPixelRectInContext:(EHRenderContext *)context
{
    if (self.dirty) {
        return (EHRect) {context.targetRectInPixel.origin.x, context.targetRectInPixel.origin.y, self.pixelSize.width, self.pixelSize.height};
    }
    if (self.child.dirty) {
        double x = MIN(MAX(self.dirtyOffset.x, context.targetRectInPixel.origin.x), context.targetRectInPixel.origin.x + self.pixelSize.width);
        double y = MIN(MAX(self.dirtyOffset.y, context.targetRectInPixel.origin.y), context.targetRectInPixel.origin.y + self.pixelSize.height);
        EHRect childDirtyRect = [self.child dirtyPixelRectInContext:context];
        double width = MIN(childDirtyRect.size.width, self.pixelSize.width);
        double height = MIN(childDirtyRect.size.height, self.pixelSize.height);
        return (EHRect) {x, y, width, height};
    }
    return (EHRect) {context.targetRectInPixel.origin.x, context.targetRectInPixel.origin.y, 0.0, 0.0};
}

- (void)renderInContext:(EHRenderContext *)context
{
    id<MTLRenderCommandEncoder> renderEncoder = context.encoder;
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
    
    
    {
        EHRect rect = (EHRect) {context.targetRect.origin.x + self.offset.x, context.targetRect.origin.y + self.offset.y, self.size.width - self.offset.x, self.size.height - self.offset.y};
        EHRenderContext *childContext = [context copyWithTargetRect:rect];
        const float alpha[] = {self.alpha};
        [renderEncoder setFragmentBytes:&alpha length:sizeof(alpha) atIndex:EHFragmentInputIndexAlpha];
        [self.child renderInContext:childContext];
    }
}

@end
