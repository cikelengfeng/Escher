//
//  EHAnimator.h
//  Escher
//
//  Created by 徐 东 on 2019/4/16.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, EHAnimatorState) {
    EHAnimatorStateInitial,
    EHAnimatorStateForwarding,
    EHAnimatorStateReversing,
    EHAnimatorStateCompleted,
    EHAnimatorStateCancelled,
    EHAnimatorStatePaused,
};

NS_ASSUME_NONNULL_BEGIN

@protocol EHTicker <NSObject>

@property (nonatomic, copy) void(^vsyncCallback)(void);

@end

@interface EHAnimator : NSObject

@property (nonatomic, assign, readonly) NSUInteger frameIndex;
@property (nonatomic, assign, readonly) NSUInteger frameCount;
@property (nonatomic, assign, readonly) EHAnimatorState state;
@property (nonatomic, copy) void(^stateChanged)(EHAnimatorState state);
@property (nonatomic, copy) void(^listener)(void);

- (instancetype)initWithDuration:(NSTimeInterval)duration ticker:(id<EHTicker>)ticker;

- (void)start;
- (void)reverse;
- (void)reset;
- (void)pause;
- (void)setOffsetTo:(NSTimeInterval)to;
- (void)setOffsetBy:(NSTimeInterval)by;

@end

NS_ASSUME_NONNULL_END
