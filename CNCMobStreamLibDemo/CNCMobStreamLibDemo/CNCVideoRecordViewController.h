//
//  CNCVideoRecordViewController.h
//  CNCMobStreamDemo
//
//  Created by mfm on 16/4/21.
//  Copyright © 2016年 cad. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonInclude.h"

@interface CNCVideoRecordViewController : UIViewController {
    
}


@property (nonatomic, retain) CNCStreamCfg *stream_cfg;

@property (nonatomic, assign) int sw_encoder_priority_type;
@end
