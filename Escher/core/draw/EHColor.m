//
//  EHColor.m
//  Escher
//
//  Created by 徐 东 on 2019/4/23.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import "EHColor.h"

EHColor EHColorMake(NSUInteger r, NSUInteger g, NSUInteger b, NSUInteger a)
{
    return (EHColor){r, g, b, a};
}

BOOL EHColorEqual(EHColor c1, EHColor c2)
{
    return c1.red == c2.red
        && c1.green == c2.green
        && c1.blue == c2.blue
        && c1.alpha == c2.alpha;
}
