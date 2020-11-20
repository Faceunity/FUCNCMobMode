//
//  CNCLayeredMenuViewController.m
//  CNCMobStreamLibDemo
//
//  Created by 82008223 on 2017/3/28.
//  Copyright © 2017年 chinanetcenter. All rights reserved.
//

#import "CNCLayeredMenuViewController.h"
#ifdef CNC_DEMO_FU
#import "CNCVideoLayeredViewControllerFU.h"
#endif
#ifdef CNC_DEMO_ST
#import "CNCVideoLayeredViewControllerST.h"
#endif

#import "CNCVideoLayeredViewController.h"

#import <AVFoundation/AVFoundation.h>

@interface CNCLayeredMenuViewController () {
    
}

@property (nonatomic) NSInteger cur_idx;


//@property (nonatomic, retain) NSArray *array;
//@property (nonatomic, retain) NSArray *array_value;

@property (nonatomic, retain) UITextField *width_textField;
@property (nonatomic, retain) UITextField *height_textField;

//@property (nonatomic) BOOL need_custom_w_x_h;
@property (nonatomic) BOOL use_recommend_video_resolution;
@property (nonatomic, retain) NSArray *array_video_resolution;
@property (nonatomic, retain) NSArray *array_value_video_resolution;
@property (nonatomic) NSInteger cur_idx_video;

@property (nonatomic) NSInteger def_width;
@property (nonatomic) NSInteger def_height;
@property (nonatomic, retain) CNCVideoSourceCfg *stream_para;
@property (nonatomic, retain) CNCCaptureInfo *capture_info;

@property (nonatomic, retain) NSArray *array_format;
@property (nonatomic, retain) NSArray *array_value_format;
@property (nonatomic) NSInteger cur_idx_format;
@end

