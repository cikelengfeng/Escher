//
//  EHRenderBox.m
//  Escher
//
//  Created by 徐 东 on 2019/4/18.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import "EHRenderBox.h"
#import "EHRenderBoxInternal.h"

@implementation EHLayoutSizeBox

- (instancetype)initWithWidth:(double)width height:(double)height
{
    self = [super init];
    if (self) {
        _width = width;
        _height = height;
    }
    return self;
}

@end

@implementation EHLayoutSizeBoxConstraints

- (BOOL)isSizeSatisfied:(id<EHLayoutSize>)layoutSize
{
    EHLayoutSizeBox *size = layoutSize;
    if (![size isKindOfClass:[EHLayoutSizeBox class]]) {
        return NO;
    }
    return size.width >= self.minWidth
    && size.width <= self.maxWidth
    && size.height >= self.minHeight
    && size.height <= self.maxHeight;
}


@end

@implementation EHRenderBox

@synthesize parentData;

- (void)layout
{
    
}

- (void)renderInContext:(EHRenderContext *)context
{
    
}


@end
