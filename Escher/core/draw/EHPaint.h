//
//  EHPaint.h
//  Escher
//
//  Created by 徐 东 on 2019/4/18.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>
#import "Geometry.h"

NS_ASSUME_NONNULL_BEGIN

@interface EHPaint : NSObject

- (void)setStrokeWidth:(double)width;
- (void)moveToPoint:(EHPoint)point;
- (void)strokeToPoint:(EHPoint)point;
- (void)drawImage:(CGImageRef)image;

@end

NS_ASSUME_NONNULL_END
