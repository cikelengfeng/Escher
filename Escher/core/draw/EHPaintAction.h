//
//  EHPaintAction.h
//  Escher
//
//  Created by 徐 东 on 2019/4/19.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EHCanvas.h"

NS_ASSUME_NONNULL_BEGIN

@interface EHPaintAction : NSObject

@property (nonatomic, strong, readonly) EHCanvas *canvas;

- (instancetype)initWithCanvas:(EHCanvas *)canvas;

@end

@interface EHPaintLineAction : EHPaintAction

@end

@interface EHPaintArcAction : EHPaintAction

@end

@interface EHPaintImageAction : EHPaintAction

@end

@interface EHPaintTextAction : EHPaintAction

@end

NS_ASSUME_NONNULL_END
