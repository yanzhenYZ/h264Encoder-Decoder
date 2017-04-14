//
//  LocalVideoWindow.m
//  HWVideo
//
//  Created by yanzhen on 2017/4/11.
//  Copyright © 2017年 v2tech. All rights reserved.
//

#import "LocalVideoWindow.h"

@interface LocalVideoWindow ()
@property (nonatomic, strong) UIImageView *videoView;
@property (nonatomic) CGPoint beginPoint;
@end

@implementation LocalVideoWindow
#pragma mark - 1.0.5.5
//下面三个方法解决1.0.5.5
-(instancetype)initWithFrame:(CGRect)frame videoWidth:(CGFloat)width{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _videoView = [[UIImageView alloc] initWithFrame:CGRectMake((frame.size.width - width) * 0.5, 0, width, frame.size.height)];
        _videoView.backgroundColor = [UIColor blackColor];
        _videoView.layer.borderWidth = 1.0;
        _videoView.layer.borderColor = [UIColor grayColor].CGColor;
        [self addSubview:_videoView];
    }
    return self;
}

- (void)addSubLayer:(CALayer *)layer
{
    layer.frame = self.videoView.bounds;
    [self.videoView.layer addSublayer:layer];
}

-(void)setTransform:(CGAffineTransform)transform{
    _videoView.transform = transform;
}

#pragma mark - touch
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    _beginPoint = [[touches anyObject] locationInView:self];
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    CGPoint nowPoint = [[touches anyObject] locationInView:self];
    CGFloat offsetX = nowPoint.x - _beginPoint.x;
    CGFloat offsetY = nowPoint.y - _beginPoint.y;
    CGFloat centerX = self.center.x + offsetX;
    CGFloat centerY = self.center.y + offsetY;
    self.center = CGPointMake(centerX, centerY);
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self resetFrame];
}

- (void)resetFrame{
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenH = [UIScreen mainScreen].bounds.size.height;
    CGFloat centerX = self.center.x;
    CGFloat centerY = self.center.y;
    CGFloat width = self.videoView.frame.size.width;
    CGFloat height = self.videoView.frame.size.height;
    
    if (centerX < width / 2) {
        centerX = width / 2;
    }else if (centerX > screenW - width / 2){
        centerX = screenW - width / 2;
    }
    
    if (centerY < height / 2) {
        centerY = height / 2;
    }else if (centerY > screenH - height / 2){
        centerY = screenH - height / 2;
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        self.center = CGPointMake(centerX, centerY);
    }];
}

@end
