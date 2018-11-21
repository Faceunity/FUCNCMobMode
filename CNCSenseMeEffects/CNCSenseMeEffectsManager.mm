//
//  ViewController.m
//
//  Created by HaifengMay on 16/11/7.
//  Copyright © 2016年 SenseTime. All rights reserved.
//

#import "CNCSenseMeEffectsManager.h"
#import "CNCGLPreview.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <CommonCrypto/CommonDigest.h>
#import <OpenGLES/ES2/glext.h>
#import "STMobileLog.h"

#import "STTriggerView.h"
#import "STScrollTitleView.h"
#import "STCommonObjectContainerView.h"
#import "STCollectionView.h"
#import "STParamUtil.h"


#import "STSliderView.h"



//#import "STEffectsTimer.h"

#import "STFilterView.h"
#import "STButton.h"
#import <sys/utsname.h>

//ST_MOBILE
#import "st_mobile_sticker.h"
#import "st_mobile_beautify.h"
#import "st_mobile_license.h"
#import "st_mobile_face_attribute.h"
#import "st_mobile_filter.h"
#import "st_mobile_object.h"

// 两种 check license 的方式 , 一种是根据 license 文件的路径 , 另一种是 license 文件的缓存选择应用场景合适的即可
#define CHECK_LICENSE_WITH_PATH 1


#define SLIDER_HEIGHT (CGRectGetHeight(_level2Beautify.frame) - CGRectGetHeight(_btnCloseBeautify.frame)) / 6.0

#define DRAW_FACE_KEY_POINTS 0
#define ENABLE_DYNAMIC_ADD_AND_REMOVE_MODELS 0

#define USE_GLKVIEW 0

typedef NS_ENUM(NSInteger, STViewTag) {
    
    STViewTagSpecialEffectsBtn = 1,
    STViewTagBeautyBtn,
    
    STViewTagBeautyShapeView,
    STViewTagBeautyBaseView,
    
    STViewTagShrinkFaceSlider,
    STViewTagEnlargeEyeSlider,
    STViewTagShrinkJawSlider,
    STViewTagSmoothSlider,
    STViewTagReddenSlider,
    STViewTagWhitenSlider
};

typedef NS_ENUM(NSInteger, STWriterRecordingStatus){
    STWriterRecordingStatusIdle = 0,
    STWriterRecordingStatusStartingRecording,
    STWriterRecordingStatusRecording,
    STWriterRecordingStatusStoppingRecording
};

//@protocol STEffectsMessageDelegate <NSObject>
//
//- (void)loadSound:(NSData *)soundData name:(NSString *)strName;
//- (void)playSound:(NSString *)strName loop:(int)iLoop;
//- (void)stopSound:(NSString *)strName;
//
//@end


@interface STEffectsMessageManager : NSObject

//@property (nonatomic, readwrite, weak) id<STEffectsMessageDelegate> delegate;
@end

@implementation STEffectsMessageManager

@end

//STEffectsMessageManager *messageManager = nil;


@interface CNCSenseMeEffectsManager () < STCommonObjectContainerViewDelegate, STViewButtonDelegate>
{
    st_handle_t _hSticker;  // sticker句柄
    st_handle_t _hDetector; // detector句柄
    st_handle_t _hBeautify; // beautify句柄
    st_handle_t _hAttribute;// attribute句柄
    st_handle_t _hFilter;   // filter句柄
    st_handle_t _hTracker;  // 通用物体跟踪句柄
    
    st_rect_t _rect;  // 通用物体位置
    float _result_score; //通用物体置信度
    
    st_mobile_106_t *_pFacesDetection; // 检测输出人脸信息数组
    st_mobile_106_t *_pFacesBeautify;  // 美颜输出人脸信息数组
    
    CVOpenGLESTextureCacheRef _cvTextureCache;
    
    CVOpenGLESTextureRef _cvTextureOrigin;
    CVOpenGLESTextureRef _cvTextureBeautify;
    CVOpenGLESTextureRef _cvTextureSticker;
    CVOpenGLESTextureRef _cvTextureFilter;
    
    CVPixelBufferRef _cvBeautifyBuffer;
    CVPixelBufferRef _cvStickerBuffer;
    CVPixelBufferRef _cvFilterBuffer;
    
    GLuint _textureOriginInput;
    GLuint _textureBeautifyOutput;
    GLuint _textureStickerOutput;
    GLuint _textureFilterOutput;
    
    int capture_width;
    int capture_height;
    CGFloat screen_width;
    CGFloat screen_height;
    CGFloat container_view_width;
    CGFloat container_view_height;
    CGFloat container_view_space_height;
}

//bottom tab bar
@property (nonatomic, strong) STViewButton *specialEffectsBtn;
@property (nonatomic, strong) STViewButton *beautyBtn;

//resolution change btn
//@property (nonatomic, readwrite, strong) UIButton *btn640x480;
//@property (nonatomic, readwrite, strong) UIButton *btn1280x720;
//@property (nonatomic, readwrite, strong) CAShapeLayer *btn640x480BorderLayer;
//@property (nonatomic, readwrite, strong) CAShapeLayer *btn1280x720BorderLayer;


@property (nonatomic, strong) UIButton *btnCompare;
//@property (nonatomic, readwrite, strong) UIButton *btnSetting;
//@property (nonatomic, readwrite, strong) STButton *btnAlbum;

@property (nonatomic, strong) UIView *gradientView;
@property (nonatomic, strong) UIView *specialEffectsContainerView;
@property (nonatomic, strong) UIView *beautyContainerView;
@property (nonatomic, strong) UIView *filterCategoryView;
@property (nonatomic, strong) UIView *filterSwitchView;
@property (nonatomic, strong) STFilterView *filterView;

@property (nonatomic, strong) UIView *beautyShapeView;
@property (nonatomic, strong) UIView *beautyBaseView;

//@property (nonatomic, readwrite, strong) UIView *settingView;

@property (nonatomic, strong) UIImageView *recordImageView;
@property (nonatomic, strong) UIView *filterStrengthView;

@property (nonatomic, strong) STScrollTitleView *scrollTitleView;
@property (nonatomic, strong) STScrollTitleView *beautyScrollTitleView;

@property (nonatomic, strong) STCollectionView *collectionView;
@property (nonatomic, strong) STCollectionView *objectTrackCollectionView;
@property (nonatomic, strong) STFilterCollectionView *filterCollectionView;

@property (nonatomic, strong) STTriggerView *triggerView;

@property (nonatomic, copy) NSString *strStickerPath;

@property (nonatomic, strong) NSMutableArray *arrBeautyViews;
@property (nonatomic, strong) NSMutableArray<STViewButton *> *arrFilterCategoryViews;

@property (nonatomic, assign) BOOL specialEffectsContainerViewIsShow;
@property (nonatomic, assign) BOOL beautyContainerViewIsShow;
@property (nonatomic, assign) BOOL settingViewIsShow;

@property (nonatomic, assign) unsigned long long iCurrentAction;

@property (nonatomic, assign) BOOL needSnap;
@property (nonatomic, assign) BOOL pauseOutput;
@property (nonatomic, assign) BOOL isAppActive;

@property (nonatomic, assign) CGFloat imageWidth;
@property (nonatomic, assign) CGFloat imageHeight;

//bottom tab bar status
@property (nonatomic, assign) BOOL bAttribute;
@property (nonatomic, assign) BOOL bBeauty;
@property (nonatomic, assign) BOOL bSticker;
@property (nonatomic, assign) BOOL bTracker;
@property (nonatomic, assign) BOOL bFilter;

@property (nonatomic, assign) BOOL isComparing;

//beauty value
@property (nonatomic, assign) float fSmoothStrength;
@property (nonatomic, assign) float fReddenStrength;
@property (nonatomic, assign) float fWhitenStrength;
@property (nonatomic, assign) float fEnlargeEyeStrength;
@property (nonatomic, assign) float fShrinkFaceStrength;
@property (nonatomic, assign) float fShrinkJawStrength;
//filter value
@property (nonatomic, assign) float fFilterStrength;

//@property (nonatomic, strong) UILabel *lblAttribute;
//@property (nonatomic, strong) UILabel *lblSpeed;
//@property (nonatomic, strong) UILabel *lblCPU;
@property (nonatomic, strong) UILabel *lblSaveStatus;
@property (nonatomic, strong) UILabel *lblFilterStrength;

//@property (nonatomic, strong) UILabel *resolutionLabel;
//@property (nonatomic, readwrite, strong) UILabel *attributeLabel;

//@property (nonatomic, readwrite, strong) UISwitch *attributeSwitch;

//@property (nonatomic, strong) STCamera *stCamera;
@property (nonatomic, retain) CNCGLPreview *glPreview;
//@property (nonatomic, strong) STAudioManager *audioManager;
@property (nonatomic, strong) STCommonObjectContainerView *commonObjectContainerView;

@property (nonatomic, retain) EAGLContext *glContext;
@property (nonatomic, retain) CIContext *ciContext;

@property (nonatomic, strong) NSMutableArray *normalImages;
@property (nonatomic, strong) NSMutableArray *selectedImages;

@property (nonatomic, assign) CGFloat scale;  //视频充满全屏的缩放比例
@property (nonatomic, assign) int margin;
@property (nonatomic, assign, getter=isCommonObjectViewAdded) BOOL commonObjectViewAdded;
@property (nonatomic, assign, getter=isCommonObjectViewSetted) BOOL commonObjectViewSetted;

@property (nonatomic, strong) NSMutableArray *arrPersons;
@property (nonatomic, strong) NSMutableArray *arrPoints;

@property (nonatomic, assign) double lastTimeAttrDetected;

@property (nonatomic, strong) NSArray *arr2DStickers;
@property (nonatomic, strong) NSArray *arr3DStickers;
@property (nonatomic, strong) NSArray *arrGestureStickers;
@property (nonatomic, strong) NSArray *arrSegmentStickers;
@property (nonatomic, strong) NSArray *arrFacedeformationStickers;
@property (nonatomic, strong) NSArray *arrObjectTrackers;

//record
//@property (nonatomic, readwrite, strong) STMovieRecorder *stRecoder;
@property (nonatomic, strong) dispatch_queue_t callBackQueue;
@property (nonatomic, assign, getter=isRecording) BOOL recording;
@property (nonatomic, assign) STWriterRecordingStatus recordStatus;

//@property (nonatomic, assign) CMFormatDescriptionRef outputVideoFormatDescription;
//@property (nonatomic, assign) CMFormatDescriptionRef outputAudioFormatDescription;
@property (nonatomic, assign) double recordStartTime;

//@property (nonatomic, readwrite, strong) STEffectsAudioPlayer *audioPlayer;

@property (nonatomic, strong) NSString *currentSessionPreset;

@property (nonatomic, strong) STSliderView *thinFaceView;
@property (nonatomic, strong) STSliderView *enlargeEyesView;
@property (nonatomic, strong) STSliderView *smallFaceView;
@property (nonatomic, strong) STSliderView *dermabrasionView;
@property (nonatomic, strong) STSliderView *ruddyView;
@property (nonatomic, strong) STSliderView *whitenView;

//@property (nonatomic, readwrite, strong) UILabel *recordTimeLabel;

//@property (nonatomic, readwrite, strong) STEffectsTimer *timer;

@property (nonatomic, strong) UIImageView *noneStickerImageView;

@property (nonatomic, assign) BOOL isNullSticker;
@property (nonatomic, assign) BOOL filterStrengthViewHiddenState;

@property (nonatomic, strong) UISlider *filterStrengthSlider;
@property (nonatomic, strong) STCollectionViewDisplayModel *currentSelectedFilterModel;

@property (nonatomic, retain) NSMutableArray *faceArray;

@property (nonatomic,  strong) dispatch_queue_t changeModelQueue;
@property (nonatomic,  strong) dispatch_queue_t changeStickerQueue;

@property (nonatomic, copy) NSString *preFilterModelPath;
@property (nonatomic, copy) NSString *curFilterModelPath;

//@property (nonatomic, copy) NSString *strBodyAction;
//@property (nonatomic, strong) UILabel *lblBodyAction;
@property (nonatomic, retain) UIView *preview;
@end

@implementation CNCSenseMeEffectsManager
#pragma mark - dealloc
- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.strStickerPath = nil;
    self.glContext = nil;
    self.ciContext = nil;

    self.specialEffectsBtn = nil;
    self.beautyBtn = nil;
    self.btnCompare = nil;
    self.gradientView = nil;
    self.specialEffectsContainerView = nil;
    self.beautyContainerView = nil;
    self.filterCategoryView = nil;
    self.filterSwitchView = nil;
    self.filterView = nil;
    
    self.beautyShapeView = nil;
    self.beautyBaseView = nil;
    self.recordImageView = nil;
    self.filterStrengthView = nil;
    
    self.scrollTitleView = nil;
    self.beautyScrollTitleView = nil;
    
    self.collectionView = nil;
    self.objectTrackCollectionView = nil;
    self.filterCollectionView = nil;
    self.triggerView = nil;
//    self.arrBeautyViews = nil;
//    self.arrFilterCategoryViews = nil;
//    self.lblAttribute = nil;
    self.lblSaveStatus = nil;
    self.lblFilterStrength = nil;
    
//    self.resolutionLabel = nil;
    self.glPreview = nil;
    self.commonObjectContainerView = nil;
    
    self.normalImages = nil;
    self.selectedImages = nil;
    self.arrPersons = nil;
    self.arrPoints = nil;
    self.arr2DStickers = nil;
    self.arr3DStickers = nil;
    self.arrGestureStickers = nil;
    self.arrSegmentStickers = nil;
    self.arrFacedeformationStickers = nil;
    self.arrObjectTrackers = nil;
    
    if (_callBackQueue != NULL) {
        dispatch_release(_callBackQueue);
        _callBackQueue = NULL;
    }
    
//    self.outputAudioFormatDescription = nil;
//    self.outputVideoFormatDescription = nil;
    
    self.currentSessionPreset = nil;
    self.thinFaceView = nil;
    self.enlargeEyesView = nil;
    self.smallFaceView = nil;
    self.dermabrasionView = nil;
    self.ruddyView = nil;
    self.whitenView = nil;
    
    self.noneStickerImageView = nil;
    self.filterStrengthSlider = nil;
    self.currentSelectedFilterModel = nil;
    
    if (_changeModelQueue != NULL) {
        dispatch_release(_changeModelQueue);
        _changeModelQueue = NULL;
    }
    if (_changeStickerQueue != NULL) {
        dispatch_release(_changeStickerQueue);
        _changeStickerQueue = NULL;
    }
    
    self.preFilterModelPath = nil;
    self.curFilterModelPath = nil;
//    self.preview = nil;
    self.arrBeautyViews = nil;
    self.arrFilterCategoryViews = nil;
    self.faceArray = nil;
    self.preview = nil;
    [super dealloc];
}
#pragma mark - life cycle
- (instancetype)initWith:(UIView *)preview direct:(CNCENMDirectType)direct width:(int)w height:(int)h{
    self = [super init];
    if (self) {
        
        self.preview = preview;
        self.video_direct_type = direct;
        capture_width = w;
        capture_height = h;
        [self load_para];
    }
    return self;
}
- (void)load_para {
    
    [self setDefaultValue];
    
    [self addSubviews];
    [self init_resource];
}

- (void)init_resource {
//    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    self.audioManager = [[STAudioManager alloc] init];
//    self.audioManager.delegate = self;
//
//    self.audioPlayer = [[STEffectsAudioPlayer alloc] init];
//    self.audioPlayer.delegate = self;
    
//    messageManager = [[STEffectsMessageManager alloc] init];
//    messageManager.delegate = self;
    
//    self.timer = [[STEffectsTimer alloc] init];
//    self.timer.delegate = self;
    
//    ALAssetsLibrary *photoLibrary = [[ALAssetsLibrary alloc] init];
//    [photoLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:nil failureBlock:nil];
//    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {}];
//
//    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"FIRSTLAUNCH"]) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"点击屏幕底部圆形按钮可拍照，长按可录制视频" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
//        [alert show];
//        [[NSUserDefaults standardUserDefaults] setObject:@(1) forKey:@"FIRSTLAUNCH"];
//    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAudioInterruption:) name:AVAudioSessionInterruptionNotification object:nil];
    
    [self initResource];
}

- (void)handleAudioInterruption:(NSNotification *)notification {
        
    NSLog(@"audio session interruption.");
}

- (void)releaseResources
{
    [EAGLContext setCurrentContext:self.glContext];
    
    if (_hSticker) {
        
        st_mobile_sticker_destroy(_hSticker);
        _hSticker = NULL;
    }
    if (_hBeautify) {
        
        st_mobile_beautify_destroy(_hBeautify);
        _hBeautify = NULL;
    }
    
    if (_hDetector) {
        
        st_mobile_human_action_destroy(_hDetector);
        _hDetector = NULL;
    }
    
    if (_hAttribute) {
        
        st_mobile_face_attribute_destroy(_hAttribute);
        _hAttribute = NULL;
    }
    
    if (_pFacesDetection) {
        
        free(_pFacesDetection);
        _pFacesDetection = NULL;
    }
    
    if (_pFacesBeautify) {
        
        free(_pFacesBeautify);
        _pFacesBeautify = NULL;
    }
    
    if (_hFilter) {
        
        st_mobile_gl_filter_destroy(_hFilter);
        _hFilter = NULL;
    }
    
    if (_hTracker) {
        st_mobile_object_tracker_destroy(_hTracker);
        _hTracker = NULL;
    }
    
    [self releaseResultTexture];
    
    if (_cvTextureCache) {
        
        CFRelease(_cvTextureCache);
        _cvTextureCache = NULL;
    }
    
    glFinish();
    
    [EAGLContext setCurrentContext:nil];
    
    self.glContext = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.glPreview removeFromSuperview];
        self.glPreview = nil;
        
        [self.commonObjectContainerView removeFromSuperview];
        self.commonObjectContainerView.delegate = nil;
        self.commonObjectContainerView = nil;
        
        self.ciContext = nil;
    });
//    messageManager.delegate = nil;
//    messageManager = nil;
//    self.timer.delegate = nil;
}


- (void)initResource
{
    ///ST_MOBILE：设置预览时需要注意 EAGLContext 的初始化
    [self setup_GLPreview];
    
    // 设置SDK OpenGL 环境 , 只有在正确的 OpenGL 环境下 SDK 才会被正确初始化 .
    self.ciContext = [CIContext contextWithEAGLContext:self.glContext
                                               options:@{kCIContextWorkingColorSpace : [NSNull null]}];
    
    [EAGLContext setCurrentContext:self.glContext];
    
    // 初始化结果文理及纹理缓存
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.glContext, NULL, &_cvTextureCache);
    
    if (err) {
        
        NSLog(@"CVOpenGLESTextureCacheCreate %d" , err);
    }
    
    [self initResultTexture];
    
    [self resetSettings];
    
    ///ST_MOBILE：初始化句柄之前需要验证License
    if ([self checkActiveCode]) {
        ///ST_MOBILE：初始化相关的句柄
        [self setupHandle];
    }
    
    self.pauseOutput = NO;
    //TODO
}



#pragma mark - setup subviews

