//
//  CNCVideoLayeredViewController.m
//  CNCMobStreamLibDemo
//
//  Created by 82008223 on 2017/3/28.
//  Copyright © 2017年 chinanetcenter. All rights reserved.
//

#import "CNCVideoLayeredViewControllerFU.h"
#import <FUAPIDemoBar/FUAPIDemoBar.h>
#import "MBProgressHUD.h"
#include <sys/utsname.h>
#include <mach/mach.h>
#include <sys/mount.h>
#import "CNCFaceUnityManager.h"
#import <OpenGLES/ES2/glext.h>
#import "CNCDemoFunc.h"

#define LIGHTGRAY [UIColor colorWithWhite:212.0/255 alpha:1.f]
#define SELECTEDCOLOR [UIColor colorWithRed:252.f/255 green:51.f/255 blue:66.f/255 alpha:1.f]
#define STREAM_NAME_CACHE [[NSUserDefaults standardUserDefaults]stringForKey:@"stream_name_cache"]

unsigned long long mGetTickCountFU()
{
    struct timeval tv;
    if(gettimeofday(&tv,NULL)!=0)
    {
        return 0;
    }
    return (tv.tv_sec * 1000) + (tv.tv_usec / 1000);
}
@interface CNCVideoLayeredViewControllerFU () <UIGestureRecognizerDelegate,UIPickerViewDelegate,UIPickerViewDataSource,CNCMobStreamAudioEngineDelegate, CNCMobStreamVideoEncoderDelegate, CNCCaptureVideoDataManagerDelegate, CNCMobStreamRtmpSenderDelegate,FUAPIDemoBarDelegate,UITableViewDataSource,UITableViewDelegate> {
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
    int beauty_type;
    int combine_filter_type;
    NSInteger _ovelay_mask_index;
    CNCRecordVideoType store_type;
    BOOL is_long_store;
    BOOL is_sticker_open;
    BOOL is_att_open;
    BOOL is_filter_open;
    
    CGFloat st_smooth_strength;
    CGFloat st_red_strength;
    CGFloat st_whiten_strength;
    CGFloat st_enlarg_eye_strength;
    CGFloat st_shrink_face_strength;
    CGFloat st_shrink_jaw_strength;
    
    unsigned long long  real_fps;
    BOOL is_fu_open;
    
    BOOL is_pause_opengl_view;
    
    
    NSDictionary *pixelbufferAttributes;
    

    BOOL source_mirror;//采集镜像
    BOOL preview_mirror;//预览镜像
    BOOL _ovelay_mask_work;

    int init_display_wait_count;//初次启用Demo时选择权限对初始化display的等待计数
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
@property (nonatomic, retain) UIView *overlay_mask_view;
//美声设置页
@property (nonatomic, retain) UIView *audioBeautyView;

@property (nonatomic, retain) UIPickerView *roomType_pickView;
@property (nonatomic, retain) UIPickerView *music_pickView;
@property (nonatomic, retain) NSArray *roomType_array;
@property (nonatomic, retain) NSArray *music_array;

@property (nonatomic, retain) UISlider *human_slider;
@property (nonatomic, retain) UISlider *music_slider;
@property (nonatomic, retain) UISlider *output_slider;
@property (nonatomic, retain) UISlider *reverb_slider;

@property (nonatomic, retain) UIButton *playOrPauseBtn;
@property (nonatomic, retain) UIButton *stopButton;
@property (nonatomic, retain) UISlider *musicProgress;
@property (nonatomic, retain) UILabel  *currentTimeLabel;
@property (nonatomic, retain) UILabel  *totalTimeLabel;

@property (nonatomic, retain) NSTimer  *flashMusicPlayerUITimer;
@property (nonatomic) BOOL is_pushing;
//录制视频
@property (nonatomic, retain) UIView *store_view;
@property (nonatomic, retain) UISlider *store_slider;

@property (nonatomic, retain) CNCRecordFileSeesionManager *record_manager;
///视频采集类（包括美颜模块）
@property (nonatomic, retain) CNCCaptureVideoDataManager *capture_manager;
///图像显示类
@property (nonatomic, retain) CNCMobStreamVideoDisplayer *displayer;
///音频采集类（包括音频编码）
@property (nonatomic, retain) CNCMobStreamAudioEngine *audioEng;
///时间戳生成器
@property (nonatomic, retain) CNCMobStreamTimeStampGenerator *timeGenerator;
///视频编码器
@property (nonatomic, retain) CNCMobStreamVideoEncoder *videoEncoder;
///RTMP推流器
@property (nonatomic, retain) CNCMobStreamRtmpSender *rtmpSender;

@property (nonatomic, assign) BOOL bMusicLoopEnable;

@property (nonatomic, assign) BOOL bAudioMuted;

@property (nonatomic) char *sps;
@property (nonatomic) char *pps;
@property (nonatomic) int ppslen;
@property (nonatomic) int spslen;

@property (nonatomic, retain) UIView *preview;
//属性
@property (nonatomic, retain) UILabel  *attribute_label;
@property (nonatomic, retain) NSMutableArray *sticker_array;
@property (nonatomic, retain) NSMutableArray *filter_array;
@property (nonatomic, retain) NSMutableArray *sticker_title_array;
@property (nonatomic, retain) NSMutableArray *filter_title_array;
//FU
@property (nonatomic, retain) FUAPIDemoBar *demo_bar;
@property (nonatomic, retain) CNCFaceUnityManager *faceunity_manager;
//镜像
@property(nonatomic, retain) UIView *mirror_set_view;
//record code UI
@property (nonatomic, retain) UITableView *record_code_tableView;
@property (nonatomic, retain) __block NSMutableArray *record_code_data_array;
@end

@implementation CNCVideoLayeredViewControllerFU

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.has_video = self.stream_cfg.has_video;
    self.is_pushing = NO;
    
