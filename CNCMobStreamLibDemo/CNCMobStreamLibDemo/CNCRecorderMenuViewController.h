//
//  CNCRecorderMenuViewController.h
//  CNCIJKPlayerDemo
//
//  Created by mfm on 16/5/12.
//  Copyright © 2016年 cad. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InfrastructureViewController.h"

@interface CNCRecorderMenuViewController : InfrastructureViewController


@property (nonatomic) NSInteger cur_idx;

///分辨率
@property (nonatomic, retain) NSArray *array_video_resolution;
@property (nonatomic, retain) NSArray *array_value_video_resolution;
@property (nonatomic, retain) NSArray *array;
@property (nonatomic, retain) NSArray *array_value;


@property (nonatomic, retain) UITextField *width_textField;
@property (nonatomic, retain) UITextField *height_textField;

//@property (nonatomic) BOOL need_custom_w_x_h;
@property (nonatomic) BOOL use_recommend_video_resolution;
@property (nonatomic) NSInteger cur_idx_video;

@property (nonatomic) NSInteger def_width;
@property (nonatomic) NSInteger def_height;

@property (nonatomic, retain) UISwitch *socksSwitch;


@end
