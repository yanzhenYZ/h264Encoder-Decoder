//
//  VideoDecoder.h
//  HWVideo
//
//  Created by yanzhen on 16/8/29.
//  Copyright © 2016年 v2tech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol HWH264DecoderOutputDelegate <NSObject>

- (void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sample;

@end
@interface VideoDecoder : NSObject
@property (nonatomic, assign) id<HWH264DecoderOutputDelegate> delegate;

- (void)decodeData:(NSData *)data;
@end
