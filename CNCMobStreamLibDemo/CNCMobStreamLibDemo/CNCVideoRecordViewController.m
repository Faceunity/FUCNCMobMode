//
//  CNCVideoRecordViewController.m
//  CNCMobStreamDemo
//
//  Created by mfm on 16/4/21.
//  Copyright © 2016年 cad. All rights reserved.
//

#import "CNCVideoRecordViewController.h"
#import "CNCDemoFunc.h"
#import "MBProgressHUD.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/UTCoreTypes.h>

#define LIGHTGRAY [UIColor colorWithWhite:212.0/255 alpha:1.f]
#define SELECTEDCOLOR [UIColor colorWithRed:252.f/255 green:51.f/255 blue:66.f/255 alpha:1.f]
#define STREAM_NAME_CACHE [[NSUserDefaults standardUserDefaults]stringForKey:@"stream_name_cache"]


@interface CNCVideoRecordViewController () <UIGestureRecognizerDelegate,UIPickerViewDelegate,UIPickerViewDataSource,UITextFieldDelegate,UITableViewDataSource,UITableViewDelegate> {
    CGFloat screen_w_;
    CGFloat screen_h_;
    
    CGFloat _beginGestureScale;
    //放大的倍数（1~videoZoomFactor)
    CGFloat _effectiveScale;
    //    //手动聚焦时的聚焦点
    //    UIImageView *_foucsCursor;
    //实时速率
    unsigned int _speed;
    //提示信息
    NSString *_tips;
    //开始推流时间
    double _startTime;
    
    NSInteger _resolution_index;
    CGFloat beauty_smoothDegree;
    CGFloat beauty_effect;
    CGFloat filter_effect;
    CNCBEAUTY beauty_type;
    CNCCOMBINE combine_filter_type;
    NSInteger _ovelay_mask_index;
    CNCRecordVideoType store_type;
    BOOL is_long_store;
    NSTimer *shot_timer;
    int shot_time_index;
    
    CGFloat video_caputre_width;
    CGFloat video_caputre_height;
    
    BOOL source_mirror;//编码
    BOOL preview_mirror;//预览
    int _push_bad_network_time_count;
    NSString *bad_network_message;
    
    
}

// 在UI上显示的调试信息
@property (nonatomic, retain) UILabel *stat;
// 调试信息刷新timer thread
@property (nonatomic, retain) NSTimer *timer;

// UI上的一些操作控件或视图
@property (nonatomic, retain) UIScrollView *backView;
@property (nonatomic, retain) UISlider *bitrate_slider;
@property (nonatomic, retain) UISlider *beauty_slider;
@property (nonatomic, retain) UISlider *effect_slider;
@property (nonatomic, retain) UISlider *filter_slider;
@property (nonatomic, retain) UIButton *recordButton;
@property (nonatomic, retain) UIButton *torchButton;
@property (nonatomic, retain) UIButton *closeButton;
@property (nonatomic, retain) UIButton *beauty_btn;

// 预览时支持的可设置的一些参数视图
@property (nonatomic, retain) UIView *settingView;
@property (nonatomic, retain) UITextView *rtmp_url_textview;

@property (nonatomic, retain) NSArray *array;
@property (nonatomic, retain) NSArray *array_value;

//手动聚焦时的聚焦点
@property (nonatomic, retain) UIImageView *foucs_cursor;
//美颜
@property (nonatomic, retain) UIPickerView *beauty_pickView;
@property (nonatomic, retain) UIPickerView *combine_pickView;
@property (nonatomic, retain) NSArray *beauty_array;
@property (nonatomic, retain) NSArray *combine_array;
@property (nonatomic, retain) UIView *beauty_view;
@property (nonatomic) BOOL has_video;
@property(nonatomic, retain) UIView *overlay_mask_view;
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
@property(nonatomic) BOOL is_pushing;
//录制视频
@property(nonatomic, retain) UIView *store_view;
@property (nonatomic, retain) UISlider *store_slider;

@property (nonatomic, assign) BOOL bMusicLoopEnable;

@property(nonatomic, retain) UIView *preview;
@property(nonatomic)CNCENMDirectType viewcontroller_direct;//初始的vc的方向
//@property(nonatomic)CNCENMDirectType video_direct;
@property(nonatomic, retain) UIView *mirror_set_view;//镜像
//水印
@property (nonatomic, retain) NSArray *overlay_mask_logo_array;
@property (nonatomic, retain) NSArray *overlay_mask_text_array;
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

//切换摄像头时的镜像设置
@property (nonatomic) NSInteger cur_swap_mirror_idx;
@property (nonatomic, retain) NSArray *array_swap_mirror;
@end

@implementation CNCVideoRecordViewController
{
    float overlay_mask_rect_x;
    float overlay_mask_rect_y;
    float overlay_mask_rect_width;
    float overlay_mask_rect_height;
    NSInteger overlay_mask_logo_index;
    NSInteger overlay_mask_text_index;
    NSInteger sei_question_index;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.has_video = self.stream_cfg.has_video;
    
    self.view.backgroundColor = [UIColor grayColor];
    ///初始化参数
    [self init_para];
    ///添加通知
    [self addObservers];
    ///添加手势
    [self addGestureRecognizer];
    
    self.viewcontroller_direct = self.stream_cfg.direction;
//    self.video_direct = self.stream_cfg.direction;
    
    ///配置SDK参数
    [CNCMobStreamSDK set_stream_config:self.stream_cfg];
    [CNCMobStreamSDK set_sw_encoder_priority_type:self.sw_encoder_priority_type];
    
    ///可选择采集模式是否带有 回音消除、降噪、自动增益功能的开关，但可能也会引发声音变小问题
//    [CNCMobStreamSDK set_audio_process_enable:YES];
    
    ///如果self.stream_cfg.has_video 设为NO时，可以不调用set_show_video_preview:
    ///调用的话，会显示画面，但不会推视频帧
    ///set_show_video_preview:参数可传nil；
    CGFloat width = screen_w_;
    CGFloat heigth = screen_h_;
    CGFloat x = (screen_w_-width)/2;
    CGFloat y = (screen_h_-heigth)/2;   
    
    self.is_pushing = NO;
   

    UIView *preview = [[[UIView alloc] initWithFrame:CGRectMake(x,y,width,heigth)] autorelease];
    [self.view addSubview:preview];
    self.preview = preview;
    
    NSInteger retry_cnt = 0;
    BOOL is_camera_start = NO;
    
    BOOL preview_mirror = NO;
    BOOL source_mirror = NO;
    
    
    /*
    0 - @"默认镜像设置",
    1 - @"预览:YES 编码:YES",
    2 - @"预览:YES 编码:NO",
    3 - @"预览:NO 编码:NO",
    4 - @"预览:NO 编码:YES",
     */
    switch (self.mirror_idx) {
        case 1: {
            preview_mirror = YES;
            source_mirror = YES;
        }
            break;
        case 2: {
            preview_mirror = YES;
            source_mirror = NO;
        }
            break;
        case 3: {
            preview_mirror = NO;
            source_mirror = NO;
        }
            break;
        case 4: {
            preview_mirror = NO;
            source_mirror = YES;
        }
            break;
            
        default:
            break;
    }
    
    do {
        
        if (self.mirror_idx == 0) {
            is_camera_start = [CNCMobStreamSDK set_show_video_preview:preview];
        } else {
            is_camera_start = [CNCMobStreamSDK set_show_video_preview:preview source_mirror:source_mirror preview_mirror:preview_mirror];
        }
        
        if (is_camera_start) {
            break;
        }
        retry_cnt ++;
        sleep(1);
        
    } while (retry_cnt < 2);
    
    if (!is_camera_start) {
        NSLog(@"摄像头启动失败");
    }
    
    ///初始化界面UI
    [self setup_view];
//    self.screen_hot = [[UIButton alloc] initWithFrame:CGRectMake(20, 50, 30, 30)];
//    [self.screen_hot addTarget:self action:@selector(screenShot) forControlEvents:UIControlEventTouchUpInside];
//    [self.screen_hot setBackgroundColor:[UIColor blueColor]];
//    [self.view addSubview:self.screen_hot];
    
}

- (void)init_para {
    overlay_mask_rect_x = 0.0;
    overlay_mask_rect_y = 0.0;
    overlay_mask_rect_width = 0.0;
    overlay_mask_rect_height = 0.0;
    overlay_mask_text_index = 0;
    overlay_mask_logo_index = 0;
    _push_bad_network_time_count = 0;
    _ovelay_mask_index = 0;
    _effectiveScale = 1.0;
    _startTime = 0;
    
    CGFloat fw = [UIScreen mainScreen].bounds.size.width;
    CGFloat fh = [UIScreen mainScreen].bounds.size.height;
    
    if (self.stream_cfg.direction == CNC_ENM_Direct_Vertical) {
        screen_h_ = (fw > fh) ? fw : fh;
        screen_w_ = (fw < fh) ? fw : fh;
    } else {
        screen_w_ = (fw > fh) ? fw : fh;
        screen_h_ = (fw < fh) ? fw : fh;
    }
    
    self.array = [NSArray arrayWithObjects:
                  @"640*480",
                  @"352x288",
                  @"960*540",
                  @"1280*720",
                  //                  @"1920x1080",
                  //@"3840x2160",
                  nil];
    
    self.array_value = [NSArray arrayWithObjects:
                        @(CNCResolution_4_3__640x480),
                        @(CNCResolution_5_4__352x288),
                        @(CNCResolution_16_9__960x540),
                        @(CNCResolution_16_9__1280x720),
                        //                        @(CNCResolution_16_9__1920x1080),
                        nil];
    _resolution_index = [self.array_value indexOfObject:[NSNumber numberWithInteger:self.stream_cfg.camera_resolution_type]];
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

- (void)addObservers {
    // statistics update every seconds
    self.timer =  [NSTimer scheduledTimerWithTimeInterval:1.0
                                                   target:self
                                                 selector:@selector(updateStat:)
                                                 userInfo:nil
                                                  repeats:YES];
    //添加错误码通知消息处理
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(do_sdk_return_code_center:)
                                                 name:kMobStreamSDKReturnCodeNotification
                                               object:nil];
    
    //添加发送速率通知消息处理
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(update_sdk_send_speed:)
                                                 name:kMobStreamSDKSendSpeedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(become_active:)                                                name:UIApplicationDidBecomeActiveNotification object:nil];
}
- (void)become_active :(NSNotification *)noti {
    self.torchButton.selected = NO;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    if ([touch.view isKindOfClass:[UISlider class]]){
        return NO;
    }
    
    return YES;
}
- (void)addGestureRecognizer {
    UIPinchGestureRecognizer *panGes = [[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)] autorelease];
    panGes.delegate = self;
    
    UITapGestureRecognizer *tapGes = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)] autorelease];
    tapGes.delegate = self;
    
    UISwipeGestureRecognizer *swipeLeftGes = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)] autorelease];
    swipeLeftGes.direction = UISwipeGestureRecognizerDirectionLeft;
    swipeLeftGes.delegate = self;
    
    UISwipeGestureRecognizer *swipeRightGes = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipes:)] autorelease];
    swipeRightGes.direction = UISwipeGestureRecognizerDirectionRight;
    swipeRightGes.delegate = self;
    
    [self.view addGestureRecognizer:panGes];
    [self.view addGestureRecognizer:tapGes];
    [self.view addGestureRecognizer:swipeLeftGes];
    [self.view addGestureRecognizer:swipeRightGes];
}

