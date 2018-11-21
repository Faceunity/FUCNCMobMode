//
//  InfrastructureViewController.m
//  CNCMobStreamDemo
//
//  Created by weiyansheng on 2017/4/28.
//  Copyright © 2017年 cad. All rights reserved.
//

#import "NewInfrastructureViewController.h"
#import "CNCAppUserDataMng.h"
@interface NewInfrastructureViewController ()<UITextFieldDelegate>

@end

@implementation NewInfrastructureViewController
{
    int pickerView_count;
    NSMutableArray *select_arr;
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.scrollView = [[[UIScrollView alloc] initWithFrame:CGRectMake(0, 64, _screenWidth-64, _screenHeight)] autorelease];
    self.scrollView.frame = self.view.bounds;
    self.scrollView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.scrollView];
    UITapGestureRecognizer *tapGes = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)] autorelease];
    tapGes.delegate = self;
    [self.scrollView addGestureRecognizer:tapGes];
}
- (void)tapGesture:(UITapGestureRecognizer *)tap {
    [self textField_resignFirstResponder];
}
- (void)textField_resignFirstResponder {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.rtmp_stream_name_TF resignFirstResponder];
        [self.anchor_roomID_TF resignFirstResponder];
        [self.anchor_ID_TF resignFirstResponder];
        [self.audience_ID_TF resignFirstResponder];
    });
}
- (void)create_view{
    
    ///初始化基础数值
    [self infrastrucnture_init_param];
    
    ///初始化推流配置参数枚举数组
    [self infrastrucnture_init_rtmp_param_array];
    
    ///初始化地址输入框
    [self infrastrucnture_init_rtmp_textField];
    
    ///初始化推流配置参数
    [self infrastrucnture_init_rtmp_pickview_control];
    
    ///初始化各id及相应输入框
//    [self infrastrucnture_init_IDS_textField];
    
    ///初始化开始按钮
//    [self infrastrucnture_init_start_btn];
    
    ///初始化 下来选框
    [self init_select_pubulishing_point_view];
    
    ///初始化推流配置参数 初始值
    [self infrastrucnture_init_rtmp_cofig_param];
    
    //    {
    //        CGRect r = CGRectMake(10, _screenHeight - 30, _screenWidth - 20, 20);
    //        UILabel *label = [[[UILabel alloc] init] autorelease];
    //        label.frame = r;
    //        label.layer.cornerRadius = 5;
    //        label.font = [UIFont systemFontOfSize:15];
    //        label.backgroundColor = [UIColor grayColor];
    //        label.textColor = [UIColor redColor];
    //        label.textAlignment = NSTextAlignmentCenter;
    //
    //        label.lineBreakMode = NSLineBreakByWordWrapping;
    //        label.numberOfLines = 2;
    //        [self.scrollView addSubview:label];
    //
    //        //        label.text = [NSString stringWithFormat:@"版本号:%@  build号:%@ \nSDK版号:%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"], [CNCMobStreamSDK get_sdk_version]];
    //
    //    }
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
    
    _currentUIMaxY = 30;

    CGFloat fw = [[UIScreen mainScreen] bounds].size.width;
    CGFloat fh = [[UIScreen mainScreen] bounds].size.height;
    
    _screenWidth = (fw < fh) ? fw : fh;
    _screenHeight = (fw > fh) ? fw : fh;

    pickerView_count = 6;
    
    self.publishing_point_str = [select_arr objectAtIndex:0];
}

