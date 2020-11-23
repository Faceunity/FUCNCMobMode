//
//  CNCDemoVideoCaptureMenuViewController.m
//  CNCMobStreamDemo
//
//  Created by mfm on 16/12/20.
//  Copyright © 2016年 cad. All rights reserved.
//

#import "CNCDemoVideoCaptureMenuViewController.h"

#import <AVFoundation/AVFoundation.h>
#import "CommonInclude.h"


#import "CNCVideoRecordViewController.h"
#import "CNCDemoVideoCaptureViewController.h"


@interface CNCDemoVideoCaptureMenuViewController () {
    
}

@property (nonatomic, retain) NSArray *array_came_resolution;
@property (nonatomic, retain) NSArray *array_capture_resolution;
@property (nonatomic, retain) NSArray *array_value;
@property (nonatomic) NSInteger cur_idx_came;

@property (nonatomic, retain) NSArray *array_format;
@property (nonatomic, retain) NSArray *array_value_format;
@property (nonatomic) NSInteger cur_idx_format;
@property (nonatomic) BOOL openOrClosePushInBk;
@property (nonatomic) BOOL adaptive_bit_rate;
@property (nonatomic) BOOL new_format_input;
@end

@implementation CNCDemoVideoCaptureMenuViewController
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.adaptive_bit_rate = NO;
    self.new_format_input = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"分层推流测试";


    CGFloat height= 40;
    {
        self.array_came_resolution = [NSArray arrayWithObjects:
                                      @"352*288",
                                      @"640*480",
                                      @"960*540",
                                      @"1280*720",
                                      
                                      nil];
        self.array_capture_resolution = [NSArray arrayWithObjects:
                                            AVCaptureSessionPreset352x288,
                                            AVCaptureSessionPreset640x480,
                                            AVCaptureSessionPresetiFrame960x540,
                                            AVCaptureSessionPreset1280x720,
                                            
                                            nil];
        
        self.array_value = [NSArray arrayWithObjects:
                            @(CNCResolution_5_4__352x288),
                            @(CNCResolution_4_3__640x480),
                            @(CNCResolution_16_9__960x540),
                            @(CNCResolution_16_9__1280x720),
                            //                                                    @(CNCResolution_16_9__1920x1080),
                            nil];
        
        self.cur_idx_came = 1;
    }
    

    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(_screenWidth/3.0, _currentUIMaxY, _screenWidth/3.0, height);
        [btn setTitle:[self.array_came_resolution objectAtIndex:self.cur_idx_came] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(action_set_video_resolution:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
        btn.tag = 1009;
        
    }
    
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
    
    _currentUIMaxY += height;
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(100, _currentUIMaxY, _screenWidth - 200, height);
        [btn setTitle:[self.array_format objectAtIndex:self.cur_idx_format] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(action_set_format:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
        btn.tag = 1011;
        
    }
    
    _currentUIMaxY += height;
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(100, _currentUIMaxY, _screenWidth-200, height);
        [btn setTitle:@"分层推流测试" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(action_start_video_src_input:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }   
    

    
    _currentUIMaxY += 50;
    {
        self.openOrClosePushInBk = NO;
        CGRect rect = CGRectMake(20, _currentUIMaxY, 120, 30);
        UILabel *label = [[[UILabel alloc]init] autorelease];
        label.frame = rect;
        label.text = @"后台继续推流:";
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor blackColor];
        label.font = [UIFont systemFontOfSize:15.f];
        [self.view addSubview:label];
        
        rect = CGRectMake(140, _currentUIMaxY, 160, 30);
        UISwitch *continuePushSwitch = [[[UISwitch alloc] initWithFrame:rect] autorelease];
        [continuePushSwitch setSelected:NO];
        [continuePushSwitch addTarget:self action:@selector(actionOpenOrClosePushInBk:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:continuePushSwitch];
    }

    _currentUIMaxY += 50;
    {
        self.adaptive_bit_rate = NO;
        CGRect rect = CGRectMake(20, _currentUIMaxY, 120, 30);
        UILabel *label = [[[UILabel alloc]init] autorelease];
        label.frame = rect;
        label.text = @"自适应码率:";
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor blackColor];
        label.font = [UIFont systemFontOfSize:15.f];
        [self.view addSubview:label];
        
        rect = CGRectMake(140, _currentUIMaxY, 160, 30);
        UISwitch *continuePushSwitch = [[[UISwitch alloc] initWithFrame:rect] autorelease];
        [continuePushSwitch setSelected:NO];
        [continuePushSwitch addTarget:self action:@selector(action_adaptive_bit_rate:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:continuePushSwitch];
    }
    _currentUIMaxY += 50;
    {
        self.new_format_input = NO;
        CGRect rect = CGRectMake(20, _currentUIMaxY, 120, 30);
        UILabel *label = [[[UILabel alloc]init] autorelease];
        label.frame = rect;
        label.text = @"新格式输入:";
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor blackColor];
        label.font = [UIFont systemFontOfSize:15.f];
        [self.view addSubview:label];
        
        rect = CGRectMake(140, _currentUIMaxY, 160, 30);
        UISwitch *continuePushSwitch = [[[UISwitch alloc] initWithFrame:rect] autorelease];
        [continuePushSwitch setSelected:NO];
        [continuePushSwitch addTarget:self action:@selector(action_new_format_input:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:continuePushSwitch];
    }
    
    
}

- (void)action_set_video_resolution:(UIButton *)btn {
    //初始化AlertView
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@""
                                                     message:@""
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:nil] autorelease];
    //设置标题与信息，通常在使用frame初始化AlertView时使用
    alert.title = @"选择输出视频分辨率";
    //    alert.message = @"AlertViewMessage";
    
    //这个属性继承自UIView，当一个视图中有多个AlertView时，可以用这个属性来区分
    alert.tag = 6;
    //只读属性，看AlertView是否可见
    NSLog(@"%d",alert.visible);
    //通过给定标题添加按钮
    
    for (NSString *s in self.array_came_resolution) {
        [alert addButtonWithTitle:s];
    }
    
    //显示AlertView
    [alert show];
    //    [alert release];
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



#pragma marks -- UIAlertViewDelegate --
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
            NSString *s = [self.array_came_resolution objectAtIndex:buttonIndex-1];
            UIButton *btn = [self.view viewWithTag:1009];
            [btn setTitle:s forState:UIControlStateNormal];
            NSInteger new_idx = buttonIndex-1;
            if (new_idx != self.cur_idx_came) {
                self.cur_idx_came = new_idx;
            }
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


- (void)action_start_video_src_input:(UIButton *)btn {
    UIViewController *vc;
    
    [self.rtmp_address_inputTF resignFirstResponder];
    NSString *rtmp_name = self.rtmp_address_inputTF.text;
    
    if (rtmp_name.length>0) {
        [[NSUserDefaults standardUserDefaults] setObject:rtmp_name forKey:@"stream_name_cache"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    rtmp_name = [rtmp_name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSString * resolution = [self.array_capture_resolution objectAtIndex:self.cur_idx_came];
    
    CNCVideoSourceCfg *para = [[[CNCVideoSourceCfg alloc] init] autorelease];
    para.rtmp_url = rtmp_name;

    [self.array_capture_resolution objectAtIndex:self.cur_idx_came];
    
    
    para.encoder_type = self.encoder_type;
    para.video_bit_rate = self.video_bit_rate;
    para.video_fps = self.video_frame_rate;
    para.is_adaptive_bit_rate = self.adaptive_bit_rate;
    
    NSInteger w = 0;
    NSInteger h = 0;
    [self get_w:&w h:&h resolution:resolution direct:self.direct_type];
    
    para.video_height = h;
    para.video_width = w;
    if (self.came_sel_type == 2) {
        para.has_video = NO;
    }
    
    CNCDemoVideoCaptureViewController *tmp_vc = [[[CNCDemoVideoCaptureViewController alloc] init] autorelease];
    tmp_vc.para = para;
    tmp_vc.openOrClosePushInBk = self.openOrClosePushInBk;
    tmp_vc.video_direct_type = self.direct_type;
    tmp_vc.came_resolution = resolution;
    tmp_vc.came_sel_type = self.came_sel_type;
    tmp_vc.pixel_format_type = (CNCENM_Buf_Format)[[self.array_value_format objectAtIndex:self.cur_idx_format] integerValue];
    tmp_vc.new_format_input = self.new_format_input;
    tmp_vc.sw_encoder_priority_type = self.sw_encoder_priority_type;
    vc = tmp_vc;
    
    
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:vc animated:YES completion:^(){
        }];
//    });
}

- (void)get_w:(NSInteger *)pw h:(NSInteger *)ph resolution:(NSString *)resolution direct:(NSInteger)direct {
    NSInteger tmp_w = -1;
    NSInteger tmp_h = -1;
    
    
    if ([resolution isEqualToString:AVCaptureSessionPreset352x288]) {
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

- (void)action_adaptive_bit_rate:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    self.adaptive_bit_rate = sender.selected;
}

- (void)action_new_format_input:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    self.new_format_input = sender.selected;
}

- (void)actionOpenOrClosePushInBk:(UISwitch *)sender {
    
    sender.selected = !sender.isSelected;
    self.openOrClosePushInBk = sender.selected;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    
    self.array_came_resolution = nil;
    self.array_capture_resolution = nil;
    self.array_value = nil;
    self.array_format = nil;
    self.array_value_format = nil;
    
    [super dealloc];
}

#pragma mark - 保持竖屏
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


@end
