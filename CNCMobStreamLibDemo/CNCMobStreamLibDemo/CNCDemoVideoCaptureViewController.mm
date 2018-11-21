//
//  CNCDemoVideoCaptureViewController.m
//  CNCMobStreamDemo
//
//  Created by mfm on 16/12/16.
//  Copyright © 2016年 cad. All rights reserved.
//

#import "CNCDemoVideoCaptureViewController.h"
#include <sys/time.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>

#import "MBProgressHUD.h"
#import "CNCDemoFunc.h"

#define LIGHTGRAY [UIColor colorWithWhite:212.0/255 alpha:1.f]
#define SELECTEDCOLOR [UIColor colorWithRed:252.f/255 green:51.f/255 blue:66.f/255 alpha:1.f]
@interface CNCDemoVideoCaptureViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,UIPickerViewDelegate,UIPickerViewDataSource,UITableViewDataSource,UITableViewDelegate,UIGestureRecognizerDelegate> {
    dispatch_queue_t queue_video_data_;
    
    CGFloat screen_w_;
    CGFloat screen_h_;
    BOOL is_enter_back_ground;//进入后台
}

@property (nonatomic, retain) AVCaptureSession *capture_session;
@property (nonatomic, strong) AVCaptureVideoDataOutput *capture_output;
@property (nonatomic, retain) AVCaptureDeviceFormat *default_format;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *preview_layer;
@property (nonatomic, retain) CNCMobStreamVideoDisplayer *displayer;

@property (nonatomic, retain) UIView *preview;
@property (nonatomic, retain) NSLock *lock_oprt;

// UI上的一些操作控件或视图
@property (nonatomic, retain) UIScrollView *backView;

@property (nonatomic, retain) CNCVideoSourceInput *src_input;
@property(nonatomic, retain) UIButton *record_btn;
// 在UI上显示的调试信息
@property(nonatomic, retain) UILabel *stat;
// 调试信息刷新timer thread
@property(nonatomic, retain) NSTimer *timer;
//美声设置页
@property(nonatomic, retain) UIView *audioBeautyView;
@property(nonatomic, retain) UIPickerView *roomType_pickView;
@property(nonatomic, retain) UIPickerView *music_pickView;
@property(nonatomic, retain) NSArray *roomType_array;
@property(nonatomic, retain) NSArray *music_array;

@property(nonatomic, retain) UISlider *human_slider;
@property(nonatomic, retain) UISlider *music_slider;
@property(nonatomic, retain) UISlider *output_slider;
@property(nonatomic, retain) UISlider *reverb_slider;

@property(nonatomic, retain) UIButton *playOrPauseBtn;
@property(nonatomic, retain) UIButton *stopButton;
@property(nonatomic, retain) UISlider *musicProgress;
@property(nonatomic, retain) UILabel  *currentTimeLabel;
@property(nonatomic, retain) UILabel  *totalTimeLabel;

@property(nonatomic, retain) NSTimer  *flashMusicPlayerUITimer;


//录制视频
@property(nonatomic, retain) UIView *store_view;
@property (nonatomic, retain) UISlider *store_slider;
@property(nonatomic) BOOL is_pushing;
@property (nonatomic, retain) UIButton *closeButton;
///音乐循环控制开关
@property (nonatomic, assign) BOOL bMusicLoopEnable;
//sei
@property (nonatomic, retain) UITextView *sei_textview;
@property (nonatomic, retain) UIView *sei_view;
@property (nonatomic, retain) NSMutableArray *sei_questions_array;
@property (nonatomic, retain) NSMutableArray *sei_questions_title_array;
@property (nonatomic, retain) NSMutableDictionary *sei_json_dict;
@property (nonatomic, retain) UIPickerView *sei_questions_pickView;
//record code UI
@property (nonatomic, retain) UITableView *record_code_tableView;
@property (nonatomic, retain) __block NSMutableArray *record_code_data_array;
@end

