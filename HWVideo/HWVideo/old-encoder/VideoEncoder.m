//
//  VideoEncoder.m
//  HWVideo
//
//  Created by yanzhen on 16/8/29.
//  Copyright © 2016年 v2tech. All rights reserved.
//

#import "VideoEncoder.h"
#import <VideoToolbox/VideoToolbox.h>
#import <CoreFoundation/CFDictionary.h>


void videoCompressionOutputCallback(void*  outputCallbackRefCon,
                                    void*  sourceFrameRefCon,
                                    OSStatus status,
                                    VTEncodeInfoFlags infoFlags,
                                    CMSampleBufferRef sampleBuffer )
{
    
    VideoEncoder* encoder = (__bridge VideoEncoder *)outputCallbackRefCon;
    
    if (status != 0) return;
    
    if (!CMSampleBufferDataIsReady(sampleBuffer))
    {
        NSLog(@"didCompressH264 data is not ready ");
        return;
    }
    
    // Check if we have got a key frame first 判断当前帧是否为关键帧
    bool keyframe = !CFDictionaryContainsKey((CFDictionaryRef) CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0), kCMSampleAttachmentKey_NotSync);
    if (keyframe)
    {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        size_t sparameterSetSize, sparameterSetCount;
        const uint8_t *sparameterSet;
        OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &sparameterSetSize, &sparameterSetCount, 0 );
        if (statusCode == noErr)
        {
            // Found sps and now check for pps
            size_t pparameterSetSize, pparameterSetCount;
            const uint8_t *pparameterSet;
            OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, 0 );
            if (statusCode == noErr)
            {
                // Found pps
                //序列参数集
                NSData *spsData = [NSData dataWithBytes:(void*)sparameterSet length:sparameterSetSize];
                
                //图像参数集
                NSData *ppsData = [NSData dataWithBytes:(void*)pparameterSet length:pparameterSetSize];
                [encoder.delegate didEncodedSps:spsData pps:ppsData];
            }
        }
    }
    
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
    if (statusCodeRet == noErr) {
        
        size_t bufferOffset = 0;
        static const int AVCCHeaderLength = 4;//返回的nalu数据前四个字节不是0001的startcode，而是大端模式的帧长度length
        while (bufferOffset < totalLength - AVCCHeaderLength) {
            
            // Read the NAL unit length
            uint32_t NALUnitLength = 0;
            memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);// 获取nalu的长度，
            
            // Convert the length value from Big-endian to Little-endian
            // 大端模式转化为系统端模式
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            
            NSData *data = [NSData dataWithBytes:(dataPointer + bufferOffset + AVCCHeaderLength) length:NALUnitLength];
            [encoder.delegate didEncodedData:data isKeyFrame:keyframe];
            // 读取下一个nalu，一次回调可能包含多个nalu
            bufferOffset += AVCCHeaderLength + NALUnitLength;
        }
        
    }
    
}


@implementation VideoEncoder
{
    //压缩视频帧的会话
    VTCompressionSessionRef _encodeSession;
    int32_t _width;
    int32_t _height;
}

- (void)startWithSize:(CGSize) videoSize bitRate:(int)brate
{
    _width = videoSize.width;
    _height = videoSize.height;

    OSStatus status = VTCompressionSessionCreate(NULL, (int32_t)videoSize.width, (int32_t)videoSize.height, kCMVideoCodecType_H264, NULL, NULL, NULL, videoCompressionOutputCallback, (__bridge void *)(self), &_encodeSession);
    
    if (noErr != status) {
        NSLog(@"H264: Unable to create a H264 session code %d",status);
    }
    else
    {
        // 设置实时编码输出，降低编码延迟
        VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
        // 设置编码码率(比特率)，如果不设置，默认将会以很低的码率编码，导致编码出来的视频很模糊
        VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)(@(brate)));
        // h264 profile, 直播一般使用baseline，可减少由于b帧带来的延时
        VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
        VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_Quality, (__bridge CFTypeRef)(@(1.0)));
        // 设置关键帧间隔，即gop size
        VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)(@(10)));
        VTCompressionSessionPrepareToEncodeFrames(_encodeSession);
    }
}

- (BOOL)encode:(CMSampleBufferRef)sampleBuffer
{
    
    if (NULL == _encodeSession) {
        NSLog(@" encode failed session %p ",_encodeSession);
        return NO;
    }
    
    OSStatus status = 0;
    VTEncodeInfoFlags flags;
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    if (width != _width || height != _height) {
        NSLog(@"%zu is not equal %d",width,_width);
    }
    
    // presentationTimeStamp必须设置，否则会导致编码出来的数据非常大，原因未知
//    CMTime pts = CMTimeMake(_frameCount, 1000);
//    CMTime duration = kCMTimeInvalid;
    
    CMTime presentationTimeStamp = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
    CMTime duration = CMSampleBufferGetOutputDuration(sampleBuffer);
    status = VTCompressionSessionEncodeFrame(_encodeSession, pixelBuffer, presentationTimeStamp, duration, NULL, NULL, &flags);
    //    VTDecompressionSessionDecodeFrame(<#VTDecompressionSessionRef  _Nonnull session#>, CMSampleBufferRef  _Nonnull sampleBuffer, <#VTDecodeFrameFlags decodeFlags#>, <#void * _Nullable sourceFrameRefCon#>, <#VTDecodeInfoFlags * _Nullable infoFlagsOut#>)
    return status == noErr;
}

- (void)stop
{
    if (NULL != _encodeSession) {
        VTCompressionSessionCompleteFrames(_encodeSession, kCMTimeInvalid);
        
        VTCompressionSessionInvalidate(_encodeSession);
        CFRelease(_encodeSession);
        _encodeSession = NULL;
    }
}

@end
