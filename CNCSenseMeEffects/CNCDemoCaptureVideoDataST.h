//
//  CNCDemoCaptureVideoDataST.h
//  senseMe_Demo
//
//  Created by 82008223 on 2017/12/15.
//  Copyright © 2017年 82008223. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "CNCSenseMeEffectsManager.h"

@class CNCDemoCaptureVideoDataST;

@protocol CNCDemoCaptureVideoDataSTDelegate <NSObject>
- (void)get_senseMe_work:(BOOL)is_open;
- (void)video_capture_st:(CNCDemoCaptureVideoDataST*)capture buf:(void *)buf pix_width:(int)pix_width pix_height:(int)pix_height format:(CNCENM_Buf_Format)format time_stamp:(int64_t)ts;
- (void)capture_view_set_ges:(BOOL)is_open;
@end
@interface CNCDemoCaptureVideoDataST : NSObject {
    
}
@property (nonatomic, assign) id<CNCDemoCaptureVideoDataSTDelegate> delegate;
//@property (nonatomic, retain) CNCRTCEngineKit *rtc_kit;
@property (nonatomic, assign) BOOL use_senseMe;
- (id)init_with_preview:(UIView *)preview direct:(CNCENMDirectType)direct;
- (BOOL)start_capture;
- (void)stop_capture;

/*! @brief 设置采集参数
 * @param new_size 重置预览页面大小
 */
- (void)reset_preview_size:(CGSize)new_size;

@end
