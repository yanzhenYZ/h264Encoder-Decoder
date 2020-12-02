//
//  VideoDecoder.m
//  HWVideo
//
//  Created by yanzhen on 16/8/29.
//  Copyright © 2016年 v2tech. All rights reserved.
//

#import "VideoDecoder.h"
#import <VideoToolbox/VideoToolbox.h>
 

#define h264outputWidth 800
#define h264outputHeight 600

@interface VideoDecoder ()
@property (nonatomic) BOOL isKeyFrame;
@end

@implementation VideoDecoder{
    CMVideoFormatDescriptionRef _formatDescription;
    uint8_t* _pps;
    uint8_t* _sps;
    size_t _spsSize;
    size_t _ppsSize;
}
/*
 
 解码播放后的视频会抖动，iOS解码器不负责重排B帧顺序，需要应用自己根据PTS去做。
 
 */
-(void)decodeData:(NSData *)data{
    NSLog(@"TTTT:%@",data);
    uint8_t *frame = (uint8_t *)data.bytes;
    uint32_t frameSize = (uint32_t)data.length;
    //前面拼接了4个字节，取出第五个字节做判断
    int nalu_type = (frame[4] & 0x1F);
    
    //nal数据的长度
    uint32_t nalSize = (uint32_t)(frameSize - 4);
    uint8_t *pNalSize = (uint8_t*)(&nalSize);
    /*
    由于VideoToolbox接口只接受MP4容器格式，当接收到Elementary Stream形式的H.264流，需把Start Code（3- or 4-Byte Header）换成Length（4-Byte Header）。
     参考工程中的图片或者http://www.cnblogs.com/sunminmin/p/4976418.html
     //rtsp://192.168.2.73:1935/vod/sample.mp4
     */
    //用前4个字节来表示nalSize
    //下面等同
//    frame[0] = *(pNalSize + 3);
//    frame[1] = *(pNalSize + 2);
//    frame[2] = *(pNalSize + 1);
//    frame[3] = *(pNalSize);

    
    frame[0] = pNalSize[3];
    frame[1] = pNalSize[2];
    frame[2] = pNalSize[1];
    frame[3] = pNalSize[0];
    switch (nalu_type)
    {
        case 0x05://IDR frame  I帧-关键帧
        {
            CMBlockBufferRef blockBuffer = [self createBlockBufferWithData:data];
            CMSampleBufferRef samplebuffer= [self createSampleBufferWithBlockBuffer:blockBuffer];
            [self.delegate didOutputVideoSampleBuffer:samplebuffer];
            
            if (samplebuffer != NULL) {
                CFRelease(samplebuffer);
            }
            if (blockBuffer != NULL) {
                CFRelease(blockBuffer);
            }
        }
            break;
        case 0x07://SPS
        {
            _spsSize = frameSize - 4;
            //用malloc分配内存的首地址，然后赋值给_sps
            _sps = malloc(_spsSize);
            //把&frame[4]开始长度_spsSize内存区域拷贝到_sps所指的内存区域
            memcpy(_sps, &frame[4], _spsSize);
            if (_pps && _sps) {
                [self configureFromatDescription];
            }
        }
            break;
        case 0x08://PPS
        {
            _ppsSize = frameSize - 4;
            _pps = malloc(_ppsSize);
            memcpy(_pps, &frame[4], _ppsSize);
            if (_pps && _sps) {
                [self configureFromatDescription];
            }
        }
            break;
        default://B/P frame
        {
            //NSLog(@"Nal type is B/P frame");//其他帧
            CMBlockBufferRef blockBuffer = [self createBlockBufferWithData:data];
            CMSampleBufferRef samplebuffer= [self createSampleBufferWithBlockBuffer:blockBuffer];
            
            [self.delegate didOutputVideoSampleBuffer:samplebuffer];
            
            if (samplebuffer != NULL) {
                CFRelease(samplebuffer);
            }
            if (blockBuffer != NULL) {
                CFRelease(blockBuffer);
            }
        }
            break;
    }
}


- (CMBlockBufferRef)createBlockBufferWithData:(NSData*)data
{
    CMBlockBufferRef blockBuffer = NULL;
    
    OSStatus status  = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                          (void*)data.bytes,
                                                          data.length,
                                                          kCFAllocatorNull,
                                                          NULL,
                                                          0,
                                                          data.length,
                                                          0,
                                                          &blockBuffer);
    assert(status == noErr);
    return blockBuffer;
}

- (CMSampleBufferRef)createSampleBufferWithBlockBuffer:(CMBlockBufferRef)block
{
    CMSampleBufferRef sampleBuffer = NULL;
    if (_formatDescription) {
        OSStatus status = CMSampleBufferCreate(kCFAllocatorDefault,
                                               block,
                                               YES,
                                               NULL,
                                               NULL,
                                               _formatDescription,
                                               1,
                                               0,
                                               NULL,
                                               0,
                                               NULL,
                                               &sampleBuffer);
        
        CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
        CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
        CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
        assert(status == noErr);
    }
    
    return sampleBuffer;
}

- (void)configureFromatDescription
{
#pragma mark - 两种选择
    //---1
    if (_formatDescription) return;
    //---2
//    if (_formatDescription) {
//        CFRelease(_formatDescription);
//        _formatDescription = nil;
//    }
    
    const uint8_t* const parameterSetPointers[2] = { _sps, _pps };
    const size_t parameterSetSizes[2] = { _spsSize, _ppsSize};
    CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          2,
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          4,
                                                                          (CMFormatDescriptionRef*)&_formatDescription);
    //40---103---15---5 iPhone5
    _pps = nil;
    _sps = nil;
    _spsSize = 0;
    _ppsSize = 0;
}
@end