    self.view.backgroundColor = [UIColor grayColor];
    ///初始化参数
    [self init_para];
    ///添加通知
    [self addObservers];
    ///添加手势
    [self addGestureRecognizer];
    
    
    [self initialMobStreamTimeStampGenerator];
    [self initialMobStreamRtmpSender];
    [self initialMobStreamAudioEngine];
    [self initialRecordFileSeesionManager];
    [self init_faceunity_manager];
    [self init_capture_manager];
    [self initialMobStreamVideoEncoder];
    
    
    ///初始化界面UI
    [self setup_view];
    
}
- (void)init_capture_manager {
    while (self.has_video) {
        
        self.preview = [[[UIView alloc] init] autorelease];
        self.preview.frame = CGRectMake(0, 0, screen_w_, screen_h_);
        self.preview.backgroundColor = [UIColor blackColor];
        [self.view addSubview:self.preview];
        
        self.capture_manager = [[[CNCCaptureVideoDataManager alloc] init] autorelease];
        
        if (self.capture_manager == nil) {
            self.has_video = NO;
            break;
        }
        
        self.capture_manager.delegate = self;

        [self.capture_manager preset_para:self.capture_info];
        
        
        NSInteger retry_cnt = 0;
        BOOL is_camera_start = NO;
        do {
            is_camera_start = [self.capture_manager init_capture_width:self.preview.bounds.size.width height:self.preview.bounds.size.height];
            if (is_camera_start) {
                break;
            }
            retry_cnt ++;
            sleep(1);
            
        } while (retry_cnt < 2);

        if (!is_camera_start) {
            NSLog(@"摄像头启动失败");
        }
        
        
        
        break;
    }
    
}
- (void)init_para {
    _ovelay_mask_index = 0;
    _effectiveScale = 1.0;
    _startTime = 0;
    init_display_wait_count = 0;
    
    CGFloat fw = [UIScreen mainScreen].bounds.size.width;
    CGFloat fh = [UIScreen mainScreen].bounds.size.height;
    
    if (self.capture_info.direction == CNC_ENM_Direct_Vertical) {
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
    //    _resolution_index = [self.array_value indexOfObject:[NSNumber numberWithInteger:self.stream_cfg.camera_resolution_type]];
    self.sps = NULL;
    self.pps = NULL;
    is_sticker_open = NO;
    is_att_open = NO;
    is_filter_open = NO;
    st_smooth_strength = 0;
    st_red_strength = 0;
    st_whiten_strength = 0;
    st_enlarg_eye_strength = 0;
    st_shrink_face_strength = 0;
    st_shrink_jaw_strength = 0;
    
    if(!self.record_code_data_array) {
        self.record_code_data_array = [[[NSMutableArray alloc] init] autorelease];
    }
    
}

- (void)addObservers {
    // statistics update every seconds
#ifdef CNC_NewInterface
#else
    self.timer =  [NSTimer scheduledTimerWithTimeInterval:1.0
                                                   target:self
                                                 selector:@selector(updateStat:)
                                                 userInfo:nil
                                                  repeats:YES];
#endif
    
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
    
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resign_active:)                                               name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(become_active:)                                                name:UIApplicationDidBecomeActiveNotification object:nil];
}
- (void)removeGestureRecognizer {
    for (UIGestureRecognizer *ges in self.view.gestureRecognizers) {
        [self.view removeGestureRecognizer:ges];
    }
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
#pragma mark - CNCCaptureVideoDataManager Initial
- (void)InitialCaptureVideoMananger {
    
}

#pragma mark - CNCMobStreamVideoDisplayer Initial
- (void)initialMobStreamVideoDisplayer {
    
}

#pragma mark - CNCMobStreamAudioEngine Initial
- (void)initialMobStreamAudioEngine {
    
    //CNCMobStreamAudioEngine init方法，对应音质为16khz，没有回音消除功能
    self.audioEng = [[[CNCMobStreamAudioEngine alloc] init] autorelease];
    ///或等同于 self.audioEng = [[[CNCMobStreamAudioEngine alloc] initWithComponentSubType:AudioComponentSubTypeRemoteIO] autorelease];
    self.audioEng.delegate = self;
    [self.audioEng startRecording];
    
    /*
     //初始化为回音消除版本的音频采集
     self.audioEng = [[[CNCMobStreamAudioEngine alloc] initWithComponentSubType:AudioComponentSubTypeVoiceProcessingIO] autorelease];
     self.audioEng.delegate = self;
     [self.audioEng startRecording];
     //开启或关闭回音消除功能，默认是开启的状态 (回音消除特有方法）
     [self.audioEng setAecEnable:YES];
     //开启或关闭环境音自动增益减益功能，默认开启，开启时，人声大小会触发自动调节环境音量大小(回音消除特有方法）
     [self.audioEng setAgcEnable:NO];
     */

    
}

#pragma mark - CNCMobStreamTimeStampGenerator Initial
- (void)initialMobStreamTimeStampGenerator {
    
    self.timeGenerator = [[[CNCMobStreamTimeStampGenerator alloc] init] autorelease];
    
}

#pragma mark - CNCMobStreamVideoEncoder Initial
- (void)initialMobStreamVideoEncoder {
    
    self.videoEncoder = [[[CNCMobStreamVideoEncoder alloc] initWithVideoSize:CGSizeMake(self.stream_cfg.video_width, self.stream_cfg.video_height)] autorelease];
    [self.videoEncoder set_sw_encoder_priority_type:self.sw_encoder_priority_type];
    self.videoEncoder.real_fps = self.stream_cfg.video_fps;
    int max=0,min = 0;
    [self example_max_bit_rate:&max min_bit_rate:&min];
    if (self.stream_cfg.video_bit_rate > max) {
        self.stream_cfg.video_bit_rate = max;
    }
    if (self.stream_cfg.video_bit_rate < min) {
        self.stream_cfg.video_bit_rate = min;
    }
    
    self.videoEncoder.real_bit_rate = self.stream_cfg.video_bit_rate;
    self.videoEncoder.delegate = self;
}

#pragma mark - CNCMobStreamRtmpSender Initial
- (void)initialMobStreamRtmpSender {
    
    self.rtmpSender = [[[CNCMobStreamRtmpSender alloc] initWithRtmpUrlString:self.stream_cfg.rtmp_url] autorelease];
    
}
- (void)resign_active:(NSNotification *)noti {
    if (init_display_wait_count == 0) {
        init_display_wait_count = 2;
    }
}
- (void)become_active :(NSNotification *)noti {
    init_display_wait_count--;
    self.torchButton.selected = NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    if ([touch.view isKindOfClass:[UISlider class]]){
        return NO;
    }
    
    return YES;
}
#pragma mark - CNCRecordFileSeesionManager Initial
- (void) initialRecordFileSeesionManager {
    self.record_manager = [[[CNCRecordFileSeesionManager alloc] init] autorelease];
}
#pragma mark UI

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
        if (self.capture_info.direction == CNC_ENM_Direct_Vertical) {
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
    }
    
    index++;
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
    
    
    {
        UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(5, 40, screen_w_-buttonWidth-10, screen_h_*0.35)] autorelease];
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
        UITableView *tableView =[[UITableView alloc]initWithFrame:CGRectMake(5, y+5, screen_w_-buttonWidth-10, height) style:UITableViewStylePlain];
        tableView.dataSource = self;
        tableView.delegate =self;
        tableView.backgroundColor =[UIColor clearColor];
        
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.showsVerticalScrollIndicator = NO;
        self.record_code_tableView = tableView;
        [self.view addSubview:tableView];
    }
    
    
    int attribute_label_y = CGRectGetMinY(backView.frame)-55;
    if (attribute_label_y < 0) {
        attribute_label_y = 20;
    }
    
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, attribute_label_y, screen_w_-10, 30)] autorelease];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor redColor];
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:label];
    self.attribute_label = label;
    
    dispatch_async(dispatch_get_main_queue(), ^(){
        [self init_setting_view];
        [self init_beauty_view];
        [self init_overlay_mask_view];
        [self init_audio_beauty_view];
        
        [self init_store_view];
        [self init_mirror_set_view];
        
    });
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
    
    UITapGestureRecognizer* setTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)] autorelease];
    [view addGestureRecognizer:setTap];
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
#ifdef CNC_NewInterface
#else

    {
        UILabel* address = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
        address.text = @"推流地址：";
        [whiteView addSubview:address];
        [address sizeToFit];
        address.frame = CGRectMake(wx, hx, CGRectGetWidth(address.frame), height);
    }
#endif
    hx += height + 5;
#ifdef CNC_NewInterface
#else

    {
        UITextView *textfield = [[[UITextView alloc] init] autorelease];
        textfield.layer.borderWidth = 0.5f;
        textfield.layer.borderColor = LIGHTGRAY.CGColor;
        textfield.layer.cornerRadius = 3.f;
        textfield.font = [UIFont systemFontOfSize:14.f];
        textfield.text = self.stream_cfg.rtmp_url;
        [whiteView addSubview:self.rtmp_url_textview = textfield];
        float x = 1.0;
        if (screen_h_<1000) {
            x = 1.5;
        }
        textfield.frame = CGRectMake(wx, hx, CGRectGetWidth(whiteView.frame) - 2*wx, height*x);
    }
#endif
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
    
    
    UITapGestureRecognizer* setTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)] autorelease];
    [view addGestureRecognizer:setTap];
    
    self.settingView = view;
    
}
- (void)actionCloseFuBar:(UIButton *)sender {
    [UIView animateWithDuration:0.3 animations:^{
        self.demo_bar.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, 0);
    } completion:^(BOOL finished) {
        self.recordButton.hidden = NO;
        self.beauty_btn.hidden = NO;
        [self addGestureRecognizer];
    }];
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
    UITapGestureRecognizer* setTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)] autorelease];
    [view addGestureRecognizer:setTap];
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
        whiteView.frame = CGRectMake(30, screen_h_/3, screen_w_-60, screen_h_/3);
    } else {
        whiteView.frame = CGRectMake(screen_w_/6, screen_h_/6, screen_w_/3*2, screen_h_/3*2);
    }
    
    int hx = 10;
    CGFloat scale = MIN(screen_h_, screen_w_)/320;
    int height = 32*scale;
    hx = CGRectGetHeight(whiteView.frame) - height - 10;
    int btn_width = (CGRectGetWidth(whiteView.frame) - 30)/2;
    {
        UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(5, 10, CGRectGetWidth(whiteView.frame)-10, height)] autorelease];
        label.text = @"选择水印";
        label.textColor = [UIColor redColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:18];
        [whiteView addSubview:label];
        
        int btn_x = CGRectGetMinX(label.frame);
        int mask_width = (CGRectGetWidth(whiteView.frame) - btn_x - 20)/2;
        
        NSArray *array = [[[NSArray alloc] initWithObjects:@"无",@"文字水印",@"图片水印", nil] autorelease];
        for (int i=0; i<array.count; i++) {
            if (i%2 == 0) {
                btn_x = CGRectGetMinX(label.frame);
            } else {
                btn_x = CGRectGetMinX(label.frame) + btn_width + 10;
            }
            int btn_y = CGRectGetMinY(label.frame) +height + 10 + (height + 5)*(int)(i*0.5);
            UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(btn_x, btn_y, mask_width, height)] autorelease];
            btn.layer.cornerRadius = height/2;
            btn.layer.borderColor = LIGHTGRAY.CGColor;
            btn.layer.borderWidth = 0.5f;
            btn.tag = 1401 + i;
            [btn setTitle:[array objectAtIndex:i] forState:UIControlStateNormal];
            [btn setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
            [btn setTitleColor:SELECTEDCOLOR forState:UIControlStateDisabled];
            [btn addTarget:self action:@selector(overlay_mask_view_btn_on_click:) forControlEvents:UIControlEventTouchUpInside];
            [whiteView addSubview:btn];
            if (0 == i) {
                [btn setEnabled:NO];
                btn.layer.borderColor = SELECTEDCOLOR.CGColor;
            }
        }
    }
    
    {
        UIButton *cancle = [[[UIButton alloc] initWithFrame:CGRectMake(10, hx, btn_width, height)] autorelease];
        cancle.layer.cornerRadius = height/2;
        cancle.layer.borderWidth = 1.f;
        cancle.layer.borderColor = SELECTEDCOLOR.CGColor;
        cancle.tag = 1399;
        [cancle setTitle:@"取消" forState:UIControlStateNormal];
        [cancle setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
        [cancle addTarget:self action:@selector(overlay_mask_view_change:) forControlEvents:UIControlEventTouchUpInside];
        [whiteView addSubview:cancle];
    }
    
    {
        UIButton *sure = [[[UIButton alloc] initWithFrame:CGRectMake(20 + btn_width, hx, btn_width, height)] autorelease];
        sure.layer.cornerRadius = height/2;
        sure.layer.borderWidth = 1.f;
        sure.layer.borderColor = SELECTEDCOLOR.CGColor;
        sure.tag = 1400;
        [sure setTitle:@"确定" forState:UIControlStateNormal];
        [sure setTitleColor:SELECTEDCOLOR forState:UIControlStateNormal];
        [sure addTarget:self action:@selector(overlay_mask_view_change:) forControlEvents:UIControlEventTouchUpInside];
        [whiteView addSubview:sure];
    }
    UITapGestureRecognizer* setTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)] autorelease];
    [view addGestureRecognizer:setTap];
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
        BOOL bPushInBk = [self.audioEng isMicVoicePlayBack];
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
    UITapGestureRecognizer* setTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)] autorelease];
    [whiteView addGestureRecognizer:setTap];
    self.audioBeautyView = whiteView;
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