@implementation CNCDemoVideoCaptureViewController
{
    //实时速率
    unsigned int _speed;
    //提示信息
    NSString *_tips;
    //开始推流时间
    double _startTime;
    AVCaptureDevicePosition camera_position;
    
    CNCRecordVideoType store_type;
    BOOL is_long_store;
    BOOL has_show_in_front_view;
    NSInteger sei_question_index;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
//    CGFloat backViewHeight = buttonWidth*5;

    
    CGFloat fw = [UIScreen mainScreen].bounds.size.width;
    CGFloat fh = [UIScreen mainScreen].bounds.size.height;
    
    if (self.video_direct_type == CNC_ENM_Direct_Vertical) {
        screen_h_ = (fw > fh) ? fw : fh;
        screen_w_ = (fw < fh) ? fw : fh;
    } else {
        screen_w_ = (fw > fh) ? fw : fh;
        screen_h_ = (fw < fh) ? fw : fh;
    }
    
    UIView *preview = [[[UIView alloc] init] autorelease];
    preview.frame = CGRectMake(0, 0, screen_w_, screen_h_);
    preview.backgroundColor = [UIColor grayColor];
    [self.view addSubview:preview];
    
//    if (self.video_direct_type == CNC_ENM_Direct_Horizontal) {
//        preview.frame = CGRectMake((screen_w_-screen_h_)/2, (screen_h_-screen_w_)/2, screen_h_, screen_w_);
//        preview.transform = CGAffineTransformMakeRotation(270 *M_PI / 180.0);
//    }

    self.preview = preview;
    queue_video_data_ = dispatch_queue_create("com.cnc.CNCAVCaptureVideoData.queue_video_data_", NULL);
    self.lock_oprt = [[[NSLock alloc] init] autorelease];
    if (self.came_sel_type != 2) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self start_capture];
        });
        
    }
    
    CNCVideoSourceInput *src = [[[CNCVideoSourceInput alloc] init] autorelease];
    self.para.need_push_audio_BG = self.openOrClosePushInBk;
    [src preset_para:self.para];

    self.src_input = src;
    [self.src_input start_audio_by_collect_type:YES];
    [self.src_input set_whether_continue_push_inBk:self.para.need_push_audio_BG];
    [self.src_input set_sw_encoder_priority_type:self.sw_encoder_priority_type];
    
    [self init_para];
    
    [self setup_view];
    [self addObservers];
    ///添加手势
    [self addGestureRecognizer];
    
}
- (void)init_para {
    has_show_in_front_view = NO;
    
    self.is_pushing = NO;
    _startTime = [[NSDate date] timeIntervalSince1970];
    if (!self.sei_questions_array) {
        self.sei_questions_array = [[[NSMutableArray alloc] init] autorelease];
    }
    if(!self.sei_questions_title_array){
        self.sei_questions_title_array = [[[NSMutableArray alloc] init] autorelease];
    }
    if (!self.sei_json_dict) {
        self.sei_json_dict = [[[NSMutableDictionary alloc] init] autorelease];
    }
    sei_question_index = 0;
    if(!self.record_code_data_array) {
        self.record_code_data_array = [[[NSMutableArray alloc] init] autorelease];
    }
}
- (void)setup_view {
    
    CGFloat buttonWidth = 50;
    CGFloat backViewHeight = buttonWidth*4;
    
    UIScrollView *backView = [[[UIScrollView alloc] init] autorelease];
    backView.frame = CGRectMake(screen_w_-buttonWidth,(screen_h_-backViewHeight)/2,buttonWidth,backViewHeight);
    backView.backgroundColor = [UIColor blackColor];
    backView.alpha = 0.7f;
    //    backView.bounces = NO;
    self.backView = backView;
    [self.view addSubview:self.backView];
    
    {
        //推流按钮
        int startBtnWidth = 100;
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake((screen_w_ - startBtnWidth)/2, screen_h_ - startBtnWidth, startBtnWidth, startBtnWidth)] autorelease];
        
        btn.backgroundColor = [UIColor clearColor];
        [btn setImage:[UIImage imageNamed:@"ic_action_pause"] forState:UIControlStateSelected];
        [btn setImage:[UIImage imageNamed:@"ic_action_play"] forState:UIControlStateNormal];
        btn.selected = NO;
        [btn addTarget:self action:@selector(actionStartMeeting:) forControlEvents:UIControlEventTouchUpInside];
        self.record_btn = btn;
        [self.view addSubview:self.record_btn];
    }
    
    {
        //退出
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(screen_w_-buttonWidth, 0, buttonWidth, buttonWidth)] autorelease];
        btn.tag = 10000;
        btn.backgroundColor = [UIColor clearColor];
        [btn setImage:[UIImage imageNamed:@"clear_input"] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(action_close_vc:) forControlEvents:UIControlEventTouchUpInside];
        self.closeButton = btn;
        [self.view addSubview:btn];
    }
    
    int index = 0;
    
    {
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(0, buttonWidth*index, buttonWidth, buttonWidth)] autorelease];
        btn.tag = 10001+index;
        btn.backgroundColor = [UIColor clearColor];
        [btn setImage:[UIImage imageNamed:@"ic_mode_switch_camera"] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(actionSwap:) forControlEvents:UIControlEventTouchUpInside];
        [backView addSubview:btn];
    }
    index ++;
    {
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(0, buttonWidth*index, buttonWidth, buttonWidth)] autorelease];
        btn.tag = 10001+index;
        btn.backgroundColor = [UIColor clearColor];
        [btn setImage:[UIImage imageNamed:@"ic_microphone_on"] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:@"ic_microphone_off"] forState:UIControlStateSelected];
        
        [btn addTarget:self action:@selector(actionSetMutedMode:) forControlEvents:UIControlEventTouchUpInside];
        btn.selected = NO;
        [backView addSubview:btn];
        
    }
    index ++;
    
    {
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(0, buttonWidth*index, buttonWidth, buttonWidth)] autorelease];
        btn.tag = 10001+index;
        btn.backgroundColor = [UIColor clearColor];
        [btn setTitle:@"美声" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(action_open_audio:) forControlEvents:UIControlEventTouchUpInside];
        
        [backView addSubview:btn];
    }
    index ++;
    {
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(0, buttonWidth*index, buttonWidth, buttonWidth)] autorelease];
        btn.tag = 10001+index;
        btn.backgroundColor = [UIColor clearColor];
        [btn setTitle:@"录制" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(action_open_store_view:) forControlEvents:UIControlEventTouchUpInside];
        
        [backView addSubview:btn];
    }
    index++;
    {
        //        sei
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(0, buttonWidth*index, buttonWidth, buttonWidth)] autorelease];
        btn.tag = 10001+index;
        btn.backgroundColor = [UIColor clearColor];
        [btn setTitle:@"SEI" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(action_open_sei_view:) forControlEvents:UIControlEventTouchUpInside];
        [backView addSubview:btn];
    }
    backView.contentSize = CGSizeMake(backView.bounds.size.width, buttonWidth*(index+1));
    
    int x = 5;
    if (@available(iOS 11.0, *)) {
//        NSLog(@"%f %f",[UIApplication sharedApplication].keyWindow.safeAreaInsets.top,[UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom);
        x = [UIApplication sharedApplication].keyWindow.safeAreaInsets.top+5;
    }
    
    {
        UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(x, 40, screen_w_-buttonWidth-2*x, screen_h_*0.35)] autorelease];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor redColor];
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentLeft;
        label.font = [UIFont boldSystemFontOfSize:14];
        self.stat = label;
        [self.view addSubview:self.stat];
    }
    {
        int y = CGRectGetHeight(self.stat.frame)+CGRectGetMinY(self.stat.frame);
        int height = CGRectGetMinY(self.record_btn.frame) - y;
        UITableView *tableView =[[UITableView alloc]initWithFrame:CGRectMake(x, y+5, screen_w_-buttonWidth-2*x, height) style:UITableViewStylePlain];
        tableView.dataSource = self;
        tableView.delegate =self;
        tableView.backgroundColor =[UIColor clearColor];
        
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.showsVerticalScrollIndicator = NO;
        self.record_code_tableView = tableView;
        [self.view addSubview:tableView];
    }
    [self init_store_view];
    [self init_audio_beauty_view];
    [self init_sei_view];
    
    
}
- (void)init_sei_view {
    NSArray * questions_array  = [CNCDemoFunc get_folder_list_with_name:@"questions"];
    for (NSString *name in questions_array) {
        NSString *file_path = [[CNCDemoFunc get_folder_directory_with_name:@"questions"] stringByAppendingString:[NSString stringWithFormat:@"/%@",name]];
        NSDictionary *dictionary = [CNCDemoFunc read_question_file:file_path];
        for (NSString *key in [dictionary allKeys]) {
            
            if ([key isEqualToString:@"questionList"]) {
                NSArray *questions = [dictionary objectForKey:@"questionList"];
                for (NSDictionary *question in questions) {
                    
                    [self.sei_questions_array addObject:question];
                    [self.sei_questions_title_array addObject:[question objectForKey:@"question"]];
                }
            } else{
                [self.sei_json_dict setObject:[dictionary objectForKey:key] forKey:key];
            }
        }
    }
    
    UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, screen_w_, screen_h_)] autorelease];
    view.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.7];
    
    UIView *whiteView = [[[UIView alloc] init] autorelease];
    whiteView.backgroundColor = [UIColor whiteColor];
    whiteView.layer.borderColor = LIGHTGRAY.CGColor;
    whiteView.layer.borderWidth = 1.f;
    [view addSubview:whiteView];
    int view_x = 0,view_y=0,view_width = 0,view_height =0;
    if (screen_h_>screen_w_) {
        view_width = screen_w_-20;
        view_height = screen_h_/10*3;
    } else {
        view_width = screen_w_*2/3;
        view_height = screen_h_*2/3;
    }
    view_x = (screen_w_-view_width)/2;
    view_y = (screen_h_-view_height)/2;
    whiteView.frame = CGRectMake(view_x, view_y, view_width, view_height);
    
    CGFloat scale = MIN(screen_h_, screen_w_)/320;
    int height = 32*scale;
    
    {
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(whiteView.bounds.size.width-40, 0, 40, 40)] autorelease];
        btn.backgroundColor = [UIColor clearColor];
        [btn setImage:[UIImage imageNamed:@"clear_input"] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(action_close_sei:) forControlEvents:UIControlEventTouchUpInside];
        [whiteView addSubview:btn];
    }
    
    self.sei_questions_pickView = [[[UIPickerView alloc] initWithFrame:CGRectMake(10, 30, CGRectGetWidth(whiteView.frame)-20, CGRectGetHeight(whiteView.frame)-height-30-20)] autorelease];
    self.sei_questions_pickView.delegate = self;
    self.sei_questions_pickView.dataSource = self;
    self.sei_questions_pickView.tag = 22550;
    self.sei_questions_pickView.backgroundColor = [UIColor clearColor];
    [whiteView addSubview:self.sei_questions_pickView];
    
    int btnwidth = CGRectGetWidth(whiteView.frame)/3;
    
    {
        UIButton *sure = [[[UIButton alloc] initWithFrame:CGRectMake((CGRectGetWidth(whiteView.frame)-btnwidth)/2, CGRectGetHeight(whiteView.frame)-height-20, btnwidth, height)] autorelease];
        sure.layer.cornerRadius = height/2;
        sure.layer.borderWidth = 1.f;
        sure.layer.borderColor = SELECTEDCOLOR.CGColor;
        [sure setTitle:@"发送" forState:UIControlStateNormal];
        [sure setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
        [sure addTarget:self action:@selector(action_add_sei_json_str:) forControlEvents:UIControlEventTouchUpInside];
        [whiteView addSubview:sure];
    }
    
    
    UITapGestureRecognizer* setTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)] autorelease];
    [view addGestureRecognizer:setTap];
    
    self.sei_view = view;
    
}
- (void)handleTapGesture:(id)sender {
    [self.sei_textview resignFirstResponder];
}
- (void)init_store_view {
    //短视频录制 gif录制
    UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, screen_w_, screen_h_)] autorelease];
    
    UIView *whiteView = [[[UIView alloc] init] autorelease];
    whiteView.backgroundColor = [UIColor whiteColor];
    whiteView.layer.borderColor = LIGHTGRAY.CGColor;
    whiteView.layer.borderWidth = 1.f;
    whiteView.alpha = 0.8;
    
    if (screen_h_>screen_w_) {
        whiteView.frame = CGRectMake(10, screen_h_/5, screen_w_-20, screen_h_/5*3);
    } else {
        whiteView.frame = CGRectMake(screen_w_/6, 25, screen_w_*2/3, screen_h_-50);
    }
    [view addSubview:whiteView];
    int hy = 0;
    {
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(whiteView.bounds.size.width-40, 0, 40, 40)] autorelease];
        btn.backgroundColor = [UIColor clearColor];
        [btn setImage:[UIImage imageNamed:@"clear_input"] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(actionCloseStore:) forControlEvents:UIControlEventTouchUpInside];
        [whiteView addSubview:btn];
    }
    
    {
        UILabel *title = [[[UILabel alloc] initWithFrame:CGRectMake(0, hy, whiteView.bounds.size.width , 30)] autorelease];
        title.text = @"视频录制";
        title.textColor = [UIColor redColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.tag = 3222;
        title.backgroundColor = [UIColor clearColor];
        [whiteView addSubview:title];
    }
    hy+= 45;
    
    {
        NSString *str = @"录制时间:10.00s";
        UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10,hy,whiteView.bounds.size.width-45,30)] autorelease];
        label.text = str;
        label.textColor = [UIColor redColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.backgroundColor = [UIColor clearColor];
        label.tag = 3220;
        label.numberOfLines = 0;
        [whiteView addSubview:label];
    }
    hy+= 45;
    {
        self.store_slider =[[[UISlider alloc] initWithFrame:CGRectMake(10,hy,whiteView.bounds.size.width-20, 30)] autorelease];
        self.store_slider.continuous = YES;
        self.store_slider.minimumValue = 3.0f;
        CGFloat maxValue = 60.0;
        self.store_slider.maximumValue = maxValue;
        self.store_slider.value = 10.0f;
        self.store_slider.tag = 3221;
        [self.store_slider addTarget:self action:@selector(store_sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        [whiteView addSubview:self.store_slider];
    }
    hy+= 55;
    NSArray *type_array = [[[NSArray alloc] initWithObjects:@"FLV",@"MP4",@"GIF", nil] autorelease];
    NSArray *long_array = [[[NSArray alloc] initWithObjects:@"短视频",@"长视频", nil] autorelease];
    CGFloat scale = MIN(screen_h_, screen_w_)/320;
    int height = 32*scale;
    int btnwidth = (CGRectGetWidth(whiteView.frame) - 60)/3;
    
    {
        for (int i = 0; i<3; i++) {
            UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(15+i*(btnwidth+20), hy, btnwidth, height)] autorelease];
            btn.layer.cornerRadius = height/2;
            btn.layer.borderWidth = 1.f;
            btn.layer.borderColor = LIGHTGRAY.CGColor;
            btn.tag = 3200+i;
            [btn setTitle:[type_array objectAtIndex:i] forState:UIControlStateNormal];
            [btn setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
            if (i == 0) {
                btn.layer.borderColor = SELECTEDCOLOR.CGColor;
                [btn setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
                store_type = CNCRecordVideoType_FLV;
            }
            [btn addTarget:self action:@selector(action_set_type:) forControlEvents:UIControlEventTouchUpInside];
            [whiteView addSubview:btn];
            
        }
    }
    
    hy+= 55;
    {
        for (int i = 0; i<2; i++) {
            UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(15+i*(btnwidth+20), hy, btnwidth, height)] autorelease];
            btn.layer.cornerRadius = height/2;
            btn.layer.borderWidth = 1.f;
            btn.layer.borderColor = LIGHTGRAY.CGColor;
            btn.tag = 3203+i;
            [btn setTitle:[long_array objectAtIndex:i] forState:UIControlStateNormal];
            [btn setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(action_set_long:) forControlEvents:UIControlEventTouchUpInside];
            [whiteView addSubview:btn];
            if (i == 0) {
                btn.layer.borderColor = SELECTEDCOLOR.CGColor;
                [btn setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
                is_long_store = NO;
            }
        }
    }
    
    btnwidth = (CGRectGetWidth(whiteView.frame) - 30)/2;
    
    {
        UIButton *start = [[[UIButton alloc] initWithFrame:CGRectMake(10, whiteView.bounds.size.height-height-10, btnwidth, height)] autorelease];
        start.layer.cornerRadius = height/2;
        start.layer.borderWidth = 1.f;
        start.layer.borderColor = LIGHTGRAY.CGColor;
        start.tag = 3210;
        [start setTitle:@"开始录制" forState:UIControlStateNormal];
        [start setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
        [start addTarget:self action:@selector(action_store_event:) forControlEvents:UIControlEventTouchUpInside];
        [whiteView addSubview:start];
    }
    
    {
        UIButton *stop = [[[UIButton alloc] initWithFrame:CGRectMake(20 + btnwidth, whiteView.bounds.size.height-height-10, btnwidth, height)] autorelease];
        stop.layer.cornerRadius = height/2;
        stop.layer.borderWidth = 1.f;
        stop.layer.borderColor = SELECTEDCOLOR.CGColor;
        stop.tag = 3211;
        [stop setTitle:@"停止录制" forState:UIControlStateNormal];
        [stop setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
        [stop addTarget:self action:@selector(action_store_event:) forControlEvents:UIControlEventTouchUpInside];
        [whiteView addSubview:stop];
    }
    
    
    self.store_view = view;
}

- (void)init_audio_beauty_view {
    
    UIView *whiteView = [[[UIView alloc] init] autorelease];
    whiteView.backgroundColor = [UIColor whiteColor];
    whiteView.layer.borderColor = LIGHTGRAY.CGColor;
    whiteView.layer.borderWidth = 1.f;
    whiteView.alpha = 0.5;
    
    if (screen_h_>screen_w_) {
        whiteView.frame = CGRectMake(10, screen_h_/6, screen_w_ - 20, screen_h_*2/3);
    } else {
        whiteView.frame = CGRectMake(screen_w_/6, 15, screen_w_*2/3, screen_h_ - 30);
    }
    
    {
        CGRect rect = CGRectMake(10, 5, 50, 30);
        UILabel *label = [[[UILabel alloc]init] autorelease];
        label.frame = rect;
        label.text = @"耳返：";
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor blackColor];
        label.font = [UIFont systemFontOfSize:15.f];
        [whiteView addSubview:label];
        
        rect = CGRectMake(60, 5, 50, 30);
        UISwitch *continuePushSwitch = [[[UISwitch alloc] initWithFrame:rect] autorelease];
        BOOL bPushInBk = [self.src_input isOpenMicVoiceReturnBack];
        [continuePushSwitch setSelected:bPushInBk];
        [continuePushSwitch setOn:bPushInBk];
        [continuePushSwitch addTarget:self action:@selector(actionOpenOrCloseMicVoiceReturnBack:) forControlEvents:UIControlEventValueChanged];
        [whiteView addSubview:continuePushSwitch];
        
        
        self.bMusicLoopEnable = NO;
        
        rect = CGRectMake(120, 5, 80, 30);
        UILabel *labelLoop = [[[UILabel alloc]init] autorelease];
        labelLoop.frame = rect;
        labelLoop.text = @"循环播放：";
        labelLoop.textAlignment = NSTextAlignmentLeft;
        labelLoop.textColor = [UIColor blackColor];
        labelLoop.font = [UIFont systemFontOfSize:15.f];
        [whiteView addSubview:labelLoop];
        
        rect = CGRectMake(200, 5, 160, 30);
        UISwitch *musicLoopSwitch = [[[UISwitch alloc] initWithFrame:rect] autorelease];
        [musicLoopSwitch setSelected:self.bMusicLoopEnable];
        [musicLoopSwitch setOn:self.bMusicLoopEnable];
        [musicLoopSwitch addTarget:self action:@selector(actionSetMusicLoopEnable:) forControlEvents:UIControlEventValueChanged];
        [whiteView addSubview:musicLoopSwitch];
    }
    
    self.roomType_array = [[[NSArray alloc] initWithObjects:@"小房间",@"中房间",@"大房间",@"中礼堂",@"大礼堂",@"打碟室",@"中会议厅",@"大会议厅",@"教堂",@"大房间2",@"中礼堂2",@"中礼堂3",@"大礼堂2", nil] autorelease];
    
    self.music_array = [CNCDemoFunc get_folder_list_with_name:@"music"];
    
    self.roomType_pickView = [[[UIPickerView alloc] initWithFrame:CGRectMake(10, 20, whiteView.bounds.size.width/2-20, whiteView.bounds.size.height*1/3)] autorelease];
    //    self.beauty_pickView.showsSelectionIndicator = YES;
    self.roomType_pickView.delegate = self;
    self.roomType_pickView.dataSource = self;
    self.roomType_pickView.tag = 22330;
    [whiteView addSubview:self.roomType_pickView];
    
    self.music_pickView = [[[UIPickerView alloc] initWithFrame:CGRectMake(whiteView.bounds.size.width/2+10, 20, whiteView.bounds.size.width/2-20, whiteView.bounds.size.height*1/3)] autorelease];
    self.music_pickView.delegate = self;
    self.music_pickView.dataSource = self;
    self.music_pickView.tag = 22331;
    [whiteView addSubview:self.music_pickView];
    
    UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(whiteView.bounds.size.width-30, 0, 30, 30)] autorelease];
    btn.backgroundColor = [UIColor clearColor];
    btn.tag = 22332;
    [btn setImage:[UIImage imageNamed:@"clear_input"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(action_close_audio_view:) forControlEvents:UIControlEventTouchUpInside];
    [whiteView addSubview:btn];
    
    NSArray *titleArray = [[[NSArray alloc] initWithObjects:@"人声:",@"乐声:",@"总音:",@"混响:", nil] autorelease];
    int start_btn_height = 30;
    int slider_space = (CGRectGetHeight(whiteView.frame)-(CGRectGetHeight(self.roomType_pickView.frame)+CGRectGetMinY(self.roomType_pickView.frame))-start_btn_height*2-10)/(titleArray.count);
    if (slider_space<25) {
        if(slider_space<15) {
            if (screen_h_>screen_w_) {
                whiteView.frame = CGRectMake(10, screen_h_/6, screen_w_ - 20, screen_h_*2/3);
            } else {
                whiteView.frame = CGRectMake(screen_w_/6, 0, screen_w_*2/3, screen_h_ );
            }
        }
        slider_space = start_btn_height = (CGRectGetHeight(whiteView.frame)-(CGRectGetHeight(self.roomType_pickView.frame)+CGRectGetMinY(self.roomType_pickView.frame))-10)/(titleArray.count+2);
    }
    int slider_height = 25;
    if (slider_space<25) {
        slider_height = slider_space;
    }
    for (int i = 0;i<titleArray.count;i++) {
        NSString *str = [titleArray objectAtIndex:i];
        UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetHeight(self.roomType_pickView.frame)+CGRectGetMinY(self.roomType_pickView.frame)+5+slider_space*i, 60, slider_height)] autorelease];
        label.text = str;
        label.textColor = [UIColor blackColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [UIColor clearColor];
        [label sizeToFit];
        label.numberOfLines = 0;
        [whiteView addSubview:label];
        
        UISlider * slider = [[[UISlider alloc] initWithFrame:CGRectMake(CGRectGetMinX(label.frame)+CGRectGetWidth(label.frame)+10, CGRectGetMinY(label.frame),CGRectGetWidth(whiteView.frame)-(CGRectGetMinX(label.frame)+CGRectGetWidth(label.frame)+10)-10, slider_height)] autorelease];
        slider.continuous = YES;//设置只有在离开滑动条的最后时刻才触发滑动事件
        slider.minimumValue = 0.0f;
        CGFloat maxValue = 1.0f;
        slider.maximumValue = maxValue;
        slider.value = maxValue/2.0;
        slider.tag = 22333 + i;
        [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        [whiteView addSubview:slider];
        switch (i) {
            case 0:
                self.human_slider = slider;
                break;
            case 1:
                self.music_slider = slider;
                break;
            case 2:
                self.output_slider = slider;
                break;
            case 3:
                self.reverb_slider = slider;
                self.reverb_slider.minimumValue = 0;
                self.reverb_slider.maximumValue = 100;
                self.reverb_slider.value = 0;
                break;
            default:
                break;
        }
    }
    
    {
        //music player UI
        int buttonY = CGRectGetHeight(self.roomType_pickView.frame)+CGRectGetMinY(self.roomType_pickView.frame) + slider_space*titleArray.count+5;
        int sliderWidth = CGRectGetWidth(whiteView.frame) - 140;
        
        UIButton *PPBtn = [[[UIButton alloc] initWithFrame:CGRectMake(10, buttonY, 50, start_btn_height)] autorelease];
        [PPBtn setTitle:@"播放" forState:UIControlStateNormal];
        [PPBtn setTitle:@"暂停" forState:UIControlStateSelected];
        [PPBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [PPBtn setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        [PPBtn setSelected:NO];
        [PPBtn addTarget:self action:@selector(action_play_or_pause:) forControlEvents:UIControlEventTouchUpInside];
        [whiteView addSubview:PPBtn];
        self.playOrPauseBtn = PPBtn;
        
        UILabel *label0 = [[[UILabel alloc] initWithFrame:CGRectMake(80, buttonY, 80, start_btn_height)] autorelease];
        label0.textColor = [UIColor blackColor];
        label0.textAlignment = NSTextAlignmentLeft;
        label0.backgroundColor = [UIColor clearColor];
        label0.numberOfLines = 0;
        [whiteView addSubview:label0];
        self.currentTimeLabel = label0;
        
        UILabel *label1 = [[[UILabel alloc] initWithFrame:CGRectMake(sliderWidth, buttonY, 80, start_btn_height)] autorelease];
        label1.textColor = [UIColor blackColor];
        label1.textAlignment = NSTextAlignmentRight;
        label1.backgroundColor = [UIColor clearColor];
        label1.numberOfLines = 0;
        [whiteView addSubview:label1];
        self.totalTimeLabel = label1;
        
        buttonY += start_btn_height;
        
        UIButton *stopBtn = [[[UIButton alloc] initWithFrame:CGRectMake(10, buttonY, 50, start_btn_height)] autorelease];
        [stopBtn setTitle:@"停止" forState:UIControlStateNormal];
        [stopBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [stopBtn addTarget:self action:@selector(action_stop_music:) forControlEvents:UIControlEventTouchUpInside];
        [whiteView addSubview:stopBtn];
        self.stopButton = stopBtn;
        
        UISlider * slider = [[[UISlider alloc] initWithFrame:CGRectMake(80, buttonY,sliderWidth, start_btn_height)] autorelease];
        slider.continuous = NO;//设置只有在离开滑动条的最后时刻才触发滑动事件
        slider.minimumValue = 0.0f;
        slider.maximumValue = 1.0f;
        slider.value = 0;
        [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        [whiteView addSubview:slider];
        self.musicProgress = slider;
    }
    
    self.audioBeautyView = whiteView;
}

- (void)addObservers {
    [self add_notify];
    // statistics update every seconds
    self.timer =  [NSTimer scheduledTimerWithTimeInterval:1.0
                                                   target:self
                                                 selector:@selector(updateStat:)
                                                 userInfo:nil
                                                  repeats:YES];
    //添加发送速率通知消息处理
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(update_sdk_send_speed:)
                                                 name:kMobStreamSDKSendSpeedNotification
                                               object:nil];
    
    //添加错误码通知消息处理
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sdk_return_code_center_deal:)
                                                 name:kMobStreamSDKReturnCodeNotification
                                               object:nil];
    
}

- (void)update_sdk_send_speed:(NSNotification *)notification {
    NSNumber *speedNum = notification.object;
    _speed = [speedNum unsignedIntValue];
}

- (void)sdk_return_code_center_deal:(NSNotification *)notification {
    NSDictionary* dic = notification.object;
    
    CNC_Ret_Code code = (CNC_Ret_Code)[[dic objectForKey:@"code"] integerValue];
//    if (code == CNC_RCode_Pushstream_Success) {
//        NSLog(@"连接成功，开始推流");
//    } else {
    
        __block UIButton *btn_open;
        __block UIButton *btn_close;
        if (code != CNC_RCode_Auth_Network_Error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.record_code_data_array.count >= RECORD_CODE_COUNT) {
                    [self.record_code_data_array removeObjectAtIndex:0];
                }
                NSString *record_str = [NSString stringWithFormat:@"%ld:%@",(CNC_Ret_Code)[[dic objectForKey:@"code"] integerValue],[dic objectForKey:@"message"]];
                record_str = [[record_str componentsSeparatedByString:@":{"] firstObject];
                [self.record_code_data_array addObject:record_str];
                if (self.record_code_tableView) {
                    [self.record_code_tableView reloadData];
                    
                    NSIndexPath *scrollIndexPath = [NSIndexPath indexPathForRow:self.record_code_data_array.count-1 inSection:0];
                    
                    [self.record_code_tableView scrollToRowAtIndexPath:scrollIndexPath
                                                      atScrollPosition:UITableViewScrollPositionTop animated:YES];
                }
                
            });
        } else {
            
        }
        
        NSString *succeed_message;
        
        NSArray *succeed_message_array;
        NSString *path;
        NSString *info;
        switch (code) {
            case CNC_Record_Failed:
                dispatch_async(dispatch_get_main_queue(), ^{
                    btn_open = [self.store_view viewWithTag:3210];
                    btn_close = [self.store_view viewWithTag:3211];
                    if (![[[[dic objectForKey:@"message"] componentsSeparatedByString:@"path:"] lastObject] hasSuffix:@".jpg"]) {
                        btn_close.layer.borderColor = SELECTEDCOLOR.CGColor;
                        [btn_close setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
                        btn_open.layer.borderColor = LIGHTGRAY.CGColor;
                        [btn_open setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
                    }
                });
                break;
            case CNC_Record_Complete:
                dispatch_async(dispatch_get_main_queue(), ^{
                    btn_open = [self.store_view viewWithTag:3210];
                    btn_close = [self.store_view viewWithTag:3211];
                    if (![[[[dic objectForKey:@"message"] componentsSeparatedByString:@"Record complete:"] lastObject] hasSuffix:@".jpg"]) {
                        btn_close.layer.borderColor = SELECTEDCOLOR.CGColor;
                        [btn_close setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
                        btn_open.layer.borderColor = LIGHTGRAY.CGColor;
                        [btn_open setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
                    }
                });
                break;
            case CNC_Record_Succeed:
                
                succeed_message = [[[dic objectForKey:@"message"] componentsSeparatedByString:@"Record succeed:"] lastObject];
                succeed_message_array =[succeed_message componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"{} ,"]];
                path = [[[succeed_message_array objectAtIndex:1]componentsSeparatedByString:@"file_name:"] lastObject];
                info = [[[succeed_message_array objectAtIndex:[succeed_message_array count]-2]componentsSeparatedByString:@"info:"] lastObject];
                if (path && ([info isEqualToString:@"normal"] || [info isEqualToString:@"suspend"]) ) {
//                    [self save_to_photos_album:path];
                }
                break;
            case CNC_RCode_Push_Init_Fail:
                [self can_not_push_stream];
                break;
            case CNC_RCode_Com_Invalid_URL:
                [self can_not_push_stream];
                break;
            default:
                break;
        }
//    }
}
- (void)can_not_push_stream {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.is_pushing = NO;
        self.record_btn.selected = NO;
        self.stat.text = @"";
        if ([self.timer isValid]) {
            [self.timer invalidate];
            self.timer = nil;
        }
    });
}
- (void)updateStat:(NSTimer *)theTimer {
    
    NSString *labelText = nil;
    
    if (self.record_btn.selected) {
        
        NSInteger bitrate = [self.src_input get_bit_rate];
        NSInteger videofps = [self.src_input get_video_fps];
        double currentTime = [[NSDate date]timeIntervalSince1970];
        
        NSString* hostUrl = [NSString stringWithFormat:@"%@\n",[self.src_input get_rtmp_url_string]];
        NSString* infoSetting = [NSString stringWithFormat:@"Info_setting: %@ fps | %@ kbps \n",@(videofps),@(bitrate)];
        
        NSString* realtime = [NSString stringWithFormat:@"Realtime: %d KBps",_speed];
       
        realtime = [NSString stringWithFormat:@"%@ | %@\n",realtime,[self timeFormatted:(int)(currentTime-_startTime)]];
        
        labelText = hostUrl;
        labelText = [labelText stringByAppendingString:realtime];
        labelText = [labelText stringByAppendingString:infoSetting];
        
        realTimeLayeredFrame *strucFrame = [self.src_input get_statistics_message];
        
        if (strucFrame) {
            NSString* statics_info = [NSString stringWithFormat:@"Frame: %ld (per) , %ld (total) | Drop: %ld (pakage) , %ld (fps)\n",strucFrame->actual_per_fps,strucFrame->actual_total_send_frame,strucFrame->drop_pakage_num,strucFrame->drop_frame_num];
            labelText = [labelText stringByAppendingString:statics_info];
        }
    }
    
    if (self.record_btn.selected) {
        
        
        if (_tips) {
            labelText = [labelText stringByAppendingString:_tips];
            _tips = nil;
        }
    }
    
    self.stat.text = labelText;
}


