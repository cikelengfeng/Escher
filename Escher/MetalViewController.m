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
#import "EHRenderObject.h"
#import "EHImageRenderBox.h"
#import <ImageIO/ImageIO.h>

@import Metal;

@interface MetalViewController () <EHRenderEngineDelegate, EHTicker>

@property (nonatomic, strong) CAMetalLayer *metalLayer;

@property (nonatomic, strong) id<EHRenderObject> rootRenderObject;
@property (nonatomic, strong) EHRenderContext *rootContext;

@end

@implementation MetalViewController

@synthesize vsyncCallback;

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
    CAMetalLayer *metalLayer = [CAMetalLayer new];
    metalLayer.device = [EHRenderEngine sharedInstance].device;
    metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    metalLayer.framebufferOnly = YES;
    metalLayer.frame = self.view.layer.frame;
    [self.view.layer addSublayer:metalLayer];
    self.metalLayer = metalLayer;
    
    EHImageRenderBox *imageView = [[EHImageRenderBox alloc] initWithSize:[[EHLayoutSizeBox alloc] initWithWidth:CGRectGetWidth(metalLayer.bounds) height:CGRectGetHeight(metalLayer.bounds)]];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"test" withExtension:@"jpg"];
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (!imageSource) {
        return;
    }
    CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    imageView.image = image;
    CFRelease(imageSource);
    CGImageRelease(image);
    self.rootRenderObject = imageView;
    
    [[EHRenderEngine sharedInstance] start];
}

- (void)performRenderInContext:(EHRenderContext *)context
{
    [self.rootRenderObject renderInContext:context];
}

- (void)vsync:(id<MTLCommandQueue>)commandQueue {
    
    if (self.vsyncCallback) {
        self.vsyncCallback();
    }
    
    id<CAMetalDrawable> drawable = [self.metalLayer nextDrawable];
    if (!drawable) {
        return;
    }
    
    if (!self.rootContext) {
        self.rootContext = [[EHRenderContext alloc] initWithCommandQueue:commandQueue];
    }
    self.rootContext.canvas = drawable;
    [self performRenderInContext:self.rootContext];
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
