//
//  EHDevice.m
//  Escher
//
//  Created by 徐 东 on 2019/4/16.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import "EHDevice.h"
@import QuartzCore;

@interface EHDevice ()

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) CADisplayLink *ticker;

@property (nonatomic, assign) BOOL ready;

@end

@implementation EHDevice

- (instancetype)init
{
    self = [super init];
    if (self) {
        _device = MTLCreateSystemDefaultDevice();
        
        _commandQueue = [_device newCommandQueue];
        
        _ticker = [CADisplayLink displayLinkWithTarget:self selector:@selector(vsync)];
        [_ticker addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        _ready = NO;
    }
    return self;
}

- (void)vsync {
    if (!self.ready) {
        return;
    }
    if (![self.delegate respondsToSelector:@selector(vsync:)]) {
        return;
    }
    @autoreleasepool {
        [self.delegate vsync:self.commandQueue];
    }
}

- (void)start
{
    self.ready = YES;
}

- (void)pause
{
    self.ready = NO;
}

@end