- (void)addSubviews {
    
    [self.preview addSubview:self.lblSaveStatus];
    [self.preview addSubview:self.triggerView];
    [self.preview addSubview:self.specialEffectsContainerView];
    [self.preview addSubview:self.beautyContainerView];
    [self.preview addSubview:self.filterStrengthView];
    [self.preview addSubview:self.specialEffectsBtn];
    [self.preview addSubview:self.beautyBtn];
    [self.preview addSubview:self.btnCompare];

    //test add and remove submodels
#if ENABLE_DYNAMIC_ADD_AND_REMOVE_MODELS
    [self addTestBtns];
#endif
}
- (BOOL)resetSubviews:(CGSize)new_size {
    BOOL is_change_little = NO;
    if (new_size.width != screen_width || new_size.height != screen_height) {
        self.lblSaveStatus.hidden = YES;
        self.triggerView.hidden = YES;
        self.specialEffectsContainerView.hidden = YES;
        self.beautyContainerView.hidden = YES;
        self.filterStrengthView.hidden = YES;
        self.specialEffectsBtn.hidden = YES;
        self.beautyBtn.hidden = YES;
        self.btnCompare.hidden = YES;
        is_change_little = YES;
        self.specialEffectsContainerViewIsShow = NO;
        self.beautyContainerViewIsShow = NO;
        if (self.delegate && [self.delegate respondsToSelector:@selector(do_sense_set_ges:)]) {
            [self.delegate do_sense_set_ges:YES];
        }
    } else {
        self.lblSaveStatus.hidden = NO;
        self.triggerView.hidden = NO;
        self.specialEffectsContainerView.hidden = NO;
        self.beautyContainerView.hidden = NO;
        self.specialEffectsBtn.hidden = NO;
        self.beautyBtn.hidden = NO;
        self.btnCompare.hidden = NO;
    }
    
    CGFloat buttonWidth = 50;
    CGFloat backViewHeight = buttonWidth*4;

    self.lblSaveStatus.frame = CGRectMake((new_size.width - 266) / 2, -44, 266, 44) ;
    self.specialEffectsContainerView.frame= CGRectMake((new_size.width-container_view_width)/2, new_size.height + container_view_space_height, container_view_width,(190 + container_view_height));
    self.beautyContainerView.frame = CGRectMake((new_size.width-container_view_width)/2, (new_size.height + container_view_space_height), container_view_width,(190 + container_view_height));
    self.filterStrengthView.frame = CGRectMake((new_size.width-container_view_width)/2, new_size.height - 230 - 35.5, container_view_width-50, 35.5);
    self.specialEffectsBtn.frame  = CGRectMake(new_size.width - buttonWidth, (new_size.height - backViewHeight)/2+55*2, buttonWidth, buttonWidth);
    self.beautyBtn.frame = CGRectMake(new_size.width - buttonWidth, (new_size.height - backViewHeight)/2+55*3, buttonWidth, buttonWidth);
    self.btnCompare.frame = CGRectMake(new_size.width - buttonWidth, (new_size.height - backViewHeight)/2+55*1, 50, 50);
    return is_change_little;
}
- (void)addTestBtns {

    UIButton *btnAddBodyModel = [[UIButton alloc] initWithFrame:CGRectMake(screen_width - 100, 100, 100, 30)];
    btnAddBodyModel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
    btnAddBodyModel.layer.cornerRadius = 15;
    [btnAddBodyModel setTitle:@"add body" forState:UIControlStateNormal];
    [btnAddBodyModel setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnAddBodyModel addTarget:self action:@selector(addBodyModel) forControlEvents:UIControlEventTouchUpInside];
    [self.preview addSubview:btnAddBodyModel];

    UIButton *btnDelBodyModel = [[UIButton alloc] initWithFrame:CGRectMake(screen_width - 100, 140, 100, 30)];
    btnDelBodyModel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
    btnDelBodyModel.layer.cornerRadius = 15;
    [btnDelBodyModel setTitle:@"del body" forState:UIControlStateNormal];
    [btnDelBodyModel setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnDelBodyModel addTarget:self action:@selector(deleteBodyModel) forControlEvents:UIControlEventTouchUpInside];
    [self.preview addSubview:btnDelBodyModel];

    UIButton *btnAddEyeIrisModel = [[UIButton alloc] initWithFrame:CGRectMake(screen_width - 100,190, 100, 30)];
    btnAddEyeIrisModel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
    btnAddEyeIrisModel.layer.cornerRadius = 15;
    [btnAddEyeIrisModel setTitle:@"add iris" forState:UIControlStateNormal];
    [btnAddEyeIrisModel setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnAddEyeIrisModel addTarget:self action:@selector(addEyeIrisModel) forControlEvents:UIControlEventTouchUpInside];
    [self.preview addSubview:btnAddEyeIrisModel];

    UIButton *btnDelEyeIrisModel = [[UIButton alloc] initWithFrame:CGRectMake(screen_width - 100, 220, 100, 30)];
    btnDelEyeIrisModel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
    btnDelEyeIrisModel.layer.cornerRadius = 15;
    [btnDelEyeIrisModel setTitle:@"del iris" forState:UIControlStateNormal];
    [btnDelEyeIrisModel setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnDelEyeIrisModel addTarget:self action:@selector(deleteEyeIrisModel) forControlEvents:UIControlEventTouchUpInside];
    [self.preview addSubview:btnDelEyeIrisModel];

    UIButton *btnAddFaceExtraModel = [[UIButton alloc] initWithFrame:CGRectMake(screen_width - 100, 260, 100, 30)];
    btnAddFaceExtraModel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
    btnAddFaceExtraModel.layer.cornerRadius = 15;
    [btnAddFaceExtraModel setTitle:@"add extra" forState:UIControlStateNormal];
    [btnAddFaceExtraModel setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnAddFaceExtraModel addTarget:self action:@selector(addFaceExtraModel) forControlEvents:UIControlEventTouchUpInside];
    [self.preview addSubview:btnAddFaceExtraModel];

    UIButton *btnDelFaceExtraModel = [[UIButton alloc] initWithFrame:CGRectMake(screen_width - 100, 300, 100, 30)];
    btnDelFaceExtraModel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
    btnDelFaceExtraModel.layer.cornerRadius = 15;
    [btnDelFaceExtraModel setTitle:@"del extra" forState:UIControlStateNormal];
    [btnDelFaceExtraModel setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnDelFaceExtraModel addTarget:self action:@selector(deleteFaceExtraModel) forControlEvents:UIControlEventTouchUpInside];
    [self.preview addSubview:btnDelFaceExtraModel];

    UIButton *btnAddHandModel = [[UIButton alloc] initWithFrame:CGRectMake(screen_width - 100, 340, 100, 30)];
    btnAddHandModel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
    btnAddHandModel.layer.cornerRadius = 15;
    [btnAddHandModel setTitle:@"add hand" forState:UIControlStateNormal];
    [btnAddHandModel setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnAddHandModel addTarget:self action:@selector(addHandModel) forControlEvents:UIControlEventTouchUpInside];
    [self.preview addSubview:btnAddHandModel];

    UIButton *btnDelHandModel = [[UIButton alloc] initWithFrame:CGRectMake(screen_width - 100, 380, 100, 30)];
    btnDelHandModel.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
    btnDelHandModel.layer.cornerRadius = 15;
    [btnDelHandModel setTitle:@"del hand" forState:UIControlStateNormal];
    [btnDelHandModel setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnDelHandModel addTarget:self action:@selector(delHandModel) forControlEvents:UIControlEventTouchUpInside];
    [self.preview addSubview:btnDelHandModel];
}

- (void)setDefaultValue {
//    screen_width = [UIScreen mainScreen].bounds.size.height;
//    screen_height = [UIScreen mainScreen].bounds.size.width;
    screen_width = CGRectGetWidth(self.preview.frame);
    screen_height = CGRectGetHeight(self.preview.frame);

    
    container_view_width = screen_width;
    NSString * deviceString = [self getMobilePhoneModel];
    container_view_height = 0;
    container_view_space_height = 0;
    if ([deviceString isEqualToString:@"iPhone X"]) {
        container_view_height = 34;
        if (self.video_direct_type == CNC_ENM_Direct_Vertical) {
            if (screen_height < [UIScreen mainScreen].bounds.size.height) {
                container_view_space_height = ([UIScreen mainScreen].bounds.size.height - screen_height)/2;
            }
        }
        
    }
    if (self.video_direct_type == CNC_ENM_Direct_Horizontal) {
//        screen_width = [UIScreen mainScreen].bounds.size.height;
//        screen_height = [UIScreen mainScreen].bounds.size.width;
        container_view_width = [UIScreen mainScreen].bounds.size.width*4/3;
    }
    
    self.bAttribute = NO;
    self.bBeauty = YES;
    self.bFilter = NO;
    self.bSticker = NO;
    self.bTracker = NO;
    
    self.isNullSticker = NO;
    
    self.fFilterStrength = 1.0;
    
    self.iCurrentAction = 0;
    
    self.needSnap = NO;
    self.pauseOutput = NO;
    self.isAppActive = YES;
    
    self.imageWidth = 720;
    self.imageHeight = 1280;
    self.currentSessionPreset = AVCaptureSessionPreset1280x720;
    
    self.recordStatus = STWriterRecordingStatusIdle;
    self.recording = NO;
    
    
//    self.outputAudioFormatDescription = nil;
//    self.outputVideoFormatDescription = nil;
    
    _changeModelQueue = dispatch_queue_create("com.sensetime.changemodelqueue", NULL);
    _changeStickerQueue = dispatch_queue_create("com.sensetime.changestickerqueue", NULL);
    self.filterStrengthViewHiddenState = YES;
    
    self.preFilterModelPath = nil;
    self.curFilterModelPath = nil;
}

- (void)setup_GLPreview {
    _result_score = 0.0;
    
    int x=0,y=0,gl_width=0,gl_height =0;
    if(self.video_direct_type == CNC_ENM_Direct_Horizontal){
        gl_height = CGRectGetHeight(self.preview.frame);
        gl_width = gl_height * capture_width/capture_height;
    } else{
        gl_width = CGRectGetWidth(self.preview.frame);
        gl_height = gl_width * capture_height/capture_width;
    }
    
    x = (CGRectGetWidth(self.preview.frame)-gl_width)/2;
    y = (CGRectGetHeight(self.preview.frame)-gl_height)/2;
    CGRect render_view_rect = CGRectMake(x, y, gl_width,gl_height);
    
    self.glContext = [[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2] autorelease];
    
    
    self.glPreview = [[[CNCGLPreview alloc] initWithFrame:render_view_rect context:self.glContext] autorelease];
    [self.preview insertSubview:self.glPreview atIndex:0];
    
    self.commonObjectContainerView = [[[STCommonObjectContainerView alloc] initWithFrame:CGRectMake(0, 0, screen_width, screen_height)] autorelease];
    self.commonObjectContainerView.delegate = self;
    [self.preview insertSubview:self.commonObjectContainerView atIndex:1];
}
- (void)reset_glPreview:(CGSize)new_size {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        int x=0,y=0,gl_width=0,gl_height =0;
        if(self.video_direct_type == CNC_ENM_Direct_Horizontal){
            gl_height = new_size.height;
            gl_width = gl_height * capture_width/capture_height;
        } else{
            gl_width = new_size.width;
            gl_height = gl_width * capture_height/capture_width;
        }
        
        x = (new_size.width-gl_width)/2;
        y = (new_size.height-gl_height)/2;
        CGRect render_view_rect = CGRectMake(x, y, gl_width,gl_height);
//        self.specialEffectsBtn
        
        [self.glPreview removeFromSuperview];
        
        self.glPreview.frame = render_view_rect;
        [self.preview insertSubview:self.glPreview atIndex:0];
        [self resetSubviews:new_size];
    });
}

#pragma mark - setup handle

- (void)setupHandle {
    
    st_result_t iRet = ST_OK;
    
    [EAGLContext setCurrentContext:self.glContext];
    
    
    //初始化检测模块句柄
    NSString *strModelPath = [[NSBundle mainBundle] pathForResource:@"M_SenseME_Action_5.2.0" ofType:@"model"];
    
    uint32_t config = ST_MOBILE_HUMAN_ACTION_DEFAULT_CONFIG_VIDEO;
    
//    TIMELOG(key);
    
    iRet = st_mobile_human_action_create(strModelPath.UTF8String,
                                         config,
                                         &_hDetector);
    
//    TIMEPRINT(key,"human action create time:");
    
    if (ST_OK != iRet || !_hDetector) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示" message:@"算法SDK初始化失败，可能是模型路径错误，SDK权限过期，与绑定包名不符" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        
        [alert show];
    }
    
//    NSString *strEyeCenter = [[NSBundle mainBundle] pathForResource:@"M_Eyeball_Center" ofType:@"model"];
//    NSString *strEyeContour = [[NSBundle mainBundle] pathForResource:@"M_Eyeball_Contour" ofType:@"model"];
//
//    iRet = st_mobile_human_action_add_sub_model(_hDetector, strEyeCenter.UTF8String);
//
//    if (iRet != ST_OK) {
//        NSLog(@"st mobile human action add eye center model failed: %d", iRet);
//    }
//
//    iRet = st_mobile_human_action_add_sub_model(_hDetector, strEyeContour.UTF8String);
//
//    if (iRet != ST_OK) {
//        NSLog(@"st mobile human action add eye contour model failed: %d", iRet);
//    }
    
    //初始化贴纸模块句柄 , 默认开始时无贴纸 , 所以第一个路径参数传空
//    TIMELOG(keySticker);
    
    iRet = st_mobile_sticker_create(NULL , &_hSticker);
    
//    TIMEPRINT(keySticker, "sticker create time:");
    
    if (ST_OK != iRet || !_hSticker) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示" message:@"贴纸SDK初始化失败 , SDK权限过期，或者与绑定包名不符" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        
        [alert show];
    }
    
//    st_mobile_sticker_set_sound_callback_funcs(_hSticker, load_sound, play_sound, stop_sound);
    
    //初始化人脸属性模块句柄
//    NSString *strAttriModelPath = [[NSBundle mainBundle] pathForResource:@"face_attribute_1.0.1" ofType:@"model"];
//
//    iRet = st_mobile_face_attribute_create(strAttriModelPath.UTF8String, &_hAttribute);
//
//    if (ST_OK != iRet || !_hAttribute) {
//
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示" message:@"属性SDK初始化失败，可能是模型路径错误，SDK权限过期，与绑定包名不符" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
//
//        [alert show];
//    }
    
    
    //初始化美颜模块句柄
    iRet = st_mobile_beautify_create(&_hBeautify);
    
    if (ST_OK != iRet || !_hBeautify) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示" message:@"美颜SDK初始化失败，可能是模型路径错误，SDK权限过期，与绑定包名不符" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        
        [alert show];
    }else{
        
        // 设置默认红润参数
        iRet = st_mobile_beautify_setparam(_hBeautify, ST_BEAUTIFY_REDDEN_STRENGTH, self.fReddenStrength);
        
        if (ST_OK != iRet){
            
            STLog(@"st_mobile_beautify_setparam REDDEN:error %d" ,iRet);
        }
        
        // 设置默认磨皮参数
        iRet = st_mobile_beautify_setparam(_hBeautify, ST_BEAUTIFY_SMOOTH_STRENGTH, self.fSmoothStrength);
        
        if (ST_OK != iRet) {
            
            STLog(@"st_mobile_beautify_setparam SMOOTH:error %d" ,iRet);
        }
        
        // 设置默认大眼参数
        iRet = st_mobile_beautify_setparam(_hBeautify, ST_BEAUTIFY_ENLARGE_EYE_RATIO, self.fEnlargeEyeStrength);
        
        if (ST_OK != iRet) {
            
            STLog(@"st_mobile_beautify_setparam ENLARGE_EYE:error %d" , iRet);
        }
        
        // 设置默认瘦脸参数
        iRet = st_mobile_beautify_setparam(_hBeautify, ST_BEAUTIFY_SHRINK_FACE_RATIO, self.fShrinkFaceStrength);
        
        if (ST_OK != iRet) {
            
            STLog(@"st_mobile_beautify_setparam SHRINK_FACE:error %d" , iRet);
        }
        
        // 设置小脸参数
        iRet = st_mobile_beautify_setparam(_hBeautify, ST_BEAUTIFY_SHRINK_JAW_RATIO, self.fShrinkJawStrength);
        
        if (ST_OK != iRet) {
            
            STLog(@"st_mobile_beautify_setparam SHRINK_JAW %d" , iRet);
        }
        
        // 设置美白参数
        iRet = st_mobile_beautify_setparam(_hBeautify, ST_BEAUTIFY_WHITEN_STRENGTH, self.fWhitenStrength);
        
        if (ST_OK != iRet) {
            
            STLog(@"st_mobile_beautify_setparam WHITEN:error %d" , iRet);
        }
    }
    
    // 初始化滤镜句柄
    iRet = st_mobile_gl_filter_create(&_hFilter);
    
    if (ST_OK != iRet || !_hFilter) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示" message:@"滤镜SDK初始化失败，可能是SDK权限过期或与绑定包名不符" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        
        [alert show];
    }
    
    
    // 初始化通用物体追踪句柄
    iRet = st_mobile_object_tracker_create(&_hTracker);
    
    if (ST_OK != iRet || !_hTracker) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示" message:@"通用物体跟踪SDK初始化失败，可能是SDK权限过期或与绑定包名不符" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        
        [alert show];
    }
    
}

#pragma mark - check license
//验证license
- (BOOL)checkActiveCode
{
    NSString *strLicensePath = [[NSBundle mainBundle] pathForResource:@"SENSEME" ofType:@"lic"];
    NSData *dataLicense = [NSData dataWithContentsOfFile:strLicensePath];
    
    NSString *strKeySHA1 = @"SENSEME";
    NSString *strKeyActiveCode = @"ACTIVE_CODE";
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *strStoredSHA1 = [userDefaults objectForKey:strKeySHA1];
    NSString *strLicenseSHA1 = [self getSHA1StringWithData:dataLicense];
    
    st_result_t iRet = ST_OK;
    
    
    if (strStoredSHA1.length > 0 && [strLicenseSHA1 isEqualToString:strStoredSHA1]) {
        
        // Get current active code
        // In this app active code was stored in NSUserDefaults
        // It also can be stored in other places
        NSData *activeCodeData = [userDefaults objectForKey:strKeyActiveCode];
        
        // Check if current active code is available
#if CHECK_LICENSE_WITH_PATH
        
        // use file
        iRet = st_mobile_check_activecode(
                                          strLicensePath.UTF8String,
                                          (const char *)[activeCodeData bytes],
                                          (int)[activeCodeData length]
                                          );
        
#else
        
        // use buffer
        NSData *licenseData = [NSData dataWithContentsOfFile:strLicensePath];
        
        iRet = st_mobile_check_activecode_from_buffer(
                                                      [licenseData bytes],
                                                      (int)[licenseData length],
                                                      [activeCodeData bytes],
                                                      (int)[activeCodeData length]
                                                      );
#endif
        
        
        if (ST_OK == iRet) {
            
            // check success
            return YES;
        }
    }
    
    /*
     1. check fail
     2. new one
     3. update
     */
    
    char active_code[1024];
    int active_code_len = 1024;
    
    // generate one
#if CHECK_LICENSE_WITH_PATH
    
    // use file
    iRet = st_mobile_generate_activecode(
                                         strLicensePath.UTF8String,
                                         active_code,
                                         &active_code_len
                                         );
    
#else
    
    // use buffer
    NSData *licenseData = [NSData dataWithContentsOfFile:strLicensePath];
    
    iRet = st_mobile_generate_activecode_from_buffer(
                                                     [licenseData bytes],
                                                     (int)[licenseData length],
                                                     active_code,
                                                     &active_code_len
                                                     );
#endif
    
    if (ST_OK != iRet) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示" message:@"使用 license 文件生成激活码时失败，可能是授权文件过期。" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        
        [alert show];
        
        return NO;
        
    } else {
        
        // Store active code
        NSData *activeCodeData = [NSData dataWithBytes:active_code length:active_code_len];
        
        [userDefaults setObject:activeCodeData forKey:strKeyActiveCode];
        [userDefaults setObject:strLicenseSHA1 forKey:strKeySHA1];
        
        [userDefaults synchronize];
    }
    
    return YES;
}

- (NSString *)getSHA1StringWithData:(NSData *)data
{
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, (unsigned int)data.length, digest);
    
    NSMutableString *strSHA1 = [NSMutableString string];
    
    for (int i = 0 ; i < CC_SHA1_DIGEST_LENGTH ; i ++) {
        
        [strSHA1 appendFormat:@"%02x" , digest[i]];
    }
    
    return strSHA1;
}

#pragma mark - handle texture

- (void)initResultTexture {
    // 创建结果纹理
    [self setupTextureWithPixelBuffer:&_cvBeautifyBuffer
                                    w:self.imageWidth
                                    h:self.imageHeight
                            glTexture:&_textureBeautifyOutput
                            cvTexture:&_cvTextureBeautify];
    
    [self setupTextureWithPixelBuffer:&_cvStickerBuffer
                                    w:self.imageWidth
                                    h:self.imageHeight
                            glTexture:&_textureStickerOutput
                            cvTexture:&_cvTextureSticker];
    
    
    [self setupTextureWithPixelBuffer:&_cvFilterBuffer
                                    w:self.imageWidth
                                    h:self.imageHeight
                            glTexture:&_textureFilterOutput
                            cvTexture:&_cvTextureFilter];
}

- (BOOL)setupTextureWithPixelBuffer:(CVPixelBufferRef *)pixelBufferOut
                                  w:(int)iWidth
                                  h:(int)iHeight
                          glTexture:(GLuint *)glTexture
                          cvTexture:(CVOpenGLESTextureRef *)cvTexture {
    CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault,
                                               NULL,
                                               NULL,
                                               0,
                                               &kCFTypeDictionaryKeyCallBacks,
                                               &kCFTypeDictionaryValueCallBacks);
    
    CFMutableDictionaryRef attrs = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                             1,
                                                             &kCFTypeDictionaryKeyCallBacks,
                                                             &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    
    CVReturn cvRet = CVPixelBufferCreate(kCFAllocatorDefault,
                                         iWidth,
                                         iHeight,
                                         kCVPixelFormatType_32BGRA,
                                         attrs,
                                         pixelBufferOut);
    
    if (kCVReturnSuccess != cvRet) {
        
        NSLog(@"CVPixelBufferCreate %d" , cvRet);
    }
    
    cvRet = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                         _cvTextureCache,
                                                         *pixelBufferOut,
                                                         NULL,
                                                         GL_TEXTURE_2D,
                                                         GL_RGBA,
                                                         self.imageWidth,
                                                         self.imageHeight,
                                                         GL_BGRA,
                                                         GL_UNSIGNED_BYTE,
                                                         0,
                                                         cvTexture);
    
    CFRelease(attrs);
    CFRelease(empty);
    
    if (kCVReturnSuccess != cvRet) {
        
        NSLog(@"CVOpenGLESTextureCacheCreateTextureFromImage %d" , cvRet);
        
        return NO;
    }
    
    *glTexture = CVOpenGLESTextureGetName(*cvTexture);
    glBindTexture(CVOpenGLESTextureGetTarget(*cvTexture), *glTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    return YES;
}

- (BOOL)setupOriginTextureWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    CVReturn cvRet = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                  _cvTextureCache,
                                                                  pixelBuffer,
                                                                  NULL,
                                                                  GL_TEXTURE_2D,
                                                                  GL_RGBA,
                                                                  self.imageWidth,
                                                                  self.imageHeight,
                                                                  GL_BGRA,
                                                                  GL_UNSIGNED_BYTE,
                                                                  0,
                                                                  &_cvTextureOrigin);
    
    if (!_cvTextureOrigin || kCVReturnSuccess != cvRet) {
        
        NSLog(@"CVOpenGLESTextureCacheCreateTextureFromImage %d" , cvRet);
        
        return NO;
    }
    
    _textureOriginInput = CVOpenGLESTextureGetName(_cvTextureOrigin);
    glBindTexture(GL_TEXTURE_2D , _textureOriginInput);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    return YES;
}