- (void)setup_view {
    
    CGFloat buttonWidth = 50;
    CGFloat backViewHeight = buttonWidth*5;
    
    UIScrollView *backView = [[[UIScrollView alloc] init] autorelease];
    backView.frame = CGRectMake(screen_w_-buttonWidth,(screen_h_-backViewHeight)/2,buttonWidth,backViewHeight);
    backView.backgroundColor = [UIColor blackColor];
    backView.alpha = 0.7f;
//    backView.bounces = NO;
    self.backView = backView;
    [self.view addSubview:self.backView];
    
    {
        int y = 0;
        if (self.stream_cfg.direction == CNC_ENM_Direct_Vertical) {
            y = 20;
        }
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(screen_w_-buttonWidth, y, buttonWidth, buttonWidth)] autorelease];
        btn.tag = 10000;
        btn.backgroundColor = [UIColor clearColor];
        [btn setImage:[UIImage imageNamed:@"clear_input"] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(actionDismissViewController:) forControlEvents:UIControlEventTouchUpInside];
        self.closeButton = btn;
        [self.view addSubview:self.closeButton];
    }
    
    int index = 0;
    {
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(0, buttonWidth*index, buttonWidth, buttonWidth)] autorelease];
        btn.tag = 10001+index;
        btn.backgroundColor = [UIColor clearColor];
        [btn setImage:[UIImage imageNamed:@"ic_mode_switch_camera"] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(actionSwap:) forControlEvents:UIControlEventTouchUpInside];
        [backView addSubview:btn];
        
        //镜像设置
        self.cur_swap_mirror_idx = 0;
        self.array_swap_mirror = [NSArray arrayWithObjects:
                             @"不改变镜像设置",
                             @"预览:YES 编码:YES",
                             @"预览:YES 编码:NO",
                             @"预览:NO 编码:NO",
                             @"预览:NO 编码:YES",
                             nil];
    }
    
    index++;
    {
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(0, buttonWidth*index, buttonWidth, buttonWidth)] autorelease];
        btn.tag = 10001+index;
        btn.backgroundColor = [UIColor clearColor];
        [btn setImage:[UIImage imageNamed:@"ic_microphone_on"] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:@"ic_microphone_off"] forState:UIControlStateSelected];
        [btn addTarget:self action:@selector(actionSetMutedMode:) forControlEvents:UIControlEventTouchUpInside];
        btn.selected = [CNCMobStreamSDK isMuted];
        [backView addSubview:btn];
    }
    
    index++;
    {
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(0, buttonWidth*index, buttonWidth, buttonWidth)] autorelease];
        btn.tag = 10001+index;
        btn.backgroundColor = [UIColor clearColor];
        [btn setImage:[UIImage imageNamed:@"ic_viewfinder_flash_off"] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:@"ic_viewfinder_flash_on"] forState:UIControlStateSelected];
        [btn addTarget:self action:@selector(actionTorchTurnOnOrOff:) forControlEvents:UIControlEventTouchUpInside];
        btn.selected = NO;
        [backView addSubview:self.torchButton = btn];
    }
    
    index++;
    {
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(0, buttonWidth*index, buttonWidth, buttonWidth)] autorelease];
        btn.tag = 10001+index;
        btn.backgroundColor = [UIColor clearColor];
        [btn setTitle:@"横屏" forState:UIControlStateNormal];
        [btn setTitle:@"竖屏" forState:UIControlStateSelected];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(action_chg_cam_direct:) forControlEvents:UIControlEventTouchUpInside];
        btn.selected = (self.stream_cfg.direction == CNC_ENM_Direct_Vertical);
        [backView addSubview:btn];
    }
    
    
    index++;
    {
        //        录屏
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(0, buttonWidth*index, buttonWidth, buttonWidth)] autorelease];
        btn.tag = 10001+index;
        btn.backgroundColor = [UIColor clearColor];
        [btn setTitle:@"录屏" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(action_store_video:) forControlEvents:UIControlEventTouchUpInside];
        [backView addSubview:btn];
        
    }
    
    index++;
    {
        //        截屏
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(0, buttonWidth*index, buttonWidth, buttonWidth)] autorelease];
        btn.tag = 10001+index;
        btn.backgroundColor = [UIColor clearColor];
        [btn setTitle:@"截屏" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(screenShot:) forControlEvents:UIControlEventTouchUpInside];
        [backView addSubview:btn];
    }
    
    index++;
    {
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(0, buttonWidth*index, buttonWidth, buttonWidth)] autorelease];
        btn.tag = 10001+index;
        btn.backgroundColor = [UIColor clearColor];
        [btn setTitle:@"码率" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        //[btn setImage:[UIImage imageNamed:@"ic_flip"] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(actionChangeVideoFrame:) forControlEvents:UIControlEventTouchUpInside];
        btn.selected = NO;
        [backView addSubview:btn];
    }
    
    index++;
    {
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(0, buttonWidth*index, buttonWidth, buttonWidth)] autorelease];
        btn.tag = 10001+index;
        btn.backgroundColor = [UIColor clearColor];
        [btn setImage:[UIImage imageNamed:@"setting"] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(actionSetStreamCfg:) forControlEvents:UIControlEventTouchUpInside];
        [backView addSubview:btn];
    }
    
    index++;
    {
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(0, buttonWidth*index, buttonWidth, buttonWidth)] autorelease];
        btn.tag = 10001+index;
        btn.backgroundColor = [UIColor clearColor];
        [btn setTitle:@"镜像" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(action_open_mirror_set_view:) forControlEvents:UIControlEventTouchUpInside];
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
    index++;
    {
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(screen_w_ - buttonWidth, screen_h_ - buttonWidth, buttonWidth, buttonWidth)] autorelease];
        btn.tag = 10001+index;
        btn.backgroundColor = [UIColor clearColor];
        [btn setImage:[UIImage imageNamed:@"ic_beauty_off"] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:@"ic_beauty_on"] forState:UIControlStateSelected];
        btn.selected = NO;
        [btn addTarget:self action:@selector(beauty:) forControlEvents:UIControlEventTouchUpInside];
        self.beauty_btn = btn;
        [self.view addSubview:self.beauty_btn];
    }
    
    index++;
    int startBtnWidth = 100;
    {
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake((screen_w_ - startBtnWidth)/2, screen_h_ - startBtnWidth, startBtnWidth, startBtnWidth)] autorelease];
        btn.tag = 10001+index;
        btn.backgroundColor = [UIColor clearColor];
        [btn setImage:[UIImage imageNamed:@"ic_action_pause"] forState:UIControlStateSelected];
        [btn setImage:[UIImage imageNamed:@"ic_action_play"] forState:UIControlStateNormal];
        btn.selected = NO;
        [btn addTarget:self action:@selector(actionStartMeeting:) forControlEvents:UIControlEventTouchUpInside];
        self.recordButton = btn;
        [self.view addSubview:self.recordButton];
    }
    int x = 5;
    if (@available(iOS 11.0, *)) {
//                NSLog(@"%f %f",[UIApplication sharedApplication].keyWindow.safeAreaInsets.top,[UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom);
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
        int height = CGRectGetMinY(self.recordButton.frame) - y;
        UITableView *tableView =[[UITableView alloc]initWithFrame:CGRectMake(x, y+5, screen_w_-buttonWidth-2*x, height) style:UITableViewStylePlain];
        tableView.dataSource = self;
        tableView.delegate =self;
        tableView.backgroundColor =[UIColor clearColor];
        
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.showsVerticalScrollIndicator = NO;
        self.record_code_tableView = tableView;
        [self.view addSubview:tableView];
    }
    {
        self.foucs_cursor = [[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"camera_focus_red"]] autorelease];
        self.foucs_cursor.frame = CGRectMake(80, 80, 80, 80);
        [self.view addSubview:self.foucs_cursor];
        self.foucs_cursor.alpha = 0;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^(){
        [self init_setting_view];
        [self init_beauty_view];
        [self init_overlay_mask_view];
        [self init_audio_beauty_view];
        [self init_store_view];
        [self init_mirror_set_view];
        [self init_sei_view];
        UITapGestureRecognizer* setTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)] autorelease];
        [self.view addGestureRecognizer:setTap];
        
    });
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
- (void)init_mirror_set_view {
    UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, screen_w_, screen_h_)] autorelease];
    
    UIView *whiteView = [[[UIView alloc] init] autorelease];
    whiteView.backgroundColor = [UIColor whiteColor];
    whiteView.layer.borderColor = LIGHTGRAY.CGColor;
    whiteView.layer.borderWidth = 1.f;
    whiteView.alpha = 0.8;
    
    if (screen_h_>screen_w_) {
        whiteView.frame = CGRectMake(10, screen_h_/10*3, screen_w_-20, screen_h_/5*2);
    } else {
        whiteView.frame = CGRectMake(screen_w_/6, 50, screen_w_*2/3, screen_h_-100);
    }
    [view addSubview:whiteView];
    
    {
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(whiteView.bounds.size.width-40, 0, 40, 40)] autorelease];
        btn.backgroundColor = [UIColor clearColor];
        [btn setImage:[UIImage imageNamed:@"clear_input"] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(actionCloseMirror:) forControlEvents:UIControlEventTouchUpInside];
        [whiteView addSubview:btn];
    }
    
    NSArray *array = [[[NSArray alloc] initWithObjects:@"预览:",@"编码:", nil] autorelease];
    int hy = 50;
    for (int i = 0; i < [array count]; i++) {
        UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(whiteView.bounds.size.width/2*i, hy, 50 , 30)] autorelease];
        label.text = [array objectAtIndex:i];
        label.textColor = [UIColor redColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [UIColor clearColor];
        [whiteView addSubview:label];
        
        UISwitch *mirror_switch = [[[UISwitch alloc] initWithFrame:CGRectMake(CGRectGetMinX(label.frame)+CGRectGetWidth(label.frame), CGRectGetMinY(label.frame), 50, 30)] autorelease];
//        if (i == 0 && self.stream_cfg.camera_position == AVCaptureDevicePositionFront) {
//            preview_mirror = YES;
//            [mirror_switch setSelected:YES];
//            [mirror_switch setOn:YES];
//            
//        } else {
            [mirror_switch setSelected:NO];
//        }
        
        mirror_switch.tag = 4200+i;
        [mirror_switch addTarget:self action:@selector(action_set_mirror_value:) forControlEvents:UIControlEventValueChanged];
        [whiteView addSubview:mirror_switch];
    }
    
    UIButton *stop = [[[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(whiteView.frame)/4 ,CGRectGetHeight(whiteView.frame)-50 ,CGRectGetWidth(whiteView.frame)/2, 40)] autorelease];
    stop.layer.cornerRadius = 20;
    stop.layer.borderWidth = 1.f;
    stop.layer.borderColor = SELECTEDCOLOR.CGColor;
    [stop setTitle:@"确认" forState:UIControlStateNormal];
    [stop setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
    [stop addTarget:self action:@selector(action_set_mirror:) forControlEvents:UIControlEventTouchUpInside];
    [whiteView addSubview:stop];

    self.mirror_set_view = view;
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
- (void)init_setting_view {
    
    UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, screen_w_, screen_h_)] autorelease];
    view.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.7];
    
    UIView *whiteView = [[[UIView alloc] init] autorelease];
    whiteView.backgroundColor = [UIColor whiteColor];
    whiteView.layer.borderColor = LIGHTGRAY.CGColor;
    whiteView.layer.borderWidth = 1.f;
    [view addSubview:whiteView];
    
    if (screen_h_>screen_w_) {
        whiteView.frame = CGRectMake(10, screen_h_/10*3, screen_w_-20, screen_h_/5*2);
    } else {
        whiteView.frame = CGRectMake(screen_w_/6, 50, screen_w_*2/3, screen_h_-100);
    }
    int wx = 20;
    int hx = 10;
    CGFloat scale = MIN(screen_h_, screen_w_)/320;
    int height = 32*scale;
    
    {
        UILabel* address = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
        address.text = @"推流地址：";
        [whiteView addSubview:address];
        [address sizeToFit];
        address.frame = CGRectMake(wx, hx, CGRectGetWidth(address.frame), height);
    }
    
    hx += height + 5;
    {
        UITextView *textfield = [[[UITextView alloc] init] autorelease];
        textfield.layer.borderWidth = 0.5f;
        textfield.layer.borderColor = LIGHTGRAY.CGColor;
        textfield.layer.cornerRadius = 3.f;
        textfield.font = [UIFont systemFontOfSize:14.f];
        textfield.text = [CNCMobStreamSDK get_rtmp_url_string];
        [whiteView addSubview:self.rtmp_url_textview = textfield];
        float x = 1.0;
        if (screen_h_<1000) {
            x = 1.5;
        }
        textfield.frame = CGRectMake(wx, hx, CGRectGetWidth(whiteView.frame) - 2*wx, height*x);
    }
    
    //    hx += height*1.5 + 10;
    //    {
    //        UILabel* resolution = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    //        resolution.text = @"分辨率：";
    //        [whiteView addSubview:resolution];
    //        [resolution sizeToFit];
    //        resolution.frame = CGRectMake(wx, hx, CGRectGetWidth(resolution.frame), height);
    //
    //        int btn_x = CGRectGetMaxX(resolution.frame);
    //        int btnwidth = (CGRectGetWidth(whiteView.frame) - btn_x - 20)/2;
    //
    //
    //        for (int i=0; i<self.array.count; i++) {
    //            if (i%2 == 0) {
    //                btn_x = CGRectGetMaxX(resolution.frame);
    //            } else {
    //                btn_x = CGRectGetMaxX(resolution.frame) + btnwidth + 10;
    //            }
    //            int btn_y = hx + (height + 5)*(int)(i*0.5);
    //            UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(btn_x, btn_y, btnwidth, height)] autorelease];
    //            btn.layer.cornerRadius = height/2;
    //            btn.layer.borderColor = LIGHTGRAY.CGColor;
    //            btn.layer.borderWidth = 0.5f;
    //            btn.tag = 1201 + i;
    //            [btn setTitle:[self.array objectAtIndex:i] forState:UIControlStateNormal];
    //            [btn setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
    //            [btn setTitleColor:SELECTEDCOLOR forState:UIControlStateDisabled];
    //            [btn addTarget:self action:@selector(actionResolutionClick:) forControlEvents:UIControlEventTouchUpInside];
    //            [whiteView addSubview:btn];
    //            if (_resolution_index == i) {
    //                [btn setEnabled:NO];
    //            }
    //        }
    //    }
    
    
    {
        UILabel* resolution = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
        resolution.text = @"码率自适应:";
        [whiteView addSubview:resolution];
        [resolution sizeToFit];
        resolution.frame = CGRectMake(wx, (whiteView.frame.size.height-height)/2+20, CGRectGetWidth(resolution.frame), height);
        int btn_x = CGRectGetMaxX(resolution.frame);
        int btnwidth = (CGRectGetWidth(whiteView.frame) - btn_x - 20)/2;
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(btn_x+5, resolution.frame.origin.y, btnwidth, height)] autorelease];
        btn.layer.cornerRadius = height/2;
        btn.layer.borderColor = LIGHTGRAY.CGColor;
        btn.layer.borderWidth = 0.5f;
        btn.tag = 1301;
        [btn setTitle:@"关闭" forState:UIControlStateNormal];
        [btn setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
        [btn setTitleColor:SELECTEDCOLOR forState:UIControlStateDisabled];
        [btn addTarget:self action:@selector(action_adaptive:) forControlEvents:UIControlEventTouchUpInside];
        [whiteView addSubview:btn];
        
    }
    hx = CGRectGetHeight(whiteView.frame) - height - 10;
    int btnwidth = (CGRectGetWidth(whiteView.frame) - 30)/2;
    {
        UIButton *cancle = [[[UIButton alloc] initWithFrame:CGRectMake(10, hx, btnwidth, height)] autorelease];
        cancle.layer.cornerRadius = height/2;
        cancle.layer.borderWidth = 1.f;
        cancle.layer.borderColor = LIGHTGRAY.CGColor;
        cancle.tag = 1199;
        [cancle setTitle:@"取消" forState:UIControlStateNormal];
        [cancle setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
        [cancle addTarget:self action:@selector(actionConfigChange:) forControlEvents:UIControlEventTouchUpInside];
        [whiteView addSubview:cancle];
    }
    
    {
        UIButton *sure = [[[UIButton alloc] initWithFrame:CGRectMake(20 + btnwidth, hx, btnwidth, height)] autorelease];
        sure.layer.cornerRadius = height/2;
        sure.layer.borderWidth = 1.f;
        sure.layer.borderColor = SELECTEDCOLOR.CGColor;
        sure.tag = 1200;
        [sure setTitle:@"确定" forState:UIControlStateNormal];
        [sure setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
        [sure addTarget:self action:@selector(actionConfigChange:) forControlEvents:UIControlEventTouchUpInside];
        [whiteView addSubview:sure];
    }
    
    self.settingView = view;
    
}
- (void)init_beauty_view {
    
    UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, screen_w_, screen_h_)] autorelease];
    //    view.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.7];
    
    UIView *whiteView = [[[UIView alloc] init] autorelease];
    whiteView.backgroundColor = [UIColor whiteColor];
    whiteView.layer.borderColor = LIGHTGRAY.CGColor;
    whiteView.layer.borderWidth = 1.f;
    whiteView.alpha = 0.5;
    
    if (screen_h_>screen_w_) {
        whiteView.frame = CGRectMake(10, screen_h_/6+20, screen_w_-20, screen_h_*2/3-60);
    } else {
        whiteView.frame = CGRectMake(screen_w_/6, 30, screen_w_*2/3, screen_h_-60);
    }
    [view addSubview:whiteView];
    
    self.beauty_array = [[[NSArray alloc] initWithObjects:@"无",@"磨皮",@"磨皮+皮肤美白",@"磨皮+皮肤红润",@"磨皮+全屏美白",@"美肤平滑", nil] autorelease];
    self.combine_array = [[[NSArray alloc] initWithObjects:@"无",@"怀旧",@"曝光",@"对比",@"浓度",@"加深",@"阴霾",@"底片",@"单色",@"阴影",@"色度",@"漫画",@"素描",@"马赛克",@"旋涡",@"晕影",@"鱼眼",@"哈哈镜",@"分离",@"浮雕",@"锐化", nil] autorelease];
    
    self.beauty_pickView = [[[UIPickerView alloc] initWithFrame:CGRectMake(10, 40, whiteView.bounds.size.width/2-20, 80)] autorelease];
    //    self.beauty_pickView.showsSelectionIndicator = YES;
    self.beauty_pickView.delegate = self;
    self.beauty_pickView.dataSource = self;
    self.beauty_pickView.tag = 22220;
    [whiteView addSubview:self.beauty_pickView];
    
    self.combine_pickView = [[[UIPickerView alloc] initWithFrame:CGRectMake(whiteView.bounds.size.width/2+10, 40, whiteView.bounds.size.width/2-20, 80)] autorelease];
    self.combine_pickView.delegate = self;
    self.combine_pickView.dataSource = self;
    self.combine_pickView.tag = 22221;
    [whiteView addSubview:self.combine_pickView];
    
    //    CGFloat scale = MIN(screen_h_, screen_w_)/320;
    //    int height = 32*scale;
    
    UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(whiteView.bounds.size.width-40, 0, 40, 40)] autorelease];
    btn.backgroundColor = [UIColor clearColor];
    btn.tag = 22222;
    [btn setImage:[UIImage imageNamed:@"clear_input"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(actionCloseBeauty:) forControlEvents:UIControlEventTouchUpInside];
    [whiteView addSubview:btn];
    
    NSArray *titleArray = [[[NSArray alloc] initWithObjects:@"磨皮:",@"效果:",@"滤镜:", nil] autorelease];
    for (int i = 0;i<titleArray.count;i++) {
        int slider_height = (CGRectGetHeight(whiteView.frame)/2-10)/3;
        NSString *str = [titleArray objectAtIndex:i];
        UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetHeight(whiteView.frame)/2+15+slider_height*i, 60, slider_height-5)] autorelease];
        label.text = str;
        label.textColor = [UIColor blackColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [UIColor clearColor];
        [label sizeToFit];
        label.numberOfLines = 0;
        [whiteView addSubview:label];
        
        UISlider * slider =[[[UISlider alloc] initWithFrame:CGRectMake(CGRectGetMinX(label.frame)+CGRectGetWidth(label.frame)+10, CGRectGetMinY(label.frame),CGRectGetWidth(whiteView.frame)-(CGRectGetMinX(label.frame)+CGRectGetWidth(label.frame)+10)-10, slider_height-5)] autorelease];
        slider.continuous = YES;//设置只有在离开滑动条的最后时刻才触发滑动事件
        slider.minimumValue = 0.0f;
        CGFloat maxValue = 1.0;
        slider.maximumValue = maxValue;
        slider.value = maxValue/2.0;
        slider.tag = 22223 + i;
        [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        [whiteView addSubview:slider];
        switch (i) {
            case 0:
                self.beauty_slider = slider;
                maxValue = 2.0;
                self.beauty_slider.maximumValue = maxValue;
                self.beauty_slider.value = maxValue/2.0;
                beauty_smoothDegree = self.beauty_slider.value;
                break;
            case 1:
                self.effect_slider = slider;
                beauty_effect = self.effect_slider.value;
                break;
            case 2:
                self.filter_slider = slider;
                filter_effect = self.filter_slider.value;
                break;
                
            default:
                break;
        }
    }
    
    self.beauty_view  = view;
    
}
- (void)init_overlay_mask_view {
    UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, screen_w_, screen_h_)] autorelease];
    view.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.7];
    
    UIView *whiteView = [[[UIView alloc] init] autorelease];
    whiteView.backgroundColor = [UIColor whiteColor];
    whiteView.layer.borderColor = LIGHTGRAY.CGColor;
    whiteView.layer.borderWidth = 1.f;
    whiteView.alpha = 0.5;
    [view addSubview:whiteView];
    
    if (screen_h_>screen_w_) {
        whiteView.frame = CGRectMake(10, screen_h_/6, screen_w_-20, screen_h_*2/3-60);
    } else {
        whiteView.frame = CGRectMake(screen_w_/6, 10, screen_w_*2/3, screen_h_-20);
    }
    UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(whiteView.bounds.size.width-40, 0, 40, 40)] autorelease];
    btn.backgroundColor = [UIColor clearColor];
    [btn setImage:[UIImage imageNamed:@"clear_input"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(removeWatherMaskView:) forControlEvents:UIControlEventTouchUpInside];
    [whiteView addSubview:btn];
    
    self.overlay_mask_logo_array = [CNCDemoFunc get_folder_list_with_name:@"watherMask"];
    self.overlay_mask_text_array = [NSArray arrayWithObjects:@"黑",@"深灰",@"潜灰",@"白",@"灰",@"红",@"绿",@"蓝",@"青",@"黄",@"品红",@"橙",@"紫",@"棕褐", nil];

    int hx = 10;
    CGFloat scale = MIN(screen_h_, screen_w_)/320;
    int height = 40*scale;
    hx = CGRectGetHeight(whiteView.frame) - height - 10;
    int btn_width = (CGRectGetWidth(whiteView.frame) - 30)/2;
    {
        UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(5, 5, CGRectGetWidth(whiteView.frame)-10, 30)] autorelease];
        label.text = @"选择水印";
        label.textColor = [UIColor redColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:18];
        [whiteView addSubview:label];
        
        int btn_x = CGRectGetMinX(label.frame);
        int mask_width = (CGRectGetWidth(whiteView.frame) - btn_x - 20)/2;
        
        int text_y = CGRectGetMinY(label.frame) + CGRectGetHeight(label.frame);
        NSArray *rect_array = [NSArray arrayWithObjects:@"左侧位置",@"上端位置",@"宽度",@"高度", nil];
        for (int i = 0; i<4; i++) {
            
            UITextField *textfield = [[[UITextField alloc] init] autorelease];
            textfield.frame = CGRectMake(CGRectGetMinX(label.frame)+(i%2)*(btn_width + 10),text_y + 35*(i/2), mask_width, 30);
            textfield.borderStyle = UITextBorderStyleRoundedRect;
            textfield.placeholder = [rect_array objectAtIndex:i];
            textfield.tag = 2000+i;
            textfield.delegate = self;
            [whiteView addSubview:textfield];
        }
        
        NSArray *array = [[[NSArray alloc] initWithObjects:@"文字水印",@"图片水印", nil] autorelease];
        for (int i=0; i<array.count; i++) {
//            if (i%2 == 0) {
            btn_x = CGRectGetMinX(label.frame) + (mask_width + 10)*i;
//            } else {
//                btn_x = CGRectGetMinX(label.frame) + btn_width + 10;
//            }
            
            int btn_y = text_y + 35*2 + 20;
            UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(btn_x, btn_y, mask_width, height)] autorelease];
            btn.layer.cornerRadius = height/2;
            btn.layer.borderColor = LIGHTGRAY.CGColor;
            [btn setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
            btn.layer.borderWidth = 0.5f;
            btn.tag = 1401 + i;
            [btn setTitle:[array objectAtIndex:i] forState:UIControlStateNormal];
            
            [btn addTarget:self action:@selector(overlay_mask_view_btn_on_click:) forControlEvents:UIControlEventTouchUpInside];
            [whiteView addSubview:btn];
            if (0 == i) {
                [btn setSelected:YES];
                [btn setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
                btn.layer.borderColor = SELECTEDCOLOR.CGColor;
            }
            
            UIPickerView *pickView = [[[UIPickerView alloc] initWithFrame:CGRectMake(btn_x, btn_y+height+5,mask_width, 60)] autorelease];
            pickView.delegate = self;
            pickView.dataSource = self;
            pickView.tag = 22440+i;
            [whiteView addSubview:pickView];
          
        }
       
    }
    
   
    
    {
        UIButton *cancle = [[[UIButton alloc] initWithFrame:CGRectMake(10, hx, btn_width, height)] autorelease];
        cancle.layer.cornerRadius = height/2;
        cancle.layer.borderWidth = 1.f;
        cancle.layer.borderColor = SELECTEDCOLOR.CGColor;
        cancle.tag = 1401;
        [cancle setTitle:@"关闭水印" forState:UIControlStateNormal];
        [cancle setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
        [cancle addTarget:self action:@selector(close_overlay_mask:) forControlEvents:UIControlEventTouchUpInside];
        [whiteView addSubview:cancle];
    }
    
    {
        UIButton *sure = [[[UIButton alloc] initWithFrame:CGRectMake(20 + btn_width, hx, btn_width, height)] autorelease];
        sure.layer.cornerRadius = height/2;
        sure.layer.borderWidth = 1.f;
        sure.layer.borderColor = SELECTEDCOLOR.CGColor;
        sure.tag = 1400;
        [sure setTitle:@"设置水印" forState:UIControlStateNormal];
        [sure setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
        [sure addTarget:self action:@selector(overlay_mask_view_change:) forControlEvents:UIControlEventTouchUpInside];
        [whiteView addSubview:sure];
    }
    
    self.overlay_mask_view = view;
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
        BOOL bPushInBk = [CNCMobStreamSDK isOpenMicVoiceReturnBack];
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
    [btn addTarget:self action:@selector(actionCloseBeauty:) forControlEvents:UIControlEventTouchUpInside];
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
#pragma mark - UIPickView data source
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    switch (pickerView.tag) {
        case 22220:
            return self.beauty_array.count;
            break;
        case 22221:
            return self.combine_array.count;
            break;
        case 22330:
            return self.roomType_array.count;
            break;
        case 22331:
            return self.music_array.count;
            break;
        case 22440:
            return self.overlay_mask_text_array.count;
            break;
        case 22441:
            return self.overlay_mask_logo_array.count;
            break;
        case 22550:
            return self.sei_questions_title_array.count;
            break;
        default:
            break;
    }
    
    return 0;
}

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSArray *dataList = nil;
    
    switch (pickerView.tag) {
        case 22220:
            dataList = self.beauty_array;
            break;
        case 22221:
            dataList = self.combine_array;
            break;
        case 22330:
            dataList = self.roomType_array;
            break;
        case 22331:
            dataList = self.music_array;
            break;
        case 22440:
            dataList = self.overlay_mask_text_array;
            break;
        case 22441:
            dataList = self.overlay_mask_logo_array;
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
        case 22220:
        {
            NSLog(@"%@",[self.beauty_array objectAtIndex:row]);
            beauty_type = row;
            [CNCMobStreamSDK set_beauty_filter_with_type:beauty_type];
        }
            break;
        case 22221:
        {
            NSLog(@"%@",[self.combine_array objectAtIndex:row]);
            combine_filter_type = row;
            [CNCMobStreamSDK set_combine_filter_with_type:combine_filter_type];
        }
            break;
        case 22330:
        {
            NSLog(@"%@",[self.roomType_array objectAtIndex:row]);
            [CNCMobStreamSDK setAudioRoomType:(CNCAudioRoomType)row];
        }
            break;
        case 22331:
        {
            if (row < self.music_array.count) {
                NSString *filename = self.music_array[row];
                NSString *fileString = [[CNCDemoFunc get_folder_directory_with_name:@"music"] stringByAppendingPathComponent:filename];
                NSLog(@"%@",filename);
                
                
                BOOL bOpenFile = [CNCMobStreamSDK setUpAUFilePlayer:fileString loopEnable:self.bMusicLoopEnable];
                
                if (!bOpenFile) {
                    [self action_stop_music:nil];
                    [self showMessage:[NSString stringWithFormat:@"无法打开文件：%@", filename]];
                } else {
                    [CNCMobStreamSDK startPlayMusic];
                    self.playOrPauseBtn.selected = YES;
                    self.totalTimeLabel.text = [CNCMobStreamSDK getDurationString];
                    [self start_music_ui_flash];
                }

            }
        }
            break;
        case 22440:
        {
            overlay_mask_text_index = row;
        }
            break;
        case 22441:
        {
            overlay_mask_logo_index = row;
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
    
    if (beauty_type == CNCBEAUTY_NONE && combine_filter_type == CNCCOMBINE_NONE) {
        self.beauty_btn.selected = NO;
    } else {
        self.beauty_btn.selected = YES;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [CNCMobStreamSDK set_beauty_with:beauty_smoothDegree effect:beauty_effect filter_effect:filter_effect];
    });
    
}
#pragma mark - 刷新调试信息

- (void)updateStat:(NSTimer *)theTimer {
    
    if (_startTime>0) {
        NSInteger bitrate = [CNCMobStreamSDK get_bit_rate];
        NSInteger videofps = [CNCMobStreamSDK get_video_fps];
        double currentTime = [[NSDate date]timeIntervalSince1970];
        realTimeFrame *strucFrame = [CNCMobStreamSDK get_statistics_message];
        
        NSString* hostUrl = [NSString stringWithFormat:@"%@\n",[CNCMobStreamSDK get_rtmp_url_string]];
        NSString* realtime = [NSString stringWithFormat:@"Realtime: %d KB/s | %@ \n",_speed,[self timeFormatted:(int)(currentTime-_startTime)]];
        NSString* infoSetting = [NSString stringWithFormat:@"Info_setting: %@ fps | %@ kbps \n",@(videofps),@(bitrate)];
        
        _stat.text = hostUrl;
        _stat.text = [_stat.text  stringByAppendingString:realtime];
        _stat.text = [_stat.text  stringByAppendingString:infoSetting];
        
        if (strucFrame) {
            NSString* statics_info = [NSString stringWithFormat:@"Frame: %ld (per) , %ld (total) | Drop: %ld (pakage) , %ld (fps)\n",strucFrame->actual_per_fps,strucFrame->actual_total_send_frame,strucFrame->drop_pakage_num,strucFrame->drop_frame_num];
            NSString* beauty_info = [NSString stringWithFormat:@"Beauty Before: %ld (per) | After: %ld (per) \n",strucFrame->beauty_before_fps,strucFrame->beauty_after_fps];
            _stat.text = [_stat.text stringByAppendingString:statics_info];
            _stat.text = [_stat.text stringByAppendingString:beauty_info];
        }
    }
    
}

- (NSString *)timeFormatted:(int)totalSeconds {
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
}

- (void)resetParam {
    _startTime = 0;
}


#pragma mark- UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 601) {
        
        switch (buttonIndex) {
            case 0:
                //do nothing
                break;
            case 1:
                //美颜
                [self.view addSubview:self.beauty_view];
                break;
            case 2:
                //水印
                [self.view addSubview:self.overlay_mask_view];
                break;
            case 3://美声
            {
                self.human_slider.value = [CNCMobStreamSDK currentHumanVolume];
                self.music_slider.value = [CNCMobStreamSDK currentMusicVolume];
                self.output_slider.value = [CNCMobStreamSDK currentOutPutVolume];
                self.reverb_slider.value = [CNCMobStreamSDK currentAudioMixReverb];
                [self.view addSubview:self.audioBeautyView];
            }
                break;
                
            default:
                break;
        }
    } else if(alertView.tag == 602) {
        switch (buttonIndex) {
            case 0:
                //do nothing
                break;
            case 1://美声
            {
                self.human_slider.value = [CNCMobStreamSDK currentHumanVolume];
                self.music_slider.value = [CNCMobStreamSDK currentMusicVolume];
                self.output_slider.value = [CNCMobStreamSDK currentOutPutVolume];
                self.reverb_slider.value = [CNCMobStreamSDK currentAudioMixReverb];
                [self.view addSubview:self.audioBeautyView];
            }
                break;
            default:
                break;
        }
    }  else if (alertView.tag == 996) {
           
           if (buttonIndex > 0) {
               NSString *s = [self.array_swap_mirror objectAtIndex:buttonIndex-1];
//               UIButton *btn = [self.view viewWithTag:2006];
//               [btn setTitle:s forState:UIControlStateNormal];
               NSInteger new_idx = buttonIndex-1;
               self.cur_swap_mirror_idx = new_idx;
               
               [self do_swap_camera];
           }
    } else {
        
    }
    
}
#pragma mark -uitextfield
- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField.text length] == 0 || textField.text == nil)
        return;
    NSScanner* scan = [NSScanner scannerWithString:textField.text];
    float val;
    if ([scan scanFloat:&val] && [scan isAtEnd] && [textField.text floatValue] <= 1.0 && [textField.text floatValue] >= 0.0) {
        
        switch (textField.tag-2000) {
            case 0:
                overlay_mask_rect_x = [textField.text floatValue];
                break;
            case 1:
                overlay_mask_rect_y = [textField.text floatValue];
                break;
            case 2:
                overlay_mask_rect_width = [textField.text floatValue];
                break;
            case 3:
                overlay_mask_rect_height = [textField.text floatValue];
                break;
                
            default:
                break;
        }
    } else {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showMessage:@"请输入正确数值 区间为0.0 ~ 1.0"];
        });
        textField.text = nil;
    }
    
    
}

