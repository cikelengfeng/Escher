//
//  ViewController.m
//  Escher
//
//  Created by 徐 东 on 2019/4/15.
//  Copyright © 2019 DXLab. All rights reserved.
//

#import "ViewController.h"
#import "SkCanvas.h"
#import "SkGraphics.h"
#import "SkSurface.h"
#import "SkString.h"
#import "SkRRect.h"
#import "SkTextUtils.h"
#import "SkTextBlob.h"

@interface ViewController ()

@property (nonatomic, weak) UIImageView *contentView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    [self.view addSubview:imageView];
    self.contentView = imageView;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.contentView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
    [self drawInImageView:self.contentView];
}

- (void)drawInImageView:(UIImageView *)imgView {
    SkScalar screenScale = UIScreen.mainScreen.scale;
    int width = imgView.bounds.size.width * screenScale;
    int height = imgView.bounds.size.height * screenScale;
    
    
    SkBitmap bitmap;
    bitmap.setInfo(SkImageInfo::Make(width, height, kRGBA_8888_SkColorType, kOpaque_SkAlphaType, nullptr));
    bitmap.allocPixels();
    
    SkCanvas canvas(bitmap);
    canvas.drawColor(SK_ColorWHITE);
    canvas.scale(screenScale, screenScale);
    
    SkPaint paint;
    paint.setStyle(SkPaint::kFill_Style);
    paint.setAntiAlias(true);
    paint.setStrokeWidth(4);
    paint.setColor(0xffFE938C);
    
    SkRect rect_sk = SkRect::MakeXYWH(10, 30, 100, 160);
    canvas.drawRect(rect_sk, paint);
    
    SkRRect oval;
    oval.setOval(rect_sk);
    oval.offset(40, 80);
    paint.setColor(0xffE6B89C);
    canvas.drawRRect(oval, paint);
    
    paint.setColor(0xff9CAFB7);
    canvas.drawCircle(180, 50, 25, paint);
    
    rect_sk.offset(80, 50);
    paint.setColor(0xff4281A4);
    paint.setStyle(SkPaint::kStroke_Style);
    canvas.drawRoundRect(rect_sk, 10, 10, paint);
    
    SkPaint paint2;
    paint2.setAntiAlias(true);
    auto text = SkTextBlob::MakeFromString("Hello, Skia!", SkFont(nullptr, 18));
    canvas.drawTextBlob(text.get(), 50, 100, paint2);
    
    void* data = bitmap.getPixels();
    
    NSUInteger dataLength = width * height * 4;
    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, dataLength, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef iref = CGImageCreate(width, height, 8, 32, width * 4, colorspace,
                                    kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
                                    ref, NULL, true, kCGRenderingIntentDefault);
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), YES, 0.0);
    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(cgcontext, 0, height);
    CGContextScaleCTM(cgcontext, 1.0, -1.0);
    CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
    CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, width, height), iref);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CFRelease(ref);
    CFRelease(colorspace);
    CGImageRelease(iref);
    bitmap.reset();
    
    imgView.image = image;
}

@end
