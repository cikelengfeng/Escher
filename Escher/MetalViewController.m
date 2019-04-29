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
#import "EHTextRenderBox.h"

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
    metalLayer.frame = self.view.layer.frame;
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
    
    EHTextRenderBox *textView = [[EHTextRenderBox alloc] init];
    textView.size = [[EHLayoutSizeBox alloc] initWithWidth:200 height:100];
    textView.text = @"Hello Escher! 你好 埃舍尔！";
    textView.textColor = EHColorMake(123, 255, 0, 255);
    
    EHSingleChildRenderBox *testContainer = [[EHSingleChildRenderBox alloc] initWithSize:[[EHLayoutSizeBox alloc] initWithWidth:textView.size.width height:textView.size.height]];
    testContainer.child = textView;
    testContainer.backgroundColor = EHColorMake(0, 123, 123, 255);
    
    EHSingleChildRenderBox *container = [[EHSingleChildRenderBox alloc] initWithSize:[[EHLayoutSizeBox alloc] initWithWidth:CGRectGetWidth(metalLayer.bounds) height:CGRectGetHeight(metalLayer.bounds)]];
    container.child = testContainer;
    container.offset = (EHPoint) {0, 100};
    container.backgroundColor = EHColorMake(0, 255, 255, 255);
    
    self.rootRenderObject = container;
    [EHRenderEngine sharedInstance].layer = self.metalLayer;
    [[EHRenderEngine sharedInstance] start];
    [[EHRenderEngine sharedInstance] render];
    
    EHSimpleTicker *ticker = [[EHSimpleTicker alloc] init];
    EHAnimator *animator = [[EHAnimator alloc] initWithDuration:5 ticker:ticker];
    EHNumberInterpolator *interpolator = [[EHNumberInterpolator alloc] initWithBegin:@(0) end:@(100)];
//    EHNumberInterpolator *colorInterpolator = [[EHNumberInterpolator alloc] initWithBegin:@(0) end:@(255)];
    __weak typeof(animator) weakAnimator = animator;
    [animator setListener:^{
        EHPoint offset = {container.offset.x, 100 + [interpolator evaluate:weakAnimator].doubleValue};
        container.offset = offset;
        container.alpha = [interpolator evaluate:weakAnimator].doubleValue / 100.0;
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
    self.rootRenderObject.dirty = NO;
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
