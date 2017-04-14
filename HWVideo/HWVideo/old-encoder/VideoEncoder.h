//
//  VideoEncoder.h
//  HWVideo
//
//  Created by yanzhen on 16/8/29.
//  Copyright © 2016年 v2tech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@protocol HWH264EncoderDelegate <NSObject>


//- (void)didEncodedData:(NSArray*)array isKeyFrame:(BOOL)isKey;


- (void)didEncodedData:(NSData*)data isKeyFrame:(BOOL)isKey;
- (void)didEncodedSps:(NSData*)sps pps:(NSData*)pps;
@optional
//???
- (void)didEncodedData1:(NSArray*)datas isKeyFrame:(BOOL)isKey;

@end

@interface VideoEncoder : NSObject
@property (nonatomic,assign) id <HWH264EncoderDelegate> delegate;

- (void)startWithSize:(CGSize) videoSize bitRate:(int)brate;
- (BOOL)encode:(CMSampleBufferRef)sampleBuffer;
- (void)stop;
@end
