//
//  CNCBaseNavigationController.m
//  CNCIJKPlayerDemo
//
//  Created by mfm on 16/5/12.
//  Copyright © 2016年 cad. All rights reserved.
//

#import "CNCBaseNavigationController.h"
//#import "CNCPlayerViewController.h"

@interface CNCBaseNavigationController ()

@end

@implementation CNCBaseNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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

#pragma mark 旋转相关
//旋转相关
-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

//You need this if you support interface rotation
//-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
//    NSLog(@"willAnimateRotationToInterfaceOrientation");
//}

- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)toInterfaceOrientation {
    
//    UIViewController *vc = self.topViewController;
//    if ([vc isKindOfClass:[CNCPlayerViewController class]]) {
//        return ((toInterfaceOrientation == UIInterfaceOrientationPortrait)
//                || (toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
//                || (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft)
//                || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
//                );
//    }
    
    //    return YES;
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}


//#pragma mark - IOS6.0 旋转
- (BOOL)shouldAutorotate {
//    UIViewController *vc = self.topViewController;
//    if ([vc isKindOfClass:[CNCPlayerViewController class]]) {
//        return YES;
//    }
    
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
//    UIViewController *vc = self.topViewController;
//    if ([vc isKindOfClass:[CNCPlayerViewController class]]) {
//        return UIInterfaceOrientationMaskAll;
//    }
    //return UIInterfaceOrientationLandscapeRight;
    return UIInterfaceOrientationMaskPortrait;
}

@end