#pragma mark UIPickView data source
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
            return self.sticker_title_array.count;
            break;
        case 22441:
            return self.filter_title_array.count;
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
            dataList = self.sticker_title_array;
            break;
        case 22441:
            dataList = self.filter_title_array;
            break;
        default:
            break;
    }
    
    if (row >= dataList.count) {
        return @"Error";
    }
    
    return [dataList objectAtIndex:row];
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    switch (pickerView.tag) {
        case 22220:
        {
            NSLog(@"%@",[self.beauty_array objectAtIndex:row]);
            beauty_type = (int)row;
            [self.capture_manager set_beauty_filter_with_type:(CNCBEAUTY)beauty_type];
        }
            break;
        case 22221:
        {
            NSLog(@"%@",[self.combine_array objectAtIndex:row]);
            combine_filter_type = (int)row;
            [self.capture_manager set_combine_filter_with_type:(CNCCOMBINE)combine_filter_type];
        }
            break;
        case 22330:
        {
            NSLog(@"%@",[self.roomType_array objectAtIndex:row]);
            [self.audioEng setReverbRoomType:(AUReverbRoomType)row];
        }
            break;
        case 22331:
        {
            if (row < self.music_array.count) {
                NSString *filename = self.music_array[row];
                NSString *fileString = [[self getMusicDirectory] stringByAppendingPathComponent:filename];
                NSLog(@"%@",filename);
                BOOL bOpenFile = [self.audioEng loadAudioFile:fileString loopEnable:self.bMusicLoopEnable];
                
                if (!bOpenFile) {
                    [self action_stop_music:nil];
                    [self showMessage:[NSString stringWithFormat:@"无法打开文件：%@", filename]];
                } else {
                    if ([self.audioEng startPlayMusic]) {
                        self.playOrPauseBtn.selected = YES;
                        self.totalTimeLabel.text = [self.audioEng getDurationString];
                        [self start_music_ui_flash];
                    } else {
                        [self showMessage:[NSString stringWithFormat:@"无法播放文件：%@", filename]];
                    }
                }
            }
        }
            break;
        case 22440:
        {
            
           
        }
            break;
        case 22441:
        {
            
            
        }
        default:
            break;
    }
    
    if (beauty_type == CNCBEAUTY_NONE && combine_filter_type == CNCCOMBINE_NONE) {
        self.beauty_btn.selected = NO;
    } else {
        self.beauty_btn.selected = YES;
    }
    
    if (pickerView.tag != 22330 && pickerView.tag != 22331) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self.capture_manager set_beauty_with:beauty_smoothDegree effect:beauty_effect filter_effect:filter_effect];
        });
    }
    
}
#pragma mark - 刷新调试信息

- (void)updateStat:(NSTimer *)theTimer {
    
    if (_startTime>0) {
        NSInteger bitrate = self.videoEncoder.real_bit_rate;
        NSInteger videofps = self.videoEncoder.real_fps;
        double currentTime = [[NSDate date]timeIntervalSince1970];
        
        NSString* hostUrl = [NSString stringWithFormat:@"%@\n",[self.rtmpSender rtmp_url]];
        NSString* realtime = [NSString stringWithFormat:@"Realtime: %d KB/s | %@ \n",_speed,[self timeFormatted:(int)(currentTime-_startTime)]];
        NSString* infoSetting = [NSString stringWithFormat:@"Info_setting: %@ fps | %@ kbps \n",@(videofps),@(bitrate)];
        
        _stat.text = hostUrl;
        _stat.text = [_stat.text  stringByAppendingString:realtime];
        _stat.text = [_stat.text  stringByAppendingString:infoSetting];
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
                self.human_slider.value = [self.audioEng currentHumanVolume];
                self.music_slider.value = [self.audioEng currentMusicVolume];
                self.output_slider.value = [self.audioEng currentOutPutVolume];
                self.reverb_slider.value = [self.audioEng currentHumanDryWet];
                [self.view addSubview:self.audioBeautyView];
            }
                break;
            case 4://FU
                
                [UIView animateWithDuration:0.3 animations:^{
                    self.recordButton.hidden = YES;
                    self.beauty_btn.hidden = YES;
                    self.demo_bar.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, -208);
                } completion:^(BOOL finished) {
                    is_fu_open = YES;
                    [self removeGestureRecognizer];
                    self.attribute_label.text = nil;
                }];
                
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
                self.human_slider.value = [self.audioEng currentHumanVolume];
                self.music_slider.value = [self.audioEng currentMusicVolume];
                self.output_slider.value = [self.audioEng currentOutPutVolume];
                self.reverb_slider.value = [self.audioEng currentHumanDryWet];
                [self.view addSubview:self.audioBeautyView];
            }
                break;
            default:
                break;
        }
    } else {
        
    }
    
}
#pragma mark FU 美颜
- (void)init_fu_bar {
    int y = screen_h_;
    
    if (@available(iOS 11.0, *)) {
            y -= [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom;
    }
    self.demo_bar = [[[FUAPIDemoBar alloc] initWithFrame:CGRectMake(0, y, screen_w_, 208)] autorelease];
    
    {
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(self.demo_bar.bounds.size.width-30, 60, 40, 40)] autorelease];
        btn.backgroundColor = [UIColor clearColor];
        [btn setImage:[UIImage imageNamed:@"clear_input"] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(actionCloseFuBar:) forControlEvents:UIControlEventTouchUpInside];
        [self.demo_bar addSubview:btn];
    }
    [self.view addSubview:self.demo_bar];
    
}
- (void)init_faceunity_manager {
    if ((self.has_video)){
        self.faceunity_manager = [[[CNCFaceUnityManager alloc] init] autorelease];
        [self.faceunity_manager setUpFaceunity];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self init_fu_bar];
            [self setDemoBar];
        });
    }
    
}
- (void)setDemoBar
{
    self.demo_bar.delegate = self;
    
    self.demo_bar.itemsDataSource =  self.faceunity_manager.itemsDataSource;
    self.demo_bar.filtersDataSource = self.faceunity_manager.filtersDataSource;
    
    self.demo_bar.selectedItem = self.faceunity_manager.selectedItem;      /**选中的道具名称*/
    self.demo_bar.selectedFilter = self.faceunity_manager.selectedFilter;  /**选中的滤镜名称*/
    self.demo_bar.beautyLevel = self.faceunity_manager.beautyLevel;        /**美白 (0~1)*/
    self.demo_bar.redLevel = self.faceunity_manager.redLevel;              /**红润 (0~1)*/
    self.demo_bar.selectedBlur = self.faceunity_manager.selectedBlur;      /**磨皮(0、1、2、3、4、5、6)*/
    self.demo_bar.faceShape = self.faceunity_manager.faceShape;            /**美型类型 (0、1、2、3) 默认：3，女神：0，网红：1，自然：2*/
    self.demo_bar.faceShapeLevel = self.faceunity_manager.faceShapeLevel;  /**美型等级 (0~1)*/
    self.demo_bar.enlargingLevel = self.faceunity_manager.enlargingLevel;  /**大眼 (0~1)*/
    self.demo_bar.thinningLevel = self.faceunity_manager.thinningLevel;    /**瘦脸 (0~1)*/
    
}
#pragma -FUAPIDemoBarDelegate
- (void)demoBarDidSelectedItem:(NSString *)item
{
    
    //加载道具
    [self.faceunity_manager loadItem:item];
    
    //    _isAvatar = [item isEqualToString:@"lixiaolong"];
    dispatch_async(dispatch_get_main_queue(), ^{
        //        self.landmarksGlView.hidden = !_isAvatar;
    });
}

