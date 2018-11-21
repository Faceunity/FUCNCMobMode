//
//  CNCVideoLayeredViewController.h
//  CNCMobStreamLibDemo
//
//  Created by 82008223 on 2017/3/28.
//  Copyright © 2017年 chinanetcenter. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonInclude.h"

@interface CNCVideoLayeredViewControllerFU : UIViewController

@property (nonatomic, retain) CNCVideoSourceCfg *stream_cfg;
@property (nonatomic, retain) CNCCaptureInfo *capture_info;
@property (nonatomic, assign) int sw_encoder_priority_type;
@end
