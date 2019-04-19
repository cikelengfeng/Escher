//
//  EHSingleChildRenderBox.h
//  Escher
//
//  Created by 徐 东 on 2019/4/18.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import "EHRenderBox.h"

NS_ASSUME_NONNULL_BEGIN

@interface EHSingleChildRenderBox : EHRenderBox

@property (nonatomic, strong) EHRenderBox *child;

//in point, in this render box coordination
@property (nonatomic, assign) EHPoint offset;

- (instancetype)initWithSize:(EHLayoutSizeBox *)size;

- (void)setTriangle;

@end

NS_ASSUME_NONNULL_END
