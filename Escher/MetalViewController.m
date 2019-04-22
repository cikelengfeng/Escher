//
//  MetalViewController.m
//  Escher
//
//  Created by 徐 东 on 2019/4/16.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import "MetalViewController.h"
#import "EHRenderEngine.h"
#import "EHAnimator.h"
#import "EHInterpolator.h"
#import "EHRenderBoxInternal.h"
#import <ImageIO/ImageIO.h>

@import Metal;

#import "EHImageRenderBox.h"
#import "EHSingleChildRenderBox.h"

@interface MetalViewController () <EHRenderEngineDelegate>

@property (nonatomic, strong) CAMetalLayer *metalLayer;

@property (nonatomic, strong) EHRenderBox *rootRenderObject;

@end

@implementation MetalViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self internalInit];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self internalInit];
    }
    return self;
}

- (void)internalInit {
    [EHRenderEngine sharedInstance].delegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    double scale = [EHRenderEngine sharedInstance].nativeScale;
    CAMetalLayer *metalLayer = [CAMetalLayer new];
    metalLayer.device = [EHRenderEngine sharedInstance].device;
    metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    metalLayer.framebufferOnly = YES;
    metalLayer.frame = self.view.layer.frame;
    metalLayer.contentsScale = scale;
    [self.view.layer addSublayer:metalLayer];
    self.metalLayer = metalLayer;
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"test" withExtension:@"jpg"];
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (!imageSource) {
        return;
    }
    CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    double imageWidth = CGImageGetWidth(image) / scale;
    double imageHeight = CGImageGetHeight(image) / scale;
    EHImageRenderBox *imageView = [[EHImageRenderBox alloc] initWithSize:[[EHLayoutSizeBox alloc] initWithWidth:imageWidth height:imageHeight]];
    imageView.image = image;
    CFRelease(imageSource);
    CGImageRelease(image);
    
    
    EHSingleChildRenderBox *container = [[EHSingleChildRenderBox alloc] initWithSize:[[EHLayoutSizeBox alloc] initWithWidth:CGRectGetWidth(metalLayer.bounds) height:CGRectGetHeight(metalLayer.bounds)]];
    container.child = imageView;
    container.offset = (EHPoint) {100, 100};
    [container setTriangle];
    
    self.rootRenderObject = container;
    [EHRenderEngine sharedInstance].layer = self.metalLayer;
    [[EHRenderEngine sharedInstance] start];
    [[EHRenderEngine sharedInstance] render];
    
    EHSimpleTicker *ticker = [[EHSimpleTicker alloc] init];
    EHAnimator *animator = [[EHAnimator alloc] initWithDuration:1 ticker:ticker];
    EHNumberInterpolator *interpolator = [[EHNumberInterpolator alloc] initWithBegin:@(0) end:@(100)];
    __weak typeof(animator) weakAnimator = animator;
    [animator setListener:^{
        EHPoint offset = {container.offset.x, 100 + [interpolator evaluate:weakAnimator].doubleValue};
        container.offset = offset;
        [[EHRenderEngine sharedInstance] render];
    }];
    [animator setStateChanged:^(EHAnimatorState state) {
        if (state == EHAnimatorStateCompleted) {
            [weakAnimator reverse];
        } else if (state == EHAnimatorStateInitial) {
            [weakAnimator start];
        }
    }];
    [animator start];
}

- (void)renderInContext:(EHRenderContext *)context
{
    [self.rootRenderObject renderInContext:context];
}





/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
