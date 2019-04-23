//
//  Geometry.h
//  Escher
//
//  Created by 徐 东 on 2019/4/16.
//  Copyright © 2019 DXLab. All rights reserved.
//

#ifndef Geometry_h
#define Geometry_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

struct
EHPoint {
    double x;
    double y;
};
typedef struct EHPoint EHPoint;

struct EHSize {
    double width;
    double height;
};
typedef struct EHSize EHSize;

struct EHRect {
    EHPoint origin;
    EHSize size;
};
typedef struct EHRect EHRect;

NS_ASSUME_NONNULL_END

#endif
