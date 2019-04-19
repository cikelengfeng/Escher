//
//  EHSimpleTicker.h
//  Escher
//
//  Created by 徐 东 on 2019/4/18.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EHTicker.h"

NS_ASSUME_NONNULL_BEGIN

@protocol EHTicker <NSObject>

@property (nonatomic, copy) void(^vsyncCallback)(void);

- (void)start;
- (void)pause;
- (void)stop;

@end

@interface EHSimpleTicker : NSObject<EHTicker>

@end

NS_ASSUME_NONNULL_END
