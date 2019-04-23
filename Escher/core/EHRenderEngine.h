//
//  EHDevice.h
//  Escher
//
//  Created by 徐 东 on 2019/4/16.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Geometry.h"
@import Metal;
@import QuartzCore;

NS_ASSUME_NONNULL_BEGIN

@interface EHRenderContext : NSObject<NSCopying>

@property (nonatomic, assign, readonly) EHRect targetRect;
@property (nonatomic, assign, readonly) EHRect targetRectInPixel;
@property (nonatomic, strong, readonly) id<CAMetalDrawable> canvas;
@property (nonatomic, strong, readonly) id<MTLRenderCommandEncoder> encoder;
@property (nonatomic, assign, readonly) double nativeScale;

- (instancetype)initWithCanvas:(id<CAMetalDrawable>)canvas encoder:(id<MTLRenderCommandEncoder>)encoder targetRect:(EHRect)targetRect;

- (instancetype)copyWithTargetRect:(EHRect)targetRect;

@end

@protocol EHRenderEngineDelegate <NSObject>

- (void)renderInContext:(EHRenderContext *)context;

@end

@interface EHRenderEngine : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, weak) id<EHRenderEngineDelegate> delegate;
@property (nonatomic, weak) CAMetalLayer *layer;

@property (nonatomic, strong, readonly) id<MTLDevice> device;
@property (nonatomic, assign, readonly) double nativeScale;

- (void)start;
- (void)render;

@end

NS_ASSUME_NONNULL_END