- (NSString *)timeFormatted:(int)totalSeconds {
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
}

- (NSString *)memFormatted:(long)totalSize {
    
    double convertedValue = totalSize;
    int multiplyFactor = 0;
    
    NSArray *tokens = [NSArray arrayWithObjects:@"B",@"KB",@"MB",@"GB",@"TB",nil];
    
    while (convertedValue > 1024) {
        convertedValue /= 1024;
        multiplyFactor++;
        if (multiplyFactor == 4) {
            break;
        }
    }
    
    return [NSString stringWithFormat:@"%4.2f %@",convertedValue, [tokens objectAtIndex:multiplyFactor]];
}

#pragma mark - notice show
- (void)showMessage:(NSString *)message
{
    UIWindow * window = [UIApplication sharedApplication].keyWindow;
    UIView *showview =  [[[UIView alloc]init] autorelease];
    showview.backgroundColor = [UIColor redColor];
    showview.frame = CGRectMake(1, 1, 1, 1);
    showview.alpha = 1.0f;
    showview.layer.masksToBounds = YES;
    [window addSubview:showview];
    
    int SCREEN_WIDTH = [UIScreen mainScreen].bounds.size.width;
    int view_height = 100;
    
    UILabel *label = [[[UILabel alloc] init] autorelease];
    label.frame = CGRectMake(0, 0, SCREEN_WIDTH, view_height);
    label.text = message;
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:15];
    label.numberOfLines = 0;
    label.tag = 10050;
    [showview addSubview:label];
    
    showview.frame = CGRectMake(0, 0, SCREEN_WIDTH, view_height);
    [UIView animateWithDuration:3.5 animations:^{
        showview.alpha = 0;
    } completion:^(BOOL finished) {
        [showview removeFromSuperview];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark 判断地址栏是否正确
- (BOOL)isTrueRtmpUrl:(NSString *)enter_text {
    
    if (!enter_text || [enter_text length] == 0) {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"推流地址不能为空，请在配置页输入推流地址！" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil] autorelease];
        [alert show];
        return NO;
    }
    
    NSRange r = [enter_text rangeOfString:@"rtmp://"];
    
    if (r.location != 0) {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"推流地址不正确，必须以“rtmp://”开头，请在配置页修改推流地址！" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil] autorelease];
        [alert show];
        return NO;
    }
    
    return YES;
}

