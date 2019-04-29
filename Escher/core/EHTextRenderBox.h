//
//  EHTextRenderBox.h
//  Escher
//
//  Created by 徐 东 on 2019/4/23.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import "EHRenderBox.h"
#import "EHColor.h"

NS_ASSUME_NONNULL_BEGIN

@interface EHTextRenderBox : EHRenderBox

@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign) EHColor textColor;
@property (nonatomic, assign) double fontSize;

@end

NS_ASSUME_NONNULL_END
