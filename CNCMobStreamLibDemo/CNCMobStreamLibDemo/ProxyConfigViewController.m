//
//  ProxyConfigViewController.m
//  CNCMobStreamDemo
//
//  Created by weiyansheng on 2017/4/17.
//  Copyright © 2017年 cad. All rights reserved.
//

#import "ProxyConfigViewController.h"
#import "CommonInclude.h"

@interface ProxyConfigViewController ()

@end

@implementation ProxyConfigViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.ip_tf.text = [userDefaults stringForKey:@"CNCMobSteamSDK_Proxy_IP"];
    self.port_tf.text = [userDefaults stringForKey:@"CNCMobSteamSDK_Proxy_Port"];
    self.user_tf.text = [userDefaults stringForKey:@"CNCMobSteamSDK_Proxy_User"];
    self.passw_tf.text = [userDefaults stringForKey:@"CNCMobSteamSDK_Proxy_Passw"];
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

- (IBAction)cancleButtonAction:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)sureButtonAction:(UIButton *)sender {
    
    if (self.ip_tf.text.length <=0 ) {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"错误提示" message:@"IP地址不能为空！！！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] autorelease];
        [alert show];
        alert = nil;
        return;
    }
    
    if (self.port_tf.text.length <=0 ) {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"错误提示" message:@"IP端口号不能为空！！！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] autorelease];
        [alert show];
        alert = nil;
        return;
    }
    
    if (self.user_tf.text.length <=0 ) {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"错误提示" message:@"用户名不能为空！！！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] autorelease];
        [alert show];
        alert = nil;
        return;
    }
    
    
    if (self.passw_tf.text.length <=0 ) {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"错误提示" message:@"密码不能为空！！！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] autorelease];
        [alert show];
        alert = nil;
        return;
    }
    
    NSString *port = self.port_tf.text;
    
    NSInteger port_int = [port integerValue];
    
    BOOL bSuccess = [CNCMobStreamSDK openSocks5WithIp:self.ip_tf.text withPort:port_int withUser:self.user_tf.text withPass:self.passw_tf.text];
    
    if (bSuccess) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"提示" message:@"设置不成功！！！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] autorelease];
        [alert show];
        alert = nil;
    }
    
}

- (void)dealloc {
    
    self.ip_tf = nil;
    self.port_tf = nil;
    self.user_tf = nil;
    self.passw_tf = nil;
    
    [super dealloc];
}


@end
