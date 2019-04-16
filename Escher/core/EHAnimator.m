//
//  EHAnimator.m
//  Escher
//
//  Created by 徐 东 on 2019/4/16.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import "EHAnimator.h"

@interface EHAnimator ()

@property (nonatomic, assign) NSUInteger frameIndex;
@property (nonatomic, assign) NSUInteger frameCount;
@property (nonatomic, assign) EHAnimatorState state;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) NSUInteger frameRate;//default is 60
@property (nonatomic, assign) BOOL reversed;


@end

@implementation EHAnimator

- (instancetype)initWithDuration:(NSTimeInterval)duration ticker:(id<EHTicker>)ticker
{
    self = [super init];
    if (self) {
        _duration = duration;
        _frameIndex = 0;
        _state = EHAnimatorStateInitial;
        _frameRate = 60;
        _frameCount = ceil(_duration * _frameRate);
        [ticker setVsyncCallback:^{
            [self onVsync];
        }];
    }
    return self;
}

- (void)onVsync
{
    if (self.frameIndex == self.frameCount - 1 && self.state == EHAnimatorStateForwarding) {
        self.frameIndex = self.frameCount;
        self.state = EHAnimatorStateCompleted;
        return;
    }
    if (self.frameIndex < self.frameCount - 1 && self.state == EHAnimatorStateForwarding) {
        self.frameIndex += 1;
        return;
    }
    if (self.frameIndex > 1 && self.state == EHAnimatorStateReversing) {
        self.frameIndex -= 1;
        return;
    }
    if (self.frameIndex == 1 && self.state == EHAnimatorStateReversing) {
        self.frameIndex = 0;
        self.state = EHAnimatorStateInitial;
        return;
    }
}

- (void)start
{
    if (self.frameIndex == 0 && self.state == EHAnimatorStateInitial) {
        self.state = EHAnimatorStateForwarding;
        return;
    }
    if (self.frameIndex > 1 && self.state == EHAnimatorStateReversing) {
        self.state = EHAnimatorStateForwarding;
        return;
    }
    if (self.frameIndex == 1 && self.state == EHAnimatorStateReversing) {
        self.state = EHAnimatorStateForwarding;
        return;
    }
}

- (void)reset
{
    self.frameIndex = 0;
    self.state = EHAnimatorStateInitial;
}

- (void)reverse
{
    if (self.frameIndex < self.frameCount - 1 && self.state == EHAnimatorStateForwarding) {
        self.state = EHAnimatorStateReversing;
        return;
    }
    if (self.frameIndex == self.frameCount - 1 && self.state == EHAnimatorStateForwarding) {
        self.state = EHAnimatorStateReversing;
        return;
    }
    if (self.frameIndex == self.frameCount && self.state == EHAnimatorStateCompleted) {
        self.state = EHAnimatorStateReversing;
        return;
    }
}

- (void)setState:(EHAnimatorState)state
{
    _state = state;
    if (self.stateChanged) {
        self.stateChanged(_state);
    }
}

- (void)setFrameIndex:(NSUInteger)frameIndex
{
    _frameIndex = frameIndex;
    if (self.listener) {
        self.listener();
    }
}

@end