#pragma mark 交互
- (void)action_open_store_view:(UIButton *)sender {
    if (!has_show_in_front_view) {
        has_show_in_front_view = YES;
        [self.view addSubview:self.store_view];
    }
    
}
- (void)action_open_audio:(UIButton *)sender {
    if (!has_show_in_front_view) {
        has_show_in_front_view = YES;
        [self.view addSubview:self.audioBeautyView];
    }
}

- (void)action_close_audio_view:(UIButton *)sender {
    switch (sender.tag) {
        case 22332:
            if (has_show_in_front_view) {
                has_show_in_front_view = NO;
                [self.audioBeautyView removeFromSuperview];
            }
            
            break;
        default:
            break;
    }
}

- (void)actionSetMutedMode:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    [self.src_input set_muted_status:sender.selected];
}
- (void)action_close_vc:(id)sender {
    
    if ([self.timer isValid]) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    MBProgressHUD* progressHud_ = [[[MBProgressHUD alloc] initWithView:self.view] autorelease];
    progressHud_.removeFromSuperViewOnHide = YES;
    progressHud_.labelText = @"正在退出...";
    [self.view addSubview:progressHud_];
    [progressHud_ show:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        
        [self.src_input stop_push];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self stop_capture];
            [progressHud_ hide:NO];
            
        });
    });
    
    [self dismissViewControllerAnimated:YES completion:^(){}];
}