-(float)notRounding:(float)price afterPoint:(int)position{
    
    NSDecimalNumberHandler* roundingBehavior = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundDown scale:position raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO];
    
    NSDecimalNumber *ouncesDecimal;
    
    NSDecimalNumber *roundedOunces;
    
    
    
    ouncesDecimal = [[NSDecimalNumber alloc] initWithFloat:price];
    
    roundedOunces = [ouncesDecimal decimalNumberByRoundingAccordingToBehavior:roundingBehavior];
    
    [ouncesDecimal release];
    
    float return_value = [roundedOunces floatValue] * 100/100;
    return return_value;
    
}

#pragma mark -水印操作
- (BOOL)setLogo_overlay_mask {
    [self get_frame];
    UIImageView *iv = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)] autorelease];
//    iv.image = [UIImage imageNamed:@"watermark.png"];
//    UIImage imageWithData:[ns]
    NSString *path = [CNCDemoFunc get_folder_directory_with_name:@"watherMask"];
    NSString *name = [self.overlay_mask_logo_array objectAtIndex:overlay_mask_logo_index];
  
    NSString *image_path = [NSString stringWithFormat:@"%@/%@",path,name];
    UIImage *image = [UIImage imageWithContentsOfFile:image_path];
    iv.image = image;
    
    void  (^block)() = ^{
    };
    
    
