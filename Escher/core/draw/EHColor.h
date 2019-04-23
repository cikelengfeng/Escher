//
//  EHColor.h
//  Escher
//
//  Created by 徐 东 on 2019/4/23.
//  Copyright © 2019 DXLab. All rights reserved.
//

#ifndef EHColor_H
#define EHColor_H

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

struct EHColor {
    NSUInteger red;
    NSUInteger green;
    NSUInteger blue;
    NSUInteger alpha;
};
typedef struct EHColor EHColor;

EHColor EHColorMake(NSUInteger r, NSUInteger g, NSUInteger b, NSUInteger a);
BOOL EHColorEqual(EHColor c1, EHColor c2);

NS_ASSUME_NONNULL_END

#endif
