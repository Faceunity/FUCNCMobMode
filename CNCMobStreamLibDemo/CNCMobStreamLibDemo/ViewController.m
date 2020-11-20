//
//  ViewController.m
//  CNCMobStreamLibDemo
//
//  Created by mfm on 16/5/19.
//  Copyright © 2016年 chinanetcenter. All rights reserved.
//

#import "ViewController.h"
#import "CNCRecorderMenuViewController.h"
#import "CNCDemoVideoCaptureMenuViewController.h"
#import "CNCLayeredMenuViewController.h"
#import "MBProgressHUD.h"

#import "CommonInclude.h"

@interface ViewController () <UIAlertViewDelegate, UIGestureRecognizerDelegate,UITextFieldDelegate> {
    
}

///是否已鉴权
@property (nonatomic, assign, getter=isAuth) BOOL auth;


//纯属方便测试 非DEMO业务代码
@property(nonatomic, retain) UITextField *loader_textfield;
@property(nonatomic, retain) UIButton *loader_btn;
@property(nonatomic, retain) UIButton *speak_btn;
@property(nonatomic, retain) UIButton *audio_mode_btn;
//鉴权
@property(nonatomic, retain) UITextField *auth_textfield_appid;
@property(nonatomic, retain) UITextField *auth_textfield_authkey;
@property(nonatomic, retain) UIScrollView *scroll_view;
@end

@implementation ViewController
{
    int select_index;//是否开启分层测试
    CGFloat screen_w_;
    CGFloat screen_h_;
    CGFloat scroll_view_content_size_height;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.auth = NO;
    select_index = 0;
    CGFloat fw = [UIScreen mainScreen].bounds.size.width;
    CGFloat fh = [UIScreen mainScreen].bounds.size.height;
    
    screen_h_ = (fw > fh) ? fw : fh;
    screen_w_ = (fw < fh) ? fw : fh;
    self.scroll_view = [[[UIScrollView alloc] init] autorelease];
    self.scroll_view.frame = CGRectMake(0, 90, screen_w_, screen_h_-90);
    self.scroll_view.backgroundColor = [UIColor clearColor];
    self.scroll_view.clipsToBounds = YES;
    self.scroll_view.bounces = NO;
    [self.view addSubview:self.scroll_view];
#ifdef CNC_NewInterface
    select_index = 2;
    [self init_NewInterface_view];
#else
    [self init_view];
#endif
    
    scroll_view_content_size_height = CGRectGetHeight(self.scroll_view.frame);
    [self.scroll_view setContentSize:CGSizeMake(CGRectGetWidth(self.scroll_view.frame), scroll_view_content_size_height)];
    [self add_gesture_recognizer];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^(){
        [self copy_res_to_music_path];
        [self copy_res_to_wather_path];
        [self copy_res_to_questions_path];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)init_view {
    self.title = @"网宿推流LibDemo";
    CGFloat screen_w = [[ UIScreen mainScreen ] bounds ].size.width;
    
    CGFloat fy = 100;
    
//    {
//        UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//        [btn addTarget:self action:@selector(actionPlayTest:) forControlEvents:UIControlEventTouchUpInside];
//        btn.frame = CGRectMake((kMScreenW-200)/2, fy, 200, 35);
//        [btn setTitle:@"播放测试" forState:UIControlStateNormal];
//        [self.view addSubview:btn];
//        
//        
//    }
//    
//    
//    fy += 60;
    
    {
        UILabel *label = [[[UILabel alloc] init] autorelease];
        label.frame = CGRectMake(0, fy, screen_w, 11);;
        label.layer.cornerRadius = 5;
        label.font = [UIFont systemFontOfSize:10];
        label.backgroundColor = [UIColor grayColor];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = @"SDK完整封装采集编码推流";
        [self.view addSubview:label];
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [btn addTarget:self action:@selector(actionRecordTest:) forControlEvents:UIControlEventTouchUpInside];
        btn.frame = CGRectMake((screen_w-200)/2, fy+9, 200, 35);
        [btn setTitle:@"推流测试" forState:UIControlStateNormal];
        [self.view addSubview:btn];
        
        //        fy += 50;
    }
    
    fy += 50;
    {
        UILabel *label = [[[UILabel alloc] init] autorelease];
        label.frame = CGRectMake(0, fy, screen_w, 11);;
        label.layer.cornerRadius = 5;
        label.font = [UIFont systemFontOfSize:10];
        label.backgroundColor = [UIColor grayColor];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = @"APP自定义采集+SDK编码推流";
        [self.view addSubview:label];
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [btn addTarget:self action:@selector(actionLayeredTest:) forControlEvents:UIControlEventTouchUpInside];
        btn.frame = CGRectMake((screen_w-200)/2, fy+9, 200, 35);
        [btn setTitle:@"分层测试" forState:UIControlStateNormal];
        [self.view addSubview:btn];
        
        
        //        fy += 50;
    }
    fy += 60;
    {
        
        UILabel *label = [[[UILabel alloc] init] autorelease];
        label.frame = CGRectMake(0, fy, screen_w, 11);;
        label.layer.cornerRadius = 5;
        label.font = [UIFont systemFontOfSize:10];
        label.backgroundColor = [UIColor grayColor];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = @"采集+编码+推流三层均可自定义";
        [self.view addSubview:label];
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [btn addTarget:self action:@selector(actionCaptureTest:) forControlEvents:UIControlEventTouchUpInside];
        btn.frame = CGRectMake((screen_w-200)/2, fy+9, 200, 35);
        [btn setTitle:@"分层采集" forState:UIControlStateNormal];
        [self.view addSubview:btn];
        
        
        
        //        fy += 50;
    }
    
    fy += 50;
    
#ifdef CNC_DEMO_FU
    {
        UILabel *label = [[[UILabel alloc] init] autorelease];
        label.frame = CGRectMake(0, fy, screen_w, 11);;
        label.layer.cornerRadius = 5;
        label.font = [UIFont systemFontOfSize:10];
        label.backgroundColor = [UIColor grayColor];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = @"FU美颜 + 采集+编码+推流三层均可自定义";
        [self.view addSubview:label];
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [btn addTarget:self action:@selector(actionFUTest:) forControlEvents:UIControlEventTouchUpInside];
        btn.frame = CGRectMake((screen_w-200)/2, fy+9, 200, 35);
        [btn setTitle:@"FU测试" forState:UIControlStateNormal];
        [self.view addSubview:btn];
    }
    fy += 50;
#endif
   
    fy = [self setup_loader_info:fy view:self.view];
    {
        CGRect r = CGRectMake(10, fy, screen_w-20, 40);
        UILabel *label = [[[UILabel alloc] init] autorelease];
        label.frame = r;
        label.layer.cornerRadius = 5;
        label.font = [UIFont systemFontOfSize:15];
        label.backgroundColor = [UIColor blueColor];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;

        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.numberOfLines = 2;
        [self.view addSubview:label];

        label.text = [NSString stringWithFormat:@"版本号:%@  build号:%@ \nSDK版号 : %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"], [CNCMobStreamSDK get_sdk_version]];

    }
    
    [self checkPermission];
    
}

