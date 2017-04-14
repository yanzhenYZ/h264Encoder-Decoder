//
//  Version.h
//  HWVideo
//
//  Created by yanzhen on 2017/4/6.
//  Copyright © 2017年 v2tech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Version : NSObject

/*
 1.0.1 iPhone没有问题，iPad会出现解码花屏的问题
 1.0.2 解决ipad出现花屏的现象
 1.0.3 视频尺寸(iPhone和iPad支持的不同，设备的前后摄像头支持的也不同)
 1.0.4 满屏显示的问题
 1.0.5 方向旋转(本demo只支持iPhone，不支持方向旋转)
       本地预览建议使用AVCaptureVideoPreviewLayer
       AVSampleBufferDisplayLayer会出现预览反向的问题
 1.0.5.1 iPhone不支持横屏   当iPhone方向发生改变时，需要把设备方向传过去（参考FaceTime）
 1.0.5.2 iPhone支持横屏    当iPhone方向发生改变时，需要把设备方向传过去（参考FaceTime），同时旋转本地预览视图
 1.0.5.3 iPad不支持横屏    同1.0.5.1
 1.0.5.4 iPad支持横屏      同1.0.5.2
 1.0.5.5 iPhone和iPad支持横屏时，转转屏幕后(视图做transform操作之后，不能对视图做frame改变)，本地预览拖动问题
 
 
 ?? pps sps--decoder解码
 */

@end
