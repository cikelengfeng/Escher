//
//  EHRenderObject.m
//  Escher
//
//  Created by 徐 东 on 2019/4/17.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import "EHRenderObject.h"

@implementation EHRenderContext

- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)queue
{
    self = [super init];
    if (self) {
        _commandQueue = queue;
    }
    return self;
}

@end
