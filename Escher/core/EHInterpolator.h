//
//  EHInterpolator.h
//  Escher
//
//  Created by 徐 东 on 2019/4/16.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EHAnimator.h"

NS_ASSUME_NONNULL_BEGIN

@interface EHInterpolator : NSObject

- (instancetype)initWithBegin:(id)begin end:(id)end;
- (id)evaluate:(EHAnimator *)animator;

@end

@interface EHNumberInterpolator : EHInterpolator

- (NSNumber *)evaluate:(EHAnimator *)animator;

@end

NS_ASSUME_NONNULL_END
