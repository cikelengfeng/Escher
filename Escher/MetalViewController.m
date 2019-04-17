//
//  MetalViewController.m
//  Escher
//
//  Created by 徐 东 on 2019/4/16.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import "MetalViewController.h"
#import "EHDevice.h"
#import "EHAnimator.h"
#import "EHInterpolator.h"

@import Metal;

@interface MetalViewController () <EHDeviceDelegate, EHTicker>

@property (nonatomic, strong) CAMetalLayer *metalLayer;
@property (nonatomic, strong) EHDevice *device;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;

@property (nonatomic, strong) EHAnimator *animator;
@property (nonatomic, strong) EHNumberInterpolator *interpolator;

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
    _device = [[EHDevice alloc] init];
    _device.delegate = self;
    id<MTLLibrary> defaultLibrary = [_device.device newDefaultLibrary];
    id<MTLFunction> fragmentProgram = [defaultLibrary newFunctionWithName:@"basic_fragment"];
    id<MTLFunction> vertexProgram = [defaultLibrary newFunctionWithName:@"basic_vertex"];
    MTLRenderPipelineDescriptor *pipelineStateDesc = [MTLRenderPipelineDescriptor new];
    pipelineStateDesc.vertexFunction = vertexProgram;
    pipelineStateDesc.fragmentFunction = fragmentProgram;
    pipelineStateDesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    NSError *error;
    _pipelineState = [_device.device newRenderPipelineStateWithDescriptor:pipelineStateDesc error:&error];
    
    _animator = [[EHAnimator alloc] initWithDuration:5 ticker:self];
    _interpolator = [[EHNumberInterpolator alloc] initWithBegin:@(0) end:@(0.5)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    CAMetalLayer *metalLayer = [CAMetalLayer new];
    metalLayer.device = self.device.device;
    metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    metalLayer.framebufferOnly = YES;
    metalLayer.frame = self.view.layer.frame;
    [self.view.layer addSublayer:metalLayer];
    self.metalLayer = metalLayer;
    
    [self.device start];
    
    __weak typeof(self) weakSelf = self;
    [self.animator setStateChanged:^(EHAnimatorState state) {
        switch (state) {
            case EHAnimatorStateInitial:
                [weakSelf.animator start];
                break;
            case EHAnimatorStateCompleted:
                [weakSelf.animator reverse];
                break;
            default:
                break;
        }
    }];
    [self.animator setListener:^{
        NSLog(@"frameindex: %ld", weakSelf.animator.frameIndex);
//        if (weakSelf.animator.frameIndex % 11 == 0) {
//            if (weakSelf.animator.state == EHAnimatorStateForwarding) {
//                [weakSelf.animator setOffsetBy:0.2];
//            } else if (weakSelf.animator.state == EHAnimatorStateReversing) {
//                [weakSelf.animator setOffsetBy:-0.2];
//            }
//        }
    }];
    [self.animator start];
    [weakSelf.animator setOffsetTo:2];
}

- (void)vsync:(id<MTLCommandQueue>)commandQueue {
    
    if (self.vsyncCallback) {
        self.vsyncCallback();
    }
    
    id<CAMetalDrawable> drawable = [self.metalLayer nextDrawable];
    if (!drawable) {
        return;
    }
    MTLRenderPassDescriptor *renderPassDesc = [MTLRenderPassDescriptor new];
    renderPassDesc.colorAttachments[0].texture = drawable.texture;
    renderPassDesc.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(0, 104.f/255.f, 55.f/255.f, 1);
    
    const int vertexCount = 9;
    float vertexData[vertexCount] =    {0.0 + [self.interpolator evaluate:self.animator].floatValue, 0.6, 0.0,
                                        -1.0 + [self.interpolator evaluate:self.animator].floatValue, -0.6, 0.0,
                                        1.0 + [self.interpolator evaluate:self.animator].floatValue, -0.6, 0.0};
    id<MTLBuffer> buffer = [self.device.device newBufferWithBytes:vertexData length:sizeof(double) * vertexCount options:0];
    
    
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
    [renderEncoder setRenderPipelineState:self.pipelineState];
    [renderEncoder setVertexBuffer:buffer offset:0 atIndex:0];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3 instanceCount:1];
    [renderEncoder endEncoding];
    
    [commandBuffer presentDrawable:drawable];
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
