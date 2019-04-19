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
@property (nonatomic, assign, readonly) NSUInteger maxFrameIndex;
@property (nonatomic, assign) EHAnimatorState state;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) NSUInteger frameRate;//default is 60
@property (nonatomic, assign) BOOL reversed;
@property (nonatomic, strong) id<EHTicker> ticker;


@end

@implementation EHAnimator

@dynamic maxFrameIndex;

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
        _ticker = ticker;
    }
    return self;
}

- (void)onVsync
{
    if (self.frameIndex == self.maxFrameIndex - 1 && self.state == EHAnimatorStateForwarding) {
        [self setFrameIndexAndNotifyListener:self.maxFrameIndex];
        self.state = EHAnimatorStateCompleted;
        return;
    }
    if (self.frameIndex < self.maxFrameIndex - 1 && self.state == EHAnimatorStateForwarding) {
        [self setFrameIndexAndNotifyListener:self.frameIndex + 1];
        return;
    }
    if (self.frameIndex > 1 && self.state == EHAnimatorStateReversing) {
        [self setFrameIndexAndNotifyListener:self.frameIndex - 1];
        return;
    }
    if (self.frameIndex == 1 && self.state == EHAnimatorStateReversing) {
        [self setFrameIndexAndNotifyListener:0];
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
    if (self.frameIndex > 0 && self.frameIndex < self.maxFrameIndex - 1 && self.state == EHAnimatorStatePaused) {
        self.state = EHAnimatorStateForwarding;
        return;
    }
}

- (void)reset
{
    [self setFrameIndexAndNotifyListener:0];
    self.state = EHAnimatorStateInitial;
}

- (void)reverse
{
    if (self.frameIndex < self.maxFrameIndex - 1 && self.state == EHAnimatorStateForwarding) {
        self.state = EHAnimatorStateReversing;
        return;
    }
    if (self.frameIndex == self.maxFrameIndex - 1 && self.state == EHAnimatorStateForwarding) {
        self.state = EHAnimatorStateReversing;
        return;
    }
    if (self.frameIndex == self.maxFrameIndex && self.state == EHAnimatorStateCompleted) {
        self.state = EHAnimatorStateReversing;
        return;
    }
    if (self.frameIndex > 0 && self.frameIndex < self.maxFrameIndex - 1 && self.state == EHAnimatorStatePaused) {
        self.state = EHAnimatorStateReversing;
        return;
    }
}

- (void)pause
{
    if (self.frameIndex < self.maxFrameIndex - 1 && self.state == EHAnimatorStateForwarding) {
        self.state = EHAnimatorStatePaused;
        return;
    }
    if (self.frameIndex == self.maxFrameIndex - 1 && self.state == EHAnimatorStateForwarding) {
        self.state = EHAnimatorStatePaused;
        return;
    }
    if (self.frameIndex > 1 && self.state == EHAnimatorStateReversing) {
        self.state = EHAnimatorStatePaused;
        return;
    }
    if (self.frameIndex == 1 && self.state == EHAnimatorStateReversing) {
        self.state = EHAnimatorStatePaused;
        return;
    }
}

- (void)setOffsetIndex:(NSUInteger)newFrameIndex
{
    if (self.frameIndex < self.maxFrameIndex - 1 && self.state == EHAnimatorStateForwarding) {
        self.frameIndex = newFrameIndex;
        return;
    }
    if (self.frameIndex == self.maxFrameIndex - 1 && self.state == EHAnimatorStateForwarding) {
        self.frameIndex = newFrameIndex;
        return;
    }
    if (self.frameIndex > 1 && self.state == EHAnimatorStateReversing) {
        self.frameIndex = newFrameIndex;
        return;
    }
    if (self.frameIndex == 1 && self.state == EHAnimatorStateReversing) {
        self.frameIndex = newFrameIndex;
        return;
    }
    if (self.frameIndex > 0 && self.frameIndex < self.maxFrameIndex && self.state == EHAnimatorStatePaused) {
        self.frameIndex = newFrameIndex;
        return;
    }
}

- (void)setOffsetTo:(NSTimeInterval)to
{
    if (to < 0) {
        return;
    }
    if (to > self.duration) {
        return;
    }
    NSUInteger newFrameIndex = to * self.frameRate;
    newFrameIndex = MAX(MIN(self.maxFrameIndex - 1, newFrameIndex), 1);
    [self setOffsetIndex:newFrameIndex];
}

- (void)setOffsetBy:(NSTimeInterval)by
{
    if (ABS(by) > self.duration) {
        return;
    }
    NSInteger byIndex = by * self.frameRate;
    byIndex = MAX((NSInteger)-self.frameIndex, byIndex);
    NSUInteger newFrameIndex = self.frameIndex + byIndex;
    newFrameIndex = MAX(MIN(self.maxFrameIndex - 1, newFrameIndex), 1);
    [self setOffsetIndex:newFrameIndex];
}

- (void)setState:(EHAnimatorState)state
{
    _state = state;
    if (_state == EHAnimatorStateForwarding
        || _state == EHAnimatorStateReversing) {
        [self.ticker start];
    } else if (_state == EHAnimatorStatePaused) {
        [self.ticker pause];
    } else if (_state == EHAnimatorStateInitial
               || _state == EHAnimatorStateCompleted
               || _state == EHAnimatorStateCancelled) {
        [self.ticker stop];
    }
    if (self.stateChanged) {
        self.stateChanged(_state);
    }
}

- (void)setFrameIndexAndNotifyListener:(NSUInteger)frameIndex
{
    self.frameIndex = frameIndex;
    if (self.listener) {
        self.listener();
    }
}

- (NSUInteger)maxFrameIndex
{
    return self.frameCount - 1;
}

@end