- (void)checkPermission {
    AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (videoAuthStatus == AVAuthorizationStatusNotDetermined) {// 未询问用户是否授权
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            NSLog(@"requestAccessForMediaTypeVideo granted:%@", @(granted));
            
            AVAuthorizationStatus audioAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
            if (audioAuthStatus == AVAuthorizationStatusNotDetermined) {// 未询问用户是否授权
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                    NSLog(@"requestAccessForMediaTypeAudio granted:%@", @(granted));
                }];
            }
        }];
    }
}

//- (void)actionPlayTest:(UIButton*)btn {
//
//    CNCPlayerMenuViewController *vc = [[[CNCPlayerMenuViewController alloc] init] autorelease];
//    
//    [self.navigationController pushViewController:vc animated:YES];
//}
- (void)actionRecordTest:(UIButton *)btn {
    select_index = 0;
    [self actionAuthClick];
}

- (void)actionLayeredTest:(UIButton *)btn {
    select_index = 1;
    [self actionAuthClick];
}

- (void)actionCaptureTest:(UIButton *)btn {
    select_index = 2;
    [self actionAuthClick];
}

- (void)actionFUTest:(UIButton *)btn {
    select_index = 3;
    [self actionAuthClick];
}


- (void)actionAuthClick {
    if (self.isAuth) {
        if (select_index == 0) {
            CNCRecorderMenuViewController *vc = [[[CNCRecorderMenuViewController alloc] init] autorelease];
            [self.navigationController pushViewController:vc animated:YES];
        } else if (select_index == 1) {
            CNCDemoVideoCaptureMenuViewController *vc = [[[CNCDemoVideoCaptureMenuViewController alloc] init] autorelease];
            [self.navigationController pushViewController:vc animated:YES];
        } else if (select_index == 2) {
            CNCLayeredMenuViewController *vc = [[[CNCLayeredMenuViewController alloc] init] autorelease];
#ifdef CNC_NewInterface
#else
            vc.show_the_third_sdk = YES;
#endif
            [self.navigationController pushViewController:vc animated:YES];
        } else if (select_index == 3) {
            CNCLayeredMenuViewController *vc = [[[CNCLayeredMenuViewController alloc] init] autorelease];
            vc.is_fu = YES;
            [self.navigationController pushViewController:vc animated:YES];
        } else {
            //do nothing
        }
//        CNCRecorderMenuViewController *vc = [[[CNCRecorderMenuViewController alloc] init] autorelease];
        
//        [self.navigationController pushViewController:vc animated:YES];
    } else {
        
        NSString *app_id = [[NSUserDefaults standardUserDefaults] objectForKey:@"CNCMobSteamSDK_App_ID"];
        NSString *auth_key = [[NSUserDefaults standardUserDefaults] objectForKey:@"CNCMobSteamSDK_Auth_Key"];
        
        UIAlertView* alertView = [[[UIAlertView alloc] initWithTitle:@"请输入鉴权信息" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil] autorelease];
        [alertView setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
        
        UITextField* appid_textfield = [alertView textFieldAtIndex:0];
        UITextField* auth_key_textfield = [alertView textFieldAtIndex:1];
        
        appid_textfield.placeholder = @"Please enter your App ID";
        auth_key_textfield.placeholder = @"Please enter your Auth Key";
        
        appid_textfield.secureTextEntry = NO;
        auth_key_textfield.secureTextEntry = NO;
        
        appid_textfield.text = app_id;
        auth_key_textfield.text = auth_key;
        
        [alertView show];
        alertView = nil;
    }
}

- (void)dealloc {
    self.loader_btn = nil;
    self.speak_btn = nil;
    self.audio_mode_btn = nil;
    self.loader_textfield = nil;
    self.auth_textfield_appid = nil;
    self.auth_textfield_authkey = nil;
    self.scroll_view = nil;
    [super dealloc];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        UITextField* appid_textfield = [alertView textFieldAtIndex:0];
        UITextField* auth_key_textfield = [alertView textFieldAtIndex:1];
        NSString *app_id = appid_textfield.text;
        NSString *auth_key = auth_key_textfield.text;
        [self do_auth_with_id:app_id key:auth_key];
    }
}
- (void)do_auth_with_id:(NSString *)app_id key:(NSString *)auth_key {
    
    
    MBProgressHUD* progressHud_ = [[[MBProgressHUD alloc] initWithView:self.view] autorelease];
    progressHud_.removeFromSuperViewOnHide = YES;
    progressHud_.labelText = @"正在鉴权";
    [self.view addSubview:progressHud_];
    [progressHud_ show:YES];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [CNCMobStreamSDK set_log_system_enable:YES];
        CNC_Ret_Code ret = [CNCMobStreamSDK regist_app:app_id auth_key:auth_key];
        NSLog(@"registApp RET = %@", @(ret));
        
        sleep(0.5);
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [progressHud_ hide:NO];
            if (ret == CNC_RCode_Com_SDK_Init_Success || ret == 0) {
                self.auth = YES;
                [[NSUserDefaults standardUserDefaults] setObject:app_id forKey:@"CNCMobSteamSDK_App_ID"];
                [[NSUserDefaults standardUserDefaults] setObject:auth_key forKey:@"CNCMobSteamSDK_Auth_Key"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                if (select_index == 0) {
                    CNCRecorderMenuViewController *vc = [[[CNCRecorderMenuViewController alloc] init] autorelease];
                    [self.navigationController pushViewController:vc animated:YES];
                } else if (select_index == 1) {
                    CNCDemoVideoCaptureMenuViewController *vc = [[[CNCDemoVideoCaptureMenuViewController alloc] init] autorelease];
                    [self.navigationController pushViewController:vc animated:YES];
                } else if (select_index == 2) {
                    CNCLayeredMenuViewController *vc = [[[CNCLayeredMenuViewController alloc] init] autorelease];
#ifdef CNC_NewInterface
#else
            vc.show_the_third_sdk = YES;
#endif
                    [self.navigationController pushViewController:vc animated:YES];
                } else if (select_index == 3) {
                    CNCLayeredMenuViewController *vc = [[[CNCLayeredMenuViewController alloc] init] autorelease];
                    vc.is_fu = YES;
                    [self.navigationController pushViewController:vc animated:YES];
                } else {
                    //do nothing
                }
                
                
            } else {
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"notice" message:[NSString stringWithFormat:@"SDK鉴权失败 业务接口不可用 ret = %@", @(ret)] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
                [alert show];
            }
        });
    });
}
#pragma mark 旋转相关
//旋转相关
-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

