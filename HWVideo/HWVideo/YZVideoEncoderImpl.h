//
//  YZVideoEncoderImpl.h
//  HWVideo
//
//  Created by yanzhen on 2017/4/10.
//  Copyright © 2017年 v2tech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol H264EncoderDelegate <NSObject>

- (void)didEncodedData:(NSData *)data isKeyFrame:(BOOL)isKey;
- (void)didEncodedSps:(NSData *)sps pps:(NSData *)pps;
@optional
//???
- (void)didEncodedData1:(NSArray*)datas isKeyFrame:(BOOL)isKey;

@end

@interface YZVideoEncoderImpl : NSObject
@property (nonatomic, weak) id<H264EncoderDelegate> delegate;

- (void)startWithSize:(CGSize)videoSize;
- (BOOL)encode:(CMSampleBufferRef)sampleBuffer;
- (void)stop;
@end
