//
//  AppDelegate.m
//  CNCMobStreamLibDemo
//
//  Created by mfm on 16/5/19.
//  Copyright © 2016年 chinanetcenter. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "CNCBaseNavigationController.h"




@interface AppDelegate ()

@end

@implementation AppDelegate

//- (void)umengTrack {
//    //    [MobClick setAppVersion:XcodeAppVersion]; //参数为NSString * 类型,自定义app版本信息，如果不设置，默认从CFBundleVersion里取
//    [MobClick setLogEnabled:YES];
//    UMConfigInstance.appKey = UMENG_APPKEY;
//    UMConfigInstance.secret = @"secretstringaldfkals";
//    //    UMConfigInstance.eSType = E_UM_GAME;
//    [MobClick startWithConfigure:UMConfigInstance];
//}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
//    [self umengTrack];
    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    
    [self.window makeKeyAndVisible];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    ViewController *mainViewController = [[[ViewController alloc] init] autorelease];
    
    
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    //    MEditCardViewController *mainViewController = [[[MEditCardViewController alloc] init] autorelease];
    
    //    MBaseNavigationViewController *nav = [[[MBaseNavigationViewController alloc] initWithRootViewController:mainViewController] autorelease];
    
//    UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:mainViewController] autorelease] ;

    CNCBaseNavigationController *nav = [[[CNCBaseNavigationController alloc] initWithRootViewController:mainViewController] autorelease];
    
    
    self.window.rootViewController = nav;

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
