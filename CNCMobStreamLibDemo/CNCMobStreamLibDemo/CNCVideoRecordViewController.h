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

/*
0 - @"默认镜像设置",
1 - @"预览:YES 编码:YES",
2 - @"预览:YES 编码:NO",
3 - @"预览:NO 编码:NO",
4 - @"预览:NO 编码:YES",
 */
@property (nonatomic) NSInteger mirror_idx;
@end