//    CGFloat scale_x = iv.frame.origin.x/video_caputre_width;
//    CGFloat scale_y = iv.frame.origin.y/video_caputre_height;
//    CGFloat scale_width = 0.1;
//    CGFloat scale_height = scale_width*video_caputre_width/video_caputre_height;
//    CGRect scale_rect = CGRectMake(scale_x, scale_y, scale_width, scale_height);
    
    CGRect scale_rect = CGRectMake(overlay_mask_rect_x, overlay_mask_rect_y, overlay_mask_rect_width, overlay_mask_rect_height);
    return [CNCMobStreamSDK overlayMaskWithObject:iv rect:scale_rect block:block];
}

- (BOOL)setLabel_overlay_mask {
    
    [self get_frame];
    UILabel *time_label = [[[UILabel alloc] initWithFrame:CGRectMake(10,20, 0, 0)] autorelease];
    
    CGFloat font = (20.0/360.0)*((video_caputre_width < video_caputre_height) ? video_caputre_width : video_caputre_height);
    
    time_label.font = [UIFont boldSystemFontOfSize:font];
    [self setColor:time_label];
//    time_label.textColor = [UIColor redColor];
    time_label.textAlignment = NSTextAlignmentLeft;
    
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss:SSS"];
    void  (^block)() = ^{
        NSString *str = [[[NSString alloc] initWithFormat:@"%@", [dateFormatter stringFromDate:[NSDate date]]] autorelease];
        time_label.text = str;        
    };
    
//    CGFloat scale_x = 0.05;
//    CGFloat scale_y = 0.02;
//    CGFloat scale_width = 0.8;
//    CGFloat scale_height = 0.1;
//    CGRect scale_rect = CGRectMake(scale_x, scale_y, scale_width, scale_height);
    CGRect scale_rect = CGRectMake(overlay_mask_rect_x, overlay_mask_rect_y, overlay_mask_rect_width, overlay_mask_rect_height);
    return [CNCMobStreamSDK overlayMaskWithObject:time_label rect:scale_rect block:block];
    
}