/**设置美颜参数*/
- (void)demoBarBeautyParamChanged
{
    [self syncBeautyParams];
}

- (void)syncBeautyParams
{
    self.faceunity_manager.selectedFilter = self.demo_bar.selectedFilter;
    self.faceunity_manager.selectedBlur = self.demo_bar.selectedBlur;
    self.faceunity_manager.beautyLevel = self.demo_bar.beautyLevel;
    self.faceunity_manager.redLevel = self.demo_bar.redLevel;
    self.faceunity_manager.faceShape = self.demo_bar.faceShape;
    self.faceunity_manager.faceShapeLevel = self.demo_bar.faceShapeLevel;
    self.faceunity_manager.thinningLevel = self.demo_bar.thinningLevel;
    self.faceunity_manager.enlargingLevel = self.demo_bar.enlargingLevel;
}

#pragma mark -水印操作
- (BOOL)setLogo_overlay_mask {
    UIImageView *iv = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)] autorelease];
    iv.image = [UIImage imageNamed:@"watermark.png"];
    
    void  (^block)() = ^{
    };
    
    CGFloat scale_x = iv.frame.origin.x/self.capture_info.capture_width;
    CGFloat scale_y = iv.frame.origin.y/self.capture_info.capture_height;
    CGFloat scale_width = 0.1;
    CGFloat scale_height = scale_width*self.capture_info.capture_width/self.capture_info.capture_height;
    CGRect scale_rect = CGRectMake(scale_x, scale_y, scale_width, scale_height);
    
    
        [self.displayer overlay_mask:iv rect:scale_rect];
    
    
    return [self.capture_manager overlayMaskWithObject:iv rect:scale_rect block:block];

}
- (BOOL)setLabel_overlay_mask {
    
    UILabel *time_label = [[[UILabel alloc] initWithFrame:CGRectMake(10,20, 0, 0)] autorelease];
    
    CGFloat font = (20.0/360.0)*((self.capture_info.capture_width < self.capture_info.capture_height) ? self.capture_info.capture_width : self.capture_info.capture_height);
    
    time_label.font = [UIFont boldSystemFontOfSize:font];
    time_label.textColor = [UIColor redColor];
    time_label.textAlignment = NSTextAlignmentLeft;
    
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss:SSS"];
    void  (^block)() = ^{
        NSString *str = [[[NSString alloc] initWithFormat:@"%@", [dateFormatter stringFromDate:[NSDate date]]] autorelease];
        time_label.text = str;
    };
    
    CGFloat scale_x = 0.05;
    CGFloat scale_y = 0.02;
    CGFloat scale_width = 0.8;
    CGFloat scale_height = 0.1;
    CGRect scale_rect = CGRectMake(scale_x, scale_y, scale_width, scale_height);
    
    
        [self.displayer overlay_mask:time_label rect:scale_rect];
    
    
    return [self.capture_manager overlayMaskWithObject:time_label rect:scale_rect block:block];
    
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
//        [CNCMobStreamSDK set_source_mirror:source_mirror preview_mirror_:preview_mirror];
        [self.capture_manager set_source_mirror:source_mirror];
        if(source_mirror) {
            if (preview_mirror) {
                
                [self.displayer set_display_mirror:NO];
            } else {
                [self.displayer set_display_mirror:YES];
            }
        } else {
            if (preview_mirror) {
                [self.displayer set_display_mirror:YES];
            } else {
                [self.displayer set_display_mirror:NO];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^(){
            [self.mirror_set_view removeFromSuperview];
        });
    });
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
    
    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"美颜" message:@"样式" delegate:self cancelButtonTitle:@"关闭" otherButtonTitles:@"美颜",@"水印",@"美声",@"FU", nil] autorelease];
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
    //    NSLog(@"%f",paramSender.value);
    if ([paramSender isEqual:self.bitrate_slider]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            if (self.videoEncoder) {
                self.videoEncoder.real_bit_rate = (NSUInteger)paramSender.value;
                int max,min;
                [self example_max_bit_rate:&max min_bit_rate:&min];
                [self.rtmpSender openVideoBitRateAutoFitWithMiniRate:min MaxiRate:max CurrentRate:self.videoEncoder.real_bit_rate];
            }
        });
    }
    else if ([paramSender isEqual:self.beauty_slider]) {
        beauty_smoothDegree = paramSender.value;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self.capture_manager set_beauty_with:beauty_smoothDegree effect:beauty_effect filter_effect:filter_effect];
        });
    }else if ([paramSender isEqual:self.effect_slider]) {
        beauty_effect = paramSender.value;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self.capture_manager set_beauty_with:beauty_smoothDegree effect:beauty_effect filter_effect:filter_effect];
        });
    } else if ([paramSender isEqual:self.filter_slider]) {
        filter_effect = paramSender.value;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self.capture_manager set_beauty_with:beauty_smoothDegree effect:beauty_effect filter_effect:filter_effect];
        });
    } else if ([paramSender isEqual:self.human_slider]) {
        Float32 value = paramSender.value;
        [self.audioEng setHumanVolume:value];
    } else if ([paramSender isEqual:self.music_slider]) {
        Float32 value = paramSender.value;
        [self.audioEng setMusicVolume:value];
    } else if ([paramSender isEqual:self.output_slider]) {
        Float32 value = paramSender.value;
        [self.audioEng setOutPutVolume:value];
    } else if ([paramSender isEqual:self.reverb_slider]) {
        Float32 value = paramSender.value;
        [self.audioEng setReverbDryWetMix:value];
    } else if ([paramSender isEqual:self.musicProgress]) {
        Float32 value = paramSender.value;
        NSLog(@"music progress %f",value);
        [self.audioEng seekPlayheadTo:value];
        [self.audioEng startPlayMusic];
        [self start_music_ui_flash];
    }
}
#pragma mark -
#pragma mark - Overlay Mask
- (void)overlay_mask_view_btn_on_click :(UIButton *)sender {
    
    sender.layer.borderColor = SELECTEDCOLOR.CGColor;
    [sender setEnabled:NO];
    
    for (int i = 0; i < 3; i++) {
        if (sender.tag != 1401+i) {
            UIButton * btn = [self.overlay_mask_view viewWithTag:1401+i];
            btn.layer.borderColor = LIGHTGRAY.CGColor;
            [btn setEnabled:YES];
        }
    }
    
}
- (void)overlay_mask_view_change:(UIButton *)sender {
    if (sender.tag == 1400) {
        for (int i = 0; i < 3; i++) {
            UIButton * btn = [self.overlay_mask_view viewWithTag:1401+i];
            if (!btn.isEnabled) {
//                if (_ovelay_mask_index != i) {
            
                    switch (i) {
                        case 0:
                            
                            if ([self.capture_manager overlayMaskWithObject:nil rect:CGRectZero block:nil]) {
                                [self.displayer overlay_mask:nil rect:CGRectZero];
                                _ovelay_mask_index = 0;
                            }
                            
                            break;
                        case 1:
                            if ([self setLabel_overlay_mask]) {
                                _ovelay_mask_index = 1;
                            }
                            
                            break;
                        case 2:
                            if ([self setLogo_overlay_mask]) {
                                _ovelay_mask_index = 2;
                            }
                            
                            break;
                        default:
                            break;
                    }
//                }
//                
                break;
            }
            
        }

        
    } else {
        
    }
    for (int i = 0; i < 3; i++) {
        UIButton * btn = [self.overlay_mask_view viewWithTag:1401+i];
        if (_ovelay_mask_index != i) {
            
            btn.layer.borderColor = LIGHTGRAY.CGColor;
            [btn setEnabled:YES];
        } else {
            btn.layer.borderColor = SELECTEDCOLOR.CGColor;
            [btn setEnabled:NO];
        }
    }
    [self.overlay_mask_view removeFromSuperview];
}

