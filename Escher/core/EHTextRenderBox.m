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

@interface EHGlyphCacheEntry : NSObject

@property (nonatomic, assign) FT_F26Dot6 charCode;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, id<MTLTexture>> *map;

@end

@implementation EHGlyphCacheEntry

- (instancetype)init
{
    self = [super init];
    if (self) {
        _map = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setTexture:(id<MTLTexture>)texture forSize:(FT_F26Dot6)size
{
    self.map[@(size)] = texture;
}

- (id<MTLTexture>)textureForSize:(FT_F26Dot6)size
{
    return self.map[@(size)];
}

@end

@interface EHGlyphCache : NSObject

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, EHGlyphCacheEntry *> *map;

- (id<MTLTexture>)textureForChar:(char)c size:(FT_F26Dot6)size;

@end

@implementation EHGlyphCache

- (instancetype)init
{
    self = [super init];
    if (self) {
        _map = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addTexture:(id<MTLTexture>)txtr forChar:(char)c size:(FT_F26Dot6)size
{
    EHGlyphCacheEntry *entry = self.map[@(c)];
    if (!entry) {
        entry = [[EHGlyphCacheEntry alloc] init];
        self.map[@(c)] = entry;
    }
    [entry setTexture:txtr forSize:size];
}

- (id<MTLTexture>)textureForChar:(char)c size:(FT_F26Dot6)size
{
    EHGlyphCacheEntry *entry = self.map[@(c)];
    if (!entry) {
        return nil;
    }
    return [entry textureForSize:size];
}

@end

@interface EHTextRenderBox ()

@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, assign) FT_Face face;

@property (nonatomic, strong) EHGlyphCache *cache;

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
        
        _textColor = EHColorMake(0, 0, 0, 255);
        _fontSize = 12;
        
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
        _cache = [[EHGlyphCache alloc] init];
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
    const FT_GlyphSlot g = self.face->glyph;
    const char *utf8str = [_text UTF8String];
    const unsigned long length = strlen(utf8str);
    double x = 0;
    double y = 0;
    double baseline = 0;
    double scale = [EHRenderEngine sharedInstance].nativeScale;
    FT_UInt fontSize = (unsigned int)(self.fontSize * scale);
    FT_Set_Pixel_Sizes(self.face, fontSize, 0);
    
    for (int i = 0; i < length; i++) {
        char c = utf8str[i];
        if (FT_Load_Char(self.face, c, FT_LOAD_RENDER)) {
            continue;
        }
        float glyphWidth = g->bitmap.width;
        float glyphHeight = g->bitmap.rows;
        FT_Vector advance = g->advance;
        if (glyphWidth == 0) {
            x += advance.x >> 6;
            continue;
        }
        MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR8Unorm width:glyphWidth height:glyphHeight mipmapped:NO];
        desc.usage = MTLTextureUsageShaderRead;
        id<MTLTexture> texture = [self.cache textureForChar:c size:fontSize];
        if (!texture) {
            texture = [[EHRenderEngine sharedInstance].device newTextureWithDescriptor:desc];
            [self.cache addTexture:texture forChar:c size:fontSize];
        }
        
        MTLRegion region = {
            { 0, 0, 0 },                   // MTLOrigin
            {desc.width, desc.height, 1} // MTLSize
        };
        const UInt8 *buffer = g->bitmap.buffer;
        [texture replaceRegion:region mipmapLevel:0 withBytes:buffer bytesPerRow:glyphWidth];
        
        x += g->bitmap_left >> 6;
        double penY = y + (g->bitmap_top >> 6);
        double vw = self.pixelSize.width;
        double vh = self.pixelSize.height;
        
        EHTextureVertex quadVertices[] =
        {
            // Pixel positions, Texture coordinates
            { {  x + glyphWidth - vw / 2,  vh / 2 - (penY + glyphHeight) },  { 1.f, 1.f } },//右下
            { {  x - vw / 2             ,  vh / 2 - (penY + glyphHeight) },  { 0.f, 1.f } },//左下
            { {  x - vw / 2             ,  vh / 2 - penY },  { 0.f, 0.f } },//左上
            
            { {  x + glyphWidth - vw / 2,  vh / 2 - (penY + glyphHeight) },  { 1.f, 1.f } },//右下
            { {  x - vw / 2             ,  vh / 2 - penY },  { 0.f, 0.f } },//左上
            { {  x + glyphWidth - vw / 2,  vh / 2 - penY },  { 1.f, 0.f } },//右上
        };
        
        // Create a vertex buffer, and initialize it with the quadVertices array
        id<MTLBuffer> vertices = [[EHRenderEngine sharedInstance].device newBufferWithBytes:quadVertices
                                                                                     length:sizeof(quadVertices)
                                                                                    options:MTLResourceStorageModeShared];
        // Calculate the number of vertices by dividing the byte length by the size of each vertex
        int verticesCount = sizeof(quadVertices) / sizeof(EHTextureVertex);
        [self renderGlyph:texture vertices:vertices count:verticesCount inContext:context];
        
        x += g->advance.x >> 6;
    }
}

@end