- (void)releaseResultTexture {
    _textureBeautifyOutput = 0;
    _textureStickerOutput = 0;
    _textureFilterOutput = 0;
    
    if (_cvTextureOrigin) {
        
        CFRelease(_cvTextureOrigin);
        _cvTextureOrigin = NULL;
    }
    
    CVPixelBufferRelease(_cvTextureBeautify);
    CVPixelBufferRelease(_cvTextureSticker);
    CVPixelBufferRelease(_cvTextureFilter);
    
    CVPixelBufferRelease(_cvBeautifyBuffer);
    CVPixelBufferRelease(_cvStickerBuffer);
    CVPixelBufferRelease(_cvFilterBuffer);
}



#pragma mark -
- (void)captureSampleBuffer:(CMSampleBufferRef)sampleBuffer
//- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
    __block UIApplicationState applicationState;

    dispatch_sync(dispatch_get_main_queue(), ^{
        applicationState = [UIApplication sharedApplication].applicationState;
    });

    //应用未激活状态不做任何渲染
    if (applicationState != UIApplicationStateActive) {
        return;
    }
    
    if (!self.isAppActive) {
        return;
    }
    
    if (self.pauseOutput) {
        
        return;
    }
    
    //get pts
//    CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
//    double current = CFAbsoluteTimeGetCurrent();
    
//    NSLog(@"st_effects_recored_time : %f", current);
    
//    if (self.recording && (current - self.recordStartTime) > 10) {
//
//        [self stopRecorder];
////        [self.timer stop];
////        [self.timer reset];
//
////        dispatch_async(dispatch_get_main_queue(), ^{
////
////            self.recordImageView.hidden = YES;
////
////            self.recordTimeLabel.hidden = YES;
////
////            self.filterStrengthView.hidden = self.filterStrengthViewHiddenState;
////            self.specialEffectsBtn.hidden = NO;
////            self.beautyBtn.hidden = NO;
////            self.btnAlbum.hidden = NO;
////            self.btnSetting.hidden = NO;
////            self.btnCompare.hidden = NO;
////            self.beautyContainerView.hidden = NO;
////            self.specialEffectsContainerView.hidden = NO;
////            self.settingView.hidden = NO;
////
////        });
//
//    }
    
//    TIMELOG(frameCostKey);
    
    //获取每一帧图像信息
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    unsigned char* pBGRAImageIn = (unsigned char*)CVPixelBufferGetBaseAddress(pixelBuffer);
//    double dCost = 0.0;
//    double dStart = CFAbsoluteTimeGetCurrent();
    
    int iBytesPerRow = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
    int iWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int iHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    
    size_t iTop , iBottom , iLeft , iRight;
    CVPixelBufferGetExtendedPixels(pixelBuffer, &iLeft, &iRight, &iTop, &iBottom);
    
    iWidth = iWidth + (int)iLeft + (int)iRight;
    iHeight = iHeight + (int)iTop + (int)iBottom;
    iBytesPerRow = iBytesPerRow + (int)iLeft + (int)iRight;
    
    
    unsigned char *imageOut = NULL;
    imageOut = (unsigned char *)malloc(iWidth * iHeight * 3/2);
    
    _scale = MAX(screen_height / iHeight, screen_width / iWidth);
    _margin = (iWidth * _scale - screen_width) / 2;
    
    
    st_result_t iRet = ST_OK;
    st_mobile_human_action_t detectResult;
    memset(&detectResult, 0, sizeof(st_mobile_human_action_t));
    st_mobile_106_t *pFacesFinal = NULL;
    int iFaceCount = 0;
    
    _faceArray = [[NSMutableArray alloc] init];
    
    // 如果需要做属性,每隔一秒做一次属性
    double dTimeNow = CFAbsoluteTimeGetCurrent();
    BOOL isAttributeTime = (dTimeNow - self.lastTimeAttrDetected) >= 1.0;
    
    if (isAttributeTime) {
        
        self.lastTimeAttrDetected = dTimeNow;
    }
    
    ///ST_MOBILE 以下为通用物体跟踪部分
    if (_bTracker && _hTracker) {
        
        if (self.isCommonObjectViewAdded) {
            
            if (!self.isCommonObjectViewSetted) {
                
                iRet = st_mobile_object_tracker_set_target(_hTracker, pBGRAImageIn, ST_PIX_FMT_BGRA8888, iWidth, iHeight, iBytesPerRow, &_rect);
                
                if (iRet != ST_OK) {
//                    NSLog(@"st mobile object tracker set target failed: %d", iRet);
                    _rect.left = 0;
                    _rect.top = 0;
                    _rect.right = 0;
                    _rect.bottom = 0;
                } else {
                    self.commonObjectViewSetted = YES;
                }
            }
            
            if (self.isCommonObjectViewSetted) {
                
//                TIMELOG(keyTracker);
                iRet = st_mobile_object_tracker_track(_hTracker, pBGRAImageIn, ST_PIX_FMT_BGRA8888, iWidth, iHeight, iBytesPerRow, &_rect, &_result_score);
//                NSLog(@"tracking, result_score: %f,rect.left: %d, rect.top: %d, rect.right: %d, rect.bottom: %d", _result_score, _rect.left, _rect.top, _rect.right, _rect.bottom);
//                TIMEPRINT(keyTracker, "st_mobile_object_tracker_track time:");
                
                if (iRet != ST_OK) {
                    
//                    NSLog(@"st mobile object tracker track failed: %d", iRet);
                    _rect.left = 0;
                    _rect.top = 0;
                    _rect.right = 0;
                    _rect.bottom = 0;
                }
                
                CGRect rectDisplay = CGRectMake(_rect.left * _scale - _margin,
                                                _rect.top * _scale,
                                                _rect.right * _scale - _rect.left * _scale,
                                                _rect.bottom * _scale - _rect.top * _scale);
                CGPoint center = CGPointMake(rectDisplay.origin.x + rectDisplay.size.width / 2,
                                             rectDisplay.origin.y + rectDisplay.size.height / 2);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (self.commonObjectContainerView.currentCommonObjectView.isOnFirst) {
                        //用作同步,防止再次改变currentCommonObjectView的位置
                        
                    } else if (_rect.left == 0 && _rect.top == 0 && _rect.right == 0 && _rect.bottom == 0) {
                        
                        self.commonObjectContainerView.currentCommonObjectView.hidden = YES;
                        
                    } else {
                        self.commonObjectContainerView.currentCommonObjectView.hidden = NO;
                        self.commonObjectContainerView.currentCommonObjectView.center = center;
                    }
                });
            }
        }
    }
    
    ///ST_MOBILE 人脸信息检测部分
    if (_hDetector) {
        
        BOOL needFaceDetection = ((self.fEnlargeEyeStrength > 0 || self.fShrinkFaceStrength > 0 || self.fShrinkJawStrength > 0) && _hBeautify) || (self.bAttribute && isAttributeTime && _hAttribute);
        
        unsigned long long iConfig = self.iCurrentAction;
        
        if (needFaceDetection) {
            
            iConfig = self.iCurrentAction | ST_MOBILE_FACE_DETECT;
        }
        
        if (iConfig > 0) {
            
//            TIMELOG(keyDetect);
//            ST_CLOCKWISE_ROTATE_0 = 0,  ///< 图像不需要旋转,图像中的人脸为正脸
//            ST_CLOCKWISE_ROTATE_90 = 1, ///< 图像需要顺时针旋转90度,使图像中的人脸为正
//            ST_CLOCKWISE_ROTATE_190 = 2,///< 图像需要顺时针旋转190度,使图像中的人脸为正
//            ST_CLOCKWISE_ROTATE_270
            iRet = st_mobile_human_action_detect(_hDetector,
                                                 pBGRAImageIn,
                                                 ST_PIX_FMT_BGRA8888,
                                                 iWidth,
                                                 iHeight,
                                                 iBytesPerRow,
                                                 ST_CLOCKWISE_ROTATE_0,
                                                 iConfig,
                                                 &detectResult);
//            if (self.video_direct_type == CNC_ENM_Direct_Horizontal) {
//                st_mobile_human_action_rotate(iWidth,
//                                              iHeight,
//                                              stMobileRotate,
//                                              YES,
//                                              &detectResult);
//            }
            
//            TIMEPRINT(keyDetect, "st_mobile_human_action_detect time:");
            
#if DRAW_FACE_KEY_POINTS
            if (detectResult.p_bodys && detectResult.body_count > 0) {
                
//                NSLog(@"body action: %llx", detectResult.p_bodys[0].body_action);
                
                if (CHECK_FLAG(detectResult.p_bodys[0].body_action, ST_MOBILE_BODY_ACTION1)) {
                    self.strBodyAction = @"龙拳";
                } else if (CHECK_FLAG(detectResult.p_bodys[0].body_action, ST_MOBILE_BODY_ACTION2)) {
                    self.strBodyAction = @"一休";
                } else if (CHECK_FLAG(detectResult.p_bodys[0].body_action, ST_MOBILE_BODY_ACTION3)) {
                    self.strBodyAction = @"摊手";
                } else if (CHECK_FLAG(detectResult.p_bodys[0].body_action, ST_MOBILE_BODY_ACTION4)) {
                    self.strBodyAction = @"蜘蛛侠";
                } else if (CHECK_FLAG(detectResult.p_bodys[0].body_action, ST_MOBILE_BODY_ACTION5)) {
                    self.strBodyAction = @"动感超人";
                } else {
                    self.strBodyAction = @"";
                }
                
            } else {
                
                self.strBodyAction = @"";
            }
            
            [self drawKeyPoints:detectResult];
#endif
            
            if(iRet == ST_OK) {
                
                iFaceCount = detectResult.face_count;
                
                if (iFaceCount > 0) {
                    _pFacesDetection = (st_mobile_106_t *)malloc(sizeof(st_mobile_106_t) * iFaceCount);
                    _pFacesBeautify = (st_mobile_106_t *)malloc(sizeof(st_mobile_106_t) * iFaceCount);
                    memset(_pFacesDetection, 0, sizeof(st_mobile_106_t) * iFaceCount);
                    memset(_pFacesBeautify, 0, sizeof(st_mobile_106_t) * iFaceCount);
                }
                
                //构造人脸信息数组
                for (int i = 0; i < iFaceCount; i++) {
                    
                    _pFacesDetection[i] = detectResult.p_faces[i].face106;

                }

                pFacesFinal = _pFacesDetection;
            }else{
                
                STLog(@"st_mobile_human_action_detect failed %d" , iRet);
            }
        }
    }
    
    
    
    //    ///ST_MOBILE 以下为attribute部分 , 当人脸数大于零且人脸信息数组不为空时每秒做一次属性检测.
    //    if (self.bAttribute && _hAttribute) {
    //
    //        if (iFaceCount > 0 && _pFacesDetection && isAttributeTime) {
    //
    //            TIMELOG(attributeKey);
    //
    //            st_mobile_attribute_t *pAttrArray;
    //
    //            // attribute detect
    //            iRet = st_mobile_face_attribute_detect(_hAttribute,
    //                                                   pBGRAImageIn,
    //                                                   ST_PIX_FMT_BGRA8888,
    //                                                   iWidth,
    //                                                   iHeight,
    //                                                   iBytesPerRow,
    //                                                   _pFacesDetection,
    //                                                   1, // 这里仅取一张脸也就是第一张脸的属性作为演示
    //                                                   &pAttrArray);
    //            if (iRet != ST_OK) {
    //
    //                pFacesFinal = NULL;
    //
    //                STLog(@"st_mobile_face_attribute_detect failed. %d" , iRet);
    //
    //                goto unlockBufferAndFlushCache;
    //            }
    //
    //            TIMEPRINT(attributeKey, "st_mobile_face_attribute_detect time: ");
    //
    //
    //            // 取第一个人的属性集合作为示例
    //            st_mobile_attribute_t attributeDisplay = pAttrArray[0];
    //
    //            //获取属性描述
    //            NSString *strAttrDescription = [self getDescriptionOfAttribute:attributeDisplay];
    //
    //            dispatch_async(dispatch_get_main_queue(), ^{
    //
    //                [self.lblAttribute setText:[@"第一张人脸: " stringByAppendingString:strAttrDescription]];
    //                [self.lblAttribute setHidden:NO];
    //            });
    //        }
    //    }else{
    //
    //        dispatch_async(dispatch_get_main_queue(), ^{
    //
    //            [self.lblAttribute setText:@""];
    //            [self.lblAttribute setHidden:YES];
    //        });
    //    }
    
    
    // 设置 OpenGL 环境 , 需要与初始化 SDK 时一致
    if ([EAGLContext currentContext] != self.glContext) {
        [EAGLContext setCurrentContext:self.glContext];
    }
    
    // 当图像尺寸发生改变时需要对应改变纹理大小
    if (iWidth != self.imageWidth || iHeight != self.imageHeight) {
        
        [self releaseResultTexture];
        
        self.imageWidth = iWidth;
        self.imageHeight = iHeight;
        
        [self initResultTexture];
    }
    
    // 获取原图纹理
    BOOL isTextureOriginReady = [self setupOriginTextureWithPixelBuffer:pixelBuffer];
    
    GLuint textureResult = _textureOriginInput;
    
//    CVPixelBufferRef resultPixelBufffer = pixelBuffer;
    st_pixel_format out_format = ST_PIX_FMT_YUV420P;
    if (isTextureOriginReady) {
        
        ///ST_MOBILE 以下为美颜部分
        if (_bBeauty && _hBeautify) {
            
//            TIMELOG(keyBeautify);
            
//    st_mobile_beautify_process_and_output_texture(
//                                                  st_handle_t handle,
//                                                  unsigned int textureid_src,
//                                                  int image_width, int image_height,
//                                                  const st_mobile_106_t *p_faces_array_in, int faces_count,
//                                                  unsigned int textureid_dst,
//                                                  unsigned char *img_out, st_pixel_format fmt_out,
//                                                  st_mobile_106_t *p_faces_array_out
//                                                  );
            
//            iRet = st_mobile_beautify_process_texture(_hBeautify,
//                                                      _textureOriginInput,
//                                                      iWidth,
//                                                      iHeight,
//                                                      pFacesFinal,
//                                                      iFaceCount,
//                                                      _textureBeautifyOutput,
//                                                      _pFacesBeautify);
            iRet = st_mobile_beautify_process_and_output_texture(_hBeautify,
                                                                 _textureOriginInput,
                                                                 iWidth,
                                                                 iHeight,
                                                                 pFacesFinal,
                                                                 iFaceCount,
                                                                 _textureBeautifyOutput,
                                                                 imageOut,
                                                                 out_format,
                                                                 _pFacesBeautify);
            
//            TIMEPRINT(keyBeautify, "st_mobile_beautify_process_texture time:");
            
            if (ST_OK != iRet) {
                
                pFacesFinal = NULL;
                
                STLog(@"st_mobile_beautify_process_texture failed %d" , iRet);
                
            }
            
            pFacesFinal = _pFacesBeautify;
            textureResult = _textureBeautifyOutput;
//            resultPixelBufffer = _cvBeautifyBuffer;
//            [self pixelBufferFrom32BGRAData:imageOut size:CGSizeMake(iWidth, iHeight)];
        }
        
    }
    
    if (self.isNullSticker) {
        iRet = st_mobile_sticker_change_package(_hSticker, NULL);
        
        if (ST_OK != iRet) {
            NSLog(@"st_mobile_sticker_change_package error %d", iRet);
        }
    }
    
    ///ST_MOBILE 以下为贴纸部分
    if (_bSticker && _hSticker) {
        
        //通过 pFacesFinal 更新 detectResult
        for (int i = 0; i < iFaceCount; i ++) {
            
            detectResult.p_faces[i].face106 = pFacesFinal[i];
        }
        
        //调整贴纸最小帧处理间隔，单位ms。
        st_result_t iRet = st_mobile_sticker_set_min_interval(_hSticker, 1);
        if (iRet != ST_OK) {
            NSLog(@"st_mobile_sticker_set_min_interval failed: %d", iRet);
        }
        
//        TIMELOG(stickerProcessKey);
        
//        iRet = st_mobile_sticker_process_texture(_hSticker,
//                                                 textureResult,
//                                                 iWidth,
//                                                 iHeight,
//                                                 stMobileRotate,
//                                                 false,
//                                                 &detectResult,
//                                                 item_callback,
//                                                 _textureStickerOutput);

        iRet = st_mobile_sticker_process_and_output_texture(_hSticker,
                                                            textureResult,
                                                            iWidth,
                                                            iHeight,
                                                            ST_CLOCKWISE_ROTATE_0,
                                                            false,
                                                            &detectResult,
                                                            item_callback,
                                                            _textureStickerOutput,
                                                            imageOut,
                                                            out_format);
        
//        TIMEPRINT(stickerProcessKey, "st_mobile_sticker_process_texture time:");
        
        if (ST_OK != iRet) {
            
            pFacesFinal = NULL;
            
            STLog(@"st_mobile_sticker_process_texture %d" , iRet);
            
        }
        
        textureResult = _textureStickerOutput;
//        resultPixelBufffer = _cvStickerBuffer;
//        [self pixelBufferFrom32BGRAData:imageOut size:CGSizeMake(iWidth, iHeight)];
    }
    
    
    ///ST_MOBILE 以下为滤镜部分
    if (_bFilter && _hFilter) {
        
        if (self.curFilterModelPath != self.preFilterModelPath) {
             st_mobile_gl_filter_set_style(_hFilter, self.curFilterModelPath.UTF8String);
            self.preFilterModelPath = self.curFilterModelPath;
        }
        
//        TIMELOG(keyFilter);
//                        st_mobile_gl_filter_process_texture(
//                                                            st_handle_t handle,
//                                                            unsigned int textureid_src,
//                                                            int image_width, int image_height,
//                                                            unsigned int textureid_dst
//                                                            );
//        st_mobile_gl_filter_process_texture_and_output_buffer(
//                                                              st_handle_t handle,
//                                                              unsigned int textureid_src,
//                                                              int image_width, int image_height,
//                                                              unsigned int textureid_dst,
//                                                              unsigned char *img_out, st_pixel_format fmt_out
//                                                              );
//        iRet = st_mobile_gl_filter_process_texture(_hFilter, textureResult, iWidth, iHeight, _textureFilterOutput);
        iRet = st_mobile_gl_filter_process_texture_and_output_buffer(_hFilter,
                                                                     textureResult,
                                                                     iWidth,
                                                                     iHeight,
                                                                     _textureFilterOutput,
                                                                     imageOut,
                                                                     out_format);
        
        if (ST_OK != iRet) {
            
            STLog(@"st_mobile_gl_filter_process_texture %d" , iRet);
            
        }
        
//        TIMEPRINT(keyFilter, "st_mobile_gl_filter_process_texture time:");
        
        textureResult = _textureFilterOutput;
//        resultPixelBufffer = _cvFilterBuffer;
    }
    
    
    if (self.needSnap) {
        
        self.needSnap = NO;
        
        [self snapWithTexture:textureResult width:iWidth height:iHeight];
    }
    
    if (self.isComparing) {
        
        textureResult = _textureOriginInput;
    }
    
//    if (!self.outputVideoFormatDescription) {
//        CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, &(_outputVideoFormatDescription));
//    }
    
    @synchronized (self) {
        
        if (self.recordStatus == STWriterRecordingStatusRecording) {
            
//            [self.stRecoder appendVideoPixelBuffer:resultPixelBufffer withPresentationTime:timestamp];
            
        }
        
    }
    
    [self.glPreview renderTexture:textureResult];
    
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CVOpenGLESTextureCacheFlush(_cvTextureCache, 0);
    
    if (_cvTextureOrigin) {
        
        CFRelease(_cvTextureOrigin);
        _cvTextureOrigin = NULL;
    }
    
    if (_pFacesDetection) {
        free(_pFacesDetection);
        _pFacesDetection = NULL;
    }
    
    if (_pFacesBeautify) {
        free(_pFacesBeautify);
        _pFacesBeautify = NULL;
    }
    
//    dCost = CFAbsoluteTimeGetCurrent() - dStart;
//    dispatch_async(dispatch_get_main_queue(), ^{
//
//        if (![self.strBodyAction isEqualToString:self.lblBodyAction.text]) {
//            self.lblBodyAction.text = self.strBodyAction;
//        }
//
//        if (self.bAttribute) {
//
//            [self.lblSpeed setText:[NSString stringWithFormat:@"单帧耗时: %.0fms" ,dCost * 1000.0]];
//            [self.lblCPU setText:[NSString stringWithFormat:@"CPU占用率: %.1f%%" , [STParamUtil getCpuUsage]]];
//        } else {
//
//            self.lblSpeed.text = @"";
//            self.lblCPU.text = @"";
//        }
//
//    });
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(do_sense_data:pix_width:pix_height:format:time_stamp:)]) {
        [self.delegate do_sense_data:imageOut pix_width:iWidth pix_height:iHeight*3/2 format:CNCENM_buf_format_I420 time_stamp:0];
    }
    free(imageOut);
    