//You need this if you support interface rotation
-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    NSLog(@"willAnimateRotationToInterfaceOrientation");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)toInterfaceOrientation {
    
    //    return YES;
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}


//#pragma mark - IOS6.0 旋转
- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    //return UIInterfaceOrientationLandscapeRight;
    return UIInterfaceOrientationMaskPortrait;
}

//手势

- (void)add_gesture_recognizer {

    UITapGestureRecognizer *tapGes = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap_gesture:)] autorelease];
    tapGes.delegate = self;
    
    UISwipeGestureRecognizer *swipeLeftGes = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handle_swipes:)] autorelease];
    swipeLeftGes.direction = UISwipeGestureRecognizerDirectionLeft;
    swipeLeftGes.numberOfTouchesRequired = 2;
    swipeLeftGes.delegate = self;
    
    UISwipeGestureRecognizer *swipeRightGes = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handle_swipes:)] autorelease];
    swipeRightGes.direction = UISwipeGestureRecognizerDirectionRight;
    swipeRightGes.numberOfTouchesRequired = 2;
    swipeRightGes.delegate = self;
    
    [self.scroll_view addGestureRecognizer:tapGes];
    [self.view addGestureRecognizer:swipeLeftGes];
    [self.view addGestureRecognizer:swipeRightGes];
}

