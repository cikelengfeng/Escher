//
//  EHImageRenderBox.h
//  Escher
//
//  Created by 徐 东 on 2019/4/18.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import "EHRenderBox.h"
#import <ImageIO/ImageIO.h>

NS_ASSUME_NONNULL_BEGIN

@interface EHImageRenderBox : EHRenderBox

@property (nonatomic, assign) CGImageRef image;

- (instancetype)initWithSize:(EHLayoutSizeBox *)size;

@end

NS_ASSUME_NONNULL_END