//    CFRelease(_outputVideoFormatDescription);
//    CVPixelBufferRelease(pixelBuffer);
    
//    TIMEPRINT(frameCostKey, "every frame cost time");

}
- (void)pixelBufferFrom32BGRAData:(const unsigned char *)framedata size:(CGSize)size
{
    NSDictionary *pixelAttributes = [NSDictionary dictionaryWithObject:@{} forKey:(NSString *)kCVPixelBufferIOSurfacePropertiesKey];
    CVPixelBufferRef pixelBuffer = NULL;
    
    int width = size.width;
    int height = size.height;
    
    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                          width,
                                          height,
                                          kCVPixelFormatType_32BGRA,
                                          (__bridge CFDictionaryRef)pixelAttributes,
                                          &pixelBuffer);
    
    if (result != kCVReturnSuccess){
        //        NSLog(@"Unable to create cvpixelbuffer %d", result);
        return ;
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer,0);
    unsigned char *yDestPlane = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    if (yDestPlane == NULL)
    {
        //        NSLog(@"create yDestPlane failed. value is NULL");
        return ;
    }
    
    memcpy(yDestPlane, framedata, width * height*4);
    
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    
    CVPixelBufferRelease(pixelBuffer);
}
#pragma mark - private methods

- (void)snapWithTexture:(GLuint)iTexture width:(int)iWidth height:(int)iHeight
{
    self.pauseOutput = YES;
    
//    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
//        UIGraphicsBeginImageContextWithOptions(CGSizeMake(iWidth, iHeight), NO, 0.0);
////        [self.glPreview drawViewHierarchyInRect:CGRectMake(0, 0, iWidth, iHeight) afterScreenUpdates:YES];
//        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
//        [assetLibrary writeImageToSavedPhotosAlbum:image.CGImage
//                                       orientation:ALAssetOrientationUp
//                                   completionBlock:^(NSURL *assetURL, NSError *error) {
//
//                                       self.lblSaveStatus.text = @"图片已保存到相册";
//                                       [self showAnimationIfSaved:error == nil];
//                                   }];
        
    });
    
    
    
    /*
     CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
     
     CIImage *ciImage = [CIImage imageWithTexture:iTexture size:CGSizeMake(iWidth, iHeight) flipped:YES colorSpace:colorSpace];
     
     CGImageRef cgImage = [self.ciContext createCGImage:ciImage fromRect:CGRectMake(0, 0, iWidth, iHeight)];
     
     CGColorSpaceRelease(colorSpace);
     
     //保存图片
     ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
     
     dispatch_async(dispatch_get_main_queue(), ^{
     
     [assetLibrary writeImageToSavedPhotosAlbum:cgImage
     orientation:ALAssetOrientationUp
     completionBlock:^(NSURL *assetURL, NSError *error) {
     
     CGImageRelease(cgImage);
     
     [self showAnimationIfSaved:error == nil];
     }];
     });
     */
    self.pauseOutput = NO;
}

- (void)showAnimationIfSaved:(BOOL)bSaved {
    
//    self.snapBtn.userInteractionEnabled = NO;
    
    self.lblSaveStatus.hidden = NO;
    
//    [self.lblSaveStatus setText:bSaved ? @"图片已保存到相册" : @"图片保存失败"];
    
    [UIView animateWithDuration:0.2 animations:^{
        
        self.lblSaveStatus.center = CGPointMake(screen_width / 2.0 , 102);
        
    } completion:^(BOOL finished) {
        
        [UIView animateWithDuration:0.3 delay:2
                            options:UIViewAnimationOptionTransitionNone
                         animations:^{
                             
                             self.lblSaveStatus.center = CGPointMake(screen_width / 2.0 , -44);
                             
                         } completion:^(BOOL finished) {
                             
                             self.lblSaveStatus.hidden = YES;
                             
//                             self.snapBtn.userInteractionEnabled = YES;
                             
                         }];
    }];
}

- (NSString *)getDescriptionOfAttribute:(st_mobile_attributes_t)attribute {
    NSString *strAge=nil , *strGender=nil , *strAttricative = nil;
    
    for (int i = 0; i < attribute.attribute_count; i ++) {
        
        // 读取一条属性
        st_mobile_attribute_t attributeOne = attribute.p_attributes[i];
        
        // 获取属性类别
        const char *attr_category = attributeOne.category;
        const char *attr_label = attributeOne.label;
        
        // 年龄
        if (0 == strcmp(attr_category, "age")) {
            
            strAge = [NSString stringWithUTF8String:attr_label];
        }
        
        // 颜值
        if (0 == strcmp(attr_category, "attractive")) {
            
            strAttricative = [NSString stringWithUTF8String:attr_label];
        }
        
        // 性别
        if (0 == strcmp(attr_category, "gender")) {
            
            if (0 == strcmp(attr_label, "male") ) {
                
                strGender = @"男";
            }
            
            if (0 == strcmp(attr_label, "female") ) {
                
                strGender = @"女";
            }
        }
    }
    
    NSString *strAttrDescription = [NSString stringWithFormat:@"颜值:%@ 性别:%@ 年龄:%@" , strAttricative , strGender , strAge];
    
    return strAttrDescription;
}

#pragma mark - sticker callback

void item_callback(const char* material_name, st_material_status status) {
    
    switch (status){
        case ST_MATERIAL_BEGIN:
//            STLog(@"begin %s" , material_name);
            break;
        case ST_MATERIAL_END:
//            STLog(@"end %s" , material_name);
            break;
        case ST_MATERIAL_PROCESS:
//            STLog(@"process %s", material_name);
            break;
        default:
            STLog(@"error");
            break;
    }
}

//void load_sound(void* sound, const char* sound_name, int length) {
//
////    NSLog(@"STEffectsAudioPlayer load sound");
//
//    if ([messageManager.delegate respondsToSelector:@selector(loadSound:name:)]) {
//
//        NSData *soundData = [NSData dataWithBytes:sound length:length];
//        NSString *strName = [NSString stringWithUTF8String:sound_name];
//
//        [messageManager.delegate loadSound:soundData name:strName];
//    }
//}
//
//void play_sound(const char* sound_name, int loop) {
//
////    NSLog(@"STEffectsAudioPlayer play sound");
//
//    if ([messageManager.delegate respondsToSelector:@selector(playSound:loop:)]) {
//
//        NSString *strName = [NSString stringWithUTF8String:sound_name];
//
//        [messageManager.delegate playSound:strName loop:loop];
//    }
//}
//
//void stop_sound(const char* sound_name) {
//
////    NSLog(@"STEffectsAudioPlayer stop sound");
//
//    if ([messageManager.delegate respondsToSelector:@selector(stopSound:)]) {
//
//        NSString *strName = [NSString stringWithUTF8String:sound_name];
//
//        [messageManager.delegate stopSound:strName];
//    }
//}

- (void)filterSliderValueChanged:(UISlider *)sender {
    
    _lblFilterStrength.text = [NSString stringWithFormat:@"%d", (int)(sender.value * 100)];
    
    if (_hFilter) {
        
        st_result_t iRet = st_mobile_gl_filter_set_param(_hFilter, ST_GL_FILTER_STRENGTH, sender.value);
        
        if (ST_OK != iRet) {
            
            STLog(@"st_mobile_gl_filter_set_param %d" , iRet);
        }
    }
}

#pragma mark - handle beauty value

- (void)beautifySliderValueChanged:(UISlider *)sender {
    
    if (_hBeautify) {
        
        st_result_t iRet = ST_OK;
        
        switch (sender.tag) {
                
            case STViewTagShrinkFaceSlider:
            {
                self.fShrinkFaceStrength = sender.value / 100;
                self.thinFaceView.maxLabel.text = [NSString stringWithFormat:@"%d", (int)(sender.value)];
                iRet = st_mobile_beautify_setparam(_hBeautify, ST_BEAUTIFY_SHRINK_FACE_RATIO, self.fShrinkFaceStrength);
                if (ST_OK != iRet) {
                    STLog(@"ST_BEAUTIFY_SHRINK_FACE_RATIO: %d", iRet);
                }
            }
                break;
            case STViewTagEnlargeEyeSlider:
            {
                self.fEnlargeEyeStrength = sender.value / 100;
                self.enlargeEyesView.maxLabel.text = [NSString stringWithFormat:@"%d", (int)(sender.value)];
                iRet = st_mobile_beautify_setparam(_hBeautify, ST_BEAUTIFY_ENLARGE_EYE_RATIO, self.fEnlargeEyeStrength);
                if (ST_OK != iRet) {
                    STLog(@"ST_BEAUTIFY_ENLARGE_EYE_RATIO: %d", iRet);
                }
            }
                break;
                
            case STViewTagShrinkJawSlider:
            {
                self.fShrinkJawStrength = sender.value / 100;
                self.smallFaceView.maxLabel.text = [NSString stringWithFormat:@"%d", (int)(sender.value)];
                iRet = st_mobile_beautify_setparam(_hBeautify, ST_BEAUTIFY_SHRINK_JAW_RATIO, self.fShrinkJawStrength);
                if (ST_OK != iRet) {
                    STLog(@"ST_BEAUTIFY_SHRINK_JAW_RATIO: %d", iRet);
                }
            }
                break;
                
            case STViewTagSmoothSlider:
            {
                self.fSmoothStrength = sender.value / 100;
                self.dermabrasionView.maxLabel.text = [NSString stringWithFormat:@"%d", (int)(sender.value)];
                iRet = st_mobile_beautify_setparam(_hBeautify, ST_BEAUTIFY_SMOOTH_STRENGTH, self.fSmoothStrength);
                if (ST_OK != iRet) {
                    STLog(@"ST_BEAUTIFY_SMOOTH_STRENGTH: %d", iRet);
                }
            }
                break;
                
            case STViewTagReddenSlider:
            {
                self.fReddenStrength = sender.value / 100;
                self.ruddyView.maxLabel.text = [NSString stringWithFormat:@"%d", (int)(sender.value)];
                iRet = st_mobile_beautify_setparam(_hBeautify, ST_BEAUTIFY_REDDEN_STRENGTH, self.fReddenStrength);
                if (ST_OK != iRet) {
                    STLog(@"ST_BEAUTIFY_REDDEN_STRENGTH: %d", iRet);
                }
            }
                break;
                
            case STViewTagWhitenSlider:
            {
                self.fWhitenStrength = sender.value / 100;
                self.whitenView.maxLabel.text = [NSString stringWithFormat:@"%d", (int)(sender.value)];
                iRet = st_mobile_beautify_setparam(_hBeautify, ST_BEAUTIFY_WHITEN_STRENGTH, self.fWhitenStrength);
                if (ST_OK != iRet) {
                    STLog(@"ST_BEAUTIFY_WHITEN_STRENGTH: %d", iRet);
                }
            }
                break;
                
        }
        
        
        if (self.fShrinkFaceStrength == 0 &&
            self.fEnlargeEyeStrength == 0 &&
            self.fShrinkJawStrength == 0 &&
            self.fSmoothStrength == 0 &&
            self.fReddenStrength == 0 &&
            self.fWhitenStrength == 0) {
            
            self.bBeauty = NO;
            
        } else {
            
            self.bBeauty = YES;
        }
        
    }
}

- (void)changePreviewSize {

}

#pragma mark - draw points

- (void)drawKeyPoints:(st_mobile_human_action_t)detectResult {
    
    for (int i = 0; i < detectResult.face_count; ++i) {
        
        for (int j = 0; j < 106; ++j) {
            [_faceArray addObject:@{
                                    POINT_KEY: [NSValue valueWithCGPoint:[self coordinateTransformation:detectResult.p_faces[i].face106.points_array[j]]]
                                    }];
        }
        
        if (detectResult.p_faces[i].p_extra_face_points && detectResult.p_faces[i].extra_face_points_count > 0) {
            
            for (int j = 0; j < detectResult.p_faces[i].extra_face_points_count; ++j) {
                [_faceArray addObject:@{
                                        POINT_KEY: [NSValue valueWithCGPoint:[self coordinateTransformation:detectResult.p_faces[i].p_extra_face_points[j]]]
                                        }];
            }
        }
        
        if (detectResult.p_faces[i].p_eyeball_contour && detectResult.p_faces[i].eyeball_contour_points_count > 0) {
            
            for (int j = 0; j < detectResult.p_faces[i].eyeball_contour_points_count; ++j) {
                [_faceArray addObject:@{
                                        POINT_KEY: [NSValue valueWithCGPoint:[self coordinateTransformation:detectResult.p_faces[i].p_eyeball_contour[j]]]
                                        }];
            }
        }
        
    }
    
    if (detectResult.p_bodys && detectResult.body_count > 0) {
        
        for (int j = 0; j < detectResult.p_bodys[0].key_points_count; ++j) {
            
            if (detectResult.p_bodys[0].p_key_points_score[j] > 0.15) {
                [_faceArray addObject:@{
                                        POINT_KEY: [NSValue valueWithCGPoint:[self coordinateTransformation:detectResult.p_bodys[0].p_key_points[j]]]
                                        }];
            }
        }
    }
    
    self.commonObjectContainerView.faceArray = _faceArray;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.commonObjectContainerView setNeedsDisplay];
    });
}

- (CGPoint)coordinateTransformation:(st_pointf_t)point {
    
    return CGPointMake(_scale * point.x - _margin, _scale * point.y);
}

#pragma mark -

- (st_rotate_type)getRotateType
{
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;

    switch (deviceOrientation) {

        case UIDeviceOrientationPortrait:
            return ST_CLOCKWISE_ROTATE_0;

        case UIDeviceOrientationPortraitUpsideDown:
            return ST_CLOCKWISE_ROTATE_180;

        case UIDeviceOrientationLandscapeLeft:
            return ((self.isFrontCamera && self.isVideoMirrored) || (!self.isFrontCamera && !self.isVideoMirrored)) ? ST_CLOCKWISE_ROTATE_270 : ST_CLOCKWISE_ROTATE_90;

        case UIDeviceOrientationLandscapeRight:
            return ((self.isFrontCamera && self.isVideoMirrored) || (!self.isFrontCamera && !self.isVideoMirrored)) ? ST_CLOCKWISE_ROTATE_90 : ST_CLOCKWISE_ROTATE_270;

        default:
            return ST_CLOCKWISE_ROTATE_0;
    }
//    switch (self.video_direct_type) {
//        case CNC_ENM_Direct_Horizontal:
//            
////            return ((self.isFrontCamera && self.isVideoMirrored) || (!self.isFrontCamera && !self.isVideoMirrored)) ? ST_CLOCKWISE_ROTATE_90 : ST_CLOCKWISE_ROTATE_270;
//            return ((self.isFrontCamera && self.isVideoMirrored) || (!self.isFrontCamera && !self.isVideoMirrored)) ? ST_CLOCKWISE_ROTATE_270 : ST_CLOCKWISE_ROTATE_90;
//            break;
//        case CNC_ENM_Direct_Vertical:
//            
//            return ST_CLOCKWISE_ROTATE_0;
//            break;
//            
//        default:
////            return ST_CLOCKWISE_ROTATE_0;
//            break;
//    }
}

#pragma mark - handle system notifications

- (void)appWillResignActive {
    
    self.isAppActive = NO;
    
    if (self.isComparing) {
        self.isComparing = NO;
    }
    
    if (self.recording) {
        
        [self stopRecorder];
        
//        [self.timer stop];
//        [self.timer reset];
        
        self.recording = NO;
        self.recordImageView.hidden = YES;
        
//        self.recordTimeLabel.hidden = YES;
        
        self.filterStrengthView.hidden = self.filterStrengthViewHiddenState;
        self.specialEffectsBtn.hidden = NO;
        self.beautyBtn.hidden = NO;
//        self.btnAlbum.hidden = NO;
//        self.btnSetting.hidden = NO;
        self.btnCompare.hidden = NO;
        self.beautyContainerView.hidden = NO;
        self.specialEffectsContainerView.hidden = NO;
//        self.settingView.hidden = NO;
    }
    self.pauseOutput = YES;

}

- (void)appDidEnterBackground {

    self.isAppActive = NO;
}

- (void)appWillEnterForeground {

    self.isAppActive = YES;
}

- (void)appDidBecomeActive {

    self.pauseOutput = NO;
    self.isAppActive = YES;
}

#pragma mark - lazy load views

- (STViewButton *)specialEffectsBtn {
    if (!_specialEffectsBtn) {
        
        CGFloat buttonWidth = 50;
        CGFloat backViewHeight = buttonWidth*4;
        
        _specialEffectsBtn = [[[NSBundle mainBundle] loadNibNamed:@"STViewButton" owner:nil options:nil] firstObject];
        [_specialEffectsBtn setExclusiveTouch:YES];
        
        
        CGRect btn_rect = CGRectMake(screen_width - buttonWidth, (screen_height - backViewHeight)/2+55*2, buttonWidth, buttonWidth);
//        _specialEffectsBtn.frame = CGRectMake([self layoutWidthWithValue:143], screen_height - 50, image.size.width, 50);
        _specialEffectsBtn.frame = btn_rect;
        
//        _specialEffectsBtn.center = CGPointMake(_specialEffectsBtn.center.x, self.snapBtn.center.y);
        _specialEffectsBtn.backgroundColor = [UIColor clearColor];
        _specialEffectsBtn.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
        _specialEffectsBtn.layer.cornerRadius = 5.0f;
        _specialEffectsBtn.imageView.image = [UIImage imageNamed:@"btn_special_effects.png"];
        _specialEffectsBtn.imageView.highlightedImage = [UIImage imageNamed:@"btn_special_effects_selected.png"];
        _specialEffectsBtn.titleLabel.textColor = [UIColor whiteColor];
        _specialEffectsBtn.titleLabel.highlightedTextColor = UIColorFromRGB(0xc086e5);
        _specialEffectsBtn.titleLabel.text = @"特效";
        _specialEffectsBtn.tag = STViewTagSpecialEffectsBtn;
        
        __block CNCSenseMeEffectsManager *weakSelf = self;
        
        _specialEffectsBtn.tapBlock = ^{
            [weakSelf clickBottomViewButton:weakSelf.specialEffectsBtn];
        };
    }
    return _specialEffectsBtn;
}

- (STViewButton *)beautyBtn {
    if (!_beautyBtn) {
        _beautyBtn = [[[NSBundle mainBundle] loadNibNamed:@"STViewButton" owner:nil options:nil] firstObject];
        [_beautyBtn setExclusiveTouch:YES];
        
        UIImage *image = [UIImage imageNamed:@"btn_beauty.png"];
        
        CGFloat buttonWidth = 50;
        CGFloat backViewHeight = buttonWidth*4;
        int x = 0;
        if ((buttonWidth - image.size.width) > 0) {
            x = (buttonWidth - image.size.width)/2;
        }
        CGRect btn_rect = CGRectMake(screen_width - buttonWidth, (screen_height - backViewHeight)/2+55*3, buttonWidth, buttonWidth);
        
        _beautyBtn.frame = btn_rect;
        
//        _beautyBtn.frame = CGRectMake(screen_width - [self layoutWidthWithValue:143] - image.size.width, screen_height - 50, image.size.width, 50);
//        _beautyBtn.center = CGPointMake(_beautyBtn.center.x, self.snapBtn.center.y);
        _beautyBtn.backgroundColor = [UIColor clearColor];
        _beautyBtn.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
        _beautyBtn.layer.cornerRadius = 5.0f;
        _beautyBtn.imageView.image = [UIImage imageNamed:@"btn_beauty.png"];
        _beautyBtn.imageView.highlightedImage = [UIImage imageNamed:@"btn_beauty_selected.png"];
        _beautyBtn.titleLabel.textColor = [UIColor whiteColor];
        _beautyBtn.titleLabel.highlightedTextColor = UIColorFromRGB(0xc086e5);
        _beautyBtn.titleLabel.text = @"美颜";
        _beautyBtn.tag = STViewTagBeautyBtn;
        
        __block CNCSenseMeEffectsManager *weakSelf = self;
        
        _beautyBtn.tapBlock = ^{
            [weakSelf clickBottomViewButton:weakSelf.beautyBtn];
        };
    }
    return _beautyBtn;
}

- (UIView *)gradientView {
    
    if (!_gradientView) {
        _gradientView = [[[UIView alloc] initWithFrame:CGRectMake(screen_width / 2 - 35, screen_height - 80, 70, 70)] autorelease];
        _gradientView.alpha = 0.6;
        _gradientView.layer.cornerRadius = 35;
        _gradientView.layer.shadowColor = UIColorFromRGB(0x222256).CGColor;
        _gradientView.layer.shadowOpacity = 0.15;
        _gradientView.layer.shadowOffset = CGSizeZero;
        
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame = _gradientView.bounds;
        gradientLayer.cornerRadius = 35;
        gradientLayer.colors = @[(__bridge id)UIColorFromRGB(0xc460e1).CGColor, (__bridge id)UIColorFromRGB(0x7fd8ee).CGColor];
        gradientLayer.startPoint = CGPointMake(0, 0);
        gradientLayer.endPoint = CGPointMake(1, 1);
        gradientLayer.shadowColor = UIColorFromRGB(0x472b68).CGColor;
        gradientLayer.shadowOpacity = 0.1;
        gradientLayer.shadowOffset = CGSizeZero;
        [_gradientView.layer addSublayer:gradientLayer];
        
    }
    return _gradientView;
}

