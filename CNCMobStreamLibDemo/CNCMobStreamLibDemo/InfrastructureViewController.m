//
//  InfrastructureViewController.m
//  CNCMobStreamDemo
//
//  Created by weiyansheng on 2017/4/28.
//  Copyright © 2017年 cad. All rights reserved.
//

#import "InfrastructureViewController.h"

@interface InfrastructureViewController ()

@end

@implementation InfrastructureViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    ///初始化基础数值
    [self infrastrucnture_init_param];
    
    ///初始化推流配置参数枚举数组
    [self infrastrucnture_init_rtmp_param_array];
    
    ///初始化地址输入框
    [self infrastrucnture_init_rtmp_address_input];
    
    ///初始化推流配置参数
    [self infrastrucnture_init_rtmp_pickview_control];
    
    ///初始化推流配置参数 初始值
    [self infrastrucnture_init_rtmp_cofig_param];
    
    {
        CGRect r = CGRectMake(10, _screenHeight - 30, _screenWidth - 20, 20);
        UILabel *label = [[[UILabel alloc] init] autorelease];
        label.frame = r;
        label.layer.cornerRadius = 5;
        label.font = [UIFont systemFontOfSize:15];
        label.backgroundColor = [UIColor grayColor];
        label.textColor = [UIColor redColor];
        label.textAlignment = NSTextAlignmentCenter;
        
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.numberOfLines = 2;
        [self.view addSubview:label];
        
        //        label.text = [NSString stringWithFormat:@"版本号:%@  build号:%@ \nSDK版号:%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"], [CNCMobStreamSDK get_sdk_version]];
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - 初始化 推流配置参数 控制视图

- (void)infrastrucnture_init_param {
    
    _currentUIMaxY = 20+44+6;
    

    CGFloat fw = [[UIScreen mainScreen] bounds].size.width;
    CGFloat fh = [[UIScreen mainScreen] bounds].size.height;
    
    _screenWidth = (fw < fh) ? fw : fh;
    _screenHeight = (fw > fh) ? fw : fh;
    if (@available(iOS 11.0, *)) {
//        NSLog(@"%f %f",[UIApplication sharedApplication].keyWindow.safeAreaInsets.top,[UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom);
        
        _currentUIMaxY = [UIApplication sharedApplication].keyWindow.safeAreaInsets.top+44+6;
        
    }
}

- (void)infrastrucnture_init_rtmp_address_input {
    
    UITextField *textfield = [[[UITextField alloc] init] autorelease];
    textfield.frame = CGRectMake(10, _currentUIMaxY, _screenWidth-20, 30);
    textfield.borderStyle = UITextBorderStyleRoundedRect;
    textfield.placeholder = @"请输入完整的推流地址";
    textfield.tag = 3001;
    [self.view addSubview:textfield];
    self.rtmp_address_inputTF = textfield;
    
    if (STREAM_NAME_CACHE && STREAM_NAME_CACHE.length>0) {
        self.rtmp_address_inputTF.text = STREAM_NAME_CACHE;
    }
    
    _currentUIMaxY += 30;
}

- (void)infrastrucnture_init_rtmp_pickview_control {
    
    UIPickerView *pickerView = [[[UIPickerView alloc] initWithFrame:CGRectMake(0, _currentUIMaxY, self.view.bounds.size.width, 80)] autorelease];
    
    pickerView.showsSelectionIndicator=YES;
    pickerView.dataSource = self;
    pickerView.delegate = self;
    
    self.rtmp_config_pickview = pickerView;
    
    [self.view addSubview:self.rtmp_config_pickview];
    
    _currentUIMaxY += 80;
}


#pragma mark - 初始化 推流配置参数 枚举数组

- (void)infrastrucnture_init_rtmp_param_array {
    
    self.array_sw_encoder_priority_type = [NSArray arrayWithObjects:@"质量",@"码率", nil];
    self.array_encode_way = [NSArray arrayWithObjects:@"硬编", @"软编", nil];
    self.array_camera_side = [NSArray arrayWithObjects:@"前置", @"后置", @"纯音频", nil];
    
    if (self.show_the_third_sdk) {
#ifdef CNC_DEMO_FU
#ifdef CNC_DEMO_ST
        self.array_camera_side = [NSArray arrayWithObjects:@"前置", @"后置", @"纯音频",@"FU采集",@"ST采集", nil];
#else
        self.array_camera_side = [NSArray arrayWithObjects:@"前置", @"后置", @"纯音频",@"FU采集", nil];
#endif
#else
#ifdef CNC_DEMO_ST
        self.array_camera_side = [NSArray arrayWithObjects:@"前置", @"后置", @"纯音频",@"ST采集", nil];
#else
        self.array_camera_side = [NSArray arrayWithObjects:@"前置", @"后置", @"纯音频", nil];
#endif
#endif
    }
    
    self.array_camera_direction = [NSArray arrayWithObjects:@"竖屏", @"横屏", nil];
    
    self.array_bit_rate = [[[NSMutableArray alloc] initWithCapacity:48] autorelease];
    for (int i = 0; i<48; i++) {
        [self.array_bit_rate addObject:[NSString stringWithFormat:@"%dkbps", (i+3)*100]];
    }
    
    self.array_frame_rate = [[[NSMutableArray alloc] initWithCapacity:21] autorelease];
    for (int i = 0; i<21; i++) {
        [self.array_frame_rate addObject:[NSString stringWithFormat:@"%dfps", (i+10)]];
    }
}

#pragma mark - 初始化 推流配置参数 初始值
- (void)infrastrucnture_init_rtmp_cofig_param {
    
    ///初始值 - 质量优先
    self.sw_encoder_priority_type = 1;
    ///初始值 - 硬编
    self.encoder_type = CNC_ENM_Encoder_HW;
    
    ///初始值 - 前置
    self.came_sel_type = 0;
    self.came_pos = AVCaptureDevicePositionFront;
    
    ///初始值 - 竖屏
    self.direct_type = CNC_ENM_Direct_Vertical;
    
    ///初始值 - 码率：300 kbps
    self.video_bit_rate = 300;
    
    ///初始值 - 帧率：15fps
    self.video_frame_rate = 15;
    
    ///设置到相应位置 帧率
    [self.rtmp_config_pickview selectRow:15-10 inComponent:5 animated:NO];
    
}

#pragma mark - 点击取消输入
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [((UIView*)obj) resignFirstResponder];
    }];
}