#pragma mark - music
- (void)actionSetMusicLoopEnable:(UISwitch *)sender {
    self.bMusicLoopEnable = !self.bMusicLoopEnable;
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
    self.currentTimeLabel.text = [self.audioEng getPlayTimeString];
    float value = [self.audioEng getPlayProgress];
    self.musicProgress.value = value;
    
    if (value >= 1.0f) {
        self.playOrPauseBtn.selected = NO;
        [self stop_music_ui_flash];
    }
}



- (void)action_play_or_pause:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    if (sender.isSelected) {
        [self.audioEng startPlayMusic];
        self.totalTimeLabel.text = [self.audioEng getDurationString];
        [self start_music_ui_flash];
    } else {
        [self.audioEng pausePlayMusic];
        [self stop_music_ui_flash];
    }
}

- (void)action_stop_music:(UIButton *)sender {
    [self.audioEng stopPlayMusic];
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
        
        if (self.rtmpSender) {
            int max,min;
            [self example_max_bit_rate:&max min_bit_rate:&min];
            NSLog(@"auto bit correction value area [%d,%d]",min,max);
            BOOL bSuccess = [self.rtmpSender openVideoBitRateAutoFitWithMiniRate:min MaxiRate:max CurrentRate:self.videoEncoder.real_bit_rate];
            if (bSuccess) {
                self.rtmpSender.delegate = self;
            }
            
        }
    }else{
        [btn setTitle:@"关闭" forState:UIControlStateNormal];
        btn.layer.borderColor = LIGHTGRAY.CGColor;
        [btn setTitleColor:LIGHTGRAY forState:UIControlStateNormal];
        
        if (self.rtmpSender) {
            [self.rtmpSender closeVideoBitRateAutoFit];
            self.rtmpSender.delegate = nil;
        }
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
        [self.capture_manager set_torch_mode:sender.isSelected];
    }
}

- (void)actionOpenOrCloseMicVoiceReturnBack:(UISwitch *)sender {
    
    sender.selected = !sender.isSelected;
    
    /// 设置耳返开启关闭
    /// 在没有插入耳机的情况下，是不会有耳返功能的，请悉知
    
    [self.audioEng setMicVoicePlaybackEnable:sender.isSelected];
    
}

- (void)actionSetMutedMode:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    
    self.bAudioMuted = sender.isSelected;
    
}

- (void)actionSwap:(UIButton *)sender {
    if (!sender.isUserInteractionEnabled) {
        return;
    }
    if (!self.has_video) {
        //只有视频 就不用处理
        UIAlertView *alert = [[[UIAlertView alloc]initWithTitle:@"" message:@"纯音频推流 设置无效" delegate:self cancelButtonTitle:@"关闭" otherButtonTitles:nil, nil] autorelease];
        [alert show];
        return;
    }
    [sender setUserInteractionEnabled:NO];
    [sender setEnabled:NO];
    MBProgressHUD* progressHud_ = [[[MBProgressHUD alloc] initWithView:self.view] autorelease];
    progressHud_.removeFromSuperViewOnHide = YES;
    progressHud_.labelText = @"正在切换摄像头...";
    [self.view addSubview:progressHud_];
    [progressHud_ show:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        is_pause_opengl_view = YES;
        [self.capture_manager swap_cameras];
        is_pause_opengl_view = NO;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.faceunity_manager onCameraChange];
            [progressHud_ hide:YES];
            self.torchButton.selected = NO;
            [sender setEnabled:YES];
            
            
            ///更新显示的镜像问题
            [sender setUserInteractionEnabled:YES];
        });
    });
}


- (void)actionStartMeeting:(UIButton *)sender {
    [sender setEnabled:NO];
    sender.selected = !sender.isSelected;
    if (sender.isSelected) {
        
        NSString *rtmp_name = self.stream_cfg.rtmp_url;
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
            
            [self.timeGenerator resetGeneratorZero];
            [self.rtmpSender startConnect:self.timeGenerator];
            
            if (self.has_video && self.videoEncoder) {
                [self.videoEncoder startEncodedWithType:self.stream_cfg.encoder_type];
            }
            
            [self.audioEng startAudioPush];
            
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
            
            [self.videoEncoder stopEncoded];
            [self.rtmpSender stopConnect];
            [self.timeGenerator resetGeneratorZero];
            [self.record_manager stop_store_video];
            
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
    [self stop_music_ui_flash];
    MBProgressHUD* progressHud_ = [[[MBProgressHUD alloc] initWithView:self.view] autorelease];
    progressHud_.removeFromSuperViewOnHide = YES;
    progressHud_.labelText = @"正在退出...";
    [self.view addSubview:progressHud_];
    [progressHud_ show:YES];
    
    BOOL is_doing_store = [self.record_manager is_doing_store];
    
    
        
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if (is_doing_store) {
            [self.record_manager stop_store_video];
        }
        [self.capture_manager stop_capture];
        [self stopPushAndRelease];
        
        
        self.stream_cfg.is_adaptive_bit_rate = NO;
        //        [self.src_input preset_para:self.stream_cfg];
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [progressHud_ hide:YES];
            [self dismissViewControllerAnimated:YES completion:^(){}];
        });
    });
    
    
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
    
    self.bitrate_slider.value = self.videoEncoder.real_bit_rate;
}

- (void)actionSetStreamCfg:(UIButton *)sender {
    if (self.recordButton.selected) {
        return;
    }
    self.rtmp_url_textview.text = self.stream_cfg.rtmp_url;
    [self.view addSubview:self.settingView];
}