//- (STViewButton *)snapBtn {
//    if (!_snapBtn) {
//        _snapBtn = [[STViewButton alloc] initWithFrame:CGRectMake(screen_width / 2 - 28.5, screen_height - 73.5, 57, 57)];
//        _snapBtn.layer.cornerRadius = 28.5;
//        _snapBtn.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
//
//
//        __block CNCSenseMeEffectsManager *weakSelf = self;
//        _snapBtn.tapBlock = ^{
////            NSLog(@"stviewbtn tap tap tap");
//            weakSelf.needSnap = YES;
//        };
//        _snapBtn.delegate = self;
//    }
//    return _snapBtn;
//}

- (UIView *)specialEffectsContainerView {
    if (!_specialEffectsContainerView) {
        _specialEffectsContainerView = [[[UIView alloc] initWithFrame:CGRectMake((screen_width-container_view_width)/2, screen_height + container_view_space_height, container_view_width,(190 + container_view_height))] autorelease];
        _specialEffectsContainerView.backgroundColor = [UIColor clearColor];
        
        
        UIView *noneStickerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 57, 40)] autorelease];
        noneStickerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        noneStickerView.layer.shadowColor = UIColorFromRGB(0x141618).CGColor;
        noneStickerView.layer.shadowOpacity = 0.5;
        noneStickerView.layer.shadowOffset = CGSizeMake(3, 3);
        
        UIImage *image = [UIImage imageNamed:@"none_sticker.png"];
        UIImageView *imageView = [[[UIImageView alloc] initWithFrame:CGRectMake((57 - image.size.width) / 2, (40 - image.size.height) / 2, image.size.width, image.size.height)] autorelease];
        imageView.contentMode = UIViewContentModeCenter;
        imageView.image = image;
        imageView.highlightedImage = [UIImage imageNamed:@"none_sticker_selected.png"];
        _noneStickerImageView = imageView;
        
        UITapGestureRecognizer *tapGesture = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapNoneSticker:)] autorelease];
        [noneStickerView addGestureRecognizer:tapGesture];
        
        [noneStickerView addSubview:imageView];
        
        UIView *whiteLineView = [[[UIView alloc] initWithFrame:CGRectMake(56, 3, 1, 34)] autorelease];
        whiteLineView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
        [noneStickerView addSubview:whiteLineView];
        
        UIView *lineView = [[[UIView alloc] initWithFrame:CGRectMake(0, 40, CGRectGetWidth(_specialEffectsContainerView.frame), 1)] autorelease];
        lineView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
        [_specialEffectsContainerView addSubview:lineView];
        
        [_specialEffectsContainerView addSubview:noneStickerView];
        [_specialEffectsContainerView addSubview:self.scrollTitleView];
        [_specialEffectsContainerView addSubview:self.collectionView];
        [_specialEffectsContainerView addSubview:self.objectTrackCollectionView];
        
        UIView *blankView = [[[UIView alloc] initWithFrame:CGRectMake(0, 181, CGRectGetWidth(_specialEffectsContainerView.frame), 50)] autorelease];
        blankView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        [_specialEffectsContainerView addSubview:blankView];
    }
    return _specialEffectsContainerView;
}

- (UIView *)beautyContainerView {
    
    if (!_beautyContainerView) {
        
        _beautyContainerView = [[[UIView alloc] initWithFrame:CGRectMake((screen_width-container_view_width)/2, (screen_height + container_view_space_height), container_view_width,(190 + container_view_height))] autorelease];
        _beautyContainerView.backgroundColor = [UIColor clearColor];
        [_beautyContainerView addSubview:self.beautyScrollTitleView];
        
        UIView *whiteLineView = [[[UIView alloc] initWithFrame:CGRectMake(0, 40, CGRectGetWidth(_beautyContainerView.frame), 1)] autorelease];
        whiteLineView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
        [_beautyContainerView addSubview:whiteLineView];
        
        [_beautyContainerView addSubview:self.filterCategoryView];
        [_beautyContainerView addSubview:self.filterView];

        [_beautyContainerView addSubview:self.beautyBaseView];
        [_beautyContainerView addSubview:self.beautyShapeView];
        
        [self.arrBeautyViews addObject:self.beautyBaseView];
        [self.arrBeautyViews addObject:self.beautyShapeView];
        [self.arrBeautyViews addObject:self.filterCategoryView];
        [self.arrBeautyViews addObject:self.filterView];
    }
    return _beautyContainerView;
}

- (STFilterView *)filterView {
    
    if (!_filterView) {
        _filterView = [[[STFilterView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.filterCategoryView.frame), 41, CGRectGetWidth(self.filterCategoryView.frame),(190 + container_view_height))] autorelease];
        _filterView.alpha = 0;
        _filterView.leftView.imageView.image = [UIImage imageNamed:@"still_life_highlighted"];
        _filterView.leftView.titleLabel.text = @"静物";
        _filterView.leftView.titleLabel.textColor = [UIColor whiteColor];
        
        _filterView.filterCollectionView.arrSceneryFilterModels = [self getFilterModelsByType:STEffectsTypeFilterScenery];
        _filterView.filterCollectionView.arrPortraitFilterModels = [self getFilterModelsByType:STEffectsTypeFilterPortrait];
        _filterView.filterCollectionView.arrStillLifeFilterModels = [self getFilterModelsByType:STEffectsTypeFilterStillLife];
        _filterView.filterCollectionView.arrDeliciousFoodFilterModels = [self getFilterModelsByType:STEffectsTypeFilterDeliciousFood];
        
        __block CNCSenseMeEffectsManager *weakSelf = self;
        
        _filterView.filterCollectionView.delegateBlock = ^(STCollectionViewDisplayModel *model) {
            [weakSelf handleFilterChanged:model];
        };
        _filterView.block = ^{
            [UIView animateWithDuration:0.5 animations:^{
                weakSelf.filterCategoryView.frame = CGRectMake(0, weakSelf.filterCategoryView.frame.origin.y, container_view_width,(190 + container_view_height));
                weakSelf.filterCategoryView.alpha = 1;
                weakSelf.filterView.frame = CGRectMake(CGRectGetWidth(weakSelf.filterView.frame), weakSelf.filterView.frame.origin.y, CGRectGetWidth(weakSelf.filterView.frame),(190 + container_view_height));
                weakSelf.filterView.alpha = 0;
            }];
            weakSelf.filterStrengthView.hidden = YES;
        };
    }
    return _filterView;
}

- (UIView *)filterCategoryView {
    
    if (!_filterCategoryView) {
        
        _filterCategoryView = [[[UIView alloc] initWithFrame:CGRectMake(0, 41, container_view_width,(190 + container_view_height))] autorelease];
        _filterCategoryView.backgroundColor = [[UIColor clearColor] colorWithAlphaComponent:0.5];

        CGFloat space = (CGRectGetWidth(_filterCategoryView.frame) - 33*4)/5;
        CGFloat width = 33;
        CGFloat height = 60;
        STViewButton *portraitViewBtn = [[[NSBundle mainBundle] loadNibNamed:@"STViewButton" owner:nil options:nil] firstObject];
        portraitViewBtn.tag = STEffectsTypeFilterPortrait;
        portraitViewBtn.backgroundColor = [UIColor clearColor];
        portraitViewBtn.frame =  CGRectMake(space+(space+width)*0, 28, width, height);
        portraitViewBtn.imageView.image = [UIImage imageNamed:@"portrait"];
        portraitViewBtn.imageView.highlightedImage = [UIImage imageNamed:@"portrait_highlighted"];
        portraitViewBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        portraitViewBtn.titleLabel.textColor = [UIColor whiteColor];
        portraitViewBtn.titleLabel.highlightedTextColor = [UIColor whiteColor];
        portraitViewBtn.titleLabel.text = @"人物";
        
        for (UIGestureRecognizer *recognizer in portraitViewBtn.gestureRecognizers) {
            [portraitViewBtn removeGestureRecognizer:recognizer];
        }
        UITapGestureRecognizer *portraitRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchFilterType:)]  autorelease];
        [portraitViewBtn addGestureRecognizer:portraitRecognizer];
        [self.arrFilterCategoryViews addObject:portraitViewBtn];
        [_filterCategoryView addSubview:portraitViewBtn];
        
        
        
        STViewButton *sceneryViewBtn = [[[NSBundle mainBundle] loadNibNamed:@"STViewButton" owner:nil options:nil] firstObject];
        sceneryViewBtn.tag = STEffectsTypeFilterScenery;
        sceneryViewBtn.backgroundColor = [UIColor clearColor];
        sceneryViewBtn.frame =  CGRectMake(space+(space+width)*1, 28, width, height);
        sceneryViewBtn.imageView.image = [UIImage imageNamed:@"scenery"];
        sceneryViewBtn.imageView.highlightedImage = [UIImage imageNamed:@"scenery_highlighted"];
        sceneryViewBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        sceneryViewBtn.titleLabel.textColor = [UIColor whiteColor];
        sceneryViewBtn.titleLabel.highlightedTextColor = [UIColor whiteColor];
        sceneryViewBtn.titleLabel.text = @"风景";
        
        for (UIGestureRecognizer *recognizer in sceneryViewBtn.gestureRecognizers) {
            [sceneryViewBtn removeGestureRecognizer:recognizer];
        }
        UITapGestureRecognizer *sceneryRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchFilterType:)]  autorelease];
        [sceneryViewBtn addGestureRecognizer:sceneryRecognizer];
        [self.arrFilterCategoryViews addObject:sceneryViewBtn];
        [_filterCategoryView addSubview:sceneryViewBtn];
        
        
        
        STViewButton *stillLifeViewBtn = [[[NSBundle mainBundle] loadNibNamed:@"STViewButton" owner:nil options:nil] firstObject];
        stillLifeViewBtn.tag = STEffectsTypeFilterStillLife;
        stillLifeViewBtn.backgroundColor = [UIColor clearColor];
        stillLifeViewBtn.frame =  CGRectMake(space+(space+width)*2, 28, width, height);;
        stillLifeViewBtn.imageView.image = [UIImage imageNamed:@"still_life"];
        stillLifeViewBtn.imageView.highlightedImage = [UIImage imageNamed:@"still_life_highlighted"];
        stillLifeViewBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        stillLifeViewBtn.titleLabel.textColor = [UIColor whiteColor];
        stillLifeViewBtn.titleLabel.highlightedTextColor = [UIColor whiteColor];
        stillLifeViewBtn.titleLabel.text = @"静物";
        
        for (UIGestureRecognizer *recognizer in stillLifeViewBtn.gestureRecognizers) {
            [stillLifeViewBtn removeGestureRecognizer:recognizer];
        }
        UITapGestureRecognizer *stillLifeRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchFilterType:)] autorelease];
        [stillLifeViewBtn addGestureRecognizer:stillLifeRecognizer];
        [self.arrFilterCategoryViews addObject:stillLifeViewBtn];
        [_filterCategoryView addSubview:stillLifeViewBtn];
        
        
        
        STViewButton *deliciousFoodViewBtn = [[[NSBundle mainBundle] loadNibNamed:@"STViewButton" owner:nil options:nil] firstObject];
        deliciousFoodViewBtn.tag = STEffectsTypeFilterDeliciousFood;
        deliciousFoodViewBtn.backgroundColor = [UIColor clearColor];
        deliciousFoodViewBtn.frame =  CGRectMake(space+(space+width)*3, 28, width, height);;
        deliciousFoodViewBtn.imageView.image = [UIImage imageNamed:@"delicious_food"];
        deliciousFoodViewBtn.imageView.highlightedImage = [UIImage imageNamed:@"delicious_food_highlighted"];
        deliciousFoodViewBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        deliciousFoodViewBtn.titleLabel.textColor = [UIColor whiteColor];
        deliciousFoodViewBtn.titleLabel.highlightedTextColor = [UIColor whiteColor];
        deliciousFoodViewBtn.titleLabel.text = @"美食";
        
        for (UIGestureRecognizer *recognizer in deliciousFoodViewBtn.gestureRecognizers) {
            [deliciousFoodViewBtn removeGestureRecognizer:recognizer];
        }
        UITapGestureRecognizer *deliciousFoodRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchFilterType:)] autorelease];
        [deliciousFoodViewBtn addGestureRecognizer:deliciousFoodRecognizer];
        [self.arrFilterCategoryViews addObject:deliciousFoodViewBtn];
        [_filterCategoryView addSubview:deliciousFoodViewBtn];
        
    }
    return _filterCategoryView;
}

- (void)switchFilterType:(UITapGestureRecognizer *)recognizer {
    
    [UIView animateWithDuration:0.5 animations:^{
        self.filterCategoryView.frame = CGRectMake(-container_view_width, self.filterCategoryView.frame.origin.y, container_view_width,(190 + container_view_height));
        self.filterCategoryView.alpha = 0;
        self.filterView.frame = CGRectMake(0, self.filterView.frame.origin.y, CGRectGetWidth(self.filterView.frame),(190 + container_view_height));
        self.filterView.alpha = 1;
    }];
    
    if (self.currentSelectedFilterModel.modelType == recognizer.view.tag && self.currentSelectedFilterModel.isSelected) {
        self.filterStrengthView.hidden = NO;
    } else {
        self.filterStrengthView.hidden = YES;
    }
    
//    self.filterStrengthView.hidden = !(self.currentSelectedFilterModel.modelType == recognizer.view.tag);
    
    switch (recognizer.view.tag) {
            
        case STEffectsTypeFilterPortrait:
            
            _filterView.leftView.imageView.image = [UIImage imageNamed:@"portrait_highlighted"];
            _filterView.leftView.titleLabel.text = @"人物";
            _filterView.filterCollectionView.arrModels = _filterView.filterCollectionView.arrPortraitFilterModels;
            
            break;
            
        
        case STEffectsTypeFilterScenery:
            
            _filterView.leftView.imageView.image = [UIImage imageNamed:@"scenery_highlighted"];
            _filterView.leftView.titleLabel.text = @"风景";
            _filterView.filterCollectionView.arrModels = _filterView.filterCollectionView.arrSceneryFilterModels;
            
            break;
            
        case STEffectsTypeFilterStillLife:
            
            _filterView.leftView.imageView.image = [UIImage imageNamed:@"still_life_highlighted"];
            _filterView.leftView.titleLabel.text = @"静物";
            _filterView.filterCollectionView.arrModels = _filterView.filterCollectionView.arrStillLifeFilterModels;
            
            break;
            
        case STEffectsTypeFilterDeliciousFood:
            
            _filterView.leftView.imageView.image = [UIImage imageNamed:@"delicious_food_highlighted"];
            _filterView.leftView.titleLabel.text = @"美食";
            _filterView.filterCollectionView.arrModels = _filterView.filterCollectionView.arrDeliciousFoodFilterModels;
            
            break;
            
        default:
            break;
    }
    
    [_filterView.filterCollectionView reloadData];
}

- (void)refreshFilterCategoryState:(STEffectsType)type {
    
    for (int i = 0; i < self.arrFilterCategoryViews.count; ++i) {
        
        if (self.arrFilterCategoryViews[i].highlighted) {
            self.arrFilterCategoryViews[i].highlighted = NO;
        }
    }
    
    switch (type) {
        case STEffectsTypeFilterPortrait:
            
            self.arrFilterCategoryViews[0].highlighted = YES;
            
            break;
            
        case STEffectsTypeFilterScenery:
            
            self.arrFilterCategoryViews[1].highlighted = YES;
            
            break;
            
        case STEffectsTypeFilterStillLife:
            
            self.arrFilterCategoryViews[2].highlighted = YES;
            
            break;
            
        case STEffectsTypeFilterDeliciousFood:
            
            self.arrFilterCategoryViews[3].highlighted = YES;
            
            break;
            
        default:
            break;
    }
}

- (STScrollTitleView *)beautyScrollTitleView {
    if (!_beautyScrollTitleView) {
        
        __block CNCSenseMeEffectsManager *weakSelf = self;
        
        _beautyScrollTitleView = [[STScrollTitleView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.beautyContainerView.frame), 40) titles:@[@"滤镜", @"基础美颜", @"美形"] effectsType:@[@(STEffectsTypeBeautyFilter), @(STEffectsTypeBeautyBase), @(STEffectsTypeBeautyShape)] titleOnClick:^(STTitleViewItem *titleView, NSInteger index, STEffectsType type) {
            [weakSelf handleEffectsType:type];
        }];
        _beautyScrollTitleView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    }
    return _beautyScrollTitleView;
}

- (STScrollTitleView *)scrollTitleView {
    if (!_scrollTitleView) {
        
        __block CNCSenseMeEffectsManager *weakSelf = self;

        _scrollTitleView = [[STScrollTitleView alloc] initWithFrame:CGRectMake(57, 0, CGRectGetWidth(self.specialEffectsContainerView.frame) - 57, 40) normalImages:[self getNormalImages] selectedImages:[self getSelectedImages] effectsType:@[@(STEffectsTypeSticker2D), @(STEffectsTypeSticker3D), @(STEffectsTypeStickerGesture), @(STEffectsTypeStickerSegment), @(STEffectsTypeStickerFaceDeformation), @(STEffectsTypeObjectTrack)] titleOnClick:^(STTitleViewItem *titleView, NSInteger index, STEffectsType type) {
            [weakSelf handleEffectsType:type];
        }];
        
        _scrollTitleView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    }
    return _scrollTitleView;
}

- (STCollectionView *)collectionView {
    if (!_collectionView) {
        
        __block CNCSenseMeEffectsManager *weakSelf = self;
        _collectionView = [[STCollectionView alloc] initWithFrame:CGRectMake(0, 41, CGRectGetWidth(self.specialEffectsContainerView.frame), 140) withModels:nil andDelegateBlock:^(STCollectionViewDisplayModel *model) {
            
            [weakSelf handleStickerChanged:model];
        }];
        
        _collectionView.arr2DModels = self.arr2DStickers;
        _collectionView.arr3DModels = self.arr3DStickers;
        _collectionView.arrGestureModels = self.arrGestureStickers;
        _collectionView.arrSegmentModels = self.arrSegmentStickers;
        _collectionView.arrFaceDeformationModels = self.arrFacedeformationStickers;
        
        _collectionView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        
    }
    return _collectionView;
}

- (STCollectionView *)objectTrackCollectionView {
    if (!_objectTrackCollectionView) {
        
        __block CNCSenseMeEffectsManager *weakSelf = self;
        _objectTrackCollectionView = [[STCollectionView alloc] initWithFrame:CGRectMake(0, 41, CGRectGetWidth(self.specialEffectsContainerView.frame), 140) withModels:nil andDelegateBlock:^(STCollectionViewDisplayModel *model) {
            [weakSelf handleObjectTrackChanged:model];
        }];
        
        _objectTrackCollectionView.arrModels = self.arrObjectTrackers;
        _objectTrackCollectionView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    }
    return _objectTrackCollectionView;
}

