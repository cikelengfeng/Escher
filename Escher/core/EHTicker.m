//
//  EHSimpleTicker.m
//  Escher
//
//  Created by 徐 东 on 2019/4/18.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import "EHTicker.h"
#import <QuartzCore/QuartzCore.h>

typedef NS_ENUM(NSUInteger, EHSimpleTickerState) {
    EHSimpleTickerStateInitial,
    EHSimpleTickerStateRunning,
    EHSimpleTickerStatePaused,
    EHSimpleTickerStateCompleted,
};

@interface EHSimpleTicker ()

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) EHSimpleTickerState state;

@end

@implementation EHSimpleTicker
@synthesize vsyncCallback;

- (void)start
{
    self.state = EHSimpleTickerStateRunning;
}

- (void)pause
{
    if (self.state == EHSimpleTickerStateRunning) {
        self.state = EHSimpleTickerStatePaused;
        return;
    }
}

- (void)stop
{
    self.state = EHSimpleTickerStateCompleted;
}

- (void)setState:(EHSimpleTickerState)state
{
    _state = state;
    if (_state == EHSimpleTickerStateRunning && !self.displayLink) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(vsync)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
    if (_state == EHSimpleTickerStatePaused) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
    if (_state == EHSimpleTickerStateCompleted && self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

- (void)vsync
{
    if (self.vsyncCallback) {
        self.vsyncCallback();
    }
}

@end