@implementation CNCLayeredMenuViewController
{
    
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self init_para];
    }
    return self;
}
- (void)init_para {
    if (!self.stream_para) {
        self.stream_para = [[[CNCVideoSourceCfg alloc] init] autorelease];
        self.capture_info = [[[CNCCaptureInfo alloc] init] autorelease];

        self.is_fu = NO;
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    if (self.is_fu) {
        self.title = @"FU测试";
    } else {
        self.title = @"分层采集";
    }
    
#ifdef CNC_NewInterface
    [self set_new_interface_view];
#else
    [self set_view];
#endif
    
}

- (void)set_view {
    
//    NSString *app_id = [[NSUserDefaults standardUserDefaults] objectForKey:@"CNCMobSteamSDK_App_ID"];
//    if([app_id isEqualToString:@"wstest001"]) {
//        self.array = [NSArray arrayWithObjects:
//                      @"640*480",
//                      @"352x288",
//                      @"960*540",
//                      @"1280*720",
//                      //                                        @"1920x1080",
//                      //@"3840x2160",
//                      nil];
//        
//        self.array_value = [NSArray arrayWithObjects:
//                            @(CNCResolution_4_3__640x480),
//                            @(CNCResolution_5_4__352x288),
//                            @(CNCResolution_16_9__960x540),
//                            @(CNCResolution_16_9__1280x720),
//                            //                                                    @(CNCResolution_16_9__1920x1080),
//                            nil];
//    } else {
//        self.array = [NSArray arrayWithObjects:
//                      @"640*480",
//                      //                  @"352x288",
//                      //                  @"960*540",
//                      @"1280*720",
//                      //                  @"1920x1080",
//                      //@"3840x2160",
//                      nil];
//        self.array_value = [NSArray arrayWithObjects:
//                            @(CNCResolution_4_3__640x480),
//                            //                        @(CNCResolution_5_4__352x288),
//                            //                        @(CNCResolution_16_9__960x540),
//                            @(CNCResolution_16_9__1280x720),
//                            //                        @(CNCResolution_16_9__1920x1080),
//                            nil];
//    }
    
    self.array_video_resolution = [NSArray arrayWithObjects:
                                   @"360P 4:3",
                                   @"360P 16:9",
                                   @"480P 4:3",
                                   @"480P 16:9",
                                   @"540P 4:3",
                                   @"540P 16:9",
                                   @"720P 4:3",
                                   @"720P 16:9",
//                                   @"高级自定义",
                                   
                                   nil];
    self.array_value_video_resolution = [NSArray arrayWithObjects:
                                         
                                         @(CNCVideoResolution_360P_4_3),
                                         @(CNCVideoResolution_360P_16_9),
                                         @(CNCVideoResolution_480P_4_3),
                                         @(CNCVideoResolution_480P_16_9),
                                         @(CNCVideoResolution_540P_4_3),
                                         @(CNCVideoResolution_540P_16_9),
                                         @(CNCVideoResolution_720P_4_3),
                                         @(CNCVideoResolution_720P_16_9),
//                                         @(99999),
                                         
                                         nil];
    
    
    self.cur_idx = 0;
    
    self.cur_idx_video = 2;
    
    if (self.is_fu) {
         self.array_video_resolution = [NSArray arrayWithObjects:
//                                           @"360P 4:3",
//                                           @"360P 16:9",
                                           @"480P 4:3",
                                           @"480P 16:9",
//                                           @"540P 4:3",
//                                           @"540P 16:9",
                                           @"720P 4:3",
                                           @"720P 16:9",
        //                                   @"高级自定义",
                                           
                                           nil];
            self.array_value_video_resolution = [NSArray arrayWithObjects:
                                                 
//                                                 @(CNCVideoResolution_360P_4_3),
//                                                 @(CNCVideoResolution_360P_16_9),
                                                 @(CNCVideoResolution_480P_4_3),
                                                 @(CNCVideoResolution_480P_16_9),
//                                                 @(CNCVideoResolution_540P_4_3),
//                                                 @(CNCVideoResolution_540P_16_9),
                                                 @(CNCVideoResolution_720P_4_3),
                                                 @(CNCVideoResolution_720P_16_9),
        //                                         @(99999),
                                                 
                                                 nil];
        self.cur_idx_video = 0;
    }
    
    CGFloat height = 40;
    
    {
        self.use_recommend_video_resolution = YES;
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(_screenWidth/3.0, _currentUIMaxY, _screenWidth/3.0, height);
        [btn setTitle:[self.array_video_resolution objectAtIndex:self.cur_idx_video] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(action_set_video_resolution:) forControlEvents:UIControlEventTouchUpInside];
        btn.tag = 1009;
        [self.view addSubview:btn];
        btn.tag = 1009;
    }
    
//    _currentUIMaxY += height;
//    {
//        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
//        btn.frame = CGRectMake(_screenWidth/3.0, _currentUIMaxY, _screenWidth/3.0, height);
//        [btn setTitle:[self.array objectAtIndex:self.cur_idx] forState:UIControlStateNormal];
//        [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
//        [btn addTarget:self action:@selector(action_switch_w_x_h:) forControlEvents:UIControlEventTouchUpInside];
//        [self.view addSubview:btn];
//        btn.tag = 1001;
//        
//        btn.hidden = self.use_recommend_video_resolution;
//        [self set_def_w_x_h];
//    }
    
    _currentUIMaxY += height;
 
    {
        self.array_format = [NSArray arrayWithObjects:
                             @"I420",
                             @"NV12",
                             @"NV21",
                             @"BGRA",
                             
                             nil];
        self.array_value_format = [NSArray arrayWithObjects:
                                   @(1),
                                   @(2),
                                   @(3),
                                   @(4),
                                   nil];
        
        
        self.cur_idx_format = 1;
    }
    
//    {
//        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
//        btn.frame = CGRectMake(100, _currentUIMaxY, _screenWidth-200, height);
//        [btn setTitle:[self.array_format objectAtIndex:self.cur_idx_format] forState:UIControlStateNormal];
//        [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
//        [btn addTarget:self action:@selector(action_set_format:) forControlEvents:UIControlEventTouchUpInside];
//        [self.view addSubview:btn];
//        btn.tag = 1011;
//        
//    }
    
    _currentUIMaxY += height;
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(100, _currentUIMaxY, _screenWidth-200, 50);
        [btn setTitle:@"开始录制" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(action_start:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
    
    _currentUIMaxY += 50;
    {
        CGRect rect = CGRectMake(20, _currentUIMaxY, 140, 30);
        UILabel *label = [[[UILabel alloc]init] autorelease];
        label.frame = rect;
        label.text = @"后台继续推拉流：";
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor blackColor];
        label.font = [UIFont systemFontOfSize:15.f];
        [self.view addSubview:label];
        
        rect = CGRectMake(160, _currentUIMaxY, 160, 30);
        UISwitch *continuePushSwitch = [[[UISwitch alloc] initWithFrame:rect] autorelease];
        //        BOOL bPushInBk = [CNCMobStreamSDK isContinuePushInBk];
        BOOL bPushInBk = self.stream_para.need_push_audio_BG;
        [continuePushSwitch setSelected:bPushInBk];
        [continuePushSwitch setOn:bPushInBk];
        [continuePushSwitch addTarget:self action:@selector(actionOpenOrClosePushInBk:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:continuePushSwitch];
    }
}

- (void)action_set_format:(UIButton *)btn {
    //初始化AlertView
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@""
                                                     message:@""
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:nil] autorelease];
    //设置标题与信息，通常在使用frame初始化AlertView时使用
    alert.title = @"选择输入格式";
    //    alert.message = @"AlertViewMessage";
    
    //这个属性继承自UIView，当一个视图中有多个AlertView时，可以用这个属性来区分
    alert.tag = 9;
    //只读属性，看AlertView是否可见
    NSLog(@"%d",alert.visible);
    //通过给定标题添加按钮
    
    for (NSString *s in self.array_format) {
        [alert addButtonWithTitle:s];
    }
    
    //显示AlertView
    [alert show];
    //    [alert release];
}
#pragma mark - action
- (void)action_set_video_resolution:(UIButton *)btn {
    //初始化AlertView
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                    message:@""
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:nil];
    //设置标题与信息，通常在使用frame初始化AlertView时使用
    alert.title = @"选择输出视频分辨率";
    //    alert.message = @"AlertViewMessage";
    
    //这个属性继承自UIView，当一个视图中有多个AlertView时，可以用这个属性来区分
    alert.tag = 6;
    //只读属性，看AlertView是否可见
    NSLog(@"%d",alert.visible);
    //通过给定标题添加按钮
    
    for (NSString *s in self.array_video_resolution) {
        [alert addButtonWithTitle:s];
    }
    
    //显示AlertView
    [alert show];
    [alert release];
}