- (UIView *)beautyShapeView {
    
    if (!_beautyShapeView) {
        
        _beautyShapeView = [[[UIView alloc] initWithFrame:CGRectMake(0, 41, CGRectGetWidth(self.beautyContainerView.frame),(190 + container_view_height))] autorelease];
        
        STSliderView *thinFaceView = [[[NSBundle mainBundle] loadNibNamed:@"STSliderView" owner:nil options:nil] firstObject];
        thinFaceView.frame = CGRectMake(0, 5, CGRectGetWidth(self.beautyContainerView.frame), 35);
        thinFaceView.backgroundColor = [UIColor clearColor];
        thinFaceView.imageView.image = [UIImage imageNamed:@"thin_face.png"];
        thinFaceView.titleLabel.textColor = UIColorFromRGB(0xffffff);
        thinFaceView.titleLabel.font = [UIFont systemFontOfSize:11];
        thinFaceView.titleLabel.text = @"瘦脸";
        
        thinFaceView.minLabel.textColor = UIColorFromRGB(0xffffff);
        thinFaceView.minLabel.font = [UIFont systemFontOfSize:15];
        thinFaceView.minLabel.text = @"";
        
        thinFaceView.maxLabel.textColor = UIColorFromRGB(0xffffff);
        thinFaceView.maxLabel.font = [UIFont systemFontOfSize:15];
        
        thinFaceView.slider.thumbTintColor = UIColorFromRGB(0x9e4fcb);
        thinFaceView.slider.minimumTrackTintColor = UIColorFromRGB(0x9e4fcb);
        thinFaceView.slider.maximumValue = 100;
        [thinFaceView.slider addTarget:self action:@selector(beautifySliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        thinFaceView.slider.tag = STViewTagShrinkFaceSlider;
        _thinFaceView = thinFaceView;
        
        
        STSliderView *enlargeEyesView = [[[NSBundle mainBundle] loadNibNamed:@"STSliderView" owner:nil options:nil] firstObject];
        enlargeEyesView.frame = CGRectMake(0, 40, CGRectGetWidth(self.beautyContainerView.frame), 35);
        enlargeEyesView.backgroundColor = [UIColor clearColor];
        enlargeEyesView.imageView.image = [UIImage imageNamed:@"enlarge_eyes.png"];
        enlargeEyesView.titleLabel.textColor = UIColorFromRGB(0xffffff);
        enlargeEyesView.titleLabel.font = [UIFont systemFontOfSize:11];
        enlargeEyesView.titleLabel.text = @"大眼";
        
        enlargeEyesView.minLabel.textColor = UIColorFromRGB(0xffffff);
        enlargeEyesView.minLabel.font = [UIFont systemFontOfSize:15];
        enlargeEyesView.minLabel.text = @"";
        
        enlargeEyesView.maxLabel.textColor = UIColorFromRGB(0xffffff);
        enlargeEyesView.maxLabel.font = [UIFont systemFontOfSize:15];
        
        enlargeEyesView.slider.thumbTintColor = UIColorFromRGB(0x9e4fcb);
        enlargeEyesView.slider.minimumTrackTintColor = UIColorFromRGB(0x9e4fcb);
        enlargeEyesView.slider.maximumValue = 100;
        [enlargeEyesView.slider addTarget:self action:@selector(beautifySliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        enlargeEyesView.slider.tag = STViewTagEnlargeEyeSlider;
        _enlargeEyesView = enlargeEyesView;
        
        
        
        STSliderView *smallFaceView = [[[NSBundle mainBundle] loadNibNamed:@"STSliderView" owner:nil options:nil] firstObject];
        smallFaceView.frame = CGRectMake(0, 75, CGRectGetWidth(self.beautyContainerView.frame), 35);
        smallFaceView.backgroundColor = [UIColor clearColor];
        smallFaceView.imageView.image = [UIImage imageNamed:@"small_face.png"];
        smallFaceView.titleLabel.textColor = UIColorFromRGB(0xffffff);
        smallFaceView.titleLabel.font = [UIFont systemFontOfSize:11];
        smallFaceView.titleLabel.text = @"小脸";
        
        smallFaceView.minLabel.textColor = UIColorFromRGB(0xffffff);
        smallFaceView.minLabel.font = [UIFont systemFontOfSize:15];
        smallFaceView.minLabel.text = @"";
        
        smallFaceView.maxLabel.textColor = UIColorFromRGB(0xffffff);
        smallFaceView.maxLabel.font = [UIFont systemFontOfSize:15];
        
        smallFaceView.slider.thumbTintColor = UIColorFromRGB(0x9e4fcb);
        smallFaceView.slider.minimumTrackTintColor = UIColorFromRGB(0x9e4fcb);
        smallFaceView.slider.maximumValue = 100;
        [smallFaceView.slider addTarget:self action:@selector(beautifySliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        smallFaceView.slider.tag = STViewTagShrinkJawSlider;
        _smallFaceView = smallFaceView;
        
        [_beautyShapeView addSubview:thinFaceView];
        [_beautyShapeView addSubview:enlargeEyesView];
        [_beautyShapeView addSubview:smallFaceView];
        
        _beautyShapeView.hidden = YES;
        _beautyShapeView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    }
    return _beautyShapeView;
}

- (UIView *)beautyBaseView {
    
    if (!_beautyBaseView) {
        
        _beautyBaseView = [[[UIView alloc] initWithFrame:CGRectMake(0, 41, CGRectGetWidth(self.beautyContainerView.frame),(190 + container_view_height))] autorelease];
        
        STSliderView *dermabrasionView = [[[NSBundle mainBundle] loadNibNamed:@"STSliderView" owner:nil options:nil] firstObject];
        dermabrasionView.frame = CGRectMake(0, 5, CGRectGetWidth(self.beautyContainerView.frame), 35);
        dermabrasionView.backgroundColor = [UIColor clearColor];
        dermabrasionView.imageView.image = [UIImage imageNamed:@"mopi.png"];
        dermabrasionView.titleLabel.textColor = [UIColor whiteColor];
        dermabrasionView.titleLabel.font = [UIFont systemFontOfSize:11];
        dermabrasionView.titleLabel.text = @"磨皮";
        
        dermabrasionView.minLabel.textColor = UIColorFromRGB(0x555555);
        dermabrasionView.minLabel.font = [UIFont systemFontOfSize:15];
        dermabrasionView.minLabel.text = @"";
        
        dermabrasionView.maxLabel.textColor = [UIColor whiteColor];
        dermabrasionView.maxLabel.font = [UIFont systemFontOfSize:15];
        
        dermabrasionView.slider.thumbTintColor = UIColorFromRGB(0x9e4fcb);
        dermabrasionView.slider.minimumTrackTintColor = UIColorFromRGB(0x9e4fcb);
        dermabrasionView.slider.maximumValue = 100;
        [dermabrasionView.slider addTarget:self action:@selector(beautifySliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        dermabrasionView.slider.tag = STViewTagSmoothSlider;
        _dermabrasionView = dermabrasionView;
        
        
        STSliderView *ruddyView = [[[NSBundle mainBundle] loadNibNamed:@"STSliderView" owner:nil options:nil] firstObject];
        ruddyView.frame = CGRectMake(0, 40, CGRectGetWidth(self.beautyContainerView.frame), 35);
        ruddyView.backgroundColor = [UIColor clearColor];
        ruddyView.imageView.image = [UIImage imageNamed:@"hongrun.png"];
        ruddyView.titleLabel.textColor = [UIColor whiteColor];
        ruddyView.titleLabel.font = [UIFont systemFontOfSize:11];
        ruddyView.titleLabel.text = @"红润";
        
        ruddyView.minLabel.textColor = UIColorFromRGB(0x555555);
        ruddyView.minLabel.font = [UIFont systemFontOfSize:15];
        ruddyView.minLabel.text = @"";
        
        ruddyView.maxLabel.textColor = [UIColor whiteColor];
        ruddyView.maxLabel.font = [UIFont systemFontOfSize:15];
        
        ruddyView.slider.thumbTintColor = UIColorFromRGB(0x9e4fcb);
        ruddyView.slider.minimumTrackTintColor = UIColorFromRGB(0x9e4fcb);
        ruddyView.slider.maximumValue = 100;
        [ruddyView.slider addTarget:self action:@selector(beautifySliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        ruddyView.slider.tag = STViewTagReddenSlider;
        _ruddyView = ruddyView;
        
        
        STSliderView *whitenView = [[[NSBundle mainBundle] loadNibNamed:@"STSliderView" owner:nil options:nil] firstObject];
        whitenView.frame = CGRectMake(0, 75, CGRectGetWidth(self.beautyContainerView.frame), 40);
        whitenView.backgroundColor = [UIColor clearColor];
        whitenView.imageView.image = [UIImage imageNamed:@"meibai.png"];
        
        whitenView.titleLabel.textColor = [UIColor whiteColor];
        whitenView.titleLabel.font = [UIFont systemFontOfSize:11];
        whitenView.titleLabel.text = @"美白";
        
        whitenView.minLabel.textColor = UIColorFromRGB(0x555555);
        whitenView.minLabel.font = [UIFont systemFontOfSize:15];
        whitenView.minLabel.text = @"";
        
        whitenView.maxLabel.textColor = [UIColor whiteColor];
        whitenView.maxLabel.font = [UIFont systemFontOfSize:15];
        
        whitenView.slider.thumbTintColor = UIColorFromRGB(0x9e4fcb);
        whitenView.slider.minimumTrackTintColor = UIColorFromRGB(0x9e4fcb);
        whitenView.slider.maximumValue = 100;
        [whitenView.slider addTarget:self action:@selector(beautifySliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        whitenView.slider.tag = STViewTagWhitenSlider;
        _whitenView = whitenView;
        
        
        [_beautyBaseView addSubview:dermabrasionView];
        [_beautyBaseView addSubview:ruddyView];
        [_beautyBaseView addSubview:whitenView];
        
        _beautyBaseView.hidden = YES;
        _beautyBaseView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    }
    return _beautyBaseView;
}

//- (UIView *)settingView {
//
//    if (!_settingView) {
//        _settingView = [[UIView alloc] initWithFrame:CGRectMake(0, screen_height, screen_width, 230)];
//        _settingView.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.5];
//
//        [_settingView addSubview:self.resolutionLabel];
//        [_settingView addSubview:self.btn640x480];
//        [_settingView addSubview:self.btn1280x720];
//        [_settingView addSubview:self.attributeLabel];
//        [_settingView addSubview:self.attributeSwitch];
//    }
//    return _settingView;
//}



//- (UIButton *)btnSetting {
//
//    if (!_btnSetting) {
//
//        UIImage *image = [UIImage imageNamed:@"btn_setting_gray.png"];
//
//        _btnSetting = [[UIButton alloc] initWithFrame:CGRectMake(15, 7, image.size.width, image.size.height)];
//
//        [_btnSetting setImage:image forState:UIControlStateNormal];
//        [_btnSetting addTarget:self action:@selector(onBtnSetting) forControlEvents:UIControlEventTouchUpInside];
//    }
//    return _btnSetting;
//}

//- (STButton *)btnAlbum {
//
//    if (!_btnAlbum) {
//
//        UIImage *image = [UIImage imageNamed:@"btn_album"];
//
//        if ([[self getMobilePhoneModel] isEqualToString:@"iPhone10,3"]) {
//
//            _btnAlbum = [[STButton alloc] initWithFrame:CGRectMake(screen_width / 2 - image.size.width / 2, 30, image.size.width, image.size.height)];
//
//        } else {
//            _btnAlbum = [[STButton alloc] initWithFrame:CGRectMake(screen_width / 2 - image.size.width / 2, 12, image.size.width, image.size.height)];
//        }
//
//        [_btnAlbum setImage:image forState:UIControlStateNormal];
//        [_btnAlbum addTarget:self action:@selector(onBtnAlbum) forControlEvents:UIControlEventTouchUpInside];
//    }
//    return _btnAlbum;
//}

- (UIButton *)btnCompare {
   
    CGFloat buttonWidth = 50;
    CGFloat backViewHeight = buttonWidth*4;

    if (!_btnCompare) {
        
//        _btnCompare = [UIButton buttonWithType:UIButtonTypeCustom];
//        _btnCompare.frame = CGRectMake(screen_width - 80, screen_height - 150, 70, 35);
        _btnCompare = [[[UIButton alloc] initWithFrame:CGRectMake(screen_width - buttonWidth, (screen_height - backViewHeight)/2+55*1, 50, 50)] autorelease];
//        _btnCompare.backgroundColor = [UIColor redColor];
        [_btnCompare setTitle:@"对比" forState:UIControlStateNormal];
        _btnCompare.titleLabel.font = [UIFont systemFontOfSize:13.0];
        [_btnCompare setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _btnCompare.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
        _btnCompare.layer.cornerRadius = 5.0f;
        
        [_btnCompare addTarget:self action:@selector(onBtnCompareTouchDown:) forControlEvents:UIControlEventTouchDown];
        [_btnCompare addTarget:self action:@selector(onBtnCompareTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        [_btnCompare addTarget:self action:@selector(onBtnCompareTouchUpInside:) forControlEvents:UIControlEventTouchDragExit];
        
    }
    return _btnCompare;
}

//- (UILabel *)resolutionLabel {
//
//    CGRect bounds = [@"分辨率" boundingRectWithSize:CGSizeMake(MAXFLOAT, 0.0) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:15]} context:nil];
//
//
//    if (!_resolutionLabel) {
//        _resolutionLabel = [[UILabel alloc] initWithFrame:CGRectMake(45, 38, bounds.size.width, bounds.size.height)];
//        _resolutionLabel.text = @"分辨率";
//        _resolutionLabel.font = [UIFont systemFontOfSize:15];
//        _resolutionLabel.textColor = [UIColor whiteColor];
//    }
//    return _resolutionLabel;
//}

//- (UIButton *)btn640x480 {
//
//    if (!_btn640x480) {
//        _btn640x480 = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.resolutionLabel.frame) + 21, 30, 84, 35)];
//
//        _btn640x480.backgroundColor = [UIColor clearColor];
//        _btn640x480.layer.cornerRadius = 7;
//        _btn640x480.layer.borderColor = [UIColor whiteColor].CGColor;
//        [_btn640x480.layer addSublayer:self.btn640x480BorderLayer];
//
//
//        [_btn640x480 setTitle:@"640x480" forState:UIControlStateNormal];
//        [_btn640x480 setTitleColor:UIColorFromRGB(0x999999) forState:UIControlStateNormal];
//        _btn640x480.titleLabel.font = [UIFont systemFontOfSize:15];
//        _btn640x480.titleLabel.textAlignment = NSTextAlignmentCenter;
//
//        [_btn640x480 addTarget:self action:@selector(changeResolution:) forControlEvents:UIControlEventTouchUpInside];
//
//    }
//
//    return _btn640x480;
//}

//- (UIButton *)btn1280x720 {
//
//    if (!_btn1280x720) {
//
//        _btn1280x720 = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.btn640x480.frame) + 20, 30, 93, 35)];
//
//        _btn1280x720.backgroundColor = [UIColor whiteColor];
//        _btn1280x720.layer.cornerRadius = 7;
//        _btn1280x720.layer.borderColor = [UIColor whiteColor].CGColor;
//        _btn1280x720.layer.borderWidth = 1;
//        [_btn1280x720.layer addSublayer:self.btn1280x720BorderLayer];
//        self.btn1280x720BorderLayer.hidden = YES;
//
//        [_btn1280x720 setTitle:@"1280x720" forState:UIControlStateNormal];
//        [_btn1280x720 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//        _btn1280x720.titleLabel.font = [UIFont systemFontOfSize:15];
//        _btn1280x720.titleLabel.textAlignment = NSTextAlignmentCenter;
//
//        [_btn1280x720 addTarget:self action:@selector(changeResolution:) forControlEvents:UIControlEventTouchUpInside];
//
//    }
//    return _btn1280x720;
//}

//- (UILabel *)attributeLabel {
//
//    if (!_attributeLabel) {
//        _attributeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.resolutionLabel.frame) + 40, CGRectGetMaxX(self.resolutionLabel.frame), self.resolutionLabel.frame.size.height)];
//        _attributeLabel.text = @"性能数据";
//        _attributeLabel.textAlignment = NSTextAlignmentRight;
//        _attributeLabel.font = [UIFont systemFontOfSize:15];
//        _attributeLabel.textColor = [UIColor whiteColor];
//    }
//    return _attributeLabel;
//}

//- (UISwitch *)attributeSwitch {
//
//    if (!_attributeSwitch) {
//        _attributeSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(self.btn640x480.frame.origin.x, CGRectGetMaxY(self.btn640x480.frame) + 25, 79, 35)];
//        [_attributeSwitch addTarget:self action:@selector(onAttributeSwitch:) forControlEvents:UIControlEventValueChanged];
//    }
//    return _attributeSwitch;
//}

- (UILabel *)lblSaveStatus {
    
    if (!_lblSaveStatus) {
        
        _lblSaveStatus = [[[UILabel alloc] initWithFrame:CGRectMake((screen_width - 266) / 2, -44, 266, 44)] autorelease];
        [_lblSaveStatus setFont:[UIFont systemFontOfSize:18.0]];
        [_lblSaveStatus setTextAlignment:NSTextAlignmentCenter];
        [_lblSaveStatus setTextColor:UIColorFromRGB(0xffffff)];
        [_lblSaveStatus setBackgroundColor:UIColorFromRGB(0x000000)];
        
        _lblSaveStatus.layer.cornerRadius = 22;
        _lblSaveStatus.clipsToBounds = YES;
        _lblSaveStatus.alpha = 0.6;
        
        _lblSaveStatus.text = @"图片已保存到相册";
        _lblSaveStatus.hidden = YES;
    }
    
    return _lblSaveStatus;
}

- (STTriggerView *)triggerView {
    
    if (!_triggerView) {
        
        _triggerView = [[[STTriggerView alloc] init] autorelease];
    }
    
    return _triggerView;
}

//- (UILabel *)lblAttribute {
//
//    if (!_lblAttribute) {
//
//        _lblAttribute = [[[UILabel alloc] initWithFrame:CGRectMake(0, 60, screen_width, 15.0)] autorelease];
//        _lblAttribute.textAlignment = NSTextAlignmentCenter;
//        _lblAttribute.font = [UIFont systemFontOfSize:14.0];
//        _lblAttribute.numberOfLines = 0;
//        _lblAttribute.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
//        _lblAttribute.shadowOffset = CGSizeMake(0, 1.0);
//        _lblAttribute.backgroundColor = [UIColor clearColor];
//        _lblAttribute.textColor = [UIColor whiteColor];
//    }
//
//    return _lblAttribute;
//}

//- (UILabel *)lblSpeed {
//    if (!_lblSpeed) {
//
//        _lblSpeed = [[UILabel alloc] initWithFrame:CGRectMake(0, 60 ,screen_width, 15)];
//        _lblSpeed.textAlignment = NSTextAlignmentLeft;
//        [_lblSpeed setTextColor:[UIColor whiteColor]];
//        [_lblSpeed setBackgroundColor:[UIColor clearColor]];
//        [_lblSpeed setFont:[UIFont systemFontOfSize:15.0]];
//        [_lblSpeed setShadowColor:[UIColor blackColor]];
//        [_lblSpeed setShadowOffset:CGSizeMake(1.0, 1.0)];
//    }
//
//    return _lblSpeed;
//}

//- (UILabel *)lblCPU {
//
//    if (!_lblCPU) {
//
//        _lblCPU = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(_lblSpeed.frame), CGRectGetMaxY(_lblSpeed.frame) + 2 , CGRectGetWidth(_lblSpeed.frame), CGRectGetHeight(_lblSpeed.frame))];
//        _lblCPU.textAlignment = NSTextAlignmentLeft;
//        [_lblCPU setTextColor:[UIColor whiteColor]];
//        [_lblCPU setBackgroundColor:[UIColor clearColor]];
//        [_lblCPU setFont:[UIFont systemFontOfSize:15.0]];
//        [_lblCPU setShadowColor:[UIColor blackColor]];
//        [_lblCPU setShadowOffset:CGSizeMake(1.0, 1.0)];
//    }
//
//    return _lblCPU;
//}

//- (UILabel *)lblBodyAction {
//
//    if (!_lblBodyAction) {
//        _lblBodyAction = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.lblCPU.frame), CGRectGetMaxY(self.lblCPU.frame) + 2, screen_width, 15)];
//        _lblBodyAction.textAlignment = NSTextAlignmentLeft;
//        [_lblBodyAction setTextColor:[UIColor whiteColor]];
//        [_lblBodyAction setBackgroundColor:[UIColor clearColor]];
//        [_lblBodyAction setFont:[UIFont systemFontOfSize:15.0]];
//        [_lblBodyAction setShadowColor:[UIColor blackColor]];
//        [_lblBodyAction setShadowOffset:CGSizeMake(1.0, 1.0)];
//    }
//    return _lblBodyAction;
//}


//- (CAShapeLayer *)btn640x480BorderLayer {
//
//    if (!_btn640x480BorderLayer) {
//
//        _btn640x480BorderLayer = [CAShapeLayer layer];
//
//        _btn640x480BorderLayer.frame = self.btn640x480.bounds;
//        _btn640x480BorderLayer.strokeColor = [UIColor whiteColor].CGColor;
//        _btn640x480BorderLayer.fillColor = nil;
//        _btn640x480BorderLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.btn640x480.bounds cornerRadius:7].CGPath;
//        _btn640x480BorderLayer.lineWidth = 1;
//        _btn640x480BorderLayer.lineDashPattern = @[@4, @2];
//    }
//    return _btn640x480BorderLayer;
//}

//- (CAShapeLayer *)btn1280x720BorderLayer {
//
//    if (!_btn1280x720BorderLayer) {
//
//        _btn1280x720BorderLayer = [CAShapeLayer layer];
//
//        _btn1280x720BorderLayer.frame = self.btn1280x720.bounds;
//        _btn1280x720BorderLayer.strokeColor = [UIColor whiteColor].CGColor;
//        _btn1280x720BorderLayer.fillColor = nil;
//        _btn1280x720BorderLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.btn1280x720.bounds cornerRadius:7].CGPath;
//        _btn1280x720BorderLayer.lineWidth = 1;
//        _btn1280x720BorderLayer.lineDashPattern = @[@4, @2];
//    }
//    return _btn1280x720BorderLayer;
//}

- (UIImageView *)recordImageView {
    
    if (!_recordImageView) {
        
        UIImage *image = [UIImage imageNamed:@"record_video.png"];
        
        _recordImageView = [[[UIImageView alloc] initWithFrame:CGRectMake(self.gradientView.center.x - image.size.width / 2, CGRectGetMinY(self.gradientView.frame) - image.size.height, image.size.width, image.size.height)] autorelease];
        _recordImageView.image = image;
        _recordImageView.hidden = YES;
    }
    return _recordImageView;
}

//- (UILabel *)recordTimeLabel {
//
//    if (!_recordTimeLabel) {
//
//        _recordTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, screen_height - 100, 70, 35)];
//        _recordTimeLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
//        _recordTimeLabel.layer.cornerRadius = 5;
//        _recordTimeLabel.clipsToBounds = YES;
//        _recordTimeLabel.font = [UIFont systemFontOfSize:11];
//        _recordTimeLabel.textAlignment = NSTextAlignmentCenter;
//        _recordTimeLabel.textColor = [UIColor whiteColor];
//        _recordTimeLabel.text = @"• 00:00:00";
//        _recordTimeLabel.hidden = YES;
//    }
//
//    return _recordTimeLabel;
//}

- (UIView *)filterStrengthView {
    
    if (!_filterStrengthView) {
        
        _filterStrengthView = [[[UIView alloc] initWithFrame:CGRectMake((screen_width-container_view_width)/2, screen_height - 230 - 35.5, container_view_width-50, 35.5)] autorelease];
        _filterStrengthView.backgroundColor = [UIColor clearColor];
        _filterStrengthView.hidden = YES;
        
        UILabel *leftLabel = [[[UILabel alloc] initWithFrame:CGRectMake(20, 0, 10, 35.5)] autorelease];
        leftLabel.textColor = [UIColor whiteColor];
        leftLabel.font = [UIFont systemFontOfSize:11];
        leftLabel.text = @"0";
        [_filterStrengthView addSubview:leftLabel];
        
        UISlider *slider = [[[UISlider alloc] initWithFrame:CGRectMake(40, 0,CGRectGetWidth(_filterStrengthView.frame) - 90, 35.5)] autorelease];
        slider.thumbTintColor = UIColorFromRGB(0x9e4fcb);
        slider.minimumTrackTintColor = UIColorFromRGB(0x9e4fcb);
        slider.maximumTrackTintColor = [UIColor whiteColor];
        slider.value = 1;
        [slider addTarget:self action:@selector(filterSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        _filterStrengthSlider = slider;
        [_filterStrengthView addSubview:slider];
        
        UILabel *rightLabel = [[[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(_filterStrengthView.frame) - 40, 0, 20, 35.5)] autorelease];
        rightLabel.textColor = [UIColor whiteColor];
        rightLabel.font = [UIFont systemFontOfSize:11];
        rightLabel.text = @"100";
        _lblFilterStrength = rightLabel;
        [_filterStrengthView addSubview:rightLabel];
    }
    return _filterStrengthView;
}

#pragma mark - PhotoSelectVCDismissDelegate

- (void)photoSelectVCDidDismiss {
    [self initResource];
}

#pragma mark - scroll title click events

- (void)onTapNoneSticker:(UITapGestureRecognizer *)tapGesture {
    
    [self cancelStickerAndObjectTrack];
    
    self.noneStickerImageView.highlighted = YES;
}

- (void)cancelStickerAndObjectTrack {
    
    self.collectionView.selectedModel.isSelected = NO;
    self.objectTrackCollectionView.selectedModel.isSelected = NO;
    
    [self.collectionView reloadData];
    [self.objectTrackCollectionView reloadData];
    
    self.collectionView.selectedModel = nil;
    self.objectTrackCollectionView.selectedModel = nil;

    if (_hSticker) {
        self.isNullSticker = YES;
    }
    
    if (_hTracker) {
        
        if (self.commonObjectContainerView.currentCommonObjectView) {
            
            [self.commonObjectContainerView.currentCommonObjectView removeFromSuperview];
        }
    }
    
    self.bTracker = NO;
    
}

- (void)handleEffectsType:(STEffectsType)type {
    
    switch (type) {
            
        case STEffectsTypeSticker2D:
            self.objectTrackCollectionView.hidden = YES;
            self.collectionView.hidden = NO;
            self.collectionView.arrModels = self.arr2DStickers;
            [self.collectionView reloadData];
            break;
            
        case STEffectsTypeStickerFaceDeformation:
            self.objectTrackCollectionView.hidden = YES;
            self.collectionView.hidden = NO;
            self.collectionView.arrModels = self.arrFacedeformationStickers;
            [self.collectionView reloadData];
            break;
            
        case STEffectsTypeStickerSegment:
            self.objectTrackCollectionView.hidden = YES;
            self.collectionView.hidden = NO;
            self.collectionView.arrModels = self.arrSegmentStickers;
            [self.collectionView reloadData];
            break;
            
        case STEffectsTypeStickerGesture:
            self.objectTrackCollectionView.hidden = YES;
            self.collectionView.hidden = NO;
            self.collectionView.arrModels = self.arrGestureStickers;
            [self.collectionView reloadData];
            break;
            
        case STEffectsTypeSticker3D:
            self.objectTrackCollectionView.hidden = YES;
            self.collectionView.hidden = NO;
            self.collectionView.arrModels = self.arr3DStickers;
            [self.collectionView reloadData];
            break;
            
        case STEffectsTypeObjectTrack:
//            if (self.stCamera.devicePosition != AVCaptureDevicePositionBack) {
//                self.stCamera.devicePosition = AVCaptureDevicePositionBack;
//            }
            
            [self resetCommonObjectViewPosition];
            
            self.objectTrackCollectionView.arrModels = self.arrObjectTrackers;
            self.objectTrackCollectionView.hidden = NO;
            self.collectionView.hidden = YES;
            [self.objectTrackCollectionView reloadData];
            break;
            
        case STEffectsTypeStickerFaceChange:
            
            break;
        case STEffectsTypeBeautyFilter:
        {
            self.beautyBaseView.hidden = YES;
            self.beautyShapeView.hidden = YES;
            self.filterCategoryView.hidden = NO;
            self.filterView.hidden = NO;
            
            self.filterCategoryView.center = CGPointMake(CGRectGetWidth(self.filterCategoryView.frame) / 2, self.filterCategoryView.center.y);
            self.filterCategoryView.alpha = 1;
            self.filterView.center = CGPointMake(CGRectGetWidth(self.filterView.frame)/2, self.filterView.center.y);
            self.filterView.frame = CGRectMake(CGRectGetWidth(self.filterView.frame), self.filterView.frame.origin.y, CGRectGetWidth(self.filterView.frame),(190 + container_view_height));
            self.filterView.alpha = 0;
        }
            break;
            
        case STEffectsTypeNone:
            break;
            
        case STEffectsTypeBeautyShape:
        {
            [self hideBeautyViewExcept:self.beautyShapeView];
            self.filterStrengthView.hidden = YES;
        }
            break;
            
        case STEffectsTypeBeautyBase:
        {
            self.filterStrengthView.hidden = YES;
            [self hideBeautyViewExcept:self.beautyBaseView];
        }
            break;
            
        default:
            break;
    }
    
}

#pragma mark - collectionview click events

- (void)handleFilterChanged:(STCollectionViewDisplayModel *)model {
    
    self.currentSelectedFilterModel = model;
    
    self.lblFilterStrength.text = @"100";
    
    self.bFilter = model.index > 0;
    
    if (self.bFilter) {
        self.filterStrengthView.hidden = NO;
    } else {
        self.filterStrengthView.hidden = YES;
    }
    
    // 切换滤镜
    if (_hFilter) {
                
        self.pauseOutput = YES;
        
        // 切换滤镜不会修改强度 , 这里根据实际需求实现 , 这里重置为1.0.
        self.fFilterStrength = 1.0;
        self.filterStrengthSlider.value = 1.0;
        
        self.curFilterModelPath = model.strPath;
        [self refreshFilterCategoryState:model.modelType];
        st_result_t iRet = st_mobile_gl_filter_set_param(_hFilter, ST_GL_FILTER_STRENGTH, self.fFilterStrength);
        if (iRet != ST_OK) {
            STLog(@"st_mobile_gl_filter_set_param %d" , iRet);
        }
    }
    
    self.pauseOutput = NO;
}

- (void)handleObjectTrackChanged:(STCollectionViewDisplayModel *)model {
    
    if (self.collectionView.selectedModel || self.objectTrackCollectionView.selectedModel) {
        self.noneStickerImageView.highlighted = NO;
    } else {
        self.noneStickerImageView.highlighted = YES;
    }
    
    if (self.commonObjectContainerView.currentCommonObjectView) {
        [self.commonObjectContainerView.currentCommonObjectView removeFromSuperview];
    }
    _commonObjectViewSetted = NO;
    _commonObjectViewAdded = NO;
    
    if (model.isSelected) {
        UIImage *image = model.image;
        [self.commonObjectContainerView addCommonObjectViewWithImage:image];
        self.commonObjectContainerView.currentCommonObjectView.onFirst = YES;
        self.bTracker = YES;
    }
}

- (void)handleStickerChanged:(STCollectionViewDisplayModel *)model {
    
    if (self.collectionView.selectedModel || self.objectTrackCollectionView.selectedModel) {
        self.noneStickerImageView.highlighted = NO;
    } else {
        self.noneStickerImageView.highlighted = YES;
    }
    
    self.pauseOutput = YES;
    
    self.bSticker = YES;
    
    if ([EAGLContext currentContext] != self.glContext) {
        
        [EAGLContext setCurrentContext:self.glContext];
    }
    
    self.triggerView.hidden = YES;
    
    // 需要保证 SDK 的线程安全 , 顺序调用.
    dispatch_async(self.changeStickerQueue, ^{
        
        if (self.isNullSticker) {
            self.isNullSticker = NO;
        }
        
        // 获取触发动作类型
        unsigned long long iAction = 0;
        
        const char *stickerPath = [model.strPath UTF8String];
        
        if (!model.isSelected) {
            stickerPath = NULL;
        }
        
        st_result_t iRet = st_mobile_sticker_change_package(_hSticker, stickerPath);
        
        if (iRet != ST_OK) {
            
            STLog(@"st_mobile_sticker_change_package error %d" , iRet);
        }else{
            
            // 需要在 st_mobile_sticker_change_package 之后调用才可以获取新素材包的 trigger action .
            iRet = st_mobile_sticker_get_trigger_action(_hSticker, &iAction);
            
            if (ST_OK != iRet) {
                
                STLog(@"st_mobile_sticker_get_trigger_action error %d" , iRet);
                
                return;
            }
            
            if (0 != iAction) {//有 trigger信息
                if (CHECK_FLAG(iAction, ST_MOBILE_BROW_JUMP)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeMoveEyebrow];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_EYE_BLINK)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeBlink];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HEAD_YAW)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeTurnHead];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HEAD_PITCH)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeNod];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_MOUTH_AH)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeOpenMouse];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HAND_GOOD)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeHandGood];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HAND_PALM)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeHandPalm];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HAND_LOVE)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeHandLove];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HAND_HOLDUP)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeHandHoldUp];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HAND_CONGRATULATE)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeHandCongratulate];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HAND_FINGER_HEART)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeHandFingerHeart];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HAND_FINGER_INDEX)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeHandFingerIndex];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HAND_OK)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeHandOK];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HAND_SCISSOR)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeHandScissor];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HAND_PISTOL)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeHandPistol];
                }
            }
        }
        
        self.iCurrentAction = iAction;
    });
    
    self.strStickerPath = model.strPath;
    self.pauseOutput = NO;
}

