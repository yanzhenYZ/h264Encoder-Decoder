//
//  VideoDisplayView.h
//  HWVideo
//
//  Created by yanzhen on 2017/4/10.
//  Copyright © 2017年 v2tech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface VideoDisplayView : UIView
@property (nonatomic) BOOL draggable;

- (void)flushAndRemoveImage;
- (void)enqueueSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)decoderEnqueueSampleBuffer:(CMSampleBufferRef)sampleBuffer;
@end
