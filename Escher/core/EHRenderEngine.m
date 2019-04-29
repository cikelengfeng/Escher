//
//  EHDevice.m
//  Escher
//
//  Created by 徐 东 on 2019/4/16.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import "EHRenderEngine.h"
@import UIKit;


@interface EHRenderContext ()

@property (nonatomic, assign) EHRect targetRect;
@property (nonatomic, strong) id<CAMetalDrawable> canvas;
@property (nonatomic, strong) id<MTLRenderCommandEncoder> encoder;
@property (nonatomic, strong) id<MTLCommandBuffer> commandBuffer;

@end

@implementation EHRenderContext

@dynamic targetRectInPixel;

- (instancetype)initWithCanvas:(id<CAMetalDrawable>)canvas encoder:(nonnull id<MTLRenderCommandEncoder>)encoder targetRect:(EHRect)targetRect commandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer
{
    self = [super init];
    if (self) {
        _canvas = canvas;
        _encoder = encoder;
        _targetRect = targetRect;
        _commandBuffer = commandBuffer;
    }
    return self;
}

- (double)nativeScale
{
    return UIScreen.mainScreen.nativeScale;
}

- (EHRect)targetRectInPixel
{
    return (EHRect) {self.targetRect.origin.x * self.nativeScale, self.targetRect.origin.y * self.nativeScale, self.targetRect.size.width * self.nativeScale, self.targetRect.size.height * self.nativeScale};
}

- (id)copy
{
    EHRenderContext *copy = [[EHRenderContext alloc] initWithCanvas:self.canvas encoder:self.encoder targetRect:self.targetRect commandBuffer:self.commandBuffer];
    return copy;
}

- (instancetype)copyWithTargetRect:(EHRect)targetRect
{
    EHRenderContext *copy = [[EHRenderContext alloc] initWithCanvas:self.canvas encoder:self.encoder targetRect:targetRect commandBuffer:self.commandBuffer];
    return copy;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [self copy];
}

@end

@interface EHRenderEngine ()

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) CADisplayLink *ticker;
@property (nonatomic, strong) dispatch_semaphore_t frameBoundary;

@property (nonatomic, assign) BOOL ready;
@property (nonatomic, assign) double nativeScale;

@end

@implementation EHRenderEngine

static EHRenderEngine *singleton;

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc]init];
    });
    return singleton;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _device = MTLCreateSystemDefaultDevice();
        
        _commandQueue = [_device newCommandQueue];
        
//        _ticker = [CADisplayLink displayLinkWithTarget:self selector:@selector(vsync)];
//        [_ticker addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        _ready = NO;
        _nativeScale = UIScreen.mainScreen.nativeScale;
        _frameBoundary = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)vsync {
    [self render];
}

- (void)render
{
    if (!self.ready) {
        return;
    }
    if (!self.layer) {
        return;
    }
    if (![self.delegate respondsToSelector:@selector(renderInContext:)]) {
        return;
    }
    id<CAMetalDrawable> drawable = [self.layer nextDrawable];
    if (!drawable) {
        return;
    }
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    if (!commandBuffer) {
        return;
    }
    
    dispatch_semaphore_wait(self.frameBoundary, DISPATCH_TIME_FOREVER);
    
    __weak dispatch_semaphore_t semaphore = self.frameBoundary;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull cb) {
        dispatch_semaphore_signal(semaphore);
    }];
    
    EHRect rect = (EHRect) {self.layer.bounds.origin.x, self.layer.bounds.origin.y, self.layer.bounds.size.width, self.layer.bounds.size.height};
    MTLRenderPassDescriptor *renderPass = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPass.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1);
    renderPass.colorAttachments[0].texture = drawable.texture;
    renderPass.colorAttachments[0].storeAction = MTLStoreActionStore;
    
//    MTLRenderPassStencilAttachmentDescriptor *stencilAttachment = [[MTLRenderPassStencilAttachmentDescriptor alloc] init];
//    stencilAttachment.texture = drawable.texture;
//    stencilAttachment.clearStencil = 0;
//    stencilAttachment.loadAction = MTLLoadActionClear;
//    stencilAttachment.storeAction = MTLStoreActionStore;
//    
//    renderPass.stencilAttachment = stencilAttachment;
    
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPass];
    EHRenderContext *context = [[EHRenderContext alloc] initWithCanvas:drawable encoder:encoder targetRect:rect commandBuffer:commandBuffer];
    
    @autoreleasepool {
        [self.delegate renderInContext:context];
    }
    
    [encoder endEncoding];
    
    [commandBuffer presentDrawable:context.canvas];
    [commandBuffer commit];
    
}

- (void)start
{
    self.ready = YES;
}

- (void)pause
{
    self.ready = NO;
}

- (void)setLayer:(CAMetalLayer *)layer
{
    _layer = layer;
    _layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    _layer.framebufferOnly = YES;
    _layer.contentsScale = self.nativeScale;
}

@end