#pragma mark - btn click events

- (void)onBtnSnap {
    self.needSnap = YES;
}

- (void)onBtnChangeCamera {
    
    [self resetCommonObjectViewPosition];
    
//    if (self.stCamera.devicePosition == AVCaptureDevicePositionFront) {
//        self.stCamera.devicePosition = AVCaptureDevicePositionBack;
//
//    } else {
//        self.stCamera.devicePosition = AVCaptureDevicePositionFront;
//    }
}

- (void)onBtnSetting {
    
    if (!_settingViewIsShow) {
        
        [self hideContainerView];
        [self hideBeautyContainerView];
        [self settingViewAppear];
        
    } else {
        [self hideSettingView];
    }
}

- (void)onBtnAlbum {
    [self cancelStickerAndObjectTrack];
    
    self.pauseOutput = YES;
//    [self.stCamera stopRunning];
    
//    dispatch_async(self.stCamera.bufferQueue, ^{
//        [self releaseResources];
//    });
    
//    self.stCamera = nil;
    
    [self hideSettingView];
    [self hideContainerView];
    [self hideBeautyContainerView];
    
//    PhotoSelectVC *photoVC = [[PhotoSelectVC alloc] init];
//    photoVC.delegate = self;
//
//    [photoVC setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
//
//    [self presentViewController:photoVC animated:YES completion:nil];
}

- (void)onAttributeSwitch:(UISwitch *)sender {
    self.bAttribute = sender.isOn;
}

- (void)clickBottomViewButton:(STViewButton *)senderView {

    switch (senderView.tag) {

        case STViewTagSpecialEffectsBtn:
            
            self.beautyBtn.userInteractionEnabled = NO;
            
            if (!self.specialEffectsContainerViewIsShow) {

                if (self.delegate && [self.delegate respondsToSelector:@selector(do_sense_set_ges:)]) {
                    [self.delegate do_sense_set_ges:NO];
                }
                [self hideSettingView];
                [self hideBeautyContainerView];
                [self containerViewAppear];
                
            } else {

                if (self.delegate && [self.delegate respondsToSelector:@selector(do_sense_set_ges:)]) {
                    [self.delegate do_sense_set_ges:YES];
                }
                [self hideContainerView];
            }
            
            self.beautyBtn.userInteractionEnabled = YES;
            
            break;
            
        case STViewTagBeautyBtn:
            
            self.specialEffectsBtn.userInteractionEnabled = NO;
            
            if (!self.beautyContainerViewIsShow) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(do_sense_set_ges:)]) {
                    [self.delegate do_sense_set_ges:NO];
                }

                [self hideSettingView];
                [self hideContainerView];
                [self beautyContainerViewAppear];
                
            } else {
                if (self.delegate && [self.delegate respondsToSelector:@selector(do_sense_set_ges:)]) {
                    [self.delegate do_sense_set_ges:YES];
                }
                [self hideBeautyContainerView];
            }

            self.specialEffectsBtn.userInteractionEnabled = YES;
            
            break;
    }
    
}

- (void)onBtnCompareTouchDown:(UIButton *)sender {
    [sender setTitleColor:[[UIColor blackColor] colorWithAlphaComponent:0.4] forState:UIControlStateNormal];
    self.isComparing = YES;
//    self.snapBtn.userInteractionEnabled = NO;
}