#pragma mark -resolution
- (void)get_frame {
    
    switch (self.stream_cfg.video_encoder_resolution_type) {
        case CNCVideoResolution_360P_4_3:
            if (self.stream_cfg.direction == CNC_ENM_Direct_Horizontal) {
                //横屏
                video_caputre_width = 480;
                video_caputre_height = 360;
            } else {
                video_caputre_width = 360;
                video_caputre_height = 480;
            }
            break;
        case CNCVideoResolution_360P_16_9:
            if (self.stream_cfg.direction == CNC_ENM_Direct_Horizontal) {
                //横屏
                video_caputre_width = 640;
                video_caputre_height = 360;
            } else {
                video_caputre_width = 360;
                video_caputre_height = 640;
            }
            break;
        case CNCVideoResolution_480P_4_3:
            if (self.stream_cfg.direction == CNC_ENM_Direct_Horizontal) {
                //横屏
                video_caputre_width = 640;
                video_caputre_height = 480;
            } else {
                video_caputre_width = 480;
                video_caputre_height = 640;
            }
            break;
        case CNCVideoResolution_480P_16_9:
            if (self.stream_cfg.direction == CNC_ENM_Direct_Horizontal) {
                //横屏
                video_caputre_width = 854;
                video_caputre_height = 480;
            } else {
                video_caputre_width = 480;
                video_caputre_height = 854;
            }
            break;
        case CNCVideoResolution_540P_4_3:
            if (self.stream_cfg.direction == CNC_ENM_Direct_Horizontal) {
                //横屏
                video_caputre_width = 720;
                video_caputre_height = 540;
            } else {
                video_caputre_width = 540;
                video_caputre_height = 720;
            }
            break;
        case CNCVideoResolution_540P_16_9:
            if (self.stream_cfg.direction == CNC_ENM_Direct_Horizontal) {
                //横屏
                video_caputre_width = 960;
                video_caputre_height = 540;
            } else {
                video_caputre_width = 540;
                video_caputre_height = 960;
            }
            break;
        case CNCVideoResolution_720P_4_3:
            if (self.stream_cfg.direction == CNC_ENM_Direct_Horizontal) {
                //横屏
                video_caputre_width = 960;
                video_caputre_height = 720;
            } else {
                video_caputre_width = 720;
                video_caputre_height = 960;
            }
            break;
        case CNCVideoResolution_720P_16_9:
            if (self.stream_cfg.direction == CNC_ENM_Direct_Horizontal) {
                //横屏
                video_caputre_width = 1280;
                video_caputre_height = 720;
            } else {
                video_caputre_width = 720;
                video_caputre_height = 1280;
            }
            break;
            
        default:
            break;
    }
}

#pragma mark- 美颜操作
- (void)beauty:(UIButton *)sender {
    
    if (!self.has_video) {
        if (self.stream_cfg.has_audio) {
            UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"美颜" message:@"样式" delegate:self cancelButtonTitle:@"关闭" otherButtonTitles:@"美声", nil] autorelease];
            alertView.tag = 602;
            [alertView show];
            
        }else {
            //只有视频 就不用处理
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"" message:@"纯音频推流 设置无效" delegate:self cancelButtonTitle:@"关闭" otherButtonTitles:nil, nil] autorelease];
            [alert show];
            
        }
        return;
    }
    
    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"美颜" message:@"样式" delegate:self cancelButtonTitle:@"关闭" otherButtonTitles:@"美颜",@"水印",@"美声", nil] autorelease];
    alertView.tag = 601;
    [alertView show];
    
}

- (void)showBeautySelectWithAlertView {
    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"美颜" message:@"选择样式" delegate:self cancelButtonTitle:@"关闭美颜" otherButtonTitles:@"磨皮",@"提亮",@"怀旧", nil] autorelease];
    alertView.tag = 601;
    [alertView show];
}

#pragma mark -
#pragma mark UISliderDelegate

