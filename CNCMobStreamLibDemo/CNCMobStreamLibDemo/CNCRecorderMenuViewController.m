//
//  CNCRecorderMenuViewController.m
//  CNCIJKPlayerDemo
//
//  Created by mfm on 16/5/12.
//  Copyright © 2016年 cad. All rights reserved.
//

#import "CNCRecorderMenuViewController.h"
#import "CNCVideoRecordViewController.h"
#import "ProxyConfigViewController.h"
#import <AVFoundation/AVFoundation.h>



@interface CNCRecorderMenuViewController () {
    
}

@property (nonatomic, retain) ProxyConfigViewController *proxyViewController;

@end

@implementation CNCRecorderMenuViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"推流测试";
    
    ///视频分辨率数组
    self.array_video_resolution = [NSArray arrayWithObjects:
                                   @"360P 4:3",
                                   @"360P 16:9",
                                   @"480P 4:3",
                                   @"480P 16:9",
                                   @"540P 4:3",
                                   @"540P 16:9",
                                   @"720P 4:3",
                                   @"720P 16:9",
                                   @"高级自定义",
                                   nil];
    ///分辨率-type 映射
    self.array_value_video_resolution = [NSArray arrayWithObjects:
                                         @(CNCVideoResolution_360P_4_3),
                                         @(CNCVideoResolution_360P_16_9),
                                         @(CNCVideoResolution_480P_4_3),
                                         @(CNCVideoResolution_480P_16_9),
                                         @(CNCVideoResolution_540P_4_3),
                                         @(CNCVideoResolution_540P_16_9),
                                         @(CNCVideoResolution_720P_4_3),
                                         @(CNCVideoResolution_720P_16_9),
                                         @(99999),nil];

    NSString *app_id = [[NSUserDefaults standardUserDefaults] objectForKey:@"CNCMobSteamSDK_App_ID"];
    if([app_id isEqualToString:@"wstest001"]) {
        self.array = [NSArray arrayWithObjects:
                      @"640*480",
                      @"352x288",
                      @"960*540",
                      @"1280*720",
//                                        @"1920x1080",
                      //@"3840x2160",
                      nil];
        
        self.array_value = [NSArray arrayWithObjects:
                            @(CNCResolution_4_3__640x480),
                            @(CNCResolution_5_4__352x288),
                            @(CNCResolution_16_9__960x540),
                            @(CNCResolution_16_9__1280x720),
//                                                    @(CNCResolution_16_9__1920x1080),
                            nil];
    } else {
        self.array = [NSArray arrayWithObjects:
                      @"640*480",
                      //                  @"352x288",
                      //                  @"960*540",
                      @"1280*720",
                      //                  @"1920x1080",
                      //@"3840x2160",
                      nil];
        self.array_value = [NSArray arrayWithObjects:
                            @(CNCResolution_4_3__640x480),
                            //                        @(CNCResolution_5_4__352x288),
                            //                        @(CNCResolution_16_9__960x540),
                            @(CNCResolution_16_9__1280x720),
                            //                        @(CNCResolution_16_9__1920x1080),
                            nil];
    }
    
    self.cur_idx = 0;
    
    self.cur_idx_video = 2;
    
    CGFloat height= 40;
    {
        self.use_recommend_video_resolution = YES;
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(_screenWidth/8.0, _currentUIMaxY, _screenWidth/4.0, height);
        [btn setTitle:[self.array_video_resolution objectAtIndex:self.cur_idx_video] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(action_set_video_resolution:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
        btn.tag = 1009;
        
        
    }
    
    {
        //镜像设置
        self.cur_mirror_idx = 0;
        self.array_mirror = [NSArray arrayWithObjects:
                             @"默认镜像设置",
                             @"预览:Y 编码:Y",
                             @"预览:Y 编码:N",
                             @"预览:N 编码:N",
                             @"预览:N 编码:Y",
                             nil];
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(_screenWidth/2, _currentUIMaxY, 3*_screenWidth/8, height);
        [btn setTitle:[self.array_mirror objectAtIndex:self.cur_mirror_idx] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(action_set_mirror:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
        btn.tag = 2006;
        
    }
    
    _currentUIMaxY += height;
    
    {
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(_screenWidth/8.0, _currentUIMaxY, _screenWidth/4.0, height);
        [btn setTitle:[self.array objectAtIndex:self.cur_idx] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(action_switch_w_x_h:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
        btn.tag = 1001;
        
        btn.hidden = self.use_recommend_video_resolution;
        [self set_def_w_x_h];
    }
    
    
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
        CGRect rect = CGRectMake(20, _currentUIMaxY, 80, 30);
        UILabel *label = [[[UILabel alloc]init] autorelease];
        label.frame = rect;
        label.text = @"后台推流：";
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor blackColor];
        label.font = [UIFont systemFontOfSize:15.f];
        [self.view addSubview:label];
        
        rect = CGRectMake(100, _currentUIMaxY, 40, 30);
        UISwitch *continuePushSwitch = [[[UISwitch alloc] initWithFrame:rect] autorelease];
        BOOL bPushInBk = [CNCMobStreamSDK isContinuePushInBk];
        [continuePushSwitch setSelected:bPushInBk];
        [continuePushSwitch setOn:bPushInBk];
        [continuePushSwitch addTarget:self action:@selector(actionOpenOrClosePushInBk:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:continuePushSwitch];
    }
    
    {
        CGRect rect = CGRectMake(170, _currentUIMaxY, 90, 30);
        UILabel *label = [[[UILabel alloc]init] autorelease];
        label.frame = rect;
        label.text = @"Socket5：";
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor blackColor];
        label.font = [UIFont systemFontOfSize:15.f];
        [self.view addSubview:label];
        
        rect = CGRectMake(260, _currentUIMaxY, 40, 30);
        UISwitch *continuePushSwitch = [[[UISwitch alloc] initWithFrame:rect] autorelease];
        BOOL bPushInBk = [CNCMobStreamSDK isUseSocks5Push];
        [continuePushSwitch setSelected:bPushInBk];
        [continuePushSwitch setOn:bPushInBk];
        [continuePushSwitch addTarget:self action:@selector(actionOpenOrcloseSocks5:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:self.socketSwitch = continuePushSwitch];
    }
    
}

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



- (void)set_def_w_x_h {
    CNCResolutionType type = [[self.array_value objectAtIndex:self.cur_idx] integerValue];
    
    switch (type) {
        case CNCResolution_4_3__640x480: {
            self.def_width = 640;
            self.def_height = 480;
        }
            break;
        case CNCResolution_5_4__352x288: {
            self.def_width = 352;
            self.def_height = 288;
        }
            break;
        case CNCResolution_16_9__960x540: {
            self.def_width = 960;
            self.def_height = 540;
            
        }
            break;
        case CNCResolution_16_9__1280x720: {
            self.def_width = 1280;
            self.def_height = 720;
            
        }
            break;
        case CNCResolution_16_9__1920x1080: {
            self.def_width = 1920;
            self.def_height = 1080;
        }
            break;
        default: {
            self.def_width = 640;
            self.def_height = 480;
            
        }
            break;
    }
    
    self.width_textField.text = [NSString stringWithFormat:@"%@", @(self.def_width)];
    self.height_textField.text = [NSString stringWithFormat:@"%@", @(self.def_height)];
    
}

- (void)action_switch_w_x_h:(UIButton *)btn {
    //初始化AlertView
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                    message:@""
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:nil];
    //设置标题与信息，通常在使用frame初始化AlertView时使用
    alert.title = @"选择分辨率";
    //    alert.message = @"AlertViewMessage";
    
    //这个属性继承自UIView，当一个视图中有多个AlertView时，可以用这个属性来区分
    alert.tag = 0;
    //只读属性，看AlertView是否可见
    NSLog(@"%d",alert.visible);
    //通过给定标题添加按钮
    
    for (NSString *s in self.array) {
        [alert addButtonWithTitle:s];
    }
    
    //显示AlertView
    [alert show];
    [alert release];
}


- (void)action_set_mirror:(UIButton *)btn {
    //初始化AlertView
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                    message:@""
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:nil];
    //设置标题与信息，通常在使用frame初始化AlertView时使用
    alert.title = @"选择镜像设置";
    //    alert.message = @"AlertViewMessage";
    
    //这个属性继承自UIView，当一个视图中有多个AlertView时，可以用这个属性来区分
    alert.tag = 996;
    //只读属性，看AlertView是否可见
    NSLog(@"%d",alert.visible);
    //通过给定标题添加按钮
    
    for (NSString *s in self.array_mirror) {
        [alert addButtonWithTitle:s];
    }
    
    //显示AlertView
    [alert show];
    [alert release];
}

#pragma marks -- UIAlertViewDelegate --
//根据被点击按钮的索引处理点击事件
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 0) {
        if (buttonIndex > 0) {
            NSString *s = [self.array objectAtIndex:buttonIndex-1];
            UIButton *btn = [self.view viewWithTag:1001];
            [btn setTitle:s forState:UIControlStateNormal];
            NSInteger new_idx = buttonIndex-1;
            if (new_idx != self.cur_idx) {
                self.cur_idx = new_idx;
                [self set_def_w_x_h];
            }
            
        }
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
    } else if (alertView.tag == 996) {
        
        if (buttonIndex > 0) {
            NSString *s = [self.array_mirror objectAtIndex:buttonIndex-1];
            UIButton *btn = [self.view viewWithTag:2006];
            [btn setTitle:s forState:UIControlStateNormal];
            NSInteger new_idx = buttonIndex-1;
            self.cur_mirror_idx = new_idx;
        }
    }

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)action_start:(UIButton *)btn {
    
    [self.rtmp_address_inputTF resignFirstResponder];

    NSString *rtmp_name = self.rtmp_address_inputTF.text;

    if (rtmp_name.length>0) {
        [[NSUserDefaults standardUserDefaults] setObject:rtmp_name forKey:@"stream_name_cache"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
 
    CNCStreamCfg *para = [[[CNCStreamCfg alloc] init] autorelease];
    para.rtmp_url = rtmp_name;
    para.encoder_type = self.encoder_type;
    para.camera_position = self.came_pos;
    para.direction = self.direct_type;
    para.video_bit_rate = self.video_bit_rate;
    para.video_fps = self.video_frame_rate;
    
    if (self.came_sel_type == 2) {
        para.has_video = NO;
    }
    if (self.use_recommend_video_resolution) {
        CNCVideoResolutionType video_resolution_type = [[self.array_value_video_resolution objectAtIndex:self.cur_idx_video] integerValue];
        [para set_video_resolution_type:video_resolution_type];
    } else {
        CNCResolutionType resolution_type = [[self.array_value objectAtIndex:self.cur_idx] integerValue];
        
        [para set_camera_resolution_type:resolution_type];
    }
    
    [self textField_resignFirstResponder];
    
    CNCVideoRecordViewController *vc = [[[CNCVideoRecordViewController alloc] init] autorelease];
    vc.stream_cfg = para;
    vc.sw_encoder_priority_type = self.sw_encoder_priority_type;
    vc.mirror_idx = self.cur_mirror_idx;
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:vc animated:YES completion:^(){
        
    }];
}

- (void)textField_resignFirstResponder {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.rtmp_address_inputTF resignFirstResponder];

        [self.width_textField resignFirstResponder];
        [self.height_textField resignFirstResponder];
    });
}



