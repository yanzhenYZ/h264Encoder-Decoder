//
//  ViewController.m
//  HWVideo
//
//  Created by yanzhen on 16/8/29.
//  Copyright © 2016年 v2tech. All rights reserved.
//

#import "ViewController.h"
#import "YZVideoEncoderImpl.h"
#import "VideoDecoder.h"
#import "VideoDisplayView.h"
#import "LocalVideoWindow.h"
#import "VideoSessionPresetManager.h"
#import <AVFoundation/AVFoundation.h>
//最大值不能超过60
static int const frameRate = 12;
static CGFloat const SCALE = 2;
@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,HWH264DecoderOutputDelegate,H264EncoderDelegate>
@property (weak, nonatomic) IBOutlet VideoDisplayView *showView;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) dispatch_queue_t dataOutputQueue;
@property (nonatomic, strong) AVCaptureVideoDataOutput *dataOutput;
@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;
@property (nonatomic, strong) AVCaptureConnection *connect;
@property (nonatomic, strong) LocalVideoWindow *localVideoWid;
@property (nonatomic, copy) NSString *sessionPreset;
@property (nonatomic, strong) VideoDisplayView *localView;
//@property (nonatomic, strong) VideoDisplayView *showView;
@property (nonatomic, strong) YZVideoEncoderImpl *encoder;
@property (nonatomic, strong) VideoDecoder *decoder;
@property (nonatomic) CGSize videoSize;
@property (nonatomic) BOOL front;

@property (nonatomic) BOOL send;
@end

@implementation ViewController
/*
  在H.264/AVC视频编码标准中，整个系统框架被分为了两个层面：视频编码层面（VCL）和网络抽象层面（NAL）。其中，前者负责有效表示视频数据的内容，而后者则负责格式化数据并提供头信息，以保证数据适合各种信道和存储介质上的传输。因此我们平时的每帧数据就是一个NAL单元（SPS与PPS除外）。在实际的H264数据帧中，往往帧前面带有00 00 00 01 或 00 00 01分隔符，一般来说编码器编出的首帧数据为PPS与SPS，接着为I帧……
 */

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //AVCaptureSessionPreset352x288
    //AVCaptureSessionPreset640x480
    //AVCaptureSessionPreset1280x720
    //AVCaptureSessionPresetMedium
    //AVCaptureSessionPreset1920x1080 (后摄像头--ipad有问题)
    self.sessionPreset = AVCaptureSessionPreset640x480;
    //ipad
    _videoSize = [VideoSessionPresetManager getVideoSizeWithAVCaptureSessionPreset:self.sessionPreset];

    _localVideoWid = [[LocalVideoWindow alloc] initWithFrame:CGRectMake(0, 0, _videoSize.height/SCALE, _videoSize.height/SCALE) videoWidth:_videoSize.width/SCALE];
    [self.view addSubview:_localVideoWid];
    
    _front = YES;
    _encoder = [[YZVideoEncoderImpl alloc] init];
    _encoder.delegate = self;
    _decoder = [[VideoDecoder alloc] init];
    _decoder.delegate = self;
    
}