- (void)infrastrucnture_init_rtmp_textField {
    
    UIView *backGroundView = [[[UIView alloc] initWithFrame:CGRectMake(10, _currentUIMaxY, _screenWidth-20, 50)] autorelease];
    backGroundView.layer.cornerRadius = 5;
    backGroundView.layer.borderWidth = 0.7f;
    backGroundView.backgroundColor = [UIColor colorWithRed:238.0/256.0 green:238.0/256.0 blue:238.0/256.0 alpha:1.0];
    backGroundView.layer.borderColor = [UIColor grayColor].CGColor;
    [self.scrollView addSubview:backGroundView];
    int width = CGRectGetWidth(backGroundView.frame);
    {
        UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, _currentUIMaxY+10, 50, 30)] autorelease];
        label.text = @"发布点:";
        label.textAlignment = NSTextAlignmentRight;
        label.font = [UIFont boldSystemFontOfSize:14.0];
        [self.scrollView addSubview:label];
    }
    {

        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(55+10, _currentUIMaxY+10, width/2-55, 30)] autorelease];
        btn.backgroundColor = [UIColor whiteColor];
        btn.layer.cornerRadius = 2;
        btn.layer.borderWidth = 1.f;
        btn.layer.borderColor = [UIColor colorWithRed:200.0/256.0 green:200.0/256.0 blue:200.0/256.0 alpha:0.3].CGColor;
        [btn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [btn setTitle:self.publishing_point_str forState:UIControlStateNormal];
        [btn.titleLabel setFont:[UIFont systemFontOfSize:14.0]];
        [btn addTarget:self action:@selector(select_publishing_point:) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:self.publishing_point_Btn = btn];
        
        
    }
    {
        UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(width/2+10, _currentUIMaxY+10, 50, 30)] autorelease];
        label.text = @"流名:";
        label.textAlignment = NSTextAlignmentRight;
        label.font = [UIFont boldSystemFontOfSize:14.0];
        [self.scrollView addSubview:label];
    }
    {
        UITextField *textfield = [[[UITextField alloc] init] autorelease];
        textfield.frame = CGRectMake(55+width/2+10, _currentUIMaxY+10, width/2-55, 30);
        textfield.borderStyle = UITextBorderStyleRoundedRect;
        textfield.placeholder = @"流名";
        NSString *str;
        
        str = [[CNCAppUserDataMng instance] get_push_url];
        
        
        textfield.text = [[str componentsSeparatedByString:@"/"] lastObject];
        textfield.delegate = self;
         [self.scrollView addSubview:self.rtmp_stream_name_TF = textfield];
        
//        if (STREAM_NAME_CACHE && STREAM_NAME_CACHE.length>0) {
//            self.rtmp_stream_name_TF.text = STREAM_NAME_CACHE;
//        }
        
    }
    
    _currentUIMaxY += 50;
}

- (void)infrastrucnture_init_rtmp_pickview_control {
    
    UIPickerView *pickerView = [[[UIPickerView alloc] initWithFrame:CGRectMake(0, _currentUIMaxY, _screenWidth, 100)] autorelease];
    
    pickerView.showsSelectionIndicator=YES;
    pickerView.dataSource = self;
    pickerView.delegate = self;
    
    self.rtmp_config_pickview = pickerView;
    
    [self.scrollView addSubview:self.rtmp_config_pickview];
    
    _currentUIMaxY += 110;
}
//- (void)infrastrucnture_init_IDS_textField {
//    //创建各ID 及输入框
//    int count = 2;
//    if (!is_anchor) {
//        count = 3;
//    }
//
//    NSMutableArray *title_arr = [NSMutableArray arrayWithObjects:@"主播房间号",@"主播ID",@"观众ID",nil];
//    int label_width = (_screenWidth-40)/3;
//    int label_x = 10;
//    for (int i = 0; i < count; i++) {
//        UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake((label_x+label_width)*i+10, _currentUIMaxY, label_width, 30)] autorelease];
//        if (is_anchor && i==1) {
//            label.frame = CGRectMake((label_x+label_width)*(i+1),  _currentUIMaxY, label_width, 30);
//        }
//        label.text = [title_arr objectAtIndex:i];
//        label.textAlignment = NSTextAlignmentCenter;
//        label.textColor = [UIColor redColor];
//        label.font = [UIFont boldSystemFontOfSize:16.0];
//        [self.scrollView addSubview:label];
//
//        UITextField *textfield = [[[UITextField alloc] initWithFrame:CGRectMake(label.frame.origin.x, _currentUIMaxY+35, label_width, 30)] autorelease];
//        textfield.borderStyle = UITextBorderStyleRoundedRect;
//        textfield.placeholder = @"";
//        textfield.delegate = self;
//        [self.scrollView addSubview:textfield];
//        switch (i) {
//            case 0:
//                self.anchor_roomID_TF = textfield;
//                if (is_anchor) {
//                    self.anchor_roomID_TF.text = [[CNCAppUserDataMng instance] get_self_room_id];
//                } else {
//                    self.anchor_roomID_TF.text = [[CNCAppUserDataMng instance] get_other_room_id];
//                }
//
//                break;
//            case 1:
//                self.anchor_ID_TF = textfield;
//                if (is_anchor) {
//                    self.anchor_ID_TF.text = [[CNCAppUserDataMng instance] get_cur_user_id];
//                } else {
//                    self.anchor_ID_TF.text = [[CNCAppUserDataMng instance] get_other_anchor_id];
//                }
//                break;
//            case 2:
//                self.audience_ID_TF = textfield;
//                self.audience_ID_TF.text = [[CNCAppUserDataMng instance] get_cur_user_id];
//
//                break;
//
//            default:
//                break;
//        }
//    }
//    _currentUIMaxY += 80;
//}