- (void)actionConfigChange:(UIButton *)sender {
    if (sender.tag == 1200) {
        NSString *url = self.rtmp_url_textview.text;
        url = [url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (url != nil && ![url isEqualToString:self.stream_cfg.rtmp_url]) {
            [self.stream_cfg set_rtmp_url:url];
            self.rtmpSender.rtmp_url = url;
        }
    }
    if ([self.rtmp_url_textview isFirstResponder]) {
        [self.rtmp_url_textview resignFirstResponder];
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

#pragma mark - stop push and release

- (void)stopPushAndRelease {
    
    if (self.audioEng) {
        [self.audioEng stopPlayMusic];
        [self.audioEng stopRecording];
        self.audioEng.delegate = nil;
    }
    self.audioEng = nil;
    
    if (self.videoEncoder) {
        [self.videoEncoder stopEncoded];
        self.videoEncoder.delegate = nil;
    }
    self.videoEncoder = nil;
    
    if (self.rtmpSender) {
        [self.rtmpSender stopConnect];
        self.rtmpSender.delegate = nil;
    }
    self.rtmpSender = nil;
    
    if (self.timeGenerator) {
        [self.timeGenerator resetGeneratorZero];
    }
    self.timeGenerator = nil;
    
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
    //    self.src_input = nil;
    [self stop_music_ui_flash];
    
    if (self.sps != NULL) {
        delete[] self.sps;
    }
    
    if (self.pps != NULL) {
        delete[] self.pps;
    }
    
    self.filter_array = nil;
    self.sticker_array = nil;
}

- (void)dealloc {
    
    NSLog(@"分层推流2 dealloc");
    
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self.faceunity_manager destoryFaceunityItems];
    self.faceunity_manager = nil;
    self.demo_bar = nil;
    
    
    [self audioParamDealloc];
    [self stopPushAndRelease];
    
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
    self.capture_manager = nil;
    self.capture_info = nil;
    self.displayer = nil;
    self.record_manager = nil;
    self.filter_title_array = nil;
    
    self.attribute_label = nil;
    self.sticker_title_array = nil;
    
    self.preview = nil;
    self.mirror_set_view = nil;
    self.record_code_data_array = nil;
    self.record_code_tableView = nil;
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
    if (self.capture_info.direction == CNC_ENM_Direct_Vertical) {
        return UIInterfaceOrientationPortrait;
    }
    
    return UIInterfaceOrientationLandscapeRight;
}
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    NSLog(@"willAnimateRotationToInterfaceOrientation");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)toInterfaceOrientation {
    
    if (self.capture_info.direction == CNC_ENM_Direct_Vertical) {
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
    if (self.capture_info.direction == CNC_ENM_Direct_Vertical) {
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
    //    [UIView animateWithDuration:0.3 animations:^{
    //        self.demo_bar.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, 0);
    //    } completion:^(BOOL finished) {
    //        self.recordButton.hidden = NO;
    //        self.beauty_btn.hidden = NO;
    //    }];
    [_rtmp_url_textview resignFirstResponder];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        _beginGestureScale = _effectiveScale;
    }
    return YES;
}

- (void)tapGesture:(UITapGestureRecognizer *)recognizert {
    
    
    if ([self.rtmp_url_textview isFirstResponder]) {
        [self.rtmp_url_textview resignFirstResponder];
    }
    
    CGPoint touchPoint= [recognizert locationInView:self.view];
    [self.capture_manager tapFocusAtPoint:touchPoint];
    
    if (!self.foucs_cursor) {
        self.foucs_cursor = [[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"camera_focus_red"]] autorelease];
        self.foucs_cursor.frame = CGRectMake(80, 80, 80, 80);
        self.foucs_cursor.alpha = 0;
    }
    //        [self.foucs_cursor bringSubviewToFront:self.foucs_cursor];
    self.foucs_cursor.center = touchPoint;
    self.foucs_cursor.transform = CGAffineTransformMakeScale(1.5, 1.5);
    self.foucs_cursor.alpha=1.0;
    [self.view addSubview:self.foucs_cursor];
    
    
    [UIView animateWithDuration:1.0 animations:^{
        self.foucs_cursor.transform=CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.foucs_cursor.alpha=0;
        [self.foucs_cursor removeFromSuperview];
    }];
    
}


- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer {
    
    _effectiveScale = _beginGestureScale * recognizer.scale;
    
    if (_effectiveScale<1.0) {
        _effectiveScale = 1.0;
        recognizer.scale = 1.0/_beginGestureScale;
    }
    
    CGFloat upscale = [self.capture_manager get_current_camera_upscale];
    if (_effectiveScale>upscale) {
        _effectiveScale = upscale;
        recognizer.scale = upscale/_beginGestureScale;
    }
    
    [self.capture_manager videoZoomFactorWithScale:_effectiveScale];
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

#pragma mark - CNCMobStreamVideoEncoderDelegate

- (unsigned int)timeStampForCurrentVideoFrame {
    return [self.timeGenerator generateVideoTimeStamp];
}


- (void)outPutH264SPS:(NSData *)spsData PPS:(NSData *)ppsData {
    NSLog(@"send video header ++++++++++++++");
    if (self.rtmpSender) {
        self.spslen = (int)[spsData length];
        self.sps = new char[self.spslen];
        memcpy(self.sps, (char*)[spsData bytes], self.spslen);
        
        self.ppslen = (int)[ppsData length];
        self.pps = new char[self.ppslen];
        memcpy(self.pps, (char*)[ppsData bytes], self.ppslen);
        
        [self.rtmpSender send_video_header:spsData PPS:ppsData];
    }
    
}

- (void)requireSendMetaDataWithVideoSize:(CGSize)size bitRate:(int)rate videoFPS:(int)fps {
    NSLog(@"send mete data ++++++++++++++");
    if (self.rtmpSender) {
        [self.rtmpSender send_meta_data:size frame_rate:fps video_bit_rate:rate audio_rate:[self.audioEng currentAudioSampleRate] audio_channel:[self.audioEng currentAudioInputChannels]];
    }
}

- (void)didEncodedCallBack:(char *)compressData dataLength:(int)length frameSize:(CGSize)size isKey:(BOOL)isKey timestamp:(unsigned int)timestamp {
    
    if (self.rtmpSender) {
        if ([self.record_manager is_doing_store] && store_type != CNCRecordVideoType_GIF ){
            [self.record_manager do_store_video:compressData len:length is_key:isKey width:size.width height:size.height time_stamp:timestamp];
        }
        [self.rtmpSender send_video:compressData len:length is_key:isKey width:size.width height:size.height time_stamp:timestamp];
    }
}

#pragma mark - CNCMobStreamAudioEngineDelegate

- (unsigned int)timestampForCurrentAudioFrame {
    return [self.timeGenerator generateAudioTimeStamp];
}

- (BOOL)audioEngine:(CNCMobStreamAudioEngine *)audioEng valueForOption:(AudioEngineOption)option withDefault:(BOOL)defaultValue {
    
    switch (option) {
        case AudioEngineOptionIsMute:
        {
            return self.bAudioMuted;
        }
            break;
        case AudioEngineOptionIsPushing:
            return self.is_pushing;
            break;
        case AudioEngineOptionContinueWorkingInBK:
        {
            return self.stream_cfg.need_push_audio_BG;
        }
            break;
        default:
            break;
    }
    
    return defaultValue;
}

- (void)audioEngine:(CNCMobStreamAudioEngine *)audioEng sendAudioHeaderRate:(int)rate channel:(int)channel time_stamp:(unsigned int)time_stamp {
    NSLog(@"send audio header ++++++++++++++");
    
    if (self.rtmpSender) {
        
        if (!self.has_video) {
            ///如果是纯音频推流，需要手动发送mete data头
            [self.rtmpSender send_meta_data:CGSizeZero frame_rate:0 video_bit_rate:0 audio_rate:rate audio_channel:channel];
        }
        
        [self.rtmpSender send_acc_header:rate channel:channel];
    }
    
}

- (void)audioEngine:(CNCMobStreamAudioEngine *)audioEng sendAudioBufferData:(char *)src_sz len:(unsigned int)len time_stamp:(unsigned int)time_stamp {
    if (self.rtmpSender) {
        if ([self.record_manager is_doing_store] && store_type != CNCRecordVideoType_GIF ){
            [self.record_manager do_store_audio:src_sz len:len time_stamp:time_stamp];
        }
        [self.rtmpSender send_audio:src_sz len:len time_stamp:time_stamp];
    }
}

#pragma mark - CNCMobStreamRtmpSenderDelegate
- (void)videoBitRateAdaptiveCorrection:(NSUInteger)bit_rate {
    
    if (self.videoEncoder) {///自适应码率更新编码码率值；
        self.videoEncoder.real_bit_rate = bit_rate;
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
                
            default:
                break;
        }
//    }
}

- (void)update_sdk_send_speed:(NSNotification *)notification {
    NSNumber *speedNum = notification.object;
    _speed = [speedNum unsignedIntValue];
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

#pragma mark 截屏
- (void)screenShot:(UIButton *)sender {
    MBProgressHUD* progressHud_ = [[[MBProgressHUD alloc] initWithView:self.view] autorelease];
    progressHud_.removeFromSuperViewOnHide = YES;
    
    BOOL is_success = [self.capture_manager screen_shot:nil];
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
}

- (void)store_video_start:(BOOL) start{
    if (!self.is_pushing) {
        return;
    }
    
    MBProgressHUD* progressHud_ = [[[MBProgressHUD alloc] initWithView:self.view] autorelease];
    progressHud_.removeFromSuperViewOnHide = YES;
    BOOL is_doing_store = [self.record_manager is_doing_store];
    
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
            
            CNCRecordFileInfo *info = [[[CNCRecordFileInfo alloc] init] autorelease];
            info.has_video = self.stream_cfg.has_video;
            info.has_audio = self.stream_cfg.has_audio;
            info.video_width = (int)self.capture_info.capture_width;
            info.video_height = (int)self.capture_info.capture_height;
            info.video_spslen = self.spslen;
            info.video_sps = self.sps;
            info.video_ppslen = self.ppslen;
            info.video_pps = self.pps;
            if (real_fps !=0) {
                info.video_fps = (int)real_fps;
            } else {
                info.video_fps = (int)self.videoEncoder.real_fps;
            }
            
            info.video_bitrate = (int)self.videoEncoder.real_bit_rate;
            info.audio_channel = (int)self.stream_cfg.audio_channel;
            info.audio_sample_rate = (int)self.stream_cfg.audio_sample_rate;
            info.need_push_audio_BG = self.stream_cfg.need_push_audio_BG;
            
            ret = [self.record_manager start_store_video:nil info:info fileType:store_type max_time:max_time long_store:is_long_store size:max_size return_id:str];
            if (!ret) {
                //启动录制失败
            }
            
        } else {
            
            [self.record_manager stop_store_video];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [progressHud_ hide:YES];
        });
    });
    
}

#pragma mark - 码率自适应范围界定 示例值
- (void)example_max_bit_rate:(int *)max_bit_rate min_bit_rate:(int *)min_bit_rate {
    
    int boundary_max = 0;
    int boundary_min = 0;
    
    int default_max_bit_rate = 4000;
    int default_min_bit_rate = 300;
    
    
    [self.stream_cfg get_resolution_max_bit_rate:&boundary_max min_bit_rate:&boundary_min];
    
    if (default_max_bit_rate < boundary_min || default_min_bit_rate > boundary_max || default_max_bit_rate <= default_min_bit_rate) {
        *max_bit_rate = boundary_max;
        *min_bit_rate = boundary_min;
    } else {
        if (default_max_bit_rate > boundary_max) {
            *max_bit_rate = boundary_max;
        } else {
            *max_bit_rate = default_max_bit_rate;
        }
        
        if (default_min_bit_rate < boundary_min) {
            *min_bit_rate = boundary_min;
        } else {
            *min_bit_rate = default_min_bit_rate;
        }
    }
}
#pragma mark -- display

