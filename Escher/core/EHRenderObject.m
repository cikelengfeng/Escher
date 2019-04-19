//
//  EHRenderObject.m
//  Escher
//
//  Created by 徐 东 on 2019/4/17.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import "EHRenderObject.h"
#import <UIKit/UIKit.h>

@interface EHRenderContext ()

@property (nonatomic, assign) EHRect targetRect;
@property (nonatomic, strong) id<CAMetalDrawable> canvas;
@property (nonatomic, strong) id<MTLRenderCommandEncoder> encoder;

@end

@implementation EHRenderContext

@dynamic targetRectInPixel;

- (instancetype)initWithCanvas:(id<CAMetalDrawable>)canvas encoder:(nonnull id<MTLRenderCommandEncoder>)encoder targetRect:(EHRect)targetRect
{
    self = [super init];
    if (self) {
        _canvas = canvas;
        _encoder = encoder;
        _targetRect = targetRect;
    }
    return self;
}

- (double)nativeScale
{
    return UIScreen.mainScreen.nativeScale;
}

- (EHRect)targetRectInPixel
{
    return (EHRect) {self.targetRect.origin.x * self.nativeScale, self.targetRect.origin.y * self.nativeScale, self.targetRect.size.width * self.nativeScale, self.targetRect.size.height * self.nativeScale};
}

@end
