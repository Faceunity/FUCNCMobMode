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

@interface NewInfrastructureViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, UIGestureRecognizerDelegate>
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

///布局 左上右上
@property (nonatomic, retain) NSMutableArray *array_auto_layout;

///自动布局
@property (nonatomic, assign) NSInteger auto_layout;

///推流配置参数 pickview
@property (nonatomic, retain) UIPickerView *rtmp_config_pickview;

///流名
@property (nonatomic, retain) UITextField *rtmp_stream_name_TF;

///发布点 及控件
@property (nonatomic, retain) UIButton *publishing_point_Btn;
@property (nonatomic, retain) UIView *publishing_point_View;
@property (nonatomic, retain) NSString *publishing_point_str;
///推流配置参数
@property (nonatomic, assign) int sw_encoder_priority_type;
@property (nonatomic) CNCENMEncoderType encoder_type;
@property (nonatomic) CNCENMDirectType direct_type;
@property (nonatomic, assign) NSInteger video_bit_rate;
@property (nonatomic, assign) NSInteger video_frame_rate;
@property (nonatomic, assign) NSInteger came_sel_type;//0 后置 1 前置  2 纯音频
@property (nonatomic) AVCaptureDevicePosition came_pos;
@property (nonatomic, retain) NSArray *array_video_resolution;
@property (nonatomic, retain) NSArray *array_value_video_resolution;
@property (nonatomic, retain) NSMutableArray *array_value_mix_rate;
@property (nonatomic, assign) CNCVideoResolutionType video_resolution_type;
@property (nonatomic, assign) NSInteger video_mix_rate;
@property (nonatomic, retain) UIScrollView *scrollView;

///主播房间号
@property (nonatomic, retain) UITextField *anchor_roomID_TF;
///主播ID
@property (nonatomic, retain) UITextField *anchor_ID_TF;
///观众ID
@property (nonatomic, retain) UITextField *audience_ID_TF;
///APP计费域名
@property (nonatomic, retain) NSString *host_str;
@property (nonatomic, retain) NSString *push_domain_name;
@property (nonatomic, retain) NSString *pull_domain_name;

- (void)create_view;
//- (void) action_start_btn:(UIButton *)sender;
- (void)infrastrucnture_init_start_btn;
- (void)textField_resignFirstResponder;
@end