- (void)actionSwap:(UIButton *)sender {
 
    [sender setEnabled:NO];
    MBProgressHUD* progressHud_ = [[[MBProgressHUD alloc] initWithView:self.view] autorelease];
    progressHud_.removeFromSuperViewOnHide = YES;
    progressHud_.labelText = @"正在切换摄像头...";
    [self.view addSubview:progressHud_];
    [progressHud_ show:YES];
    
        dispatch_async(dispatch_get_main_queue(), ^{
            [self swap_cameras];
            [progressHud_ hide:NO];
            [sender setEnabled:YES];
        });

}
- (void)actionStartMeeting:(UIButton *)sender {
    [sender setEnabled:NO];
    sender.selected = !sender.isSelected;
    if (sender.isSelected) {
        
        NSString *rtmp_name = [self.src_input get_rtmp_url_string];
        if (![self isTrueRtmpUrl:rtmp_name]) {
            sender.selected = NO;
            [sender setEnabled:YES];
            return;
        }
      
//        [[CNCAppUserDataMng instance] set_self_host_push_url:rtmp_name];

        MBProgressHUD* progressHud_ = [[[MBProgressHUD alloc] initWithView:self.view] autorelease];
        progressHud_.removeFromSuperViewOnHide = YES;
        progressHud_.labelText = @"正在启动推流...";
        [self.view addSubview:progressHud_];
        [progressHud_ show:YES];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            [self.src_input start_push];
            self.is_pushing = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                _startTime = [[NSDate date]timeIntervalSince1970];
                [progressHud_ hide:NO];
                [sender setEnabled:YES];
            });
        });
    } else {
        MBProgressHUD* progressHud_ = [[[MBProgressHUD alloc] initWithView:self.view] autorelease];
        progressHud_.removeFromSuperViewOnHide = YES;
        progressHud_.labelText = @"正在退出...";
        [self.view addSubview:progressHud_];
        [progressHud_ show:YES];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            [self.src_input pause_push];
            self.is_pushing = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self resetParam];
                _stat.text = @"";
                [progressHud_ hide:NO];
                [sender setEnabled:YES];
            });
        });
    }
    
}
- (void)resetParam {
    _startTime = 0;
    self.record_btn.selected = NO;
}
#pragma mark UIPickView data source
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    switch (pickerView.tag) {
   
        case 22330:
            return self.roomType_array.count;
            break;
        case 22331:
            return self.music_array.count;
            break;
        case 22550:
            return self.sei_questions_title_array.count;
        default:
            break;
    }
    
    return 0;
}

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSArray *dataList = nil;
    
    switch (pickerView.tag) {
 
        case 22330:
            dataList = self.roomType_array;
            break;
        case 22331:
            dataList = self.music_array;
            break;
        case 22550:
            dataList = self.sei_questions_title_array;
            break;
        default:
            break;
    }
    
    if (row >= dataList.count) {
        return @"Error";
    }
    
    return [dataList objectAtIndex:row];
}
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    
    
    /*重新定义row 的UILabel*/
    UILabel *pickerLabel = (UILabel*)view;
    
    if (!pickerLabel){
        
        pickerLabel = [[[UILabel alloc] init] autorelease];
        [pickerLabel setTextColor:[UIColor darkGrayColor]];
        //
        [pickerLabel setTextAlignment:NSTextAlignmentCenter];
        pickerLabel.numberOfLines = 0;
        [pickerLabel setBackgroundColor:[UIColor clearColor]];
        if (pickerView == self.sei_questions_pickView) {
            [pickerLabel setFont:[UIFont systemFontOfSize:12.0f]];
            pickerLabel.adjustsFontSizeToFitWidth = YES;
        } else {
            [pickerLabel setFont:[UIFont systemFontOfSize:20.0f]];
        }
        
    }
    
    
    pickerLabel.text = [self pickerView:pickerView titleForRow:row forComponent:component];
    
    return pickerLabel;
    
    
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    switch (pickerView.tag) {
       
        case 22330:
        {
            NSLog(@"%@",[self.roomType_array objectAtIndex:row]);
            [self.src_input setAudioRoomType:(CNCAudioRoomType)row];
        }
            break;
        case 22331:
        {
            if (row < self.music_array.count) {
                NSString *filename = self.music_array[row];
                NSString *fileString = [[CNCDemoFunc get_folder_directory_with_name:@"music"] stringByAppendingPathComponent:filename];
                NSLog(@"%@",filename);
                BOOL bOpenFile = [self.src_input setUpAUFilePlayer:fileString loopEnable:self.bMusicLoopEnable];
                
                if (!bOpenFile) {
                    [self action_stop_music:nil];
                    [self showMessage:[NSString stringWithFormat:@"无法打开文件：%@", filename]];
                } else {
                    [self.src_input startPlayMusic];
                    self.playOrPauseBtn.selected = YES;
                    self.totalTimeLabel.text = [self.src_input getDurationString];
                    [self start_music_ui_flash];
                }
            }
        }
            break;
        case 22550:
        {
            sei_question_index = row;
        }
            break;
        default:
            break;
    }
    
    
    
}
#pragma mark UISliderDelegate

- (void)sliderValueChanged:(UISlider *)paramSender {
    if ([paramSender isEqual:self.human_slider]) {
        Float32 value = paramSender.value;
        [self.src_input setHumanVolume:value];
    } else if ([paramSender isEqual:self.music_slider]) {
        Float32 value = paramSender.value;
        [self.src_input setMusicVolume:value];
    } else if ([paramSender isEqual:self.output_slider]) {
        Float32 value = paramSender.value;
        [self.src_input setOutPutVolume:value];
    } else if ([paramSender isEqual:self.reverb_slider]) {
        Float32 value = paramSender.value;
        [self.src_input setAudioMixReverb:value];
    } else if ([paramSender isEqual:self.musicProgress]) {
        Float32 value = paramSender.value;
        NSLog(@"music progress %f",value);
        [self.src_input seekPlayheadTo:value];
        [self.src_input startPlayMusic];
    }
}
#pragma mark - UITableView data source && UITableViewDelegate

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.record_code_data_array count];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40;
}
static NSString *CNCRecordCodeTableViewIdentifier = @"CNCRecordCodeTableViewIdentifier";
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //    用TableSampleIdentifier表示需要重用的单元
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CNCRecordCodeTableViewIdentifier];
    //    如果如果没有多余单元，则需要创建新的单元
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CNCRecordCodeTableViewIdentifier] autorelease];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor redColor];
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14.0];
        cell.textLabel.numberOfLines = 0;
    }
    if ([self.record_code_data_array count] > indexPath.row) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@",[self.record_code_data_array objectAtIndex:indexPath.row]];
    }
    
    return cell;
}
- (void)addGestureRecognizer {
    UISwipeGestureRecognizer *swipeLeftGes = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)] autorelease];
    swipeLeftGes.direction = UISwipeGestureRecognizerDirectionLeft;
    swipeLeftGes.delegate = self;
    
    UISwipeGestureRecognizer *swipeRightGes = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)] autorelease];
    swipeRightGes.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeLeftGes];
    [self.view addGestureRecognizer:swipeRightGes];
}
- (void)handleSwipes:(UISwipeGestureRecognizer *)sender {
    
    if (sender.direction == UISwipeGestureRecognizerDirectionLeft) {
        self.backView.hidden = NO;
        [UIView animateWithDuration:0.25f animations:^{
            CGRect frame = self.backView.frame;
            frame.origin.x = screen_w_ - 50;
            self.backView.frame = frame;
        } completion:^(BOOL finished) {
            self.backView.hidden = NO;
            self.record_btn.hidden = NO;
            self.stat.hidden = NO;
            self.record_code_tableView.hidden = NO;
            self.closeButton.hidden = NO;
            
            if (self.record_code_tableView) {
                self.record_code_tableView.hidden = NO;
            }
            
            
        }];
        return;
    }
    
    if (sender.direction == UISwipeGestureRecognizerDirectionRight) {
        [UIView animateWithDuration:0.25f animations:^{
            CGRect frame = self.backView.frame;
            frame.origin.x = screen_w_;
            self.backView.frame = frame;
        } completion:^(BOOL finished) {
            self.backView.hidden = YES;
            self.stat.hidden = YES;
            self.record_code_tableView.hidden = YES;
            self.record_btn.hidden = YES;
            self.closeButton.hidden = YES;
            
            if (self.record_code_tableView) {
                self.record_code_tableView.hidden = YES;
            }
            
        }];
        return;
    }
}
#pragma mark - audio
- (void)actionOpenOrCloseMicVoiceReturnBack:(UISwitch *)sender {
    
    sender.selected = !sender.isSelected;
    
    /// 设置耳返开启关闭
    /// 在没有插入耳机的情况下，是不会有耳返功能的，请悉知
    
    [self.src_input set_audio_returnback:sender.isSelected];
    
}

#pragma mark - music
- (void)actionSetMusicLoopEnable:(UISwitch *)sender {
    self.bMusicLoopEnable = !self.bMusicLoopEnable;
}


#pragma mark - Music Player Control

- (void)start_music_ui_flash {
    if (self.flashMusicPlayerUITimer == nil) {
        self.flashMusicPlayerUITimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                                        target:self
                                                                      selector:@selector(updataMusicProgress)
                                                                      userInfo:nil
                                                                       repeats:YES];
        [self.flashMusicPlayerUITimer fire];
    }
}


- (void)stop_music_ui_flash {
    if ([self.flashMusicPlayerUITimer isValid]) {
        [self.flashMusicPlayerUITimer invalidate];
        self.flashMusicPlayerUITimer = nil;
    }
}


- (void)updataMusicProgress {
    self.currentTimeLabel.text = [self.src_input getPlayTimeString];
    float value = [self.src_input getPlayProgress];
    self.musicProgress.value = value;
    
    if (value >= 1.0f) {
        self.playOrPauseBtn.selected = NO;
        [self stop_music_ui_flash];
    }
}



- (void)action_play_or_pause:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    if (sender.isSelected) {
        [self.src_input startPlayMusic];
        self.totalTimeLabel.text = [self.src_input getDurationString];
        [self start_music_ui_flash];
    } else {
        [self.src_input pausePlayMusic];
        [self stop_music_ui_flash];
    }
}

- (void)action_stop_music:(UIButton *)sender {
    [self.src_input stopPlayMusic];
    self.playOrPauseBtn.selected = NO;
    [self stop_music_ui_flash];
}