#pragma mark - HWH264DecoderOutputDelegate
-(void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sample{
        [_showView decoderEnqueueSampleBuffer:sample];
}

#pragma mark - 暂停采集
- (IBAction)enableVideo:(id)sender {
    //暂停采集之后不能通过start方法开始采集，否则切换摄像头没有效果
    if (self.session.isRunning) {
        [self.session stopRunning];
    }else{
        [self.session startRunning];
    }
    
}
#pragma mark - 切换摄像头
- (IBAction)switchCamera:(id)sender {
    [self stop];
    _front = !_front;
    [self start];
}

- (IBAction)startVideo:(id)sender {
    if (self.session.isRunning) return;
    [_encoder startWithSize:_videoSize];
    [self start];
}



- (void)start{
    if (self.session.isRunning) return;
    
    AVCaptureDevice *camera = nil;
    camera = [self cameraWithPosition:_front ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack];
    
    NSError *error;
    self.deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:&error];
    if (error) {
        NSLog(@"error %@",error.description);
    }
    
    [self.dataOutput setSampleBufferDelegate:self queue:self.dataOutputQueue];
    
    if ([self.session canAddInput:self.deviceInput]) {
        [self.session addInput:self.deviceInput];
    }
    
    if ([self.session canAddOutput:self.dataOutput]) {
        [self.session addOutput:self.dataOutput];
        
    }
    
    [_session beginConfiguration];
    self.session.sessionPreset = self.sessionPreset;
    _connect = [self.dataOutput connectionWithMediaType:AVMediaTypeVideo];
    [_connect setVideoOrientation:(AVCaptureVideoOrientation)[self curOrientation]];
    [_session commitConfiguration];

    
    AVCaptureVideoPreviewLayer *previewLayer= [AVCaptureVideoPreviewLayer layerWithSession:_session];
//    previewLayer.frame = self.localVideoWid.bounds;
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    previewLayer.backgroundColor = [UIColor clearColor].CGColor;
    [self.localVideoWid addSubLayer:previewLayer];
    
    [camera lockForConfiguration:nil];
    camera.activeVideoMinFrameDuration = CMTimeMake(1, frameRate);
    camera.activeVideoMaxFrameDuration = CMTimeMake(1, frameRate + 2);
    [camera unlockForConfiguration];
    
//    NSArray *supportedFrameRateRanges = [camera.activeFormat videoSupportedFrameRateRanges];
//    for (AVFrameRateRange *range in supportedFrameRateRanges) {
//        NSLog(@"TTTT:%f = %f",range.minFrameRate,range.maxFrameRate);
//    }
    //防抖模式，被称为影院级的视频防抖动
    if ([camera.activeFormat isVideoStabilizationModeSupported:AVCaptureVideoStabilizationModeCinematic]) {
        [_connect setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeCinematic];
    }else if([camera.activeFormat isVideoStabilizationModeSupported:AVCaptureVideoStabilizationModeAuto]){
        [_connect setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeAuto];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
#pragma mark - 1.0.5
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
    [self.session startRunning];
    
    [_localView flushAndRemoveImage];
    [_showView flushAndRemoveImage];
}

- (void)deviceOrientationDidChange{
#pragma mark - 1.0.5.1.1
    //当iPhone方向发生改变时，需要把设备方向传过去（参考FaceTime）
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (deviceOrientation < UIDeviceOrientationPortrait || deviceOrientation > UIDeviceOrientationLandscapeRight) {
        return;
    }
#pragma mark - 1.0.5.2
#pragma mark - 1.0.5.4
    //设备方向改变时，需要旋转本地预览视图
    if (deviceOrientation == UIDeviceOrientationLandscapeRight) {
        _showView.transform = CGAffineTransformMakeRotation(-M_PI_2);
        _localVideoWid.transform = CGAffineTransformMakeRotation(M_PI_2);
    }else if (deviceOrientation == UIDeviceOrientationLandscapeLeft){
        _showView.transform = CGAffineTransformMakeRotation(M_PI_2);
        _localVideoWid.transform = CGAffineTransformMakeRotation(-M_PI_2);
    }else if (deviceOrientation == UIDeviceOrientationPortrait){
        _showView.transform = CGAffineTransformIdentity;
        _localVideoWid.transform = CGAffineTransformIdentity;
    }else if (deviceOrientation == UIDeviceOrientationPortraitUpsideDown){
        //iPhone没有？？？
        _showView.transform = CGAffineTransformMakeRotation(M_PI);
        _localVideoWid.transform = CGAffineTransformMakeRotation(M_PI);
    }
#pragma mark - 不支持横屏
//    if (不支持横屏) {
//        if (deviceOrientation == UIDeviceOrientationLandscapeRight) {
//            _showView.transform = CGAffineTransformMakeRotation(-M_PI_2);
//        }else if (deviceOrientation == UIDeviceOrientationLandscapeLeft){
//            _showView.transform = CGAffineTransformMakeRotation(M_PI_2);
//        }else if (deviceOrientation == UIDeviceOrientationPortrait){
//            _showView.transform = CGAffineTransformIdentity;
//        }else if (deviceOrientation == UIDeviceOrientationPortraitUpsideDown){
//            //iPhone没有？？？
//            _showView.transform = CGAffineTransformMakeRotation(M_PI);
//        }
//    }
}

- (void)stop{
    [self.session stopRunning];
    if (self.deviceInput) {
        [self.session removeInput:self.deviceInput];
    }
    
    if (self.dataOutput) {
        [self.session removeOutput:self.dataOutput];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}
#pragma mark - H264EncoderDelegate
-(void)didEncodedData:(NSData *)data isKeyFrame:(BOOL)isKey{
    const char bytes[] = "\x00\x00\x00\x01";//视频数据的前4个字节时 0x00 0x00 0x00 0x01
    size_t length = (sizeof bytes) - 1;
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    NSMutableData *h264Data = [[NSMutableData alloc] init];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:data];
    [_decoder decodeData:h264Data];
}

-(void)didEncodedSps:(NSData *)sps pps:(NSData *)pps{
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    //发sps
    NSMutableData *h264Data = [[NSMutableData alloc] init];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:sps];
    [_decoder decodeData:h264Data];
    
    //发pps
    [h264Data resetBytesInRange:NSMakeRange(0, [h264Data length])];
    [h264Data setLength:0];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:pps];
    [_decoder decodeData:h264Data];
}

#pragma mark - 视频数据
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    [_localView enqueueSampleBuffer:sampleBuffer];
    [_encoder encode:sampleBuffer];
}


- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
        if ( device.position == position )
            return device;
    return nil;
}

- (UIInterfaceOrientation)curOrientation
{
    return [[UIApplication sharedApplication] statusBarOrientation];
}

#pragma  mark - *** notification selector ***
- (void)willResignActive
{
    //进入后台停止编码
    [_encoder stop];
}

- (void)didBecomeActive
{
    __block ViewController* blockSelf = self;
    dispatch_async(self.dataOutputQueue, ^{
        //从后台返回，重新开始编码
        [_encoder startWithSize:_videoSize];
        [blockSelf.localView flushAndRemoveImage];
        [blockSelf.showView flushAndRemoveImage];
    });
}

#pragma mark - lazy var
-(dispatch_queue_t)dataOutputQueue{
    if (!_dataOutputQueue) {
        _dataOutputQueue = dispatch_queue_create("com.video.queue", 0);
    }
    return _dataOutputQueue;
}

-(AVCaptureSession *)session{
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
    }
    return _session;
}

- (AVCaptureVideoDataOutput*)dataOutput
{
    if (!_dataOutput) {
        _dataOutput = [[AVCaptureVideoDataOutput alloc] init];
        _dataOutput.alwaysDiscardsLateVideoFrames = YES;
#pragma mark - 1.0.2
        _dataOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
        //kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    }
    return _dataOutput;
}


@end
