//
//  LocalVideoWindow.h
//  HWVideo
//
//  Created by yanzhen on 2017/4/11.
//  Copyright © 2017年 v2tech. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LocalVideoWindow : UIView
//暂时默认width<height,frame.size.height=videoHeight
- (instancetype)initWithFrame:(CGRect)frame videoWidth:(CGFloat)width;
- (void)addSubLayer:(CALayer *)layer;
@end