#pragma mark 采集源处理
- (BOOL)start_capture {
    NSError *error;
    
    self.capture_session = [[[AVCaptureSession alloc] init] autorelease];
    if (self.came_sel_type == 0) {
        camera_position = AVCaptureDevicePositionFront;
    } else if (self.came_sel_type == 1) {
        camera_position = AVCaptureDevicePositionBack;
    }
    AVCaptureDevice *videoDevice = [self camera_with_position:camera_position];
    
    AVCaptureDeviceInput *videoIn = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    
    if (error) {
//        NSString* message = [NSString stringWithFormat:@"error_code:%ld,system_error_code:%ld,message:%@",CNC_RCode_Video_Camera_Auth_Error,error.code,error.localizedFailureReason];
//        [CNCMobComFunc post_error_message:CNC_RCode_Video_Camera_Auth_Error message:message];
        return NO;
    }
    
    
    
    if (![self.capture_session canAddInput:videoIn]) {
//        [CNCMobComFunc post_error_message:CNC_RCode_Video_Camera_Launch_Failed message:@"error_code:3343,message:Video input add-to-session failed"];
        return NO;
    }
    
    [self.capture_session addInput:videoIn];
    
    if (self.preview) {
//        dispatch_async(dispatch_get_main_queue(), ^(){
//            self.preview_layer = [[[AVCaptureVideoPreviewLayer alloc] initWithSession:self.capture_session] autorelease];
//            self.preview_layer.frame = self.preview.bounds;
//            //            self.preview_layer.contentsGravity = kCAGravityResizeAspectFill;
//            //            self.preview_layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//            //            self.preview_layer.position = CGPointMake(0, 0);
//            self.preview_layer.contentsGravity = kCAGravityCenter;
//            self.preview_layer.videoGravity = AVLayerVideoGravityResizeAspect;
//            
//            [self.preview.layer insertSublayer:self.preview_layer atIndex:0];
//        });
        
        CNCDisplayConfigs displayConfigs;
        displayConfigs.fill_mode = kCNCDisplayFillModePreserveAspectRatio;///原图
        displayConfigs.capture_width = self.para.video_width;
        displayConfigs.capture_height = self.para.video_height;
        
        if (self.pixel_format_type == 4) {
            displayConfigs.bUseCaptureYUV = NO;
        } else {
            displayConfigs.bUseCaptureYUV = YES;
        }
        displayConfigs.displayType = kCNCDisplayNormal;
        displayConfigs.direction = self.video_direct_type;
       
        self.displayer = [[[CNCMobStreamVideoDisplayer alloc] initWithView:self.preview displayConfigs:displayConfigs] autorelease];
        if (camera_position == AVCaptureDevicePositionFront) {
            [self.displayer set_display_mirror:YES];
        }
        
    }
    
    AVCaptureVideoDataOutput *avCaptureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    NSDictionary *settings = nil;
    
//    settings = [[[NSDictionary alloc] initWithObjectsAndKeys:
//                 [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,
//                 nil] autorelease];

    //1 I420  2 NV12 3 NV21 4 RGBA
    if (self.pixel_format_type == 4) {
        settings = [[[NSDictionary alloc] initWithObjectsAndKeys:
                     [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,
                     nil] autorelease];
    } else {
        
        settings = [[[NSDictionary alloc] initWithObjectsAndKeys:
                     [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange],                                   kCVPixelBufferPixelFormatTypeKey,
                     nil] autorelease];
    }
    
    
    avCaptureVideoDataOutput.videoSettings = settings;
    avCaptureVideoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    
    
    [avCaptureVideoDataOutput setSampleBufferDelegate:self queue:queue_video_data_];
    [self.capture_session addOutput:self.capture_output = avCaptureVideoDataOutput];
    
    AVCaptureConnection *videoConnection = [self.capture_output connectionWithMediaType:AVMediaTypeVideo];
    if ([videoConnection isVideoOrientationSupported]) {
        if (self.video_direct_type == CNC_ENM_Direct_Vertical) {
            [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }else {
            [videoConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        }
    }
    
//    if (kCNCSysVerson >= 8) {
//        AVCaptureVideoStabilizationMode stabilizationMode = AVCaptureVideoStabilizationModeCinematic;
//        if ([videoDevice.activeFormat isVideoStabilizationModeSupported:stabilizationMode]) {
//            [videoConnection setPreferredVideoStabilizationMode:stabilizationMode];
//        }
//    }
    
    
    
    if (![videoDevice supportsAVCaptureSessionPreset:self.came_resolution]) {
        self.capture_session.sessionPreset = AVCaptureSessionPreset640x480;
        
        if (self.video_direct_type == CNC_ENM_Direct_Vertical) {
            self.para.video_width = 480;
            self.para.video_height = 640;
        }else {
            self.para.video_width = 640;
            self.para.video_height = 480;
        }
        
        
        NSLog(@"Resolution is not supported ! \n 无法支持设定的分辨率 !");
    } else {
        
        self.capture_session.sessionPreset = self.came_resolution;
        
    }
    

    [self.src_input preset_para:self.para];
    if (kCNCSysVerson >= 7) {
        int32_t max_fps = (int32_t)30;
        int32_t min_fps = (int32_t)10;
        int32_t video_fps = (int32_t)self.para.video_fps;
        
        if (video_fps>max_fps || video_fps<min_fps) {
            video_fps = max_fps;
        }
        
        NSError *error;
        CMTime frameDuration = CMTimeMake(1, video_fps);
        NSArray *supportedFrameRateRanges = [videoDevice.activeFormat videoSupportedFrameRateRanges];
        BOOL frameRateSupported = NO;
        for (AVFrameRateRange *range in supportedFrameRateRanges) {
            if (CMTIME_COMPARE_INLINE(frameDuration, >=, range.minFrameDuration) &&
                CMTIME_COMPARE_INLINE(frameDuration, <=, range.maxFrameDuration)) {
                frameRateSupported = YES;
            }
        }
        
        if (frameRateSupported && [videoDevice lockForConfiguration:&error]) {
            [videoDevice setActiveVideoMaxFrameDuration:frameDuration];
            [videoDevice setActiveVideoMinFrameDuration:frameDuration];
            
//            videoDevice.smoothAutoFocusEnabled = YES;
            //            videoDevice.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionNone;
            //            [videoDevice setFocusMode:AVCaptureFocusModeAutoFocus];
            
            [videoDevice unlockForConfiguration];
        }
    }
    
    // save the default format
    self.default_format = videoDevice.activeFormat;
    
    [self.lock_oprt lock];
    [self.capture_session startRunning];
    [self.lock_oprt unlock];
    
//    DDLogVerbose(@"self.capture_session.sessionPreset = %@", self.capture_session.sessionPreset);
    
    return YES;
}

- (NSInteger)get_resolution_type:(NSString *)str {

    if ([str isEqualToString:AVCaptureSessionPreset352x288]) {
        return CNCResolution_5_4__352x288;
    }
    
    if ([str isEqualToString:AVCaptureSessionPreset640x480]) {
        return CNCResolution_4_3__640x480;
    }
    
    if ([str isEqualToString:AVCaptureSessionPresetiFrame960x540]) {
        return CNCResolution_16_9__960x540;
    }
    
    if ([str isEqualToString:AVCaptureSessionPreset1280x720]) {
        return CNCResolution_16_9__1280x720;
    }
    
    return CNCResolution_4_3__640x480;
}



- (void)re_start_capture {
    [self.lock_oprt lock];
    
    BOOL isRunning = self.capture_session.isRunning;
    
    if (!isRunning) {
        [self.capture_session startRunning];
    }
    
    [self.lock_oprt unlock];
}

- (AVCaptureDevicePosition)swap_cameras {
    
    AVCaptureDevicePosition new_position = (camera_position == AVCaptureDevicePositionFront) ? AVCaptureDevicePositionBack : AVCaptureDevicePositionFront;
    
    return camera_position = [self reset_came_pos:new_position];
    
}

- (AVCaptureDevicePosition)reset_came_pos:(AVCaptureDevicePosition)new_position {
    // Assume the session is already running
    
    //    dispatch_sync(queue_video_data_, ^(){
    
    NSArray *inputs = self.capture_session.inputs;
    for ( AVCaptureDeviceInput *input in inputs ) {
        AVCaptureDevice *device = input.device;
        if ( [device hasMediaType:AVMediaTypeVideo] ) {
            AVCaptureDevicePosition position = device.position;
            
            if (position == new_position) {
                //不用做
                break;
            }
            
            AVCaptureDevice *newCamera = nil;
            AVCaptureDeviceInput *newInput = nil;
            
            newCamera = [self camera_with_position:new_position];
            
            // beginConfiguration ensures that pending changes are not applied immediately
            [self.capture_session beginConfiguration];
            
            [self.capture_session removeInput:input];
            
            newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
            
            if (![newCamera supportsAVCaptureSessionPreset:self.came_resolution]) {
                self.capture_session.sessionPreset = AVCaptureSessionPreset640x480;
                
                if (self.video_direct_type == CNC_ENM_Direct_Vertical) {
                    self.para.video_width = 480;
                    self.para.video_height = 640;
                }else {
                    self.para.video_width = 640;
                    self.para.video_height = 480;
                }
                
                NSLog(@"Resolution is not supported ! \n 无法支持设定的分辨率 !");
            } else {
                self.capture_session.sessionPreset = self.came_resolution;
            }
            

            [self.src_input preset_para:self.para];
            [self.capture_session addInput:newInput];
            
            AVCaptureConnection *videoConnection = [self.capture_output connectionWithMediaType:AVMediaTypeVideo];
            if ([videoConnection isVideoOrientationSupported]) {
                if (self.video_direct_type == CNC_ENM_Direct_Vertical) {
                    [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
                }else {
                    [videoConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
                }
            }
            
//            if (kCNCSysVerson >= 8) {
//                AVCaptureVideoStabilizationMode stabilizationMode = AVCaptureVideoStabilizationModeCinematic;
//                if ([newCamera.activeFormat isVideoStabilizationModeSupported:stabilizationMode]) {
//                    [videoConnection setPreferredVideoStabilizationMode:stabilizationMode];
//                }
//            }
            
            if (kCNCSysVerson >= 7) {
                int32_t max_fps = (int32_t)30;
                int32_t min_fps = (int32_t)10;
                int32_t video_fps = (int32_t)[self.src_input get_video_fps];
                
                if (video_fps>max_fps || video_fps<min_fps) {
                    video_fps = max_fps;
                }
                
                NSError *error;
                CMTime frameDuration = CMTimeMake(1, video_fps);
                NSArray *supportedFrameRateRanges = [newCamera.activeFormat videoSupportedFrameRateRanges];
                BOOL frameRateSupported = NO;
                for (AVFrameRateRange *range in supportedFrameRateRanges) {
                    if (CMTIME_COMPARE_INLINE(frameDuration, >=, range.minFrameDuration) &&
                        CMTIME_COMPARE_INLINE(frameDuration, <=, range.maxFrameDuration)) {
                        frameRateSupported = YES;
                    }
                }
                
                if (frameRateSupported && [newCamera lockForConfiguration:&error]) {
                    [newCamera setActiveVideoMaxFrameDuration:frameDuration];
                    [newCamera setActiveVideoMinFrameDuration:frameDuration];
                    [newCamera unlockForConfiguration];
                }
            }
            
            
            // save the default format
            self.default_format = newCamera.activeFormat;
            
            // Changes take effect once the outermost commitConfiguration is invoked.
            [self.capture_session commitConfiguration];
            
            
            
            break;
        }
    }
    //    });
    
    if (self.displayer) {
        ///更新显示的镜像问题
        if (new_position == AVCaptureDevicePositionBack) {
            [self.displayer set_display_mirror:NO];
        }else{
            [self.displayer set_display_mirror:YES];
        }
    }
    
    return new_position;
}

- (void)setLayerHidden:(BOOL)isHidden{
    //    self.preview_layer.frame = CGRectMake(0, 0, 0, 0);
    dispatch_async(dispatch_get_main_queue(), ^(){
        self.preview_layer.hidden = isHidden;
    });
}
- (void)stop_capture {
    
    [self.lock_oprt lock];
    
    BOOL isRunning = self.capture_session.isRunning;
    
    if (isRunning) {
        [self.capture_session stopRunning];
    }
    
    [self.lock_oprt unlock];
    
}

- (void)remove_all_inputs {
    NSArray *inputs = self.capture_session.inputs;
    [self.capture_session beginConfiguration];
    for ( AVCaptureDeviceInput *input in inputs ) {
        [self.capture_session removeInput:input];
    }
    [self.capture_session commitConfiguration];
}

- (void)reset_video_fps:(NSInteger)video_fps {
    
    if (!self.default_format || !self.capture_session) {
//        DDLogError(@"session is null;");
        return;
    }
    
    NSError *error;
    CMTime frameDuration = CMTimeMake(1, (int32_t)video_fps);
    NSArray *supportedFrameRateRanges = [self.default_format videoSupportedFrameRateRanges];
    BOOL frameRateSupported = NO;
    for (AVFrameRateRange *range in supportedFrameRateRanges) {
        if (CMTIME_COMPARE_INLINE(frameDuration, >=, range.minFrameDuration) &&
            CMTIME_COMPARE_INLINE(frameDuration, <=, range.maxFrameDuration)) {
            frameRateSupported = YES;
        }
    }
    
    AVCaptureDeviceInput *videoDeviceInput = [[self.capture_session inputs]lastObject];
    
    AVCaptureDevice *videoDevice = [videoDeviceInput device];
    
    if (frameRateSupported && [videoDevice lockForConfiguration:&error]) {
        //videoDevice.activeFormat = self.default_format;
        [videoDevice setActiveVideoMaxFrameDuration:frameDuration];
        [videoDevice setActiveVideoMinFrameDuration:frameDuration];
        [videoDevice unlockForConfiguration];
    }
}

- (AVCaptureDevice *)camera_with_position:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices ) {
        if ( device.position == position ) {
            return device;
        }
    }
    
    return nil;
}

- (void)dealloc {
    
    [self remove_notify];
    
    self.displayer = nil;
    
    if ([self.timer isValid]) {
        [self.timer invalidate];
        self.timer = nil;
    }
    self.closeButton = nil;
    self.record_btn = nil;
    self.stat = nil;
    
    self.capture_session = nil;
    self.default_format = nil;
    self.preview = nil;
    self.preview_layer = nil;
    self.lock_oprt = nil;
    
    dispatch_release(queue_video_data_);
    queue_video_data_ = NULL;
    self.capture_output = nil;
    
    self.para = nil;
    self.src_input = nil;
    self.came_resolution = nil;
    
    self.music_pickView = nil;
    self.store_slider = nil;
    self.backView = nil;
    self.music_array = nil;
    self.roomType_pickView = nil;
    self.audioBeautyView = nil;
    self.reverb_slider = nil;
    self.currentTimeLabel = nil;
    self.musicProgress = nil;
    self.totalTimeLabel = nil;
    self.store_view = nil;
    self.output_slider = nil;
    if ([self.flashMusicPlayerUITimer isValid]) {
        [self.flashMusicPlayerUITimer invalidate];
        self.flashMusicPlayerUITimer = nil;
    }
    self.playOrPauseBtn = nil;
    self.human_slider = nil;
    self.stopButton = nil;
    self.music_slider = nil;
    self.roomType_array = nil;
    self.sei_textview = nil;
    self.sei_view = nil;
    self.sei_questions_array = nil;
    self.record_code_data_array = nil;
    self.record_code_tableView = nil;
    self.sei_questions_pickView = nil;
    self.sei_questions_title_array = nil;
    self.sei_json_dict = nil;
    [super dealloc];
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if ([captureOutput isKindOfClass:[AVCaptureVideoDataOutput class]]) {

        if (self.new_format_input) {
            CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            [self.src_input send_frame_pixelBufferRef:imageBuffer format:self.pixel_format_type time_stamp:[[NSDate date] timeIntervalSince1970]];
            
        } else {
            //        //1 I420  2 NV12 3 NV21 4 RGBA
            if (self.record_btn.isSelected) {
                if (self.pixel_format_type == 4) {
                    [self do_with_frame_RGBA:sampleBuffer];
                } else {
                    [self do_with_frame_YUV:sampleBuffer];
                }
            }else {
                //do nothing
            }
        }
        [self.displayer processVideoSampleBuffer:sampleBuffer];
    }
}

- (void)do_with_frame_RGBA:(CMSampleBufferRef)sampleBuffer {
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    uint8_t *p_src_buf = (uint8_t*)CVPixelBufferGetBaseAddress(imageBuffer);
    
    size_t byte_per_row = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    size_t width  = CVPixelBufferGetWidth(imageBuffer);
    
    int real_width = int(width * 4);
    
    UInt8 *dst_buf = NULL;
    int len = int(real_width * height);
    dst_buf = new UInt8[len];
    do {
        
        if (dst_buf == NULL) {
            break;
        }
        memset(dst_buf, 0x0, len);
        UInt8 *p_tmp_dst = dst_buf;
        UInt8 *p_tmp_src = p_src_buf;
        
        if (byte_per_row != real_width) {
            for (unsigned int y = 0; y < height; ++y) {
                memcpy(p_tmp_dst, p_tmp_src, real_width);
                p_tmp_dst += real_width;
                p_tmp_src += byte_per_row;
            }
        } else {
            memcpy(dst_buf, p_src_buf, len);
        }
        
        [self.src_input send_frame_buf:dst_buf pix_width:int(real_width) pix_height:int(height) format:CNCENM_buf_format_BGRA time_stamp:[[NSDate date] timeIntervalSince1970]];
        
    } while (0);
    
    if (dst_buf != NULL) {
        delete []dst_buf;
    }
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
        
}

- (void)do_with_frame_YUV:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
//    uint8_t *buf = (uint8_t*)CVPixelBufferGetBaseAddress(imageBuffer);
    const int plane_y_idx = 0;
    const int plane_uv_idx = 1;
    
    UInt8 *p_src_y = (UInt8 *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, plane_y_idx);
    UInt8 *p_src_uv = (UInt8 *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, plane_uv_idx);
    
    size_t byte_per_row_y = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,plane_y_idx);
    size_t byte_per_row_uv = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer,plane_uv_idx);
    
    size_t height = CVPixelBufferGetHeightOfPlane(imageBuffer,plane_y_idx);
    size_t width  = CVPixelBufferGetWidthOfPlane(imageBuffer,plane_y_idx);
    
    //其实这个lock在这里释放是不对的
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
//    int stride_y = (int)(byte_per_row_y * height);
//    int stride_uv = (int)(byte_per_row_uv * height)/2;
    int stride_y = (int)(width * height);
    int stride_uv = (int)(width * height)/2;
    
    size_t len = stride_y + stride_uv;
    GLubyte *dst_buf = NULL;
    
    dst_buf = new UInt8[len];
    if (dst_buf == NULL) {
        return;
    }
    
    memset(dst_buf, 0x0, len);
    
    //1 I420  2 NV12 3 NV21 4 RGBA
    UInt8 *p_dst_y = dst_buf;
    
    
    UInt8 *p_tmp_dst_y = p_dst_y;
    UInt8 *p_tmp_src_y = p_src_y;
    if (byte_per_row_y != width) {
        for (unsigned int y = 0; y < height; ++y) {
            memcpy(p_tmp_dst_y, p_tmp_src_y, width);
            p_tmp_dst_y += width;
            p_tmp_src_y += byte_per_row_y;
        }
    } else {
        memcpy(p_dst_y, p_src_y, stride_y);
    }
    
    if (self.pixel_format_type == 1) {
        //2 I420
        
        UInt8 *p_dst_u = NULL;
        UInt8 *p_dst_v = NULL;
//        p_dst_y = dst_buf;
        p_dst_u = dst_buf + stride_y;
        p_dst_v = dst_buf + stride_y + stride_uv/2;
        
        if (byte_per_row_uv != width) {
            for (unsigned int j = 0; j < height/2; ++j) {
                int base_dst_idx = int(j * width/2);
                int base_src_idx = int(j * byte_per_row_uv);
                int idx = 0;
                for (idx = 0; idx < width/2; ++idx) {
                    int idx_src = idx<<1;
                    p_dst_u[base_dst_idx + idx] = p_src_uv[base_src_idx + idx_src];
                    p_dst_v[base_dst_idx + idx] = p_src_uv[base_src_idx + idx_src+1];
                }
            }
        } else {
            int idx = 0;
            for (idx = 0; idx < stride_uv/2; ++idx) {
                int idx_src = idx<<1;
                p_dst_u[idx] = p_src_uv[idx_src];
                p_dst_v[idx] = p_src_uv[idx_src+1];
            }

        }
        
        [self.src_input send_frame_buf:dst_buf pix_width:int(width) pix_height:int(height*3/2) format:CNCENM_buf_format_I420 time_stamp:[[NSDate date] timeIntervalSince1970]];
        
    } else if (self.pixel_format_type == 2) {
        //3 NV12
//        p_dst_y = dst_buf;
        UInt8 *p_dst_uv = dst_buf + stride_y;
        UInt8 *p_tmp_src_uv = p_src_uv;
        
        if (byte_per_row_uv != width) {
            for (unsigned int y = 0; y < height/2; ++y) {
                memcpy(p_dst_uv, p_tmp_src_uv, width);
                p_dst_uv += width;
                p_tmp_src_uv += byte_per_row_uv;
            }
        } else {
            memcpy(p_dst_uv, p_src_uv, stride_uv);
        }
        
        [self.src_input send_frame_buf:dst_buf pix_width:int(width) pix_height:int(height*3/2) format:CNCENM_buf_format_NV12 time_stamp:[[NSDate date] timeIntervalSince1970]];
        
    } else if (self.pixel_format_type == 3) {
        //4 NV21
//        p_dst_y = dst_buf;
        UInt8 *p_dst_uv = dst_buf + stride_y;
        UInt8 *p_tmp_src_uv = p_src_uv;
        
        if (byte_per_row_uv != width) {
            for (unsigned int y = 0; y < height/2; ++y) {
                memcpy(p_dst_uv, p_tmp_src_uv, width);
                p_dst_uv += width;
                p_tmp_src_uv += byte_per_row_uv;
            }
        } else {
            memcpy(p_dst_uv, p_src_uv, stride_uv);
        }
        
        p_dst_uv = dst_buf + stride_y;
        for (int i = 0; i < stride_y/2; i=i+2) {
            UInt8 tmp = p_dst_uv[i];
            p_dst_uv[i] = p_dst_uv[i+1];
            p_dst_uv[i + 1] = tmp;
            
        }
        
        [self.src_input send_frame_buf:dst_buf pix_width:int(width) pix_height:int(height*3/2) format:CNCENM_buf_format_NV21 time_stamp:[[NSDate date] timeIntervalSince1970]];
    }
    
    if (dst_buf != NULL) {
        delete []dst_buf;
        dst_buf = NULL;
    }
    
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark 旋转相关
//旋转相关
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    if (self.video_direct_type == CNC_ENM_Direct_Vertical) {
        return UIInterfaceOrientationPortrait;
    }
    
    return UIInterfaceOrientationLandscapeRight;
}
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    NSLog(@"willAnimateRotationToInterfaceOrientation");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)toInterfaceOrientation {
    
    if (self.video_direct_type == CNC_ENM_Direct_Vertical) {
        return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
    }
    
    //    return YES;
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

//#pragma mark - IOS6.0 旋转
- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (self.video_direct_type == CNC_ENM_Direct_Vertical) {
        return UIInterfaceOrientationMaskPortrait;
    }
    //return UIInterfaceOrientationLandscapeRight;
    return UIInterfaceOrientationMaskLandscapeRight;
}


