//
//  EHCanvas.h
//  Escher
//
//  Created by 徐 东 on 2019/4/19.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Geometry.h"

NS_ASSUME_NONNULL_BEGIN

@interface EHCanvas : NSObject

//in points, in window coordinator
@property (nonatomic, assign) EHRect *frame;

+ (void)pushCanvas;
+ (void)popCanvas;
//return the topmost canvas
+ (EHCanvas *)getCanvas;

@end

NS_ASSUME_NONNULL_END
