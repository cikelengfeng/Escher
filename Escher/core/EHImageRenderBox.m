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
@property (nonatomic, strong) MTLRenderPassDescriptor *renderPassDesc;
@property (nonatomic, strong) id<MTLSamplerState> sampleState;
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
        id<MTLFunction> fragmentProgram = [defaultLibrary newFunctionWithName:@"samplingShader"];
        MTLRenderPipelineDescriptor *pipelineStateDesc = [MTLRenderPipelineDescriptor new];
        pipelineStateDesc.vertexFunction = vertexProgram;
        pipelineStateDesc.fragmentFunction = fragmentProgram;
        pipelineStateDesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        NSError *error;
        _pipelineState = [[EHRenderEngine sharedInstance].device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:&error];
        
        _renderPassDesc = [MTLRenderPassDescriptor new];
        _renderPassDesc.colorAttachments[0].loadAction = MTLLoadActionClear;
        _renderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(0, 104.f/255.f, 55.f/255.f, 1);
        
        MTLSamplerDescriptor *samplerDesc = [MTLSamplerDescriptor new];
        samplerDesc.maxAnisotropy = 16;
        _sampleState = [[EHRenderEngine sharedInstance].device newSamplerStateWithDescriptor:samplerDesc];
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
    MTLTextureDescriptor *desc = [MTLTextureDescriptor new];
    desc.pixelFormat = MTLPixelFormatBGRA8Unorm;
    desc.width = CGImageGetWidth(_image);
    desc.height = CGImageGetHeight(_image);
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
    
    static const EHVertex quadVertices[] =
    {
        // Pixel positions, Texture coordinates
        { {  250,  -250 },  { 1.f, 1.f } },
        { { -250,  -250 },  { 0.f, 1.f } },
        { { -250,   250 },  { 0.f, 0.f } },
        
        { {  250,  -250 },  { 1.f, 1.f } },
        { { -250,   250 },  { 0.f, 0.f } },
        { {  250,   250 },  { 1.f, 0.f } },
    };
    
    // Create a vertex buffer, and initialize it with the quadVertices array
    self.vertices = [[EHRenderEngine sharedInstance].device newBufferWithBytes:quadVertices
                                     length:sizeof(quadVertices)
                                    options:MTLResourceStorageModeShared];
    
    // Calculate the number of vertices by dividing the byte length by the size of each vertex
    self.verticesCount = sizeof(quadVertices) / sizeof(EHVertex);
}

-(void)renderInContext:(EHRenderContext *)context
{
    id<MTLCommandBuffer> commandBuffer = [context.commandQueue commandBuffer];
    self.renderPassDesc.colorAttachments[0].texture = context.canvas.texture;
    id<MTLRenderCommandEncoder> renderEncoder =
    [commandBuffer renderCommandEncoderWithDescriptor:self.renderPassDesc];
    
    // Set the region of the drawable to draw into.
    [renderEncoder setViewport:(MTLViewport){0.0, 0.0, self.size.width, self.size.height, -1.0, 1.0 }];
    
    [renderEncoder setRenderPipelineState:self.pipelineState];
    
    [renderEncoder setVertexBuffer:_vertices
                            offset:0
                           atIndex:EHVertexInputIndexVertices];
    
    vector_uint2 size = {
        self.size.width,
        self.size.height
    };
    [renderEncoder setVertexBytes:&size
                           length:sizeof(size)
                          atIndex:EHVertexInputIndexViewportSize];
    
    // Set the texture object.  The AAPLTextureIndexBaseColor enum value corresponds
    ///  to the 'colorMap' argument in the 'samplingShader' function because its
    //   texture attribute qualifier also uses AAPLTextureIndexBaseColor for its index.
    [renderEncoder setFragmentTexture:self.texture
                              atIndex:EHTextureIndexBaseColor];
    
    // Draw the triangles.
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                      vertexStart:0
                      vertexCount:self.verticesCount];
    
    [renderEncoder endEncoding];
    
    // Schedule a present once the framebuffer is complete using the current drawable
    [commandBuffer presentDrawable:context.canvas];
    [commandBuffer commit];
}

@end
