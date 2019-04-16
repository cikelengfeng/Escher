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

@protocol EHDeviceDelegate <NSObject>

- (void)vsync:(id<MTLCommandQueue>)commandQueue;

@end

@interface EHDevice : NSObject

//rgb
@property (nonatomic, assign) UInt8 *buffer;
@property (nonatomic, assign) int64_t bufferSize;

@property (nonatomic, weak) id<EHDeviceDelegate> delegate;

@property (nonatomic, strong, readonly) id<MTLDevice> device;

- (void)start;
- (void)pause;

@end

NS_ASSUME_NONNULL_END
