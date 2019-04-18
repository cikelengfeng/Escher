//
//  EHDevice.h
//  Escher
//
//  Created by 徐 东 on 2019/4/16.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Metal;

NS_ASSUME_NONNULL_BEGIN

@protocol EHRenderEngineDelegate <NSObject>

- (void)vsync:(id<MTLCommandQueue>)commandQueue;

@end

@interface EHRenderEngine : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, weak) id<EHRenderEngineDelegate> delegate;

@property (nonatomic, strong, readonly) id<MTLDevice> device;

- (void)start;
- (void)pause;

@end

NS_ASSUME_NONNULL_END