- (void)sliderValueChanged:(UISlider *)paramSender {
    if ([paramSender isEqual:self.bitrate_slider]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [CNCMobStreamSDK reset_bit_rate:(int)paramSender.value];
        });
    }
    else if ([paramSender isEqual:self.beauty_slider]) {
        beauty_smoothDegree = paramSender.value;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [CNCMobStreamSDK set_beauty_with:beauty_smoothDegree effect:beauty_effect filter_effect:filter_effect];
        });
    }else if ([paramSender isEqual:self.effect_slider]) {
        beauty_effect = paramSender.value;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [CNCMobStreamSDK set_beauty_with:beauty_smoothDegree effect:beauty_effect filter_effect:filter_effect];
        });
    } else if ([paramSender isEqual:self.filter_slider]) {
        filter_effect = paramSender.value;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [CNCMobStreamSDK set_beauty_with:beauty_smoothDegree effect:beauty_effect filter_effect:filter_effect];
        });
    } else if ([paramSender isEqual:self.human_slider]) {
        Float32 value = paramSender.value;
        [CNCMobStreamSDK setHumanVolume:value];
    } else if ([paramSender isEqual:self.music_slider]) {
        Float32 value = paramSender.value;
        [CNCMobStreamSDK setMusicVolume:value];
    } else if ([paramSender isEqual:self.output_slider]) {
        Float32 value = paramSender.value;
        [CNCMobStreamSDK setOutPutVolume:value];
    } else if ([paramSender isEqual:self.reverb_slider]) {
        Float32 value = paramSender.value;
        [CNCMobStreamSDK setAudioMixReverb:value];
    } else if ([paramSender isEqual:self.musicProgress]) {
        Float32 value = paramSender.value;
        NSLog(@"music progress %f",value);
        [CNCMobStreamSDK seekPlayheadTo:value];
        [CNCMobStreamSDK startPlayMusic];
    }
}
#pragma mark -
#pragma mark - Overlay Mask

- (void)overlay_mask_view_btn_on_click :(UIButton *)sender {
    
    sender.layer.borderColor = SELECTEDCOLOR.CGColor;
    [sender setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
    [sender setSelected:YES];
    
    for (int i = 0; i< 2; i++) {
        if (sender.tag != 1401+i) {
            
            UIButton * btn = [self.overlay_mask_view viewWithTag:1401+i];
            btn.layer.borderColor = LIGHTGRAY.CGColor;
            [btn setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
            [btn setSelected:NO];
        }
    }
    
}
- (void)close_overlay_mask:(UIButton *)sender {
    if ([CNCMobStreamSDK overlayMaskWithObject:nil rect:CGRectZero block:nil]){
        _ovelay_mask_index = 0;
    }
}
- (void)overlay_mask_view_change:(UIButton *)sender {
    if (sender.tag == 1400) {
        for (int i = 0; i < 2; i++) {
            UIButton * btn = [self.overlay_mask_view viewWithTag:1401+i];
            if (btn.isSelected) {
                
                    switch (i) {
                        case 0:
                            if ([self setLabel_overlay_mask]){
                                _ovelay_mask_index = 1;
                            }
                            break;
                        case 1:
                            
                            if ([self setLogo_overlay_mask]){
                                _ovelay_mask_index = 2;
                            }
                            break;
                     
                        default:
                            break;
                    }
                
                break;
            }
        }
        
    } else {
        
    }
}
- (void)removeWatherMaskView:(UIButton *)sender {
    
    for (int i=0; i<4; i++) {
        UITextField *textfield = [self.view viewWithTag:2000+i];
        [textfield resignFirstResponder];
    }
    [self.overlay_mask_view removeFromSuperview];
}
- (void)setColor:(UILabel *)label {
    

    switch (overlay_mask_text_index) {
        case 0:
            label.textColor = [UIColor blackColor];//@"黑"
            break;
        case 1:
            label.textColor = [UIColor darkGrayColor];//@"深灰"
            break;
        case 2:
            label.textColor = [UIColor lightGrayColor];//@"潜灰"
            break;
        case 3:
            label.textColor = [UIColor whiteColor];//@"白"
            break;
        case 4:
            label.textColor = [UIColor grayColor];//@"灰"
            break;
        case 5:
            label.textColor = [UIColor redColor];//@"红"
            break;
        case 6:
            label.textColor = [UIColor greenColor];//@"绿"
            break;
        case 7:
            label.textColor = [UIColor blueColor];//@"蓝"
            break;
        case 8:
            label.textColor = [UIColor cyanColor];//@"青"
            break;
        case 9:
            label.textColor = [UIColor yellowColor];//@"黄"
            break;
        case 10:
            label.textColor = [UIColor magentaColor];//@"品红"
            break;
        case 11:
            label.textColor = [UIColor orangeColor];//@"橙"
            break;
        case 12:
            label.textColor = [UIColor purpleColor];//@"紫"
            break;
        case 13:
            label.textColor = [UIColor brownColor];//@"棕褐"
            break;
            
        default:
            break;
    }
    
}
#pragma mark -
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
    self.currentTimeLabel.text = [CNCMobStreamSDK getPlayTimeString];
    float value = [CNCMobStreamSDK getPlayProgress];
    self.musicProgress.value = value;
    
    if (value >= 1.0f) {
        self.playOrPauseBtn.selected = NO;
        [self stop_music_ui_flash];
    }
}



- (void)action_play_or_pause:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    if (sender.isSelected) {
        [CNCMobStreamSDK startPlayMusic];
        self.totalTimeLabel.text = [CNCMobStreamSDK getDurationString];
        [self start_music_ui_flash];
    } else {
        [CNCMobStreamSDK pausePlayMusic];
        [self stop_music_ui_flash];
    }
}

- (void)action_stop_music:(UIButton *)sender {
    [CNCMobStreamSDK stopPlayMusic];
    self.playOrPauseBtn.selected = NO;
    [self stop_music_ui_flash];
}

#pragma mark- 交互操作
- (void)action_adaptive:(UIButton *)btn
{
    btn.selected = !btn.isSelected;
    if(btn.isSelected){
        btn.layer.borderColor = SELECTEDCOLOR.CGColor;
        [btn setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
        [btn setTitle:@"开启" forState:UIControlStateNormal];
    }else{
        [btn setTitle:@"关闭" forState:UIControlStateNormal];
        btn.layer.borderColor = LIGHTGRAY.CGColor;
        [btn setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
    }
    @synchronized (self) {
        [CNCMobStreamSDK set_adaptive:btn.isSelected];
    }
}
- (void)actionTorchTurnOnOrOff:(UIButton *)sender {
 
    
    if (!self.has_video) {
        //只有视频 就不用处理
        UIAlertView *alert = [[[UIAlertView alloc]initWithTitle:@"" message:@"纯音频推流 设置无效" delegate:self cancelButtonTitle:@"关闭" otherButtonTitles:nil, nil] autorelease];
        [alert show];
        return;
    }
    
    sender.selected = !sender.isSelected;
    @synchronized (self) {
        [CNCMobStreamSDK set_torch_mode:sender.isSelected];
    }
}

- (void)actionOpenOrCloseMicVoiceReturnBack:(UISwitch *)sender {
    
    sender.selected = !sender.isSelected;
    
    /// 设置耳返开启关闭
    /// 在没有插入耳机的情况下，是不会有耳返功能的，请悉知
    
    [CNCMobStreamSDK set_audio_returnback:sender.isSelected];
    
}

#pragma mark - music
- (void)actionSetMusicLoopEnable:(UISwitch *)sender {
    self.bMusicLoopEnable = !self.bMusicLoopEnable;
}

- (void)actionSetMutedMode:(UIButton *)sender {
    

    
    sender.selected = !sender.isSelected;
    @synchronized (self) {
        [CNCMobStreamSDK set_muted_statu:sender.isSelected];
    }
}

- (void)actionSwap:(UIButton *)sender {
    if (!self.has_video) {
        //只有视频 就不用处理
        UIAlertView *alert = [[[UIAlertView alloc]initWithTitle:@"" message:@"纯音频推流 设置无效" delegate:self cancelButtonTitle:@"关闭" otherButtonTitles:nil, nil] autorelease];
        [alert show];
        return;
    }
    
    //MFMTEST
//    {
//        static int g_test = 0;
//        g_test += 3;
//        self.cur_swap_mirror_idx = g_test % 5;
//        [self do_swap_camera];
//        return;
//    }
    
    
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
    
    for (NSString *s in self.array_swap_mirror) {
        [alert addButtonWithTitle:s];
    }
    
    //显示AlertView
    [alert show];
    [alert release];
    
    
}

- (void)do_swap_camera  {
    NSString *s = [self.array_swap_mirror objectAtIndex:self.cur_swap_mirror_idx];
    
    UIButton *btn = [self.view viewWithTag:10001];
    [btn setEnabled:NO];
    MBProgressHUD* progressHud_ = [[[MBProgressHUD alloc] initWithView:self.view] autorelease];
    progressHud_.removeFromSuperViewOnHide = YES;
    progressHud_.labelText = [NSString stringWithFormat:@"%@", s];//@"正在切换摄像头...";
    [self.view addSubview:progressHud_];
    [progressHud_ show:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        BOOL preview_mirror = NO;
        BOOL source_mirror = NO;
        /*
        0 - @"默认镜像设置",
        1 - @"预览:YES 编码:YES",
        2 - @"预览:YES 编码:NO",
        3 - @"预览:NO 编码:NO",
        4 - @"预览:NO 编码:YES",
         */
        switch (self.cur_swap_mirror_idx) {
            case 1: {
                preview_mirror = YES;
                source_mirror = YES;
            }
                break;
            case 2: {
                preview_mirror = YES;
                source_mirror = NO;
            }
                break;
            case 3: {
                preview_mirror = NO;
                source_mirror = NO;
            }
                break;
            case 4: {
                preview_mirror = NO;
                source_mirror = YES;
            }
                break;
                
            default:
                break;
        }
        
        //MFM-TEST
//        self.cur_swap_mirror_idx = 0;
        if (self.cur_swap_mirror_idx == 0) {
            preview_mirror = [CNCMobStreamSDK get_cur_preview_mirror];
            source_mirror = [CNCMobStreamSDK get_cur_source_mirror];
            [CNCMobStreamSDK swap_cameras];
        } else {
            [CNCMobStreamSDK swap_cameras:source_mirror preview_mirror:preview_mirror];
        }
        
        {
            NSString *info = [NSString stringWithFormat:@"预:%@ 编:%@", @(preview_mirror), @(source_mirror)];
            NSMutableDictionary *d = [NSMutableDictionary dictionary];
            [d setObject:@(999) forKey:@"code"];
            [d setObject:info forKey:@"message"];
            [[NSNotificationCenter defaultCenter] postNotificationName:kMobStreamSDKReturnCodeNotification object:d];
        }
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [progressHud_ hide:YES];
            self.torchButton.selected = NO;
            [btn setEnabled:YES];
        });
    });
}