- (void)infrastrucnture_init_start_btn {
    UIButton *start = [[[UIButton alloc] initWithFrame:CGRectMake(_screenWidth/8*3, _currentUIMaxY, _screenWidth/4, 30)] autorelease];
    [start setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [start addTarget:self action:@selector(action_start_btn:) forControlEvents:UIControlEventTouchUpInside];
    
    [start setTitle:@"开始推流" forState:UIControlStateNormal];
    
    [self.scrollView addSubview:start];
    
}

#pragma mark - 初始化 推流配置参数 枚举数组

- (void)infrastrucnture_init_rtmp_param_array {
    
    self.array_sw_encoder_priority_type = [NSArray arrayWithObjects:@"质量",@"码率", nil];
    self.array_encode_way = [NSArray arrayWithObjects:@"硬编", @"软编", nil];
    self.array_camera_side = [NSArray arrayWithObjects:@"前置", @"后置", @"纯音频", nil];
    self.array_camera_direction = [NSArray arrayWithObjects:@"竖屏", @"横屏", nil];
    self.array_auto_layout = [[NSMutableArray alloc] initWithObjects:@"左下",@"右下",@"左上",@"右上", nil];
    
    NSMutableArray *tmp_array_video_resolution = [NSMutableArray arrayWithObjects:
                                                  @"360P 4:3",
                                                  @"360P 16:9",
                                                  @"480P 4:3",
                                                  @"480P 16:9",
                                                  @"540P 4:3",
                                                  @"540P 16:9",
                                                  @"720P 4:3",
                                                  @"720P 16:9",
                                                  nil];
    NSMutableArray *tmp_array_value_video_resolution = [NSMutableArray arrayWithObjects:
                                                        
                                                        @(CNCVideoResolution_360P_4_3),
                                                        @(CNCVideoResolution_360P_16_9),
                                                        @(CNCVideoResolution_480P_4_3),
                                                        @(CNCVideoResolution_480P_16_9),
                                                        @(CNCVideoResolution_540P_4_3),
                                                        @(CNCVideoResolution_540P_16_9),
                                                        @(CNCVideoResolution_720P_4_3),
                                                        @(CNCVideoResolution_720P_16_9),
                                                        nil];
//    szlive，gzlive，shlive，bjlive
    select_arr = [[NSMutableArray alloc] initWithObjects:@"szlive",@"gzlive",@"shlive",@"bjlive", nil];
    self.publishing_point_str = [select_arr objectAtIndex:0];
    
    self.array_video_resolution = tmp_array_video_resolution;
    self.array_value_video_resolution = tmp_array_value_video_resolution;
    
    self.array_bit_rate = [[[NSMutableArray alloc] initWithCapacity:48] autorelease];
    for (int i = 0; i<48; i++) {
        [self.array_bit_rate addObject:[NSString stringWithFormat:@"%dkbps", (i+3)*100]];
    }
    
    self.array_frame_rate = [[[NSMutableArray alloc] initWithCapacity:21] autorelease];
    for (int i = 0; i<21; i++) {
        [self.array_frame_rate addObject:[NSString stringWithFormat:@"%dfps", (i+10)]];
    }
    
    self.array_value_mix_rate = [[[NSMutableArray alloc] initWithCapacity:48] autorelease];
    for (int i = 0; i<48; i++) {
        [self.array_value_mix_rate addObject:[NSString stringWithFormat:@"%dkbps", (i+3)*100]];
    }
    self.host_str = [[CNCAppUserDataMng instance] get_app_host];
    self.push_domain_name = @"webrtc.push.8686c.com";
    self.pull_domain_name = @"webrtc.pull.8686c.com";
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
    self.video_bit_rate = 500;
    
    ///初始值 - 帧率：15fps
    self.video_frame_rate = 15;
    
    ///初始值 - 分辨率：480P 4:3
    self.video_resolution_type = CNCVideoResolution_480P_4_3;
    
    ///初始值 - 混合码率：500 kbps
    self.video_mix_rate = 500;
    
    ///初始值- 左下
    self.auto_layout = 1;
    
        ///设置到相应位置 码率
//        [self.rtmp_config_pickview selectRow:2 inComponent:3 animated:NO];
//        ///设置到相应位置 帧率
//        [self.rtmp_config_pickview selectRow:5 inComponent:4 animated:NO];
//        ///设置到相应位置 分辨率
//        [self.rtmp_config_pickview selectRow:2 inComponent:5 animated:NO];
//        ///设置到相应位置 合流码率
//        [self.rtmp_config_pickview selectRow:2 inComponent:6 animated:NO];
    [self.rtmp_config_pickview selectRow:2 inComponent:4 animated:NO];
    [self.rtmp_config_pickview selectRow:5 inComponent:5 animated:NO];
}
#pragma mark -
- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.anchor_roomID_TF) {
        
    } else if(textField == self.anchor_ID_TF){
        
    }
    else if(textField == self.audience_ID_TF){
        
    }
    else if(textField == self.rtmp_stream_name_TF){
        
    }
}
#pragma mark - pubulishing_point_view
- (void)select_publishing_point:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    if (sender.selected) {
        [self open_select_pubulishing_point_view];
    } else {
        [self close_select_pubulishing_point_view];
    }
}
- (void)select_point:(UIButton *)sender {
    int index = (int)sender.tag-500;
    self.publishing_point_str = [select_arr objectAtIndex:index];
    [self.publishing_point_Btn setTitle:self.publishing_point_str forState:UIControlStateNormal];
    self.publishing_point_Btn.selected = NO;
    [self close_select_pubulishing_point_view];
}
- (void)open_select_pubulishing_point_view{
    
    CGRect frame = CGRectMake(self.publishing_point_View.frame.origin.x,self.publishing_point_View.frame.origin.y,self.publishing_point_View.frame.size.width,[select_arr count]*self.publishing_point_Btn.frame.size.height);
    [UIView animateWithDuration:0.3 animations:^{
        self.publishing_point_View.frame = frame;
    } completion:^(BOOL finished) {
        
    }];
}
- (void)close_select_pubulishing_point_view {
    
    CGRect frame = CGRectMake(self.publishing_point_View.frame.origin.x,self.publishing_point_View.frame.origin.y,self.publishing_point_View.frame.size.width,0);
    [UIView animateWithDuration:0.3 animations:^{
        self.publishing_point_View.frame = frame;
    } completion:^(BOOL finished) {
        
    }];
}
- (void)init_select_pubulishing_point_view {
    
    CGRect frame = CGRectMake(self.publishing_point_Btn.frame.origin.x, self.publishing_point_Btn.frame.origin.y+self.publishing_point_Btn.frame.size.height, self.publishing_point_Btn.frame.size.width, 0);
    UIView *view = [[UIView alloc] initWithFrame:frame];
    view.backgroundColor = [UIColor whiteColor];
    view.clipsToBounds = YES;
    [self.scrollView addSubview:self.publishing_point_View = view];
    
    for (int i = 0; i < [select_arr count]; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        btn.frame = CGRectMake(0,self.publishing_point_Btn.frame.size.height*i , self.publishing_point_Btn.frame.size.width, self.publishing_point_Btn.frame.size.height);
        btn.tag = 500+i;
        btn.backgroundColor = [UIColor whiteColor];
        btn.layer.cornerRadius = 2;
        btn.layer.borderWidth = 1.f;
        btn.layer.borderColor = [UIColor colorWithRed:200.0/256.0 green:200.0/256.0 blue:200.0/256.0 alpha:0.3].CGColor;
        [btn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [btn.titleLabel setFont:[UIFont systemFontOfSize:14.0]];
        [btn setTitle:[select_arr objectAtIndex:i] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(select_point:) forControlEvents:UIControlEventTouchUpInside];
        [self.publishing_point_View addSubview:btn];
    }
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
    return pickerView_count;
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
    
    
    CGFloat width;
    
        width = pickerView.bounds.size.width/17;
        switch (component) {
            case 0:
                return width*2;
            case 1:
                return width*2;
                break;
            case 2:
                return width*3;
                break;
            case 3:
                return width*3;
                break;
            case 4:
                return width*3;
                break;
            case 5:
                return width*3;
                break;
        
            default:
                break;
        }
    
    return 0;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    
    /*重新定义row 的UILabel*/
    UILabel *pickerLabel = (UILabel*)view;
    
    if (!pickerLabel){
        
        pickerLabel = [[[UILabel alloc] init] autorelease];
        // Setup label properties - frame, font, colors etc
        //adjustsFontSizeToFitWidth property to YES
        [pickerLabel setTextColor:[UIColor darkGrayColor]];
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
    
    [self.rtmp_stream_name_TF removeFromSuperview];
    self.rtmp_stream_name_TF = nil;
    
    self.array_encode_way = nil;
    self.array_bit_rate = nil;
    self.array_camera_side = nil;
    self.array_camera_direction = nil;
    self.array_frame_rate = nil;
    
    self.array_sw_encoder_priority_type = nil;
    
    [super dealloc];
}

@end