//- (void)set_def_w_x_h {
//    CNCResolutionType type = [[self.array_value objectAtIndex:self.cur_idx] integerValue];
//    
//    switch (type) {
//        case CNCResolution_4_3__640x480: {
//            self.def_width = 640;
//            self.def_height = 480;
//        }
//            break;
//        case CNCResolution_5_4__352x288: {
//            self.def_width = 352;
//            self.def_height = 288;
//        }
//            break;
//        case CNCResolution_16_9__960x540: {
//            self.def_width = 960;
//            self.def_height = 540;
//            
//        }
//            break;
//        case CNCResolution_16_9__1280x720: {
//            self.def_width = 1280;
//            self.def_height = 720;
//            
//        }
//            break;
//        case CNCResolution_16_9__1920x1080: {
//            self.def_width = 1920;
//            self.def_height = 1080;
//        }
//            break;
//        default: {
//            self.def_width = 640;
//            self.def_height = 480;
//            
//        }
//            break;
//    }
//    
//    self.width_textField.text = [NSString stringWithFormat:@"%@", @(self.def_width)];
//    self.height_textField.text = [NSString stringWithFormat:@"%@", @(self.def_height)];
//    
//}

//- (void)action_switch_w_x_h:(UIButton *)btn {
//    //初始化AlertView
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
//                                                    message:@""
//                                                   delegate:self
//                                          cancelButtonTitle:@"Cancel"
//                                          otherButtonTitles:nil];
//    //设置标题与信息，通常在使用frame初始化AlertView时使用
//    alert.title = @"选择分辨率";
//    //    alert.message = @"AlertViewMessage";
//    
//    //这个属性继承自UIView，当一个视图中有多个AlertView时，可以用这个属性来区分
//    alert.tag = 0;
//    //只读属性，看AlertView是否可见
//    NSLog(@"%d",alert.visible);
//    //通过给定标题添加按钮
//    
//    for (NSString *s in self.array) {
//        [alert addButtonWithTitle:s];
//    }
//    
//    //显示AlertView
//    [alert show];
//    [alert release];
//}

