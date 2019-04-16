//
//  EHInterpolator.m
//  Escher
//
//  Created by 徐 东 on 2019/4/16.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import "EHInterpolator.h"

@interface EHInterpolator ()

@property (nonatomic, strong) id begin;
@property (nonatomic, strong) id end;

@end

@implementation EHInterpolator

- (instancetype)initWithBegin:(id)begin end:(id)end
{
    self = [super init];
    if (self) {
        _begin = begin;
        _end = end;
    }
    return self;
}

- (id)evaluate:(EHAnimator *)animator
{
    return nil;
}

@end

@interface EHNumberInterpolator ()

@end

@implementation EHNumberInterpolator

- (NSNumber *)evaluate:(EHAnimator *)animator
{
    double step = ([self.end doubleValue] - [self.begin doubleValue]) / animator.frameCount;
    NSNumber *ret = @([self.begin doubleValue] + step * animator.frameIndex);
//    NSLog(@"interpolator %@, step: %lf, frameIndex: %ld", ret, step, animator.frameIndex);
    return ret;
}

@end
