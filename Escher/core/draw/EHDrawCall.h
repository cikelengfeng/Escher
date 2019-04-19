//
//  EHDrawCall.h
//  Escher
//
//  Created by 徐 东 on 2019/4/18.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface EHDrawCall : NSObject

- (void)drawInCanvas:(id<CAMetalDrawable>)canvas;

@end

NS_ASSUME_NONNULL_END
