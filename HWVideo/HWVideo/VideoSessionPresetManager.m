//
//  VideoSessionPresetManager.m
//  HWVideo
//
//  Created by yanzhen on 2017/4/10.
//  Copyright © 2017年 v2tech. All rights reserved.
//

#import "VideoSessionPresetManager.h"
#import <AVFoundation/AVFoundation.h>

@implementation VideoSessionPresetManager
/*
 AVCaptureSessionPresetHigh
 AVCaptureSessionPresetMedium
 AVCaptureSessionPresetLow
 这三项对于不同设备，前后摄像头采集的尺寸都有差别
 */
+ (NSMutableDictionary *)allAVCaptureSessionPreset{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:[NSValue valueWithCGSize:CGSizeMake(288, 352)] forKey:AVCaptureSessionPreset352x288];
    [dict setValue:[NSValue valueWithCGSize:CGSizeMake(480, 640)] forKey:AVCaptureSessionPreset640x480];
    [dict setValue:[NSValue valueWithCGSize:CGSizeMake(720, 1280)] forKey:AVCaptureSessionPreset1280x720];
    [dict setValue:[NSValue valueWithCGSize:CGSizeMake(1080, 1920)] forKey:AVCaptureSessionPreset1920x1080];
    [dict setValue:[NSValue valueWithCGSize:CGSizeMake(2160, 3840)] forKey:AVCaptureSessionPreset3840x2160];
    return dict;
}



+ (CGSize)getVideoSizeWithAVCaptureSessionPreset:(NSString *)sessionPreset{
    CGSize videoSize  = CGSizeZero;
    NSDictionary *dict = [self allAVCaptureSessionPreset];
    NSValue *value = [dict valueForKey:sessionPreset];
    if (value) {
        videoSize = value.CGSizeValue;
    }
    return videoSize;
}
@end
