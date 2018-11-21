//
//  CNCDemoVideoCaptureViewController.h
//  CNCMobStreamDemo
//
//  Created by mfm on 16/12/16.
//  Copyright © 2016年 cad. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonInclude.h"

@interface CNCDemoVideoCaptureViewController : UIViewController {
    
}

@property (nonatomic) CNCENM_Buf_Format pixel_format_type;//1 I420  2 NV12 3 NV21 4 RGBA
@property (nonatomic) CNCENMDirectType video_direct_type;//横竖屏
@property (nonatomic, retain) NSString *came_resolution;

@property (nonatomic, retain) CNCVideoSourceCfg *para;
@property (nonatomic) NSInteger came_sel_type;//0 后置 1 前置  2 纯音频
@property (nonatomic) BOOL openOrClosePushInBk;
//@property (nonatomic, retain) CNCVideoSourceCfg *stream_cfg;
@property (nonatomic) BOOL new_format_input;
@property (nonatomic, assign) int sw_encoder_priority_type;
@end
