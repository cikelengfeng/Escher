//
//  EHRenderObject.h
//  Escher
//
//  Created by 徐 东 on 2019/4/17.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
@import Metal;

#import "Geometry.h"
#import "EHRenderEngine.h"

NS_ASSUME_NONNULL_BEGIN

@protocol EHLayoutSize <NSObject>

@end

@protocol EHLayoutPosition <NSObject>

@end

@protocol EHLayoutSizeConstraints <NSObject>

- (BOOL)isSizeSatisfied:(id<EHLayoutSize>)layoutSize;

@end

@protocol EHRenderObject <NSObject>

@property (nonatomic, strong) id<EHLayoutSizeConstraints> constraints;
@property (nonatomic, strong, readonly) id<EHLayoutSize> size;
@property (nonatomic, strong) id parentData;

- (void)layout;
- (void)renderInContext:(EHRenderContext *)context;

@end

NS_ASSUME_NONNULL_END
