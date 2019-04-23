//
//  EHImageRenderBox.m
//  Escher
//
//  Created by 徐 东 on 2019/4/18.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import "EHImageRenderBox.h"
#import "EHRenderBoxInternal.h"
#import "EHRenderEngine.h"
#import "ShaderTypes.h"


@interface EHImageRenderBox ()

@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<MTLTexture> texture;
@property (nonatomic, strong) id<MTLBuffer> vertices;
@property (nonatomic, assign) int verticesCount;

@end

@implementation EHImageRenderBox

- (instancetype)initWithSize:(EHLayoutSizeBox *)size
{
    self = [super init];
    if (self) {
        super.size = size;
        id<MTLLibrary> defaultLibrary = [[EHRenderEngine sharedInstance].device newDefaultLibrary];
        id<MTLFunction> vertexProgram = [defaultLibrary newFunctionWithName:@"vertexShader"];
        id<MTLFunction> fragmentProgram = [defaultLibrary newFunctionWithName:@"samplingRGBxBGRShader"];
        MTLRenderPipelineDescriptor *pipelineStateDesc = [MTLRenderPipelineDescriptor new];
        pipelineStateDesc.vertexFunction = vertexProgram;
        pipelineStateDesc.fragmentFunction = fragmentProgram;
        pipelineStateDesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        pipelineStateDesc.colorAttachments[0].blendingEnabled = YES;
        pipelineStateDesc.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
        pipelineStateDesc.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
        pipelineStateDesc.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
        pipelineStateDesc.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
        pipelineStateDesc.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        pipelineStateDesc.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        NSError *error;
        _pipelineState = [[EHRenderEngine sharedInstance].device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:&error];
    }
    return self;
}

- (void)setImage:(CGImageRef)image
{
    if (_image == image) {
        return;
    }
    CGImageRelease(_image);
    _image = CGImageRetain(image);
    MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:CGImageGetWidth(_image) height:CGImageGetHeight(_image) mipmapped:NO];
    desc.usage = MTLTextureUsageShaderRead;
    self.texture = [[EHRenderEngine sharedInstance].device newTextureWithDescriptor:desc];
    MTLRegion region = {
        { 0, 0, 0 },                   // MTLOrigin
        {desc.width, desc.height, 1} // MTLSize
    };
    CGDataProviderRef dataProvider = CGImageGetDataProvider(_image);
    CFDataRef data = CGDataProviderCopyData(dataProvider);
    const UInt8 *buffer = CFDataGetBytePtr(data);
    size_t bytesPerRow = CGImageGetBytesPerRow(_image);
    [self.texture replaceRegion:region mipmapLevel:0 withBytes:buffer bytesPerRow:bytesPerRow];
    
    double width = self.pixelSize.width;
    double height = self.pixelSize.height;
    EHTextureVertex quadVertices[] =
    {
        // Pixel positions, Texture coordinates
        { {  width / 2,  -height / 2 },  { 1.f, 1.f } },
        { { -width / 2,  -height / 2 },  { 0.f, 1.f } },
        { { -width / 2,   height / 2 },  { 0.f, 0.f } },
        
        { {  width / 2,  -height / 2 },  { 1.f, 1.f } },
        { { -width / 2,   height / 2 },  { 0.f, 0.f } },
        { {  width / 2,   height / 2 },  { 1.f, 0.f } },
    };
    
    // Create a vertex buffer, and initialize it with the quadVertices array
    self.vertices = [[EHRenderEngine sharedInstance].device newBufferWithBytes:quadVertices
                                     length:sizeof(quadVertices)
                                    options:MTLResourceStorageModeShared];
    // Calculate the number of vertices by dividing the byte length by the size of each vertex
    self.verticesCount = sizeof(quadVertices) / sizeof(EHTextureVertex);
    self.dirty = YES;
    
}

- (EHRect)dirtyPixelRectInContext:(EHRenderContext *)context
{
    if (self.dirty) {
        return (EHRect) {context.targetRectInPixel.origin.x, context.targetRectInPixel.origin.y, self.pixelSize.width, self.pixelSize.height};
    }
    return (EHRect) {context.targetRectInPixel.origin.x, context.targetRectInPixel.origin.y, 0.0, 0.0};
}

-(void)renderInContext:(EHRenderContext *)context
{
    if (!self.dirty) {
        return;
    }
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
    
    [renderEncoder setFragmentTexture:self.texture
                              atIndex:EHTextureIndexBaseColor];
    // Draw the triangles.
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                      vertexStart:0
                      vertexCount:self.verticesCount];
}

@end