- (void)remove_display_view {
    if (self.displayer) {
        self.displayer = nil;
    }
    
}
- (void)init_display {
    
    if (self.displayer == nil) {
        CNCDisplayConfigs displayConfigs;
        displayConfigs.fill_mode = kCNCDisplayFillModePreserveAspectRatio;///原图
        displayConfigs.capture_width = self.capture_info.capture_width;
        displayConfigs.capture_height = self.capture_info.capture_height;
        
        displayConfigs.displayType = kCNCDisplayPixelbuffer;
        displayConfigs.direction = self.capture_info.direction;
        
        if (self.capture_info.encoder_type == CNC_ENM_Encoder_HW){
            displayConfigs.bUseCaptureYUV = NO;
        } else {
            displayConfigs.bUseCaptureYUV = YES;
        }
        
        self.displayer = [[[CNCMobStreamVideoDisplayer alloc] initWithView:self.preview displayConfigs:displayConfigs] autorelease];
    }
    
}

#pragma mark 采集输出
- (void)overlayMask_buf:(void *)buf pix_width:(int)pix_width pix_height:(int)pix_height format:(CNCENM_Buf_Format)format time_stamp:(long long)time_stamp {
    //水印输出
    if (self.is_pushing) {
        if (self.videoEncoder) {
            if ([self.record_manager is_doing_store] && store_type == CNCRecordVideoType_GIF){
                [self.record_manager store_gif_record:buf pix_width:pix_width pix_height:pix_height format:format time_stamp:time_stamp];
            }
            [self.videoEncoder inputFrameBuffer:buf pix_width:pix_width pix_height:pix_height format:format time_stamp:(unsigned int)time_stamp];
        }
    }
}

- (void)video_capture_buf:(void *)buf pix_width:(int)pix_width pix_height:(int)pix_height format:(CNCENM_Buf_Format)format time_stamp:(long long)ts {

    if (!self.displayer) {
        if (init_display_wait_count==0) {
            init_display_wait_count ++;
            [self init_display];
        }
    }
    
    pixelbufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSDictionary dictionary], kCVPixelBufferIOSurfacePropertiesKey,
                             nil];
    
    if (format == CNCENM_buf_format_BGRA) {
        
        size_t len = pix_width * pix_height;
        GLubyte *imageData = NULL;
        imageData = (GLubyte *)malloc(len);
        if (imageData == NULL) {
            return;
        }
        memcpy(imageData, buf, len);
        
        CVPixelBufferRef pixelBuffer = NULL;
        
        CVPixelBufferCreateWithBytes(kCFAllocatorDefault, pix_width/4, pix_height, kCVPixelFormatType_32BGRA, imageData
                                     , pix_width, NULL, NULL, (__bridge CFDictionaryRef)pixelbufferAttributes, &pixelBuffer);
        //操作数据翻转镜像
//        CVPixelBufferRef mirror_pix =  [self mirror_pixelbuffer_BGRA:pixelBuffer];
//        CVPixelBufferRelease (pixelBuffer);
//        pixelBuffer = mirror_pix;
        CVPixelBufferLockBaseAddress(pixelBuffer,0);
        
        if (!is_pause_opengl_view){
            if (is_fu_open) {
                CVPixelBufferRef process_pixelbuffer = [self.faceunity_manager GetProcessPixelBuffer:pixelBuffer];
                CVPixelBufferRetain(process_pixelbuffer);
                CVPixelBufferLockBaseAddress(process_pixelbuffer,0);
                
//                if (_ovelay_mask_index != 0) {
                    CMTime time = kCMTimeInvalid;
                    [self.capture_manager overlay_pixelbuffer:process_pixelbuffer time:time time_stamp:(int)ts];
//                } else {
//                    [self frame_RGBA:process_pixelbuffer time_stamp:(long)ts];
//                }
                
                [self.displayer processVideoImageBuffer:process_pixelbuffer];
                CVPixelBufferUnlockBaseAddress(process_pixelbuffer, 0);
                CVPixelBufferRelease(process_pixelbuffer);
                
            } else {
                
//                if (_ovelay_mask_index != 0) {
                    CMTime time = kCMTimeInvalid;
                    [self.capture_manager overlay_pixelbuffer:pixelBuffer time:time time_stamp:(int)ts];
//                } else {
//                    [self frame_RGBA:pixelBuffer time_stamp:(long)ts];
//                }
                
                [self.displayer processVideoImageBuffer:pixelBuffer];
            }
        }
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        CVPixelBufferRelease(pixelBuffer);
        
        if (imageData) {
            free(imageData);
        }
        
    } else {
        int imageWidth = pix_width;
        int imageHeight = pix_height*2/3;
        CVPixelBufferRef pixelBuffer = [self copyDataFromBuffer:buf toYUVPixelBufferWithWidth:imageWidth Height:imageHeight];
        //操作数据翻转镜像
//        CVPixelBufferRef mirror_pixelbuffer = [self mirror_pixelbuffer_YUV:pixelBuffer mirror:YES];
//        CVPixelBufferRelease(pixelBuffer);
//        pixelBuffer = mirror_pixelbuffer;
        CVPixelBufferLockBaseAddress(pixelBuffer,0);
        if (is_fu_open) {
            CVPixelBufferRef process_pixelbuffer = [self.faceunity_manager GetProcessPixelBuffer:pixelBuffer];
            CVPixelBufferRetain(process_pixelbuffer);
            CVPixelBufferLockBaseAddress(process_pixelbuffer,0);
//            if (_ovelay_mask_index != 0) {
                CMTime time = kCMTimeInvalid;
                [self.capture_manager overlay_pixelbuffer:process_pixelbuffer time:time time_stamp:(int)ts];
//            } else {
//                if (self.is_pushing && self.videoEncoder) {
//                    [self.videoEncoder send_frame_pixelBufferRef:process_pixelbuffer format:CNCENM_buf_format_I420 time_stamp:ts];
//                }
//            }
            [self.displayer processVideoImageBuffer:process_pixelbuffer];
            CVPixelBufferUnlockBaseAddress(process_pixelbuffer, 0);
            CVPixelBufferRelease(process_pixelbuffer);
        } else {
//            if (_ovelay_mask_index != 0) {
                CMTime time = kCMTimeInvalid;
                [self.capture_manager overlay_pixelbuffer:pixelBuffer time:time time_stamp:(int)ts];
//            } else {
//                if (self.is_pushing && self.videoEncoder) {
//                    [self.videoEncoder send_frame_pixelBufferRef:pixelBuffer format:CNCENM_buf_format_I420 time_stamp:ts];
//                }
//            }
            [self.displayer processVideoImageBuffer:pixelBuffer];
        }
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        CVPixelBufferRelease(pixelBuffer);
    }
    
}
- (void)mirror_capture_buf:(void*)buf pix_width:(int)pix_width pix_height:(int)pix_height format:(CNCENM_Buf_Format)format {
    
    switch (format) {
        case CNCENM_buf_format_I420:
//            YYYYYYYYUUVV
            break;
        case CNCENM_buf_format_NV12:
//            YYYYYYYYUVUV
            break;
        case CNCENM_buf_format_NV21:
//            YYYYYYYYVUVU
            break;
        case CNCENM_buf_format_BGRA:
            
//            RGBARGBARGBA
            break;
        default:
            break;
    }
}
- (CVPixelBufferRef)mirror_pixelbuffer_YUV:(CVPixelBufferRef)pix_src mirror:(BOOL)mirror {
    
    CVPixelBufferLockBaseAddress(pix_src, 0);
    
    size_t width = CVPixelBufferGetWidthOfPlane(pix_src, 0);
    size_t height = CVPixelBufferGetHeightOfPlane(pix_src, 0);
    
    size_t width_uv = CVPixelBufferGetWidthOfPlane(pix_src, 1);
    size_t height_uv = CVPixelBufferGetHeightOfPlane(pix_src, 1);
    
    size_t bytesrow0_src = CVPixelBufferGetBytesPerRowOfPlane(pix_src,0);
    size_t bytesrow1_src  = CVPixelBufferGetBytesPerRowOfPlane(pix_src,1);
    uint8_t* p_src_Y = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(pix_src, 0);
    uint8_t* p_src_UV = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(pix_src, 1);
    
    
    CVPixelBufferRef pixelBuffer = NULL;
    
    NSDictionary *pixelAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSDictionary dictionary], kCVPixelBufferIOSurfacePropertiesKey,
                                     nil];
    
    
    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                          width,
                                          height,                                                          kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                                          (__bridge CFDictionaryRef)(pixelAttributes),
                                          &pixelBuffer);
    
    if (result != kCVReturnSuccess) {
        CVPixelBufferUnlockBaseAddress(pix_src, 0);
        return NULL;
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    size_t bytesrow0_dst = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer,0);
    size_t bytesrow1_dst  = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer,1);
    
    uint8_t* p_dst_Y = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    uint8_t* p_dst_UV = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    
    uint8_t* p_dst = p_dst_Y;
    uint8_t* p_src = p_src_Y;
    
    if (mirror) {
        //镜像 最左与最右互换
        for (int i = 0; i < height; ++i) {
            uint8_t* p_dst_tmp = p_dst + width - 1;
            uint8_t* p_src_tmp = p_src;
            for (int j = 0; j < width; ++j) {
                *p_dst_tmp = *p_src_tmp;
                --p_dst_tmp;
                ++p_src_tmp;
            }
            p_dst += bytesrow0_dst;
            p_src += bytesrow0_src;
        }
        
    } else {
        for (int i = 0; i < height; ++i) {
            memcpy(p_dst, p_src, width);
            p_dst += bytesrow0_dst;
            p_src += bytesrow0_src;
        }
    }
    
    
    p_dst = p_dst_UV;
    p_src = p_src_UV;
    if (mirror) {
        //镜像 最左与最右互换
        for (int i = 0; i < height_uv; ++i) {
            uint8_t* p_dst_tmp = p_dst + (width_uv-1)*2;
            uint8_t* p_src_tmp = p_src;
            for (int j = 0; j < width_uv; ++j) {
                *p_dst_tmp = *p_src_tmp;//U
                
                ++p_dst_tmp;
                ++p_src_tmp;
                *p_dst_tmp = *p_src_tmp;//V
                
                p_dst_tmp = p_dst_tmp-3;
                ++p_src_tmp;
            }
            p_dst += bytesrow1_dst;
            p_src += bytesrow1_src;
        }
        
    } else {
        for (int i = 0; i < height_uv; ++i) {
            memcpy(p_dst, p_src, width);
            p_dst += bytesrow1_dst;
            p_src += bytesrow1_src;
        }
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CVPixelBufferUnlockBaseAddress(pix_src, 0);
    
    return pixelBuffer;
}