#ifdef CNC_NewInterface
#else
- (void)action_start:(UIButton *)btn {
    
    NSString *rtmp_name = self.rtmp_address_inputTF.text;
    [self.rtmp_address_inputTF resignFirstResponder];
    
    if (rtmp_name.length>0) {
        [[NSUserDefaults standardUserDefaults] setObject:rtmp_name forKey:@"stream_name_cache"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    NSString * resolution = [self.array_video_resolution objectAtIndex:self.cur_idx_video];

    self.stream_para.rtmp_url = rtmp_name;
    self.stream_para.encoder_type = self.encoder_type;
    self.stream_para.video_bit_rate = self.video_bit_rate;
    self.stream_para.video_fps = self.video_frame_rate;
    self.stream_para.has_video = YES;
    
    NSInteger w = 0;
    NSInteger h = 0;
    [self get_w:&w h:&h resolution:resolution direct:self.direct_type];
    
    self.stream_para.video_height = h;
    self.stream_para.video_width = w;
    
    self.capture_info.camera_position = self.came_pos;
    self.capture_info.direction = self.direct_type;
    self.capture_info.video_fps = self.video_frame_rate;
    self.capture_info.capture_width = w;
    self.capture_info.capture_height = h;
    self.capture_info.format_type = self.cur_idx_format;
    self.capture_info.encoder_type = self.encoder_type;
    
    if (self.came_sel_type == 2) {
        self.stream_para.has_video = NO;
    }
    
    if (self.is_fu) {
#ifdef CNC_DEMO_FU
        CNCVideoLayeredViewControllerFU *vc = [[[CNCVideoLayeredViewControllerFU alloc] init] autorelease];
        vc.stream_cfg = self.stream_para;
        vc.capture_info = self.capture_info;
        vc.sw_encoder_priority_type = self.sw_encoder_priority_type;
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:vc animated:YES completion:^(){
            
        }];
#endif
    } else {
        CNCVideoLayeredViewController *vc = [[[CNCVideoLayeredViewController alloc] init] autorelease];
        vc.stream_cfg = self.stream_para;
        vc.capture_info = self.capture_info;
        vc.sw_encoder_priority_type = self.sw_encoder_priority_type;
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:vc animated:YES completion:^(){
            
        }];
    }
//    
//    
//     if (self.came_sel_type == 3) {
//#ifdef CNC_DEMO_FU
//        CNCVideoLayeredViewControllerFU *vc = [[[CNCVideoLayeredViewControllerFU alloc] init] autorelease];
//         vc.stream_cfg = self.stream_para;
//         vc.capture_info = self.capture_info;
//         vc.sw_encoder_priority_type = self.sw_encoder_priority_type;
//         vc.modalPresentationStyle = UIModalPresentationFullScreen;
//         [self presentViewController:vc animated:YES completion:^(){
//             
//         }];
//#else
//    #ifdef CNC_DEMO_ST
//        CNCVideoLayeredViewControllerST *vc = [[[CNCVideoLayeredViewControllerST alloc] init] autorelease];
//         vc.stream_cfg = self.stream_para;
//         vc.capture_info = self.capture_info;
//         vc.sw_encoder_priority_type = self.sw_encoder_priority_type;
//         vc.modalPresentationStyle = UIModalPresentationFullScreen;
//         [self presentViewController:vc animated:YES completion:^(){
//             
//         }];
//    #endif
//#endif
//        
//    }
//    else if (self.came_sel_type == 4) {
//#ifdef CNC_DEMO_ST
//        CNCVideoLayeredViewControllerST *vc = [[[CNCVideoLayeredViewControllerST alloc] init] autorelease];
//        vc.stream_cfg = self.stream_para;
//        vc.capture_info = self.capture_info;
//        vc.sw_encoder_priority_type = self.sw_encoder_priority_type;
//        vc.modalPresentationStyle = UIModalPresentationFullScreen;
//        [self presentViewController:vc animated:YES completion:^(){
//            
//        }];
//#endif
//        
//    } else {
//        if (self.came_sel_type == 2) {
//            self.stream_para.has_video = NO;
//        }
//        
//       CNCVideoLayeredViewController *vc = [[[CNCVideoLayeredViewController alloc] init] autorelease];
//        vc.stream_cfg = self.stream_para;
//        vc.capture_info = self.capture_info;
//        vc.sw_encoder_priority_type = self.sw_encoder_priority_type;
//        vc.modalPresentationStyle = UIModalPresentationFullScreen;
//        [self presentViewController:vc animated:YES completion:^(){
//            
//        }];
//    }
    
}
#endif
- (void)get_w:(NSInteger *)pw h:(NSInteger *)ph resolution:(NSString *)resolution direct:(NSInteger)direct {
    NSInteger tmp_w = -1;
    NSInteger tmp_h = -1;
    
    
    if ([resolution isEqualToString:@"360P 4:3"]) {
        tmp_w = 480;
        tmp_h = 360;
    } else if ([resolution isEqualToString:@"360P 16:9"]) {
        tmp_w = 640;
        tmp_h = 360;
    } else if ([resolution isEqualToString:@"480P 4:3"]) {
        tmp_w = 640;
        tmp_h = 480;
    } else if ([resolution isEqualToString:@"480P 16:9"]) {
        tmp_w = 854;
        tmp_h = 480;
    } else if ([resolution isEqualToString:@"540P 4:3"]) {
        tmp_w = 720;
        tmp_h = 540;
    } else if ([resolution isEqualToString:@"540P 16:9"]) {
        tmp_w = 960;
        tmp_h = 540;
    } else if ([resolution isEqualToString:@"720P 4:3"]) {
        tmp_w = 960;
        tmp_h = 720;
    } else if ([resolution isEqualToString:@"720P 16:9"]) {
        tmp_w = 1280;
        tmp_h = 720;
    } else if ([resolution isEqualToString:@"360P 4:3"]) {
        tmp_w = 352;
        tmp_h = 288;
    } else if ([resolution isEqualToString:AVCaptureSessionPreset352x288]) {
        tmp_w = 352;
        tmp_h = 288;
    } else if ([resolution isEqualToString:AVCaptureSessionPreset640x480]) {
        tmp_w = 640;
        tmp_h = 480;
    } else if ([resolution isEqualToString:AVCaptureSessionPresetiFrame960x540]) {
        tmp_w = 960;
        tmp_h = 540;
    } else if ([resolution isEqualToString:AVCaptureSessionPreset1280x720]) {
        tmp_w = 1280;
        tmp_h = 720;
    } else {
        
    }
    
    if (direct == CNC_ENM_Direct_Vertical) {
        //        int tmp = tmp_w;
        //        tmp_w = tmp_h;
        //        tmp_h = tmp_w;
        
        tmp_w = tmp_h + tmp_w;
        tmp_h = tmp_w - tmp_h;
        tmp_w = tmp_w - tmp_h;
    }
    
    if (pw != NULL) {
        *pw = tmp_w;
    }
    
    if (ph != NULL) {
        *ph = tmp_h;
    }
    
}

