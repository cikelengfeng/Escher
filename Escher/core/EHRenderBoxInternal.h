//
//  EHRenderBoxInternal.h
//  Escher
//
//  Created by 徐 东 on 2019/4/18.
//  Copyright © 2019 DXLab. All rights reserved.
//

#ifndef EHRenderBoxInternal_h
#define EHRenderBoxInternal_h
#import "EHRenderBox.h"
#import "Geometry.h"

@interface EHLayoutSizeBox ()

@property (nonatomic, assign) double width;
@property (nonatomic, assign) double height;

@end

@interface EHLayoutSizeBoxConstraints ()

@property (nonatomic, assign) double minWidth;
@property (nonatomic, assign) double maxWidth;
@property (nonatomic, assign) double minHeight;
@property (nonatomic, assign) double maxHeight;

@end

@interface EHRenderBox ()

@property (nonatomic, strong) EHLayoutSizeBox *size;
@property (nonatomic, assign) EHSize pixelSize;
@property (nonatomic, assign) BOOL dirty;
- (EHRect)dirtyPixelRectInContext:(EHRenderContext *)context;

@end

#endif /* EHRenderBoxInternal_h */