- (void)tap_gesture:(UITapGestureRecognizer *)tapGes {
    [self textField_resignFirstResponder];
}

#pragma mark 以下代码纯属方便测试 非DEMO业务代码
- (void)handle_swipes:(UISwipeGestureRecognizer *)sender {
    //纯属方便测试 非DEMO业务代码
    if (sender.direction == UISwipeGestureRecognizerDirectionLeft) {
        [self textField_resignFirstResponder];
        self.auth = NO;
        self.loader_btn.hidden = YES;
        self.speak_btn.hidden = YES;
        self.audio_mode_btn.hidden = YES;
        self.loader_textfield.hidden = YES;
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"" message:@"您已经清空鉴权信息 请重新鉴权" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil] autorelease];
        [alert show];
        return;
    }
    if (sender.direction == UISwipeGestureRecognizerDirectionRight) {
        self.loader_btn.hidden = NO;
        self.speak_btn.hidden = NO;
        self.audio_mode_btn.hidden = NO;
        self.loader_textfield.hidden = NO;
        return;
    }
}
- (void)set_textfiled_show:(BOOL)is_show {
    for (NSObject *obj in self.view.subviews) {
        if ([obj isKindOfClass:[UITextField class]]) {
            UITextField *textField = (UITextField *)obj;
            textField.hidden = is_show;
        }
    }
}
- (void)textField_resignFirstResponder {
//    for (NSObject *obj in self.view.subviews) {
//        if ([obj isKindOfClass:[UITextField class]]) {
//            UITextField *textField = (UITextField *)obj;
//            [textField resignFirstResponder];
//        }
//    }
    [self.loader_textfield resignFirstResponder];
    [self.auth_textfield_authkey resignFirstResponder];
    [self.auth_textfield_appid resignFirstResponder];
    
}