- (void)actionOpenOrClosePushInBk:(UISwitch *)sender {
    
    sender.selected = !sender.isSelected;
    ///设置为可以在后台继续（推流或拉流）音频，不断开链接；
    ///此方法需要在info.list里面添加<UIBackgroundModes:audio>
    ///或打开Capabilities的Background Modes开关，勾选audio选项
    ///如需切到后台时静音推流，请监听UIApplicationWillResignActiveNotification事件，
    ///并在回调方法里面调用[CNCMobStreamSDK set_muted_statu:YES]
    [CNCMobStreamSDK set_whether_continue_push_inBk:sender.isSelected];
    
}

- (void)actionOpenOrcloseSocks5:(UISwitch *)sender {

    if (sender.isOn) {
        
        if (self.proxyViewController == nil) {
            self.proxyViewController = [[[ProxyConfigViewController alloc] initWithNibName:@"ProxyConfigViewController" bundle:nil] autorelease];
        }
        self.proxyViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:self.proxyViewController animated:YES completion:nil];
    } else {
        [CNCMobStreamSDK closeSocks5];
    }
}




- (void)handleTapGesture:(id)sender {
    NSLog(@"handleTapGesture");
//    [self.textfield resignFirstResponder];
    [self textField_resignFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated {
    [self.socketSwitch setOn:[CNCMobStreamSDK isUseSocks5Push] animated:YES];
    
    [super viewDidAppear:animated];
}


- (void)dealloc {
    
    self.array_encode_way = nil;
    self.array_camera_side = nil;
    self.array_camera_direction = nil;
    self.array_bit_rate = nil;
    self.array_frame_rate = nil;
    
    self.rtmp_address_inputTF = nil;
    self.array = nil;
    self.array_value = nil;
    
    self.array_value_video_resolution = nil;
    [self.width_textField removeFromSuperview];
    self.width_textField = nil;
    [self.height_textField removeFromSuperview];
    self.height_textField = nil;
    self.array_video_resolution = nil;
    
    self.rtmp_config_pickview = nil;
    self.proxyViewController = nil;
    self.socketSwitch = nil;
    [super dealloc];
}

#pragma mark - 保持竖屏
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate {
    return NO;
}

@end