- (void)actionOpenOrClosePushInBk:(UISwitch *)sender {
    
    sender.selected = !sender.isSelected;
    ///设置为可以在后台继续（推流或拉流）音频，不断开链接；
    ///此方法需要在info.list里面添加<UIBackgroundModes:audio>
    ///或打开Capabilities的Background Modes开关，勾选audio选项
    ///如需切到后台时静音推流，请监听UIApplicationWillResignActiveNotification事件，
    ///并在回调方法里面调用[CNCMobStreamSDK set_muted_statu:YES]
//    [CNCMobStreamSDK set_whether_continue_push_inBk:sender.isSelected];
    self.stream_para.need_push_audio_BG = sender.isSelected;
    
}



#pragma mark - UIAlertViewDelegate
//根据被点击按钮的索引处理点击事件
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 0) {
//        if (buttonIndex > 0) {
//            NSString *s = [self.array objectAtIndex:buttonIndex-1];
//            UIButton *btn = [self.view viewWithTag:1001];
//            [btn setTitle:s forState:UIControlStateNormal];
//            NSInteger new_idx = buttonIndex-1;
//            if (new_idx != self.cur_idx) {
//                self.cur_idx = new_idx;
//                [self set_def_w_x_h];
//            }
//            
//        }
    } else  if (alertView.tag == 1) {
        //        if (buttonIndex > 0) {
        //            NSString *s = [self.array_scale objectAtIndex:buttonIndex-1];
        //            UIButton *btn = [self.view viewWithTag:2001];
        //            [btn setTitle:s forState:UIControlStateNormal];
        //            self.cur_scale_idx = buttonIndex-1;
        //        }
    } else if (alertView.tag == 6) {
        if (buttonIndex > 0) {
            NSString *s = [self.array_video_resolution objectAtIndex:buttonIndex-1];
            UIButton *btn = [self.view viewWithTag:1009];
            [btn setTitle:s forState:UIControlStateNormal];
            NSInteger new_idx = buttonIndex-1;
            if (new_idx != self.cur_idx_video) {
                self.cur_idx_video = new_idx;
            }
            
            if (new_idx == [self.array_video_resolution count]-1) {
                self.use_recommend_video_resolution = NO;
                //                self.width_textField.hidden = NO;
                //                self.height_textField.hidden = NO;
            } else {
                self.use_recommend_video_resolution = YES;
                //                self.need_custom_w_x_h = NO;
                //                UIButton *btn = (id)[self.view viewWithTag:6001];
                //                [btn setTitle:@"默认宽高" forState:UIControlStateNormal];
                //                self.width_textField.hidden = YES;
                //                self.height_textField.hidden = YES;
            }
            
            UIButton *btn2 = [self.view viewWithTag:1001];
            UIButton *btn3 = [self.view viewWithTag:6001];
            btn2.hidden = self.use_recommend_video_resolution;
            btn3.hidden = self.use_recommend_video_resolution;
            
        }
    } else if (alertView.tag == 9) {
        if (buttonIndex > 0) {
            NSString *s = [self.array_format objectAtIndex:buttonIndex-1];
            UIButton *btn = [self.view viewWithTag:1011];
            [btn setTitle:s forState:UIControlStateNormal];
            NSInteger new_idx = buttonIndex-1;
            if (new_idx != self.cur_idx_format) {
                self.cur_idx_format = new_idx;
            }
        }
    }
    
    
}

