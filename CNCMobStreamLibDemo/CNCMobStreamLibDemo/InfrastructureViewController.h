//
//  InfrastructureViewController.h
//  CNCMobStreamDemo
//
//  Created by weiyansheng on 2017/4/28.
//  Copyright © 2017年 cad. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonInclude.h"

#define STREAM_NAME_CACHE [[NSUserDefaults standardUserDefaults] stringForKey:@"stream_name_cache"]

@interface InfrastructureViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, UIGestureRecognizerDelegate>
{
    CGFloat _currentUIMaxY;
    CGFloat _screenWidth;
    CGFloat _screenHeight;
}
///软编 质量/码率优先
@property (nonatomic, retain) NSArray *array_sw_encoder_priority_type;

///编码方式
@property (nonatomic, retain) NSArray *array_encode_way;

///摄像头方向
@property (nonatomic, retain) NSArray *array_camera_side;

///横竖屏
@property (nonatomic, retain) NSArray *array_camera_direction;

///码率
@property (nonatomic, retain) NSMutableArray *array_bit_rate;

///帧率
@property (nonatomic, retain) NSMutableArray *array_frame_rate;

///推流配置参数 pickview
@property (nonatomic, retain) UIPickerView *rtmp_config_pickview;

///推流地址输入框 UITextField
@property (nonatomic, retain) UITextField *rtmp_address_inputTF;

///推流配置参数
@property (nonatomic, assign) int sw_encoder_priority_type;
@property (nonatomic) CNCENMEncoderType encoder_type;
@property (nonatomic) CNCENMDirectType direct_type;
@property (nonatomic, assign) NSInteger video_bit_rate;
@property (nonatomic, assign) NSInteger video_frame_rate;
@property (nonatomic, assign) NSInteger came_sel_type;//0 后置 1 前置  2 纯音频
@property (nonatomic) AVCaptureDevicePosition came_pos;
@property (nonatomic, assign) BOOL show_the_third_sdk;
@end