- (CGFloat)setup_loader_info:(CGFloat)fy view:(UIView *)view{
    CGFloat fy_off = fy + 5;
    CGFloat screen_w = [[UIScreen mainScreen] bounds].size.width;
    {
        UITextField *textFiled = [[[UITextField alloc] init] autorelease];
        textFiled.placeholder = @"一般人是看不到这个输入框的";
        textFiled.text = @"http://cfg.oo.com/mfmcfg";
        
        textFiled.frame = CGRectMake(10, fy_off, screen_w-20, 30);
        textFiled.borderStyle = UITextBorderStyleRoundedRect;
        textFiled.textAlignment = NSTextAlignmentLeft;
        textFiled.delegate = self;
        [view addSubview:textFiled];
        self.loader_textfield = textFiled;
        textFiled.hidden = YES;
        
        fy_off += 40;
    }
    
    
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [btn addTarget:self action:@selector(action_loader:) forControlEvents:UIControlEventTouchUpInside];
        btn.frame = CGRectMake(10, fy_off, 100, 35);
        btn.layer.borderWidth = 0.5f;
        [btn setTitle:@"加载" forState:UIControlStateNormal];
        [view addSubview:btn];
        self.loader_btn = btn;
        btn.hidden = YES;
    }
    
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn addTarget:self action:@selector(action_change_default_audio_export:) forControlEvents:UIControlEventTouchUpInside];
        btn.frame = CGRectMake(120, fy_off, 100, 35);
        btn.layer.borderWidth = 0.5f;
        [btn setTitle:@"听筒" forState:UIControlStateNormal];
        [btn setTitle:@"扩音器" forState:UIControlStateSelected];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        btn.selected = YES;
        [view addSubview:btn];
        self.speak_btn = btn;
        btn.hidden = YES;
    }
    
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [btn addTarget:self action:@selector(action_change_audio_session_mode:) forControlEvents:UIControlEventTouchUpInside];
        btn.frame = CGRectMake(230, fy_off, 100, 35);
        btn.layer.borderWidth = 0.5f;
        [btn setTitle:@"VoiceChat" forState:UIControlStateNormal];
        [view addSubview:btn];
        self.audio_mode_btn = btn;
        btn.hidden = YES;
    }

    fy_off += 50;
    
    return fy_off;
}

- (void)action_change_default_audio_export:(UIButton *)btn {
    btn.selected = !btn.isSelected;
    [CNCMobStreamSDK globalSetAudioExportDefaultToSpeaker:btn.isSelected];
}

- (void)action_change_audio_session_mode:(UIButton *)btn {
    static int mode = 1;
    NSArray *modeText = [NSArray arrayWithObjects:@"Default", @"VoiceChat", @"VideoChat", @"VideoRecord", nil];
    mode++;
    mode = mode % 4;
    [btn setTitle:[modeText objectAtIndex:mode] forState:UIControlStateNormal];
    [CNCMobStreamSDK globalSetAudioSessionMode:mode+1];
}

- (void)action_loader:(UIButton *)btn {
    self.loader_btn.hidden = YES;
    self.speak_btn.hidden = YES;
    self.audio_mode_btn.hidden = YES;
    self.loader_textfield.hidden = YES;
    
    NSObject *o = [self _get_data_from_loader:self.loader_textfield.text];
    if (![o isKindOfClass:[NSDictionary class]]) {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"" message:@"加载信息失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil] autorelease];
        [alert show];
        
        return;
    }
    
    NSDictionary *d = (NSDictionary *)o;
    NSString *tmp = nil;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    {
        tmp = [d objectForKey:@"a1"];
        if (tmp != nil && [tmp length] > 0) {
            [userDefaults setObject:tmp forKey:@"CNCMobSteamSDK_App_ID"];
        }
    }
    
    {
        tmp = [d objectForKey:@"k1"];
        if (tmp != nil && [tmp length] > 0) {
            [userDefaults setObject:tmp forKey:@"CNCMobSteamSDK_Auth_Key"];
        }
    }
    
    {
        tmp = [d objectForKey:@"pxy_i"];
        if (tmp != nil && [tmp length] > 0) {
            [userDefaults setObject:tmp forKey:@"CNCMobSteamSDK_Proxy_IP"];
        }
    }
    
    {
        tmp = [d objectForKey:@"pxy_p"];
        if (tmp != nil && [tmp length] > 0) {
            [userDefaults setObject:tmp forKey:@"CNCMobSteamSDK_Proxy_Port"];
        }
    }
    
    {
        tmp = [d objectForKey:@"pxy_u"];
        if (tmp != nil && [tmp length] > 0) {
            [userDefaults setObject:tmp forKey:@"CNCMobSteamSDK_Proxy_User"];
        }
    }
    
    {
        tmp = [d objectForKey:@"pxy_w"];
        if (tmp != nil && [tmp length] > 0) {
            [userDefaults setObject:tmp forKey:@"CNCMobSteamSDK_Proxy_Passw"];
        }
    }
    
    [userDefaults synchronize];
#ifdef CNC_NewInterface
    [self redraw_auth_view];
#else
#endif
}