#pragma mark - UIPickView data source

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 6;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    switch (component) {
        case 0:
            return self.array_sw_encoder_priority_type.count;
            break;
        case 1:
            return self.array_encode_way.count;
            break;
        case 2:
            return self.array_camera_side.count;
            break;
        case 3:
            return self.array_camera_direction.count;
            break;
        case 4:
            return self.array_bit_rate.count;
            break;
        case 5:
            return self.array_frame_rate.count;
            break;
        default:
            break;
    }
    
    return 0;
}

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    switch (component) {
        case 0:
        {
            if (row < self.array_sw_encoder_priority_type.count) {
                return self.array_sw_encoder_priority_type[row];
            }
        }
            break;
        case 1:
        {
            if (row < self.array_encode_way.count) {
                return self.array_encode_way[row];
            }
        }
            break;
        case 2:
        {
            if (row < self.array_camera_side.count) {
                return self.array_camera_side[row];
            }
        }
            break;
        case 3:
        {
            if (row < self.array_camera_direction.count) {
                return self.array_camera_direction[row];
            }
        }
            break;
        case 4:
        {
            if (row < self.array_bit_rate.count) {
                return self.array_bit_rate[row];
            }
        }
            break;
        case 5:
        {
            if (row < self.array_frame_rate.count) {
                return self.array_frame_rate[row];
            }
        }
            break;
        default:
            break;
    }
    
    return @"Error";
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    
    CGFloat width = pickerView.bounds.size.width/8;
    
    switch (component) {
        case 0:
            return width;
            break;
        case 1:
            return width;
            break;
        case 2:
            return width;
            break;
        case 3:
            return width;
            break;
        case 4:
            return width*2;
            break;
        case 5:
            return width*2;
            break;
        default:
            break;
    }
    
    return 0;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    
    /*重新定义row 的UILabel*/
    UILabel *pickerLabel = (UILabel*)view;
    
    if (!pickerLabel){
        
        pickerLabel = [[[UILabel alloc] init] autorelease];
        // Setup label properties - frame, font, colors etc
        //adjustsFontSizeToFitWidth property to YES
        [pickerLabel setTextColor:[UIColor darkGrayColor]];
        pickerLabel.adjustsFontSizeToFitWidth = YES;
        [pickerLabel setTextAlignment:NSTextAlignmentCenter];
        [pickerLabel setBackgroundColor:[UIColor clearColor]];
        [pickerLabel setFont:[UIFont systemFontOfSize:16.0f]];
    }
    
    
    pickerLabel.text = [self pickerView:pickerView titleForRow:row forComponent:component];
    
    return pickerLabel;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    switch (component) {
        case 0:
        {
            if (row == 0) {
                self.sw_encoder_priority_type = 1;
            } else {
                self.sw_encoder_priority_type = 2;
            }
        }
            break;
        case 1:
        {
            if (row == 0) {
                self.encoder_type = CNC_ENM_Encoder_HW;
            } else {
                self.encoder_type = CNC_ENM_Encoder_SW;
            }
        }
            break;
        case 2:
        {
            if (row == 0) {
                self.came_pos = AVCaptureDevicePositionFront;
            } else if (row == 1) {
                self.came_pos = AVCaptureDevicePositionBack;
            }
            
            self.came_sel_type = row;
        }
            break;
        case 3:
        {
            if (row == 0) {
                self.direct_type = CNC_ENM_Direct_Vertical;
            } else {
                self.direct_type = CNC_ENM_Direct_Horizontal;
            }
        }
            break;
        case 4:
        {
            self.video_bit_rate = (row + 3)*100;
        }
            break;
        case 5:
        {
            self.video_frame_rate = (row + 10);
        }
            break;
        default:
            break;
    }
}

- (void)dealloc {
    
    [self.rtmp_config_pickview removeFromSuperview];
    self.rtmp_config_pickview.delegate = nil;
    self.rtmp_config_pickview = nil;
    
    [self.rtmp_address_inputTF removeFromSuperview];
    self.rtmp_address_inputTF = nil;
    
    self.array_encode_way = nil;
    self.array_bit_rate = nil;
    self.array_camera_side = nil;
    self.array_camera_direction = nil;
    self.array_frame_rate = nil;
    
    self.array_sw_encoder_priority_type = nil;
    
    [super dealloc];
}

@end
