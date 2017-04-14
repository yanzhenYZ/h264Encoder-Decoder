//
//  VideoDisplayView.m
//  HWVideo
//
//  Created by yanzhen on 2017/4/10.
//  Copyright © 2017年 v2tech. All rights reserved.
//

#import "VideoDisplayView.h"

@interface VideoDisplayView ()
@property (nonatomic, strong) AVSampleBufferDisplayLayer *videoLayer;
@property (nonatomic) CGPoint beginPoint;
@end

@implementation VideoDisplayView
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initConfigure];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initConfigure];
    }
    return self;
}

- (void)initConfigure{
    _videoLayer = [AVSampleBufferDisplayLayer layer];
#pragma mark - 1.0.4
    _videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _videoLayer.backgroundColor = [UIColor blackColor].CGColor;
    _videoLayer.frame = self.bounds;
    [self.layer addSublayer:_videoLayer];
}

#pragma mark - touch
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if (!_draggable) return;
    _beginPoint = [[touches anyObject] locationInView:self];
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if (!_draggable) return;
    CGPoint nowPoint = [[touches anyObject] locationInView:self];
    CGFloat offsetX = nowPoint.x - _beginPoint.x;
    CGFloat offsetY = nowPoint.y - _beginPoint.y;
    CGFloat centerX = self.center.x + offsetX;
    CGFloat centerY = self.center.y + offsetY;
    self.center = CGPointMake(centerX, centerY);
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if (!_draggable) return;
    [self resetFrame];
}

- (void)resetFrame{
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenH = [UIScreen mainScreen].bounds.size.height;
//    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
//    if (orientation == UIDeviceOrientationLandscapeRight || orientation == UIDeviceOrientationLandscapeLeft) {
//        screenH = [UIScreen mainScreen].bounds.size.width;
//        screenW = [UIScreen mainScreen].bounds.size.height;
//    }
    CGFloat centerX = self.center.x;
    CGFloat centerY = self.center.y;
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    
//    NSLog(@"TTTT:%f -- %f -- %f -- %f",screenW,screenH,width,height);
    
    if(centerX < width / 2)
    {
        centerX = width / 2;
    }
    else if(centerX > screenW - width / 2)
    {
        centerX = screenW - width / 2;
    }
    
    if(centerY < height / 2)
    {
        centerY = height / 2;
    }
    else if(centerY > screenH - height / 2)
    {
        centerY = screenH - height / 2;
    }
    [UIView animateWithDuration:0.25 animations:^{
        self.center = CGPointMake(centerX, centerY);
    }];
}

#pragma mark - out method
- (void)flushAndRemoveImage{
    [_videoLayer flushAndRemoveImage];
}

- (void)enqueueSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    [_videoLayer enqueueSampleBuffer:sampleBuffer];
}

- (void)decoderEnqueueSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    if (UIApplicationStateActive !=[UIApplication sharedApplication].applicationState) return;
    
    if (CMSampleBufferDataIsReady(sampleBuffer) && CMSampleBufferIsValid(sampleBuffer)) {
        if (_videoLayer.status == AVQueuedSampleBufferRenderingStatusFailed) return;
        if (_videoLayer.isReadyForMoreMediaData) {
            [self enqueueSampleBuffer:sampleBuffer];
        }
    }
}

-(void)layoutSubviews{
    [super layoutSubviews];
    _videoLayer.frame = self.bounds;
}
@end