- (NSObject *)_get_data_from_loader:(NSString *)base_url {
    NSString *fullUrl = [NSString stringWithFormat:@"%@",base_url];
    NSURL *url = [NSURL URLWithString:fullUrl];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 5.0;
    
    [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    
    NSData *rsp_data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    
    if (httpResponse.statusCode != 200) {
        return nil;
    }
    
    NSString *rsp_str = [[[NSString alloc] initWithData:rsp_data encoding:NSUTF8StringEncoding] autorelease];
    
    NSError *jsonError;
    NSData *objectData = [rsp_str dataUsingEncoding:NSUTF8StringEncoding];
    NSObject *result = [NSJSONSerialization JSONObjectWithData:objectData
                                                       options:NSJSONReadingMutableContainers
                                                         error:&jsonError];
    
    return result;
}


#pragma mark 音频文件拷贝
- (void)copy_res_to_music_path {
    NSString *src_file = [[NSBundle mainBundle] pathForResource:@"XF.wav" ofType:nil];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *baseDir = paths.firstObject;
    NSString *musicDirectory = [baseDir stringByAppendingPathComponent:@"music"];
    
    NSString *dst_file = [NSString stringWithFormat:@"%@/XF.wav", musicDirectory];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:dst_file] && src_file){//如果不存在,则说明是第一次运行这个程序，那么建立这个文件夹
        [self createFolder:musicDirectory];
        
        [fileManager copyItemAtPath:src_file toPath:dst_file error:nil];
    }
}