- (CVImageBufferRef)mirror_pixelbuffer_BGRA:(CVImageBufferRef)imageBuffer {
    
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    size_t src_width = CVPixelBufferGetWidth(imageBuffer);
    size_t src_height = CVPixelBufferGetHeight(imageBuffer);
    
    void *src_buff = CVPixelBufferGetBaseAddress(imageBuffer);
    
//    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,[NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,nil];
    NSDictionary *options  = [NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionary], kCVPixelBufferIOSurfacePropertiesKey,nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    
    OSType pixelFormatType = CVPixelBufferGetPixelFormatType(imageBuffer);
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, src_width, src_height,
                                          pixelFormatType, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *dest_buff = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(dest_buff != NULL);
    
    UInt32 *src = (UInt32*) src_buff ;
    UInt32 *dest = (UInt32*) dest_buff ;
    size_t dest_bytePerRow = CVPixelBufferGetBytesPerRow(pxbuffer);
    size_t dest_real_width = dest_bytePerRow/4;
    memset(dest_buff, 0x0, dest_bytePerRow*src_height);

    for (NSInteger i = 0; i < src_height; ++i) {
        NSInteger start_dst = (i + 1) * dest_real_width - 1;
        NSInteger start_src = i * src_width;
        for (NSInteger ii = 0; ii < src_width; ++ii) {
             dest[start_dst - ii] = src[start_src + ii];
        }
    }
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    return pxbuffer;
}
- (CVPixelBufferRef)copyDataFromBuffer:(void *)buffer toYUVPixelBufferWithWidth:(size_t)w Height:(size_t)h
{
    //生成i420
    CVPixelBufferRef pixelBuffer = NULL;
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSDictionary dictionary], kCVPixelBufferIOSurfacePropertiesKey,
                                nil];
    CVPixelBufferCreate(NULL, w, h, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, (__bridge CFDictionaryRef)(dictionary), &pixelBuffer);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    size_t bytesrow0 = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer,0);
    size_t bytesrow1 = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer,1);
    
    if (bytesrow0 != w || bytesrow1 != w) {
        
        unsigned char* dstY  = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        unsigned char* dstUV = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
        
        UInt8 *src = (UInt8 *)buffer;
        
        for (unsigned int y = 0; y < h; ++y, dstY += bytesrow0, src += w) {
            memcpy(dstY, src, w);
        }
        
        size_t srcPlaneSize = w*h/4;
        size_t dstPlaneSize = bytesrow1*h/2;
        
        UInt8 *pY = (UInt8 *)buffer;
        UInt8 *pU = pY + w*h;
        UInt8 *pV = pU + w*h/4;
        
        uint8_t *dstPlane = (uint8_t *)malloc(dstPlaneSize);
        
        unsigned long k = 0, j = 0;
        
        for(int i = 0; i<srcPlaneSize; i++){
            // These might be the wrong way round.
            if ((2*i)%w == 0 && i!=0) {
                k++;
            }
            
            j = 2*i + k*(bytesrow1 - w);
            
            dstPlane[j  ] = pU[i];
            dstPlane[j+1] = pV[i];
        }
        
        memcpy(dstUV, dstPlane, dstPlaneSize);
        
        free(dstPlane);
        
    } else {
        UInt8 *pY = (UInt8 *)buffer;
        UInt8 *pU = pY + w*h;
        UInt8 *pV = pU + w*h/4;
        
        size_t srcPlaneSize = w*h/4;
        size_t dstPlaneSize = srcPlaneSize * 2;
        
        uint8_t *dstPlane = (uint8_t *)malloc(dstPlaneSize);
        
        for(size_t i = 0; i<srcPlaneSize; i++){
            // These might be the wrong way round.
            dstPlane[2*i  ] = pU[i];
            dstPlane[2*i+1] = pV[i];
        }
        
        uint8_t* addressY  = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        uint8_t* addressUV = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
        
        memcpy(addressY, buffer, w * h);
        memcpy(addressUV, dstPlane, dstPlaneSize);
        
        free(dstPlane);
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return pixelBuffer;
}

- (void)capture_sample_bufferRef_data:(CMSampleBufferRef)sample_buf time_stamp:(unsigned int)time_stamp{
        
    //    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sample_buf);
    //    [self.displayer processVideoImageBuffer:pixelBuffer];
    //    [self.displayer processVideoSampleBuffer:sample_buf];
}

- (void)capture_pixel_bufferRef_data:(CVPixelBufferRef)pixelBuffer time_stamp:(unsigned int)time_stamp {
    
}
- (void)frame_RGBA:(CVImageBufferRef)imageBuffer time_stamp:(long)time_stamp {
    
    uint8_t *p_src_buf = (uint8_t*)CVPixelBufferGetBaseAddress(imageBuffer);
    
    size_t byte_per_row = CVPixelBufferGetBytesPerRow(imageBuffer);
    //    NSLog(@"byte_per_row ： %zu",byte_per_row);
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
        
        if (self.is_pushing) {
            if (self.videoEncoder) {
                if ([self.record_manager is_doing_store] && store_type == CNCRecordVideoType_GIF){
                    [self.record_manager store_gif_record:dst_buf pix_width:int(real_width) pix_height:int(height) format:CNCENM_buf_format_BGRA time_stamp:time_stamp];
                }
                [self.videoEncoder inputFrameBuffer:dst_buf pix_width:int(real_width) pix_height:int(height) format:CNCENM_buf_format_BGRA time_stamp:(unsigned int)time_stamp];
            }
        }
    } while (0);
    
    if (dst_buf != NULL) {
        delete []dst_buf;
    }
    
}
- (void)update_statictics_beauty_after {
    
    static unsigned long long  last_log_time = 0;
    static unsigned long long  log_send_all_cnt = 0;
    static unsigned long long  log_per_send_cnt = 0;
    //    frame_after = (int)log_per_send_cnt;
    ++log_send_all_cnt;
    ++log_per_send_cnt;
    
    unsigned long long pts = mGetTickCountFU();
    
    long t_off_log = (long)(pts - last_log_time);
    
    if(labs(t_off_log) > 1000) {
        
        real_fps = (int)log_per_send_cnt;
        
        last_log_time = pts;
        log_per_send_cnt = 0;
    }
    
}

@end
