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
#import <ImageIO/ImageIO.h>

@import Metal;

#import "EHImageRenderBox.h"
#import "EHSingleChildRenderBox.h"

@interface MetalViewController () <EHRenderEngineDelegate>

@property (nonatomic, strong) CAMetalLayer *metalLayer;

@property (nonatomic, strong) id<EHRenderObject> rootRenderObject;

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

- (void)performRenderInContext:(EHRenderContext *)context
{
    [self.rootRenderObject renderInContext:context];
}

- (void)renderInQueue:(id<MTLCommandQueue>)commandQueue
{
    id<CAMetalDrawable> drawable = [self.metalLayer nextDrawable];
    if (!drawable) {
        return;
    }
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    if (!commandBuffer) {
        return;
    }
    EHRect rect = (EHRect) {self.metalLayer.bounds.origin.x, self.metalLayer.bounds.origin.y, self.metalLayer.bounds.size.width, self.metalLayer.bounds.size.height};
    MTLRenderPassDescriptor *renderPass = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPass.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1);
    renderPass.colorAttachments[0].texture = drawable.texture;
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPass];
    EHRenderContext *context = [[EHRenderContext alloc] initWithCanvas:drawable encoder:encoder targetRect:rect];
    [self performRenderInContext:context];
    
    [encoder endEncoding];
    
    [commandBuffer presentDrawable:context.canvas];
    [commandBuffer commit];
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