- (void)actionStartMeeting:(UIButton *)sender {
    [sender setEnabled:NO];
    sender.selected = !sender.isSelected;
    if (sender.isSelected) {
        
        NSString *rtmp_name = [CNCMobStreamSDK get_rtmp_url_string];
        if (![self isTrueRtmpUrl:rtmp_name]) {
            sender.selected = NO;
            [sender setEnabled:YES];
            return;
        }
        
        if (![rtmp_name isEqualToString:STREAM_NAME_CACHE]) {
            [[NSUserDefaults standardUserDefaults]setObject:rtmp_name forKey:@"stream_name_cache"];
            [[NSUserDefaults standardUserDefaults]synchronize];
        }
        
        MBProgressHUD* progressHud_ = [[[MBProgressHUD alloc] initWithView:self.view] autorelease];
        progressHud_.removeFromSuperViewOnHide = YES;
        progressHud_.labelText = @"正在启动推流...";
        [self.view addSubview:progressHud_];
        [progressHud_ show:YES];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            [CNCMobStreamSDK start_push];
            self.is_pushing = YES;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                _startTime = [[NSDate date]timeIntervalSince1970];
                [progressHud_ hide:YES];
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
            
            [CNCMobStreamSDK pause_push];
            self.is_pushing = NO;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self resetParam];
                _stat.text = @"";
                [progressHud_ hide:YES];
                [sender setEnabled:YES];
            });
        });
    }
    
}


- (void)actionDismissViewController:(id)sender {
    
    if ([self.timer isValid]) {
        [self.timer invalidate];
        self.timer = nil;
    }
    [self audioParamDealloc];
    
    MBProgressHUD* progressHud_ = [[[MBProgressHUD alloc] initWithView:self.view] autorelease];
    progressHud_.removeFromSuperViewOnHide = YES;
    progressHud_.labelText = @"正在退出...";
    [self.view addSubview:progressHud_];
    [progressHud_ show:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        [CNCMobStreamSDK stop_push];
        [CNCMobStreamSDK set_adaptive:NO];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [progressHud_ hide:YES];
            
        });
    });
    
    [self dismissViewControllerAnimated:YES completion:^(){}];
}

- (void)actionChangeVideoFrame:(UIButton *)sender {
    
    if (self.bitrate_slider) {
        [self.bitrate_slider removeFromSuperview];
        self.bitrate_slider = nil;
        return;
    }
    
    if (!self.bitrate_slider) {
        self.bitrate_slider = [[[UISlider alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.backView.frame) -  CGRectGetHeight(self.backView.frame)/2 - 20, screen_h_/2 - 10, CGRectGetHeight(self.backView.frame), 23.0f)] autorelease];
        [self.bitrate_slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        self.bitrate_slider.transform = CGAffineTransformMakeRotation( M_PI * 0.5 );
        [self.view addSubview:self.bitrate_slider];//添加视图
    }
    self.bitrate_slider.continuous = NO;
    
    int minValue = 0, maxValue = 0;
    [self.stream_cfg get_resolution_max_bit_rate:&maxValue min_bit_rate:&minValue];
    
    self.bitrate_slider.minimumValue = minValue;
    self.bitrate_slider.maximumValue = maxValue;
    
    NSLog(@"min:%d,max:%d",minValue,maxValue);
    
    self.bitrate_slider.value = [CNCMobStreamSDK get_bit_rate];
}

- (void)actionSetStreamCfg:(UIButton *)sender {
    if (self.recordButton.selected) {
        return;
    }
    self.rtmp_url_textview.text = [CNCMobStreamSDK get_rtmp_url_string];
    [self.view addSubview:self.settingView];
}

- (void)actionConfigChange:(UIButton *)sender {
    if (sender.tag == 1200) {
        NSString *url = self.rtmp_url_textview.text;
        url = [url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (url != nil) {
            [CNCMobStreamSDK reset_url_string_before_pushing:url];
        }
    }
    
    [self.settingView removeFromSuperview];
}

- (void)actionResolutionClick:(UIButton *)sender {
    sender.layer.borderColor = SELECTEDCOLOR.CGColor;
    [sender setEnabled:NO];
    _resolution_index = sender.tag - 1201;
    for (int i = 0; i<self.array.count; i++) {
        if (sender.tag != 1201+i) {
            UIButton * btn = [self.settingView viewWithTag:1201+i];
            btn.layer.borderColor = LIGHTGRAY.CGColor;
            [btn setEnabled:YES];
        }
    }
}
- (void)actionCloseBeauty:(UIButton *)sender {
    switch (sender.tag) {
        case 22222:
            [self.beauty_view removeFromSuperview];
            break;
        case 22332:
            [self.audioBeautyView removeFromSuperview];
            break;
        default:
            break;
    }
}

#pragma mark - UIViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)audioParamDealloc {
    [self.audioBeautyView removeFromSuperview];
    self.audioBeautyView = nil;
    
    self.roomType_pickView = nil;
    self.music_pickView = nil;
    self.roomType_array = nil;
    self.music_array = nil;
    
    self.human_slider = nil;
    self.music_slider = nil;
    self.output_slider = nil;
    self.reverb_slider = nil;
    
    self.playOrPauseBtn = nil;
    self.stopButton = nil;
    self.musicProgress = nil;
    self.currentTimeLabel = nil;
    self.totalTimeLabel = nil;
    
    [self stop_music_ui_flash];
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    
    [self audioParamDealloc];
    
    self.preview = nil;
    
    self.stream_cfg = nil;
    self.recordButton = nil;
    
    self.stat = nil;
    self.backView = nil;
    self.beauty_slider = nil;
    self.torchButton = nil;
    self.closeButton = nil;
    self.beauty_btn = nil;
    
    self.settingView = nil;
    self.rtmp_url_textview = nil;
    self.array = nil;
    self.array_value = nil;
    
    self.foucs_cursor = nil;
    
    self.filter_slider = nil;
    self.effect_slider = nil;
    self.beauty_view = nil;
    self.beauty_pickView = nil;
    self.combine_array = nil;
    self.combine_pickView = nil;
    self.bitrate_slider = nil;
    self.beauty_array = nil;
    self.timer = nil;
    self.overlay_mask_view = nil;
    self.store_view = nil;
    self.store_slider = nil;
    self.mirror_set_view = nil;
    self.overlay_mask_logo_array = nil;
    self.overlay_mask_text_array = nil;
    self.sei_textview = nil;
    self.sei_view = nil;
    self.sei_questions_array = nil;
    self.record_code_data_array = nil;
    self.record_code_tableView = nil;
    self.sei_questions_pickView = nil;
    self.sei_questions_title_array = nil;
    self.sei_json_dict = nil;
    self.array_swap_mirror = nil;
    [super dealloc];
}

#pragma mark 判断地址栏是否正确
- (BOOL)isTrueRtmpUrl:(NSString *)enter_text {
    
    if (!enter_text || [enter_text length] == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"推流地址不能为空，请在配置页输入推流地址！" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
        [alert show];
        return NO;
    }
    
    NSRange r = [enter_text rangeOfString:@"rtmp://"];
    
    if (r.location != 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"推流地址不正确，必须以“rtmp://”开头，请在配置页修改推流地址！" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
        [alert show];
        return NO;
    }
    
    return YES;
}

#pragma mark 旋转相关
//旋转相关
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    if (self.stream_cfg.direction == CNC_ENM_Direct_Vertical) {
        return UIInterfaceOrientationPortrait;
    }
    
    return UIInterfaceOrientationLandscapeRight;
}

//You need this if you support interface rotation
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    NSLog(@"willAnimateRotationToInterfaceOrientation");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)toInterfaceOrientation {
    
    if (self.stream_cfg.direction == CNC_ENM_Direct_Vertical) {
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
    if (self.stream_cfg.direction == CNC_ENM_Direct_Vertical) {
        return UIInterfaceOrientationMaskPortrait;
    }
    //return UIInterfaceOrientationLandscapeRight;
    return UIInterfaceOrientationMaskLandscapeRight;
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (void)handleTapGesture:(id)sender {
    for (int i=0; i<4; i++) {
        UITextField *textfield = [self.view viewWithTag:2000+i];
        [textfield resignFirstResponder];
    }
    [_rtmp_url_textview resignFirstResponder];
    [self.sei_textview resignFirstResponder];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        _beginGestureScale = _effectiveScale;
    }
    return YES;
}

- (void)tapGesture:(UITapGestureRecognizer *)recognizert {
    CGPoint touchPoint= [recognizert locationInView:self.view];
    if ([CNCMobStreamSDK tapFocusAtPoint:touchPoint]) {
        [self.view bringSubviewToFront:self.foucs_cursor];
        self.foucs_cursor.center = touchPoint;
        self.foucs_cursor.transform = CGAffineTransformMakeScale(1.5, 1.5);
        self.foucs_cursor.alpha=1.0;
        
        [UIView animateWithDuration:1.0 animations:^{
            self.foucs_cursor.transform=CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            self.foucs_cursor.alpha=0;
        }];
    }
}


- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer {
    
    _effectiveScale = _beginGestureScale * recognizer.scale;
    
    if (_effectiveScale<1.0) {
        _effectiveScale = 1.0;
        recognizer.scale = 1.0/_beginGestureScale;
    }
    
    CGFloat upscale = [CNCMobStreamSDK get_current_camera_upscale];
    if (_effectiveScale>upscale) {
        _effectiveScale = upscale;
        recognizer.scale = upscale/_beginGestureScale;
    }
    
    [CNCMobStreamSDK videoZoomFactorWithScale:_effectiveScale];
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
            self.recordButton.hidden = NO;
            self.stat.hidden = NO;
            self.record_code_tableView.hidden = NO;
            self.closeButton.hidden = NO;
            self.beauty_btn.hidden = NO;
            if (self.record_code_tableView) {
                self.record_code_tableView.hidden = NO;
            }
            if (self.bitrate_slider) {
                self.bitrate_slider.hidden = NO;
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
            self.recordButton.hidden = YES;
            self.closeButton.hidden = YES;
            self.beauty_btn.hidden = YES;
            if (self.record_code_tableView) {
                self.record_code_tableView.hidden = YES;
            }
            if (self.bitrate_slider) {
                self.bitrate_slider.hidden = YES;
            }
        }];
        return;
    }
}

#pragma mark - Notification
- (void)do_sdk_return_code_center:(NSNotification*)notification {

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
            bad_network_message = [dic objectForKey:@"message"];
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
                    [self save_to_photos_album:path];
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
        self.recordButton.selected = NO;
        self.stat.text = @"";
        if ([self.timer isValid]) {
            [self.timer invalidate];
            self.timer = nil;
        }
    });
}
- (void)update_sdk_send_speed:(NSNotification *)notification {
    NSNumber *speedNum = notification.object;
    _speed = [speedNum unsignedIntValue];
    _push_bad_network_time_count++;
    if (_push_bad_network_time_count == 5) {
        _push_bad_network_time_count = 0;
        if (bad_network_message.length > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showMessage:bad_network_message];
                bad_network_message = nil;
            });
        }
    }
}


