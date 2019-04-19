//
//  EHDevice.m
//  Escher
//
//  Created by 徐 东 on 2019/4/16.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import "EHRenderEngine.h"
@import UIKit;
@import QuartzCore;

@interface EHRenderEngine ()

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) CADisplayLink *ticker;

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
    if (![self.delegate respondsToSelector:@selector(renderInQueue:)]) {
        return;
    }
    @autoreleasepool {
        [self.delegate renderInQueue:self.commandQueue];
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
