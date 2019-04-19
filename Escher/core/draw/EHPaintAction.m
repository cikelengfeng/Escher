//
//  EHPaintAction.m
//  Escher
//
//  Created by 徐 东 on 2019/4/19.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import "EHPaintAction.h"

@interface EHPaintAction ()

@property (nonatomic, strong) EHCanvas *canvas;

@end

@implementation EHPaintAction

- (instancetype)initWithCanvas:(EHCanvas *)canvas
{
    self = [super init];
    if (self) {
        _canvas = canvas;
    }
    return self;
}

@end

@implementation EHPaintLineAction

@end

@implementation EHPaintArcAction

@end

@implementation EHPaintImageAction

@end

@implementation EHPaintTextAction

@end