#pragma mark - notice show
- (void)showMessage:(NSString *)show_message
{
    UIWindow * window = [UIApplication sharedApplication].keyWindow;
    UIView *showview =  [[[UIView alloc]init] autorelease];
    showview.backgroundColor = [UIColor redColor];
    showview.frame = CGRectMake(1, 1, 1, 1);
    showview.alpha = 1.0f;
    showview.layer.masksToBounds = YES;
    [window addSubview:showview];
    
    int SCREEN_WIDTH = [UIScreen mainScreen].bounds.size.width;
    int view_height = 150;
    
    UILabel *label = [[[UILabel alloc] init] autorelease];
    label.frame = CGRectMake(0, 0, SCREEN_WIDTH, view_height);
    label.text = show_message;
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
#pragma mark - sei
- (void)action_add_sei_json_str:(UIButton *)sender {
    
    [self.sei_textview resignFirstResponder];
    [self.sei_json_dict removeObjectForKey:@"questionList"];
    NSArray *questionsList = [NSArray arrayWithObject:[self.sei_questions_array objectAtIndex:sei_question_index]];
    [self.sei_json_dict setObject:questionsList forKey:@"questionList"];
    NSString *json_str = [CNCDemoFunc convertToJSONData:self.sei_json_dict];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        [CNCMobStreamSDK set_sw_encoder_push_time_stamp:json_str];
    });
}

- (void)action_close_sei:(UIButton *)btn {
    dispatch_async(dispatch_get_main_queue(), ^(){
        [self.sei_view removeFromSuperview];
        [self.sei_textview resignFirstResponder];
    });
}
- (void)action_open_sei_view:(UIButton *)btn {
    if (self.stream_cfg.encoder_type == CNC_ENM_Encoder_SW) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            [self.view addSubview:self.sei_view];
        });
    } else {
        UIAlertView *alert=[[[UIAlertView alloc] initWithTitle:nil message:@"此功能需开启软编" delegate:self cancelButtonTitle:@"关闭" otherButtonTitles:nil] autorelease];
        [alert show];
    }
}
#pragma mark 截屏
- (void)screenShot:(UIButton *)sender {
    MBProgressHUD* progressHud_ = [[[MBProgressHUD alloc] initWithView:self.view] autorelease];
    progressHud_.removeFromSuperViewOnHide = YES;
    BOOL is_success = [CNCMobStreamSDK screen_shot:nil];
    if (!is_success) {
        progressHud_.labelText = @"截屏失败";
    } else {
        progressHud_.labelText = @"截屏成功";
    }
    
    [self.view addSubview:progressHud_];
    [progressHud_ show:YES];
    dispatch_async(dispatch_get_main_queue(), ^{
        [progressHud_ hide:YES];
    });
//    shot_time_index = 0;
//    if (shot_timer == nil) {
//        shot_timer =  [NSTimer scheduledTimerWithTimeInterval:0.033
//                                                       target:self
//                                                     selector:@selector(shot_time:)
//                                                     userInfo:nil
//                                                      repeats:YES];
//    }
}
- (void)shot_time:(NSTimer *)time {
    shot_time_index ++;
    NSLog(@"%d",shot_time_index);
    if (shot_time_index > 30*10) {
        if ([shot_timer isValid]) {
            [shot_timer invalidate];
            shot_timer = nil;
        }
    }
    [CNCMobStreamSDK screen_shot:nil];
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
    [self.store_view removeFromSuperview];
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
   
    if (sender.tag == 3210) {
        [self store_video_start:YES];
    } else {
        
        [self store_video_start:NO];
    }
    
    [self.store_view removeFromSuperview];
}
- (void)store_video_start:(BOOL) start{
    UIButton *btn_open = [self.view viewWithTag:3210];
    UIButton *btn_close = [self.view viewWithTag:3211];
    
    
    if (!self.is_pushing) {
        return;
    }
    
    MBProgressHUD* progressHud_ = [[[MBProgressHUD alloc] initWithView:self.view] autorelease];
    progressHud_.removeFromSuperViewOnHide = YES;
    BOOL is_doing_store = [CNCMobStreamSDK is_doing_store];
    
    if (start) {
        if (is_doing_store) {
            //重复开启录制
            return;
        } else {
            progressHud_.labelText = @"正在启动录制...";
            btn_close.layer.borderColor = LIGHTGRAY.CGColor;
            [btn_close setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
            btn_open.layer.borderColor = SELECTEDCOLOR.CGColor;
            [btn_open setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
        }
    } else {
        if (is_doing_store) {
            
            progressHud_.labelText = @"正在停止录制...";
            
            btn_open.layer.borderColor = LIGHTGRAY.CGColor;
            [btn_open setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
            btn_close.layer.borderColor = SELECTEDCOLOR.CGColor;
            [btn_close setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
            
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
            
            ret = [CNCMobStreamSDK start_store_video:nil fileType:store_type max_time:max_time long_store:is_long_store size:max_size return_id:str];
            if (!ret) {
                //启动录制失败
            }
            
        } else {

           [CNCMobStreamSDK stop_store_video];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [progressHud_ hide:YES];
        });
    });

}
#pragma mark 旋转摄像头  
- (void)action_chg_cam_direct:(UIButton *)sender {
    if (_is_pushing) {
        return;
    }
    
    sender.selected = !sender.isSelected;
    
    if (self.stream_cfg.direction == CNC_ENM_Direct_Horizontal) {
        self.stream_cfg.direction = CNC_ENM_Direct_Vertical;
    } else {
        self.stream_cfg.direction = CNC_ENM_Direct_Horizontal;
    }
    [CNCMobStreamSDK reset_direct:self.stream_cfg.direction];
    
    //    return;
    
    CGFloat width = screen_w_;
    CGFloat heigth = screen_h_;
    CGFloat x = (screen_w_-width)/2;
    CGFloat y = (screen_h_-heigth)/2;
    
//    self.preview.backgroundColor = [UIColor redColor];
    
    if (self.viewcontroller_direct == self.stream_cfg.direction) {
        //实际推流方向与原先一样
        self.preview.transform = CGAffineTransformMakeRotation(0);
        self.preview.frame = CGRectMake(x, y, width, heigth);
        
    } else {
        y = (heigth - width) / 2;
        x = (width - heigth) / 2;
        
        //一定要先设置frame再旋转
        self.preview.frame = CGRectMake(x, y, heigth, width);
        
        if (self.viewcontroller_direct == CNC_ENM_Direct_Horizontal) {
            self.preview.transform = CGAffineTransformMakeRotation( M_PI * 1.5 );
        } else {
            self.preview.transform = CGAffineTransformMakeRotation( M_PI * 0.5 );
        }
        
    }
    
    [CNCMobStreamSDK reset_preview_frame:self.preview.bounds];
    [self reset_mask_when_direct_chg];

    return;
}

- (void)reset_mask_when_direct_chg {
    if (_ovelay_mask_index == 0) {
        return;
    }
    
    [CNCMobStreamSDK overlayMaskWithObject:nil rect:CGRectZero block:nil];
    if (_ovelay_mask_index == 1) {
        [self setLabel_overlay_mask];
    } else if (_ovelay_mask_index == 2) {
        [self setLogo_overlay_mask];
    } else {
        
    }
    return;
}

#pragma mark 存储至相册
- (void)save_to_photos_album:(NSString *)path {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        if ([path hasSuffix:@".jpg"]) {
            UIImage *img = [UIImage imageWithContentsOfFile:path];
            UIImageWriteToSavedPhotosAlbum(img, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        } else if ([path hasSuffix:@".gif"]) {
            NSData *data = [NSData dataWithContentsOfFile:path];
            [self save_gif_data:data];
        } else if ([path hasSuffix:@".flv"]) {
            NSLog(@"flv 无法直接转存相册");
        } else {
            
            if(UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path)) {
                UISaveVideoAtPathToSavedPhotosAlbum(path,self,@selector(video:didFinishSavingWithError:contextInfo:),nil);
            } else {
                dispatch_async(dispatch_get_main_queue(), ^(){
                    UIAlertView *alert=[[[UIAlertView alloc] initWithTitle:nil message:@"保存到相册失败" delegate:self cancelButtonTitle:@"关闭" otherButtonTitles:nil] autorelease];
                    [alert show];
                });
            }
        }
    });
}

- (void)save_gif_data:(NSData *)data
{
    ALAssetsLibrary* library = [[[ALAssetsLibrary alloc] init] autorelease];
    NSDictionary *metadata = @{@"UTI":(__bridge NSString *)kUTTypeGIF};
    // 开始写数据
    [library writeImageDataToSavedPhotosAlbum:data metadata:metadata completionBlock:^(NSURL *assetURL, NSError *error) {
        
        if (error) {
            NSLog(@"写数据失败：%@",error);
            [self show_save_result:error];
        } else {
            [library assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                NSLog(@"成功保存到相册");
                [self show_save_result:NULL];
            } failureBlock:^(NSError *error) {
                NSLog(@"gif保存到的ALAsset有问题, URL：%@，err:%@",assetURL, error);
                [self show_save_result:error];
            }];
        }
    }];
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    [self show_save_result:error];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    
    [self show_save_result:error];
}
- (void)show_save_result:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^(){
        if (error != NULL) {
            UIAlertView *alert=[[[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"保存到相册失败,error:%@",error] delegate:self cancelButtonTitle:@"关闭" otherButtonTitles:nil] autorelease];
            [alert show];
        } else {
            UIAlertView *alert=[[[UIAlertView alloc] initWithTitle:nil message:@"已保存至相册" delegate:self cancelButtonTitle:@"关闭" otherButtonTitles:nil] autorelease];
            [alert show];
        }
    });
}
#pragma mark 镜像相关

- (void)actionCloseMirror:(UIButton *)sender {
    
    [self.mirror_set_view removeFromSuperview];
    
}
- (void)action_open_mirror_set_view:(UIButton *)sender {
    
    [self.view addSubview:self.mirror_set_view];
    
}
- (void)action_set_mirror_value:(UISwitch *)sender {
    
    sender.selected = !sender.isSelected;
    if (sender.tag == 4200) {
        preview_mirror = sender.selected;
    } else {
        source_mirror = sender.selected;
    }
}
- (void)action_set_mirror:(UIButton *)sender {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [CNCMobStreamSDK set_source_mirror:source_mirror preview_mirror:preview_mirror];
        dispatch_async(dispatch_get_main_queue(), ^(){
            [self.mirror_set_view removeFromSuperview];
        });
    });
}
@end