#pragma mark 系统状态通知
- (void)add_notify {
    //监听是否触发home键挂起程序.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notify_app_will_resign_active:)                                               name:UIApplicationWillResignActiveNotification object:nil];
    
    //监听是否重新进入程序程序.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notify_app_will_did_become_active:)                                                name:UIApplicationDidBecomeActiveNotification object:nil];
    
}

- (void)remove_notify {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)notify_app_will_resign_active:(NSNotification*)notify {
    is_enter_back_ground = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stop_capture];
    });
}

- (void)notify_app_will_did_become_active:(NSNotification*)notify {
    is_enter_back_ground = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self re_start_capture];
    });
}
#pragma mark - sei
- (void)action_add_sei_json_str:(UIButton *)sender {
    
    [self.sei_textview resignFirstResponder];
    [self.sei_json_dict removeObjectForKey:@"questionList"];
    NSArray *questionsList = [NSArray arrayWithObject:[self.sei_questions_array objectAtIndex:sei_question_index]];
    [self.sei_json_dict setObject:questionsList forKey:@"questionList"];
    NSString *json_str = [CNCDemoFunc convertToJSONData:self.sei_json_dict];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        [self.src_input set_sw_encoder_push_time_stamp:json_str];
    });
}
- (void)action_close_sei:(UIButton *)btn {
    dispatch_async(dispatch_get_main_queue(), ^(){
        [self.sei_view removeFromSuperview];
        [self.sei_textview resignFirstResponder];
    });
}
- (void)action_open_sei_view:(UIButton *)btn {
    if (self.para.encoder_type == CNC_ENM_Encoder_SW) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            [self.view addSubview:self.sei_view];
        });
    } else {
        UIAlertView *alert=[[[UIAlertView alloc] initWithTitle:nil message:@"此功能需开启软编" delegate:self cancelButtonTitle:@"关闭" otherButtonTitles:nil] autorelease];
        [alert show];
    }
}
#pragma mark 录制视频
- (void)store_sliderValueChanged:(UISlider *)paramSender {
    
    UILabel *label = [self.view viewWithTag:3220];
    if (label) {
        if (is_long_store && store_type != CNCRecordVideoType_GIF) {
            if (paramSender.value != paramSender.maximumValue) {
                label.text = [NSString stringWithFormat:@"录制大小:%.2fM",paramSender.value];
            } else {
                label.text = [NSString stringWithFormat:@"录制大小:不限制"];
            }
            
        } else {
            label.text = [NSString stringWithFormat:@"录制时间:%.2fs",paramSender.value];
        }
    }
    
    
}
- (void)action_store_video:(UIButton *)sender {
    [self.view addSubview:self.store_view];
}
- (void)actionCloseStore:(UIButton *)sender {
    if (has_show_in_front_view) {
        has_show_in_front_view = NO;
        [self.store_view removeFromSuperview];
    }
    
}
- (void)action_set_long:(UIButton *)sender {
    
    UIButton *btn0 = [self.view viewWithTag:3200];
    UIButton *btn2 = [self.view viewWithTag:3202];
    UIButton *btn3 = [self.view viewWithTag:3203];
    UIButton *btn4 = [self.view viewWithTag:3204];
    
    UILabel *time_lable = [self.view viewWithTag:3220];
    UILabel *label = [self.view viewWithTag:3220];
    
    if (store_type == CNCRecordVideoType_GIF) {
        store_type = CNCRecordVideoType_FLV;
        btn0.layer.borderColor = SELECTEDCOLOR.CGColor;
        [btn0 setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
        btn2.layer.borderColor = LIGHTGRAY.CGColor;
        [btn2 setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
        
    }
    switch (sender.tag - 3203) {
        case 0:
            is_long_store = NO;
            time_lable.alpha = 1;
            self.store_slider.alpha = 1;
            if (self.store_slider.minimumValue != 3.0f || self.store_slider.maximumValue != 60.0f) {
                self.store_slider.minimumValue = 3.0f;
                self.store_slider.maximumValue = 60.0;
                self.store_slider.value = 10.0f;
            }
            if (label) {
                label.text = [NSString stringWithFormat:@"录制时间:%.2fs",self.store_slider.value];
            }
            btn3.layer.borderColor = SELECTEDCOLOR.CGColor;
            [btn3 setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
            btn4.layer.borderColor = LIGHTGRAY.CGColor;
            [btn4 setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
            break;
        case 1:
            is_long_store = YES;
            time_lable.alpha = 1;
            self.store_slider.alpha = 1;
            if (self.store_slider.minimumValue != 100.0/1024.0f || self.store_slider.maximumValue != 20.0f) {
                
                self.store_slider.minimumValue = 100.0/1024.0f;
                self.store_slider.maximumValue = 20.0;
                self.store_slider.value = 5.0f;
                
            }
            
            if (label) {
                label.text = [NSString stringWithFormat:@"录制大小:%.2fM",self.store_slider.value];
            }
            btn4.layer.borderColor = SELECTEDCOLOR.CGColor;
            [btn4 setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
            btn3.layer.borderColor = LIGHTGRAY.CGColor;
            [btn3 setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
}
- (void)action_set_type:(UIButton *)sender {
    
    UIButton *btn0 = [self.view viewWithTag:3200];
    UIButton *btn1 = [self.view viewWithTag:3201];
    UIButton *btn2 = [self.view viewWithTag:3202];
    UIButton *btn3 = [self.view viewWithTag:3203];
    UIButton *btn4 = [self.view viewWithTag:3204];
    
    UILabel *time_lable = [self.view viewWithTag:3220];
    
    switch (sender.tag-3200) {
        case 0:
            
            store_type = CNCRecordVideoType_FLV;
            if (is_long_store) {
                if (self.store_slider.minimumValue != 100.0/1024.0f || self.store_slider.maximumValue != 20.0f) {
                    
                    self.store_slider.minimumValue = 100.0/1024.0f;
                    self.store_slider.maximumValue = 20.0;
                    self.store_slider.value = 5.0f;
                    
                }
                btn3.layer.borderColor = LIGHTGRAY.CGColor;
                [btn3 setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
                
                btn4.layer.borderColor = SELECTEDCOLOR.CGColor;
                [btn4 setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
            } else {
                if (self.store_slider.minimumValue != 3.0f || self.store_slider.maximumValue != 60.0f) {
                    self.store_slider.minimumValue = 3.0f;
                    self.store_slider.maximumValue = 60.0;
                    self.store_slider.value = 10.0f;
                }
                
                btn3.layer.borderColor = SELECTEDCOLOR.CGColor;
                [btn3 setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
                
                btn4.layer.borderColor = LIGHTGRAY.CGColor;
                [btn4 setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
            }
            btn0.layer.borderColor = SELECTEDCOLOR.CGColor;
            [btn0 setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
            btn1.layer.borderColor = LIGHTGRAY.CGColor;
            [btn1 setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
            btn2.layer.borderColor = LIGHTGRAY.CGColor;
            [btn2 setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
            
            break;
        case 1:
            
            store_type = CNCRecordVideoType_MP4;
            if (is_long_store) {
                if (self.store_slider.minimumValue != 100.0/1024.0f || self.store_slider.maximumValue != 20.0f) {
                    
                    self.store_slider.minimumValue = 100.0/1024.0f;
                    self.store_slider.maximumValue = 20.0;
                    self.store_slider.value = 5.0f;
                    
                }
                btn3.layer.borderColor = LIGHTGRAY.CGColor;
                [btn3 setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
                
                btn4.layer.borderColor = SELECTEDCOLOR.CGColor;
                [btn4 setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
            } else {
                if (self.store_slider.minimumValue != 3.0f || self.store_slider.maximumValue != 60.0f) {
                    self.store_slider.minimumValue = 3.0f;
                    self.store_slider.maximumValue = 60.0f;
                    self.store_slider.value = 10.0f;
                }
                
                btn3.layer.borderColor = SELECTEDCOLOR.CGColor;
                [btn3 setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
                
                btn4.layer.borderColor = LIGHTGRAY.CGColor;
                [btn4 setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
            }
            btn0.layer.borderColor = LIGHTGRAY.CGColor;
            [btn0 setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
            btn1.layer.borderColor = SELECTEDCOLOR.CGColor;
            [btn1 setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
            btn2.layer.borderColor = LIGHTGRAY.CGColor;
            [btn2 setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
            break;
        case 2:
            store_type = CNCRecordVideoType_GIF;
            
            if (self.store_slider.minimumValue != 0.1f || self.store_slider.maximumValue != 5.0f) {
                self.store_slider.minimumValue = 0.1f;
                self.store_slider.maximumValue = 5.0;
                self.store_slider.value = 1.0f;
            }
            
            btn0.layer.borderColor = LIGHTGRAY.CGColor;
            [btn0 setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
            btn1.layer.borderColor = LIGHTGRAY.CGColor;
            [btn1 setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
            btn2.layer.borderColor = SELECTEDCOLOR.CGColor;
            [btn2 setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
            btn4.layer.borderColor = LIGHTGRAY.CGColor;
            [btn4 setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
            btn3.layer.borderColor = LIGHTGRAY.CGColor;
            [btn3 setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
    if (time_lable) {
        if (is_long_store && store_type != CNCRecordVideoType_GIF) {
            if (self.store_slider.value == self.store_slider.maximumValue) {
                time_lable.text = [NSString stringWithFormat:@"录制大小:不限制"];
            } else {
                time_lable.text = [NSString stringWithFormat:@"录制大小:%.2fM",self.store_slider.value];
            }
            
        } else {
            time_lable.text = [NSString stringWithFormat:@"录制时间:%.2fs",self.store_slider.value];
        }
        
    }
}
- (void)action_store_event:(UIButton *)sender {
    UIButton *btn_open = [self.view viewWithTag:3210];
    UIButton *btn_close = [self.view viewWithTag:3211];
    if (sender.tag == 3210) {
        btn_close.layer.borderColor = LIGHTGRAY.CGColor;
        [btn_close setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
        [self store_video_start:YES];
    } else {
        
        btn_open.layer.borderColor = LIGHTGRAY.CGColor;
        [btn_open setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
        [self store_video_start:NO];
    }
    sender.layer.borderColor = SELECTEDCOLOR.CGColor;
    [sender setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
    [self.store_view removeFromSuperview];
    has_show_in_front_view = NO;
}
- (void)store_video_start:(BOOL) start{
    if (!self.is_pushing) {
        return;
    }
    
    
    MBProgressHUD* progressHud_ = [[[MBProgressHUD alloc] initWithView:self.view] autorelease];
    progressHud_.removeFromSuperViewOnHide = YES;
    BOOL is_doing_store = [self.src_input is_doing_store];
    
    if (start) {
        if (is_doing_store) {
            //重复开启录制
            return;
        } else {
            progressHud_.labelText = @"正在启动录制...";
        }
    } else {
        if (is_doing_store) {
            progressHud_.labelText = @"正在停止录制...";
            
        } else {
            //重复停止录制
            return;
        }
    }
    
    [self.view addSubview:progressHud_];
    [progressHud_ show:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        BOOL ret = NO;
        //        NSString *msg = @"失败";
        if (start) {
            int max_time = 0;
            int max_size = 0;
            if (is_long_store && store_type != CNCRecordVideoType_GIF) {
                if (self.store_slider.value != self.store_slider.maximumValue) {
                    max_size = self.store_slider.value *1024*1024;
                } else {
                    max_size = 0;
                }
                
            } else {
                max_time = self.store_slider.value*1000;
            }
            NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss:SSS"];
            NSString *str = [[[NSString alloc] initWithFormat:@"%@", [dateFormatter stringFromDate:[NSDate date]]] autorelease];
            
            ret = [self.src_input start_store_video:nil fileType:store_type max_time:max_time long_store:is_long_store size:max_size return_id:str];
            if (!ret) {
                //启动录制失败
            } else {
                
            }
            
        } else {
            
            [self.src_input stop_store_video];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [progressHud_ hide:YES];
        });
    });
    
}



@end