- (void)copy_res_to_wather_path {
    NSString *src_file = [[NSBundle mainBundle] pathForResource:@"watermark.png" ofType:nil];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *baseDir = paths.firstObject;
    NSString *musicDirectory = [baseDir stringByAppendingPathComponent:@"watherMask"];
    
    NSString *dst_file = [NSString stringWithFormat:@"%@/watermark.png", musicDirectory];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:dst_file] && src_file ){//如果不存在,则说明是第一次运行这个程序，那么建立这个文件夹
        [self createFolder:musicDirectory];
        
        [fileManager copyItemAtPath:src_file toPath:dst_file error:nil];
    }
}
- (void)copy_res_to_questions_path {
    NSString *src_file = [[NSBundle mainBundle] pathForResource:@"questions" ofType:nil];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *baseDir = paths.firstObject;
    NSString *directory = [baseDir stringByAppendingPathComponent:@"questions"];
    
    NSString *dst_file = [NSString stringWithFormat:@"%@/questions", directory];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:dst_file] && src_file){//如果不存在,则说明是第一次运行这个程序，那么建立这个文件夹
        [self createFolder:directory];
        
        [fileManager copyItemAtPath:src_file toPath:dst_file error:nil];
    }
}
- (BOOL)createFolder:(NSString*)path {
    
    BOOL bRet = YES;
    
    //APP自用数据库文件夹
    //    NSString * dataFolderPath=[MDBBaseMng getDBPath];
    
    NSLog(@"path = %@", path);
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    
    if ( !(isDir == YES && existed == YES)) {
        bRet = [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        if (!bRet) {
            NSLog(@"创建文件夹失败");
        }
    } else {
        NSLog(@"文件夹已经存在");
        bRet = YES;
    }
    
    return bRet;
}
#ifdef CNC_NewInterface

#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (self.scroll_view.contentSize.height == scroll_view_content_size_height) {
        [self.scroll_view setContentSize:CGSizeMake(CGRectGetWidth(self.scroll_view.frame), CGRectGetHeight(self.scroll_view.frame)+60)];
    }
    
}
- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (self.scroll_view.contentSize.height != scroll_view_content_size_height) {
        [self.scroll_view setContentSize:CGSizeMake(CGRectGetWidth(self.scroll_view.frame), CGRectGetHeight(self.scroll_view.frame)-60)];
    }
    
}
#pragma mark - new interface
- (UIView *)textFiledLeftViewWithImageName:(NSString *)imageName {
    UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 40, 30)] autorelease];
    view.backgroundColor = [UIColor clearColor];
    
    
    
    UIImageView *imageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]] autorelease];
    int width = 25,height = 25;
    imageView.frame = CGRectMake((CGRectGetWidth(view.frame)-width)/2, (CGRectGetHeight(view.frame)-height)/2, width, height);
    [view addSubview:imageView];
    
    return view;
}
- (void)init_NewInterface_view {
    self.title = @"网宿推流Demo";
    int spacing_height = 40;
    
    CGFloat fy = 0;
    {
        int width = 100,height = 100;
        UIImageView *imageview = [[[UIImageView alloc] initWithFrame:CGRectMake((screen_w_-width)/2, fy, width, height)] autorelease];
        imageview.image = [UIImage imageNamed:@"logo"];
        [self.scroll_view addSubview:imageview];
    }
    fy += 130;

    {
        UITextField *textFiled = [[[UITextField alloc] init] autorelease];
        textFiled.placeholder = @"appid";
        textFiled.frame = CGRectMake(10, fy, screen_w_- 20, spacing_height-5);
        textFiled.borderStyle = UITextBorderStyleRoundedRect;
        textFiled.textAlignment = NSTextAlignmentLeft;
        textFiled.clearButtonMode = UITextFieldViewModeAlways;
        textFiled.leftViewMode = UITextFieldViewModeAlways;
        textFiled.leftView = [self textFiledLeftViewWithImageName:@"user.png"];
        textFiled.delegate = self;
        [self.scroll_view addSubview:textFiled];
        self.auth_textfield_appid = textFiled;
        
        fy += spacing_height;
    }

    {
        UITextField *textFiled = [[[UITextField alloc] init] autorelease];
        textFiled.placeholder = @"auth_key";
        textFiled.frame = CGRectMake(10, fy, screen_w_- 20, spacing_height-5);
        textFiled.borderStyle = UITextBorderStyleRoundedRect;
        textFiled.textAlignment = NSTextAlignmentLeft;
        textFiled.clearButtonMode = UITextFieldViewModeAlways;
        textFiled.leftViewMode = UITextFieldViewModeAlways;
        textFiled.leftView = [self textFiledLeftViewWithImageName:@"key.png"];
        textFiled.delegate = self;
        [self.scroll_view addSubview:textFiled];
        self.auth_textfield_authkey = textFiled;
        
        
    }
    fy += 60;
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [btn addTarget:self action:@selector(action_auth_then_step_over:) forControlEvents:UIControlEventTouchUpInside];
        btn.frame = CGRectMake(10, fy, screen_w_-20, 35);
        [btn setTitle:@"鉴权" forState:UIControlStateNormal];
        btn.layer.cornerRadius = 5;
        btn.layer.borderWidth = 0.7f;
        UIColor *color = [UIColor colorWithRed:52.0/255.0 green:103.0/255.0 blue:149.0/255.0 alpha:1.0];
        btn.backgroundColor = color;
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.scroll_view addSubview:btn];
    }
    fy += 40;
    
    
    fy = [self setup_loader_info:fy view:self.scroll_view];
    [self redraw_auth_view];
    
}
- (void)action_auth_then_step_over:(UIButton *)sender {
    UITextField* appid_textfield = self.auth_textfield_appid;
    UITextField* auth_key_textfield = self.auth_textfield_authkey;
    NSString *app_id = appid_textfield.text;
    NSString *auth_key = auth_key_textfield.text;
    [self do_auth_with_id:app_id key:auth_key];
}
- (void)redraw_auth_view {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    {
        UITextField *textFiled = self.auth_textfield_appid;
        NSString *str = [userDefaults stringForKey:@"CNCMobSteamSDK_App_ID"];
        if (str == nil) {
            textFiled.text = @"";
        } else {
            textFiled.text = str;
        }
        
    }
    
    {
        UITextField *textFiled = self.auth_textfield_authkey;
         NSString *str = [userDefaults stringForKey:@"CNCMobSteamSDK_Auth_Key"];
        if (str == nil) {
            textFiled.text = @"";
        } else {
            textFiled.text = str;
        }
    }
    [userDefaults synchronize];
}
#else
#endif
@end
