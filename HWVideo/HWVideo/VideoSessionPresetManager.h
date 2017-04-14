//
//  VideoSessionPresetManager.h
//  HWVideo
//
//  Created by yanzhen on 2017/4/10.
//  Copyright © 2017年 v2tech. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideoSessionPresetManager : NSObject

+ (CGSize)getVideoSizeWithAVCaptureSessionPreset:(NSString *)sessionPreset;

@end