#pragma mark - 保持竖屏
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate {
    return NO;
}

#pragma mark dealloc
- (void)dealloc {
//    
//    self.array = nil;
//    self.array_value = nil;
    self.array_value_video_resolution = nil;
    [self.width_textField removeFromSuperview];
    self.width_textField = nil;
    [self.height_textField removeFromSuperview];
    self.height_textField = nil;
    self.array_video_resolution = nil;
    self.stream_para = nil;
    self.array_value_format = nil;
    self.array_format = nil;
    self.capture_info = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - new interface
#ifdef CNC_NewInterface

- (void)set_new_interface_view {
    [self create_view];
    self.array_video_resolution = [NSArray arrayWithObjects:
                                   @"360P 4:3",
                                   @"360P 16:9",
                                   @"480P 4:3",
                                   @"480P 16:9",
                                   @"540P 4:3",
                                   @"540P 16:9",
                                   @"720P 4:3",
                                   @"720P 16:9",
                                   //                                   @"高级自定义",
                                   
                                   nil];
    self.array_value_video_resolution = [NSArray arrayWithObjects:
                                         
                                         @(CNCVideoResolution_360P_4_3),
                                         @(CNCVideoResolution_360P_16_9),
                                         @(CNCVideoResolution_480P_4_3),
                                         @(CNCVideoResolution_480P_16_9),
                                         @(CNCVideoResolution_540P_4_3),
                                         @(CNCVideoResolution_540P_16_9),
                                         @(CNCVideoResolution_720P_4_3),
                                         @(CNCVideoResolution_720P_16_9),
                                         //                                         @(99999),
                                         
                                         nil];
    self.cur_idx = 0;
    
    self.cur_idx_video = 2;
    
    CGFloat height = 40;
    
    {
        self.use_recommend_video_resolution = YES;
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(_screenWidth/3.0, _currentUIMaxY, _screenWidth/3.0, height);
        [btn setTitle:[self.array_video_resolution objectAtIndex:self.cur_idx_video] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(action_set_video_resolution:) forControlEvents:UIControlEventTouchUpInside];
        btn.tag = 1009;
        [self.scrollView addSubview:btn];
        btn.tag = 1009;
    }

    _currentUIMaxY += height+10;
    
    [self infrastrucnture_init_start_btn];
    _currentUIMaxY += 40;
    {
        CGRect rect = CGRectMake(20, _currentUIMaxY, 140, 30);
        UILabel *label = [[[UILabel alloc]init] autorelease];
        label.frame = rect;
        label.text = @"后台继续推拉流：";
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor blackColor];
        label.font = [UIFont systemFontOfSize:15.f];
        [self.scrollView addSubview:label];
        
        rect = CGRectMake(160, _currentUIMaxY, 160, 30);
        UISwitch *continuePushSwitch = [[[UISwitch alloc] initWithFrame:rect] autorelease];
        //        BOOL bPushInBk = [CNCMobStreamSDK isContinuePushInBk];
        BOOL bPushInBk = self.stream_para.need_push_audio_BG;
        [continuePushSwitch setSelected:bPushInBk];
        [continuePushSwitch setOn:bPushInBk];
        [continuePushSwitch addTarget:self action:@selector(actionOpenOrClosePushInBk:) forControlEvents:UIControlEventValueChanged];
        [self.scrollView addSubview:continuePushSwitch];
    }
    
}
- (void)action_start_btn:(UIButton *)sender {
    
    if (!sender.isUserInteractionEnabled) {
        return;
    }
    [self textField_resignFirstResponder];
    {
        NSString *tmp = self.rtmp_stream_name_TF.text;
        tmp = [tmp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (tmp == nil || [tmp length] == 0) {
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"" message:@"请输入有效流名" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil] autorelease];
            [alert show];
            return;
        }
        
    }
    
    NSString *rtmp_name = [NSString stringWithFormat:@"rtmp://%@/%@/%@",self.push_domain_name,self.publishing_point_str,self.rtmp_stream_name_TF.text];
    rtmp_name = [rtmp_name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    
    if (rtmp_name == nil || [rtmp_name length] == 0) {
        
    } else {
        self.stream_para.rtmp_url = rtmp_name;
        [[CNCAppUserDataMng instance] set_push_url:rtmp_name];
    }
    
    NSString * resolution = [self.array_video_resolution objectAtIndex:self.cur_idx_video];
    
    
    self.stream_para.encoder_type = self.encoder_type;
    self.stream_para.video_bit_rate = self.video_bit_rate;
    self.stream_para.video_fps = self.video_frame_rate;
    self.stream_para.has_video = YES;
    
    NSInteger w = 0;
    NSInteger h = 0;
    [self get_w:&w h:&h resolution:resolution direct:self.direct_type];
    
    self.stream_para.video_height = h;
    self.stream_para.video_width = w;
    
    self.capture_info.camera_position = self.came_pos;
    self.capture_info.direction = self.direct_type;
    self.capture_info.video_fps = self.video_frame_rate;
    self.capture_info.capture_width = w;
    self.capture_info.capture_height = h;
    self.capture_info.format_type = self.cur_idx_format;
    self.capture_info.encoder_type = self.encoder_type;
    
    if (self.came_sel_type == 2) {
        self.stream_para.has_video = NO;
    }
//    came_sel_type
#ifdef CNC_DEMO_FU
    CNCVideoLayeredViewControllerFU *vc = [[[CNCVideoLayeredViewControllerFU alloc] init] autorelease];
#else
    CNCVideoLayeredViewController *vc = [[[CNCVideoLayeredViewController alloc] init] autorelease];
#endif
    
    vc.stream_cfg = self.stream_para;
    vc.capture_info = self.capture_info;
    vc.sw_encoder_priority_type = self.sw_encoder_priority_type;
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:^(){
        
    }];
    
}
#else
#endif
@end
