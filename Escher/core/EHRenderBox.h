//
//  EHRenderBox.h
//  Escher
//
//  Created by 徐 东 on 2019/4/18.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EHRenderObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface EHLayoutSizeBoxConstraints : NSObject<EHLayoutSizeConstraints>

@end

@interface EHLayoutSizeBox : NSObject<EHLayoutSize>

- (instancetype)initWithWidth:(double)width height:(double)height;

@end

@interface EHRenderBox : NSObject<EHRenderObject>

@property (nonatomic, strong) EHLayoutSizeBoxConstraints *constraints;
@property (nonatomic, strong, readonly) EHLayoutSizeBox *size;

@end

NS_ASSUME_NONNULL_END
