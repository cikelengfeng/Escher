//
//  EHTextRenderBox.m
//  Escher
//
//  Created by 徐 东 on 2019/4/23.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import "EHTextRenderBox.h"
#import "EHRenderBoxInternal.h"
#import "EHRenderEngine.h"
#import "ShaderTypes.h"
#import "ft2build.h"
#import FT_FREETYPE_H

@interface EHTextRenderBox ()

@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
//@property (nonatomic, strong) id<MTLTexture> texture;
//@property (nonatomic, strong) id<MTLBuffer> vertices;
//@property (nonatomic, assign) int verticesCount;
@property (nonatomic, assign) FT_Face face;

@end

@implementation EHTextRenderBox

- (instancetype)init
{
    self = [super init];
    if (self) {
        id<MTLLibrary> defaultLibrary = [[EHRenderEngine sharedInstance].device newDefaultLibrary];
        id<MTLFunction> vertexProgram = [defaultLibrary newFunctionWithName:@"vertexShader"];
        id<MTLFunction> fragmentProgram = [defaultLibrary newFunctionWithName:@"samplingGray8ToBGRShader"];
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
        
        _textColor = EHColorMake(255, 0, 0, 255);
        
        FT_Library ft_lib = {NULL};
        if (FT_Init_FreeType(&ft_lib) != 0) {
            return nil;
        }
        FT_Face face = {NULL};
        NSURL *fontURL = [[NSBundle mainBundle] URLForResource:@"HelveticaNeue" withExtension:@"ttc"];
        const char *cPath = [fontURL.path UTF8String];
        FT_Error fte = FT_New_Face(ft_lib, cPath, 0, &face);
        if (fte != 0) {
            NSLog(@"%s", FT_Error_String(fte));
            return nil;
        }
        _face = face;
    }
    return self;
}

- (void)setText:(NSString *)text
{
    if ([_text isEqualToString:text]) {
        return;
    }
    _text = [text copy];
    self.dirty = YES;
}

- (void)renderGlyph:(id<MTLTexture>)texture vertices:(id<MTLBuffer>)vertices count:(int)count inContext:(EHRenderContext *)context
{
    id<MTLRenderCommandEncoder> renderEncoder = context.encoder;
    
    // Set the region of the drawable to draw into.
    [renderEncoder setViewport:(MTLViewport){context.targetRectInPixel.origin.x, context.targetRectInPixel.origin.y, self.pixelSize.width, self.pixelSize.height, -1.0, 1.0 }];
    
    [renderEncoder setRenderPipelineState:self.pipelineState];
    [renderEncoder setVertexBuffer:vertices
                            offset:0
                           atIndex:EHVertexInputIndexVertices];
    
    vector_uint2 size = {
        self.pixelSize.width,
        self.pixelSize.height
    };
    [renderEncoder setVertexBytes:&size
                           length:sizeof(size)
                          atIndex:EHVertexInputIndexViewportSize];
    [renderEncoder setFragmentTexture:texture atIndex:EHTextureIndexBaseColor];
    const float textColor[] = {self.textColor.red / 255.f, self.textColor.green / 255.f, self.textColor.blue / 255.f, self.textColor.alpha / 255.f};
    [renderEncoder setFragmentBytes:&textColor length:sizeof(textColor) atIndex:EHFragmentInputIndexColor];
    // Draw the triangles.
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                      vertexStart:0
                      vertexCount:count];
}

-(void)renderInContext:(EHRenderContext *)context
{
    if (!self.dirty) {
        return;
    }
    
    const FT_GlyphSlot g = self.face->glyph;
    const char *utf8str = [_text UTF8String];
    const unsigned long length = strlen(utf8str);
    double x = context.targetRect.origin.x;
    double y = context.targetRect.origin.y;
    FT_Set_Char_Size(self.face, 0, 0, 2274, 3408);
    
    for (int i = 0; i < length; i++) {
        char c = utf8str[i];
        if (FT_Load_Char(self.face, c, FT_LOAD_RENDER)) {
            continue;
        }
        unsigned int glyphWidth = g->bitmap.width;
        unsigned int glyphHeight = g->bitmap.rows;
        MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR8Unorm width:glyphWidth height:glyphHeight mipmapped:NO];
        desc.usage = MTLTextureUsageShaderRead;
        id<MTLTexture> texture = [[EHRenderEngine sharedInstance].device newTextureWithDescriptor:desc];
        MTLRegion region = {
            { 0, 0, 0 },                   // MTLOrigin
            {desc.width, desc.height, 1} // MTLSize
        };
        const UInt8 *buffer = g->bitmap.buffer;
        [texture replaceRegion:region mipmapLevel:0 withBytes:buffer bytesPerRow:glyphWidth];
        
        const float width = g->bitmap.width;
        const float height = g->bitmap.rows;
        
        x += width;
        
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
        id<MTLBuffer> vertices = [[EHRenderEngine sharedInstance].device newBufferWithBytes:quadVertices
                                                                                     length:sizeof(quadVertices)
                                                                                    options:MTLResourceStorageModeShared];
        // Calculate the number of vertices by dividing the byte length by the size of each vertex
        int verticesCount = sizeof(quadVertices) / sizeof(EHTextureVertex);
        EHRect newRect = (EHRect) {x, y, context.targetRect.size.width, context.targetRect.size.height};
        EHRenderContext *newContext = [context copyWithTargetRect:newRect];
        [self renderGlyph:texture vertices:vertices count:verticesCount inContext:newContext];
    }
}

@end