- (void)onBtnCompareTouchUpInside:(UIButton *)sender {
    [sender setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.isComparing = NO;
//    self.snapBtn.userInteractionEnabled = YES;
}

- (void)changeResolution:(UIButton *)sender {
    
//    self.pauseOutput = YES;
//
//    if (sender == _btn640x480) {
//
//        if (![self.stCamera.sessionPreset isEqualToString:AVCaptureSessionPreset640x480]) {
//
//            [self resetCommonObjectViewPosition];
//
//            [self.stCamera setSessionPreset:AVCaptureSessionPreset640x480];
//
//            self.currentSessionPreset = AVCaptureSessionPreset640x480;
//
//            self.btn640x480.backgroundColor = [UIColor whiteColor];
//            [self.btn640x480 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//            self.btn640x480.layer.borderWidth = 1;
//            self.btn640x480.layer.borderColor = [UIColor whiteColor].CGColor;
//            self.btn640x480BorderLayer.hidden = YES;
//
//            self.btn1280x720.backgroundColor = [UIColor clearColor];
//            [self.btn1280x720 setTitleColor:UIColorFromRGB(0x999999) forState:UIControlStateNormal];
//            self.btn1280x720.layer.borderWidth = 0;
//            self.btn1280x720BorderLayer.hidden = NO;
//
//            self.btn1280x720.enabled = NO;
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                self.btn1280x720.enabled = YES;
//            });
//        }
//    }
//
//    if (sender == _btn1280x720) {
//
//        if (![self.stCamera.sessionPreset isEqualToString:AVCaptureSessionPreset1280x720]) {
//
//            [self resetCommonObjectViewPosition];
//
//            [self.stCamera setSessionPreset:AVCaptureSessionPreset1280x720];
//
//            self.currentSessionPreset = AVCaptureSessionPreset1280x720;
//
//            self.btn1280x720.backgroundColor = [UIColor whiteColor];
//            [self.btn1280x720 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//            self.btn1280x720.layer.borderWidth = 1;
//            self.btn1280x720.layer.borderColor = [UIColor whiteColor].CGColor;
//            self.btn1280x720BorderLayer.hidden = YES;
//
//            self.btn640x480.backgroundColor = [UIColor clearColor];
//            [self.btn640x480 setTitleColor:UIColorFromRGB(0x999999) forState:UIControlStateNormal];
//            self.btn640x480.layer.borderWidth = 0;
//            self.btn640x480BorderLayer.hidden = NO;
//
//            self.btn640x480.enabled = NO;
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                self.btn640x480.enabled = YES;
//            });
//        }
//    }
//
//    [self changePreviewSize];
//
//    self.pauseOutput = NO;
}

- (void)addBodyModel {
    
    dispatch_async(self.changeModelQueue, ^{
        
        NSString *strBodyModelPath = [[NSBundle mainBundle] pathForResource:@"body" ofType:@"model"];
        st_result_t iRet = st_mobile_human_action_add_sub_model(_hDetector, strBodyModelPath.UTF8String);
        self.iCurrentAction |= ST_MOBILE_BODY_KEYPOINTS;
        if (iRet != ST_OK) {
            NSLog(@"st mobile human action add body model failed: %d", iRet);
        }
        
    });
    
}

- (void)deleteBodyModel {
    dispatch_async(self.changeModelQueue, ^{
        st_result_t iRet = st_mobile_human_action_remove_model_by_config(_hDetector, ST_MOBILE_ENABLE_BODY_KEYPOINTS);
        self.iCurrentAction &= ~ST_MOBILE_BODY_KEYPOINTS;
        if (iRet != ST_OK) {
            NSLog(@"st mobile human action remove body model failed: %d", iRet);
        }
    });
}

- (void)addFaceExtraModel {
    dispatch_async(self.changeModelQueue, ^{
        NSString *strFaceExtraModelPath = [[NSBundle mainBundle] pathForResource:@"M_SenseME_Face_Extra_5.1.0" ofType:@"model"];
        st_result_t iRet = st_mobile_human_action_add_sub_model(_hDetector, strFaceExtraModelPath.UTF8String);
        self.iCurrentAction |= ST_MOBILE_DETECT_EXTRA_FACE_POINTS;
        if (iRet != ST_OK) {
            NSLog(@"st mobile human action add face extra model failed: %d", iRet);
        }
        
    });
}

- (void)deleteFaceExtraModel {
    
    dispatch_async(self.changeModelQueue, ^{
        st_result_t iRet = st_mobile_human_action_remove_model_by_config(_hDetector, ST_MOBILE_ENABLE_FACE_EXTRA_DETECT);
        self.iCurrentAction &= ~ST_MOBILE_DETECT_EXTRA_FACE_POINTS;
        if (iRet != ST_OK) {
            NSLog(@"st mobile human action remove face extra model failed: %d", iRet);
        }
    });
}

- (void)addEyeIrisModel {
    
    dispatch_async(self.changeModelQueue, ^{
        
        NSString *strEyeIrisModel = [[NSBundle mainBundle] pathForResource:@"M_SenseME_Iris_1.7.0" ofType:@"model"];
        st_result_t iRet = st_mobile_human_action_add_sub_model(_hDetector, strEyeIrisModel.UTF8String);
        self.iCurrentAction |= ST_MOBILE_DETECT_EYEBALL_CONTOUR;
        if (iRet != ST_OK) {
            NSLog(@"st mobile human action add eye iris model failed: %d", iRet);
        }
    });
}

- (void)deleteEyeIrisModel {
    
    dispatch_async(self.changeModelQueue, ^{
        st_result_t iRet = st_mobile_human_action_remove_model_by_config(_hDetector, ST_MOBILE_ENABLE_EYEBALL_CONTOUR_DETECT);
        self.iCurrentAction &= ~ST_MOBILE_DETECT_EYEBALL_CONTOUR;
        if (iRet != ST_OK) {
            NSLog(@"st mobile human action remove eye iris model failed: %d", iRet);
        }
    });
}

- (void)addHandModel {
    
    dispatch_async(self.changeModelQueue, ^{
        
        NSString *strHandModelPath = [[NSBundle mainBundle] pathForResource:@"M_SenseME_Hand_5.0.0" ofType:@"model"];
        st_result_t iRet = st_mobile_human_action_add_sub_model(_hDetector, strHandModelPath.UTF8String);
        self.iCurrentAction |= ST_MOBILE_HAND_DETECT_FULL;
        if (iRet != ST_OK) {
            NSLog(@"st mobile human action add hand model failed: %d", iRet);
        }
    });
    
}

- (void)delHandModel {
    dispatch_async(self.changeModelQueue, ^{
        st_result_t iRet = st_mobile_human_action_remove_model_by_config(_hDetector, ST_MOBILE_ENABLE_HAND_DETECT);
        self.iCurrentAction &= ~ST_MOBILE_HAND_DETECT_FULL;
        if (iRet != ST_OK) {
            NSLog(@"st mobile human action remove hand model failed: %d", iRet);
        }
    });
}

#pragma mark - get models

- (NSArray *)getStickerModelsByType:(STEffectsType)type {
    
    NSArray *stickerZipPaths = [STParamUtil getStickerPathsByType:type];
    
    NSMutableArray *arrModels = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < stickerZipPaths.count; i ++) {
        
        STCollectionViewDisplayModel *model = [[[STCollectionViewDisplayModel alloc] init] autorelease];
        model.strPath = stickerZipPaths[i];
        
        UIImage *thumbImage = [UIImage imageWithContentsOfFile:[[model.strPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"]];
        model.image = thumbImage ? thumbImage : [UIImage imageNamed:@"none.png"];
        model.strName = @"";
        model.index = i;
        model.isSelected = NO;
        model.modelType = type;
        
        [arrModels addObject:model];
    }
    return arrModels;
}

- (NSArray *)getFilterModelsByType:(STEffectsType)type {
    
    NSArray *filterModelPath = [STParamUtil getFilterModelPathsByType:type];
    
    NSMutableArray *arrModels = [[NSMutableArray alloc] init];
    
    NSString *natureImageName = @"";
    switch (type) {
        case STEffectsTypeFilterDeliciousFood:
            natureImageName = @"nature_food";
            break;
            
        case STEffectsTypeFilterStillLife:
            natureImageName = @"nature_stilllife";
            break;
            
        case STEffectsTypeFilterScenery:
            natureImageName = @"nature_scenery";
            break;
            
        case STEffectsTypeFilterPortrait:
            natureImageName = @"nature_portrait";
            break;
            
        default:
            break;
    }
    
    STCollectionViewDisplayModel *model1 = [[[STCollectionViewDisplayModel alloc] init] autorelease];
    model1.strPath = NULL;
    model1.strName = @"original";
    model1.image = [UIImage imageNamed:natureImageName];
    model1.index = 0;
    model1.isSelected = NO;
    model1.modelType = STEffectsTypeNone;
    [arrModels addObject:model1];
    
    for (int i = 1; i < filterModelPath.count + 1; ++i) {
        
        STCollectionViewDisplayModel *model = [[[STCollectionViewDisplayModel alloc] init] autorelease];
        model.strPath = filterModelPath[i - 1];
        model.strName = [[model.strPath.lastPathComponent stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"filter_style_" withString:@""];
        
        UIImage *thumbImage = [UIImage imageWithContentsOfFile:[[model.strPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"]];
        
        model.image = thumbImage ?: [UIImage imageNamed:@"none"];
        model.index = i;
        model.isSelected = NO;
        model.modelType = type;
        
        [arrModels addObject:model];
    }
    return arrModels;
}

- (NSArray *)getObjectTrackModels {
    
    NSMutableArray *arrModels = [[NSMutableArray alloc] init];
    
    NSArray *arrImageNames = @[@"object_track_happy", @"object_track_hi", @"object_track_love", @"object_track_star", @"object_track_sticker", @"object_track_sun"];
        
    for (int i = 0; i < arrImageNames.count; ++i) {
            
        STCollectionViewDisplayModel *model = [[[STCollectionViewDisplayModel alloc] init] autorelease];
        model.strPath = NULL;
        model.strName = @"";
        model.index = i;
        model.isSelected = NO;
        model.image = [UIImage imageNamed:arrImageNames[i]];
        model.modelType = STEffectsTypeObjectTrack;
        
        [arrModels addObject:model];
    }
    
    return arrModels;
}

#pragma mark - help function

- (NSString*)getMobilePhoneModel
{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    if ([deviceString isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([deviceString isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([deviceString isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([deviceString isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([deviceString isEqualToString:@"iPhone3,2"])    return @"Verizon iPhone 4";
    if ([deviceString isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([deviceString isEqualToString:@"iPhone5,1"])    return @"iPhone 5";
    if ([deviceString isEqualToString:@"iPhone5,2"])    return @"iPhone 5";
    if ([deviceString isEqualToString:@"iPhone5,3"])    return @"iPhone 5C";
    if ([deviceString isEqualToString:@"iPhone5,4"])    return @"iPhone 5C";
    if ([deviceString isEqualToString:@"iPhone6,1"])    return @"iPhone 5S";
    if ([deviceString isEqualToString:@"iPhone6,2"])    return @"iPhone 5S";
    if ([deviceString isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
    if ([deviceString isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    if ([deviceString isEqualToString:@"iPhone8,1"])    return @"iPhone 6s";
    if ([deviceString isEqualToString:@"iPhone8,2"])    return @"iPhone 6s Plus";
    if ([deviceString isEqualToString:@"iPhone9,1"] || [deviceString isEqualToString:@"iPhone9,3"])    return @"iPhone 7";
    if ([deviceString isEqualToString:@"iPhone9,2"] || [deviceString isEqualToString:@"iPhone9,4"])    return @"iPhone 7 Plus";
    if ([deviceString isEqualToString:@"iPhone10,1"] || [deviceString isEqualToString:@"iPhone10,4"])    return @"iPhone 8";
    if ([deviceString isEqualToString:@"iPhone10,2"] || [deviceString isEqualToString:@"iPhone10,5"])    return @"iPhone 8 Plus";
    if ([deviceString isEqualToString:@"iPhone10,3"] || [deviceString isEqualToString:@"iPhone10,6"])    return @"iPhone X";
    return @"";
}

- (NSArray *)getNormalImages {
    
    NSMutableArray *res = [[NSMutableArray alloc] init];
    
    UIImage *sticker2d = [UIImage imageNamed:@"2d.png"];
    UIImage *sticker3d = [UIImage imageNamed:@"3d.png"];
    UIImage *stickerGesture = [UIImage imageNamed:@"sticker_gesture.png"];
    UIImage *stickerSegment = [UIImage imageNamed:@"sticker_segment.png"];
    UIImage *stickerDeformation = [UIImage imageNamed:@"sticker_face_deformation.png"];
    UIImage *objectTrack = [UIImage imageNamed:@"common_object_track.png"];
    
    [res addObject:sticker2d];
    [res addObject:sticker3d];
    [res addObject:stickerGesture];
    [res addObject:stickerSegment];
    [res addObject:stickerDeformation];
    [res addObject:objectTrack];
    
    return res;
}

- (NSArray *)getSelectedImages {
    
    NSMutableArray *res = [[NSMutableArray alloc] init];
    
    UIImage *sticker2d = [UIImage imageNamed:@"2d_selected.png"];
    UIImage *sticker3d = [UIImage imageNamed:@"3d_selected.png"];
    UIImage *stickerGesture = [UIImage imageNamed:@"sticker_gesture_selected.png"];
    UIImage *stickerSegment = [UIImage imageNamed:@"sticker_segment_selected.png"];
    UIImage *stickerDeformation = [UIImage imageNamed:@"sticker_face_deformation_selected.png"];
    UIImage *objectTrack = [UIImage imageNamed:@"common_object_track_selected.png"];

    [res addObject:sticker2d];
    [res addObject:sticker3d];
    [res addObject:stickerGesture];
    [res addObject:stickerSegment];
    [res addObject:stickerDeformation];
    [res addObject:objectTrack];

    return res;
}

- (CGFloat)layoutWidthWithValue:(CGFloat)value {
    
    return (value / 750) * screen_width;
}

- (CGFloat)layoutHeightWithValue:(CGFloat)value {
    
    return (value / 1334) * screen_height;
}

#pragma mark - lazy load array

- (NSArray *)arr2DStickers {
    if (!_arr2DStickers) {
        _arr2DStickers = [self getStickerModelsByType:STEffectsTypeSticker2D];
    }
    return _arr2DStickers;
}

- (NSArray *)arr3DStickers {
    if (!_arr3DStickers) {
        _arr3DStickers = [self getStickerModelsByType:STEffectsTypeSticker3D];
    }
    return _arr3DStickers;
}

- (NSArray *)arrGestureStickers {
    if (!_arrGestureStickers) {
        _arrGestureStickers = [self getStickerModelsByType:STEffectsTypeStickerGesture];
    }
    return _arrGestureStickers;
}

- (NSArray *)arrSegmentStickers {
    if (!_arrSegmentStickers) {
        _arrSegmentStickers = [self getStickerModelsByType:STEffectsTypeStickerSegment];
    }
    return _arrSegmentStickers;
}

- (NSArray *)arrFacedeformationStickers {
    if (!_arrFacedeformationStickers) {
        _arrFacedeformationStickers = [self getStickerModelsByType:STEffectsTypeStickerFaceDeformation];
    }
    return _arrFacedeformationStickers;
}

- (NSArray *)arrObjectTrackers {
    if (!_arrObjectTrackers) {
        _arrObjectTrackers = [self getObjectTrackModels];
    }
    return _arrObjectTrackers;
}

- (NSMutableArray *)arrBeautyViews {
    if (!_arrBeautyViews) {
        _arrBeautyViews = [[NSMutableArray alloc] init];
    }
    return _arrBeautyViews;
}

- (NSMutableArray *)arrFilterCategoryViews {
    
    if (!_arrFilterCategoryViews) {
        
        _arrFilterCategoryViews = [[NSMutableArray alloc] init];
    }
    return _arrFilterCategoryViews;
}

#pragma mark - touch events

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
//    UITouch *touch = [touches anyObject];
//
//    CGPoint point = [touch locationInView:self.view];
//
//
//    if (self.specialEffectsContainerViewIsShow) {
//
//        if (!CGRectContainsPoint(CGRectMake(0, screen_height - 230, screen_width, 230), point)) {
//
//            [self hideContainerView];
//        }
//    }
//
//    if (self.beautyContainerViewIsShow) {
//
//        if (!CGRectContainsPoint(CGRectMake(0, screen_height - 230, screen_width, 230), point)) {
//
//            [self hideBeautyContainerView];
//        }
//    }
//
//    if (self.settingViewIsShow) {
//
//        if (!CGRectContainsPoint(CGRectMake(0, screen_height - 230, screen_width, 230), point)) {
//
//            [self hideSettingView];
//        }
//    }
}

#pragma mark - animations

- (void)hideContainerView {
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        self.specialEffectsContainerView.frame = CGRectMake((screen_width-container_view_width)/2, screen_height + container_view_space_height, container_view_width,(190 + container_view_height));
//        self.btnCompare.frame = CGRectMake(screen_width - 80, screen_height - 150, 70, 35);
        
    } completion:^(BOOL finished) {
        self.specialEffectsContainerViewIsShow = NO;
    }];
    
    self.specialEffectsBtn.highlighted = NO;
}

- (void)containerViewAppear {
    
    self.filterStrengthView.hidden = YES;
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        self.specialEffectsContainerView.frame = CGRectMake((screen_width-container_view_width)/2, (screen_height + container_view_space_height) - (190 + container_view_height), container_view_width,(190 + container_view_height));
//        self.btnCompare.frame = CGRectMake(screen_width - 80, screen_height - 280 - 35.5, 70, 35);
    } completion:^(BOOL finished) {
        self.specialEffectsContainerViewIsShow = YES;
    }];
    self.specialEffectsBtn.highlighted = YES;
    
}

- (void)hideBeautyContainerView {
    
    self.filterStrengthView.hidden = YES;
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        self.beautyContainerView.frame = CGRectMake((screen_width-container_view_width)/2, (screen_height + container_view_space_height), container_view_width,(190 + container_view_height));
//        self.btnCompare.frame = CGRectMake(screen_width - 80, screen_height - 150, 70, 35);
        
    } completion:^(BOOL finished) {
        self.beautyContainerViewIsShow = NO;
    }];
    
    self.beautyBtn.highlighted = NO;
}

- (void)beautyContainerViewAppear {
    
    self.filterCategoryView.center = CGPointMake(CGRectGetWidth(self.filterCategoryView.frame) / 2, self.filterCategoryView.center.y);
    self.filterCategoryView.alpha = 1;
    self.filterView.center = CGPointMake(CGRectGetWidth(self.filterCategoryView.frame) * 3 / 2, self.filterView.center.y);
    self.filterView.alpha = 0;
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.beautyContainerView.frame = CGRectMake((screen_width-container_view_width)/2, (screen_height + container_view_space_height) -(190 + container_view_height), container_view_width,(190 + container_view_height));
//        self.btnCompare.frame = CGRectMake(screen_width - 80, screen_height - 280 - 35.5, 70, 35);
    } completion:^(BOOL finished) {
        self.beautyContainerViewIsShow = YES;
    }];
    self.beautyBtn.highlighted = YES;
}

- (void)settingViewAppear {
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//        self.settingView.frame = CGRectMake(0, screen_height - 230, screen_width, 230);
//        self.btnCompare.frame = CGRectMake(screen_width - 80, screen_height - 280 - 35.5, 70, 35);
    } completion:^(BOOL finished) {
        self.settingViewIsShow = YES;
    }];
}

- (void)hideSettingView {
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
//        self.settingView.frame = CGRectMake(0, screen_height, screen_width, 230);
//        self.btnCompare.frame = CGRectMake(screen_width - 80, screen_height - 150, 70, 35);
        
    } completion:^(BOOL finished) {
        self.settingViewIsShow = NO;
    }];
}

- (void)hideBeautyViewExcept:(UIView *)view {
    
    for (UIView *beautyView in self.arrBeautyViews) {
        
        beautyView.hidden = !(view == beautyView);
    }
}

#pragma mark - STViewButtonDelegate

- (void)btnLongPressEnd {
//    NSLog(@"stviewbtn long press ended");
    
    if (![self checkMediaStatus:AVMediaTypeVideo]) {
        return;
    }
    
    if (self.recording) {
        
//        [self.timer stop];
//        [self.timer reset];
        
        self.recording = NO;
        self.recordImageView.hidden = YES;
        
//        self.recordTimeLabel.hidden = YES;
        
        self.filterStrengthView.hidden = self.filterStrengthViewHiddenState;
        self.specialEffectsBtn.hidden = NO;
        self.beautyBtn.hidden = NO;
//        self.btnAlbum.hidden = NO;
//        self.btnSetting.hidden = NO;
//        self.btnChangeCamera.hidden = NO;
        self.btnCompare.hidden = NO;
        self.beautyContainerView.hidden = NO;
        self.specialEffectsContainerView.hidden = NO;
//        self.settingView.hidden = NO;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self stopRecorder];
        });
    }
}

- (void)btnLongPressBegin {
    
//    NSLog(@"stviewbtn long press begin");
    
    if (![self checkMediaStatus:AVMediaTypeVideo]) {
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"没有相机权限无法录制视频" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
//        [alertView show];
        return;
    }
    
    self.recordImageView.hidden = NO;
    
//    self.recordTimeLabel.hidden = NO;
    
    self.filterStrengthViewHiddenState = self.filterStrengthView.isHidden;
    self.filterStrengthView.hidden = YES;
    self.specialEffectsBtn.hidden = YES;
    self.beautyBtn.hidden = YES;
//    self.btnAlbum.hidden = YES;
//    self.btnSetting.hidden = YES;
//    self.btnChangeCamera.hidden = YES;
    self.btnCompare.hidden = YES;
    self.beautyContainerView.hidden = YES;
    self.specialEffectsContainerView.hidden = YES;
//    self.settingView.hidden = YES;
    
//    [self.timer start];
    
    @synchronized (self) {
        
        if (self.recordStatus != STWriterRecordingStatusIdle) {
            
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Already recording" userInfo:nil];
            return;
        }
        
        self.recordStatus = STWriterRecordingStatusStartingRecording;
        
        _callBackQueue = dispatch_queue_create("com.sensetime.recordercallback", DISPATCH_QUEUE_SERIAL);
        
//        STMovieRecorder *recorder = [[STMovieRecorder alloc] initWithURL:self.recorderURL delegate:self callbackQueue:_callBackQueue];
        
        if ([self checkMediaStatus:AVMediaTypeVideo]) {
            
//            [recorder addVideoTrackWithSourceFormatDescription:self.outputVideoFormatDescription transform:CGAffineTransformIdentity settings:self.stCamera.videoCompressingSettings];
        }
        
        if ([self checkMediaStatus:AVMediaTypeAudio]) {
//            [recorder addAudioTrackWithSourceFormatDescription:self.outputAudioFormatDescription settings:self.audioManager.audioCompressingSettings];
        }
        
//        _stRecoder = recorder;
        
        self.recording = YES;
        
//        [_stRecoder prepareToRecord];
        
        self.recordStartTime = CFAbsoluteTimeGetCurrent();
        //    NSLog(@"st_effects_recored_time start: %f", self.recordStartTime);
        
    }
}

#pragma mark - STCommonObjectContainerViewDelegate

- (void)commonObjectViewStartTrackingFrame:(CGRect)frame {
    
    _commonObjectViewAdded = YES;
    _commonObjectViewSetted = NO;
    
    CGRect rect = frame;
    _rect.left = (rect.origin.x + _margin) / _scale;
    _rect.top = rect.origin.y / _scale;
    _rect.right = (rect.origin.x + rect.size.width + _margin) / _scale;
    _rect.bottom = (rect.origin.y + rect.size.height) / _scale;
    
}

- (void)commonObjectViewFinishTrackingFrame:(CGRect)frame {
    _commonObjectViewAdded = NO;
}

#pragma mark - STMovieRecorderDelegate
//
//- (void)movieRecorder:(STMovieRecorder *)recorder didFailWithError:(NSError *)error {
//
//    @synchronized (self) {
//
//        self.stRecoder = nil;
//
//        self.recordStatus = STWriterRecordingStatusIdle;
//    }
//
//    NSLog(@"movie recorder did fail with error: %@", error.localizedDescription);
//}
//
//- (void)movieRecorderDidFinishPreparing:(STMovieRecorder *)recorder {
//
//    @synchronized(self) {
//        if (_recordStatus != STWriterRecordingStatusStartingRecording) {
//            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Expected to be in StartingRecording state" userInfo:nil];
//            return;
//        }
//
//        self.recordStatus = STWriterRecordingStatusRecording;
//    }
//}
//
//- (void)movieRecorderDidFinishRecording:(STMovieRecorder *)recorder {
//
//    @synchronized(self) {
//
//        if (_recordStatus != STWriterRecordingStatusStoppingRecording) {
//            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Expected to be in StoppingRecording state" userInfo:nil];
//            return;
//        }
//
//        self.recordStatus = STWriterRecordingStatusIdle;
//    }
//
//    _stRecoder = nil;
//
//    self.recording = NO;
//
//    double recordTime = CFAbsoluteTimeGetCurrent() - self.recordStartTime;
////    NSLog(@"st_effects_recored_time end: %f", recordTime);
//
//    dispatch_async(dispatch_get_main_queue(), ^{
//
//        if (recordTime < 2.0) {
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"视频录制时间小于2s，请重新录制" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
//            [alert show];
//        } else {
//
//            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//
//            [library writeVideoAtPathToSavedPhotosAlbum:_recorderURL completionBlock:^(NSURL *assetURL, NSError *error) {
//
//                [[NSFileManager defaultManager] removeItemAtURL:_recorderURL error:NULL];
//
//                self.lblSaveStatus.text = @"视频已存储到相册";
//                [self showAnimationIfSaved:YES];
//
//            }];
//        }
//    });
//}
//
//#pragma mark - STEffectsMessageManagerDelegate
//
//- (void)loadSound:(NSData *)soundData name:(NSString *)strName {
//
//    if ([self.audioPlayer loadSound:soundData name:strName]) {
//        NSLog(@"STEffectsAudioPlayer load %@ successfully", strName);
//    }
//}
//
//- (void)playSound:(NSString *)strName loop:(int)iLoop {
//
//    if ([self.audioPlayer playSound:strName loop:iLoop]) {
//        NSLog(@"STEffectsAudioPlayer play %@ successfully", strName);
//    }
//}
//
//- (void)stopSound:(NSString *)strName {
//
//    [self.audioPlayer stopSound:strName];
//}
//
//#pragma mark - STEffectsAudioPlayerDelegate
//
//- (void)audioPlayerDidFinishPlaying:(STEffectsAudioPlayer *)player successfully:(BOOL)flag name:(NSString *)strName {
//
//    if (_hSticker) {
//
//        st_mobile_sticker_set_sound_completed(_hSticker, [strName UTF8String]);
//    }
//}

#pragma mark - STEffectsTimerDelegate

//- (void)effectsTimer:(STEffectsTimer *)timer currentRecordHour:(int)hours minutes:(int)minutes seconds:(int)seconds {
//
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.recordTimeLabel.text = [NSString stringWithFormat:@"• %02d:%02d:%02d", hours, minutes, seconds];
//    });
//}

#pragma mark - 

- (void)stopRecorder {
    
    @synchronized (self) {
        
        if (self.recordStatus != STWriterRecordingStatusRecording) {
            return;
        }
        
        self.recordStatus = STWriterRecordingStatusStoppingRecording;
        
//        [_stRecoder finishRecording];
    }
}

- (void)resetCommonObjectViewPosition {
    if (self.commonObjectContainerView.currentCommonObjectView) {
        _commonObjectViewSetted = NO;
        _commonObjectViewAdded = NO;
        self.commonObjectContainerView.currentCommonObjectView.hidden = NO;
        self.commonObjectContainerView.currentCommonObjectView.onFirst = YES;
        self.commonObjectContainerView.currentCommonObjectView.center = CGPointMake(screen_width / 2, screen_height / 2);
    }
}

- (void)resetSettings {
    
    self.noneStickerImageView.highlighted = YES;
    self.lblFilterStrength.text = @"100";
    self.filterStrengthSlider.value = 1;
    
    self.currentSelectedFilterModel.isSelected = NO;
    [self refreshFilterCategoryState:STEffectsTypeNone];
    
    self.fSmoothStrength = 0.74;
    self.fReddenStrength = 0.36;
    self.fWhitenStrength = 0.30;
    self.fEnlargeEyeStrength = 0.13;
    self.fShrinkFaceStrength = 0.11;
    self.fShrinkJawStrength = 0.10;
    
    self.thinFaceView.slider.value = 11;
    self.thinFaceView.maxLabel.text = @"11";
    
    self.enlargeEyesView.slider.value = 13;
    self.enlargeEyesView.maxLabel.text = @"13";
    
    self.smallFaceView.slider.value = 10;
    self.smallFaceView.maxLabel.text = @"10";
    
    self.dermabrasionView.slider.value = 74;
    self.dermabrasionView.maxLabel.text = @"74";
    
    self.ruddyView.slider.value = 36;
    self.ruddyView.maxLabel.text = @"36";
    
    self.whitenView.slider.value = 30;
    self.whitenView.maxLabel.text = @"30";
    
    self.preFilterModelPath = nil;
    self.curFilterModelPath = nil;
    
}

- (BOOL)checkMediaStatus:(NSString *)mediaType {
//    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    
    BOOL res = true;
//
//    switch (authStatus) {
//        case AVAuthorizationStatusNotDetermined:
//        case AVAuthorizationStatusDenied:
//        case AVAuthorizationStatusRestricted:
//            res = NO;
//            break;
//        case AVAuthorizationStatusAuthorized:
//            res = YES;
//            break;
//    }
    return res;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}



@end
