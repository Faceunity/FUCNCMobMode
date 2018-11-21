//
//  CNCMobStruct.h
//  CNCMobStreamDemo
//
//  Created by mfm on 16/4/21.
//  Copyright © 2016年 cad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "CNCMobComDef.h"


@interface CNCStreamCfg : NSObject {
    
}


@property (nonatomic, retain, setter=set_rtmp_url:) NSString *rtmp_url;//rtmp推流地址
@property (nonatomic) CNCENMEncoderType encoder_type;//硬编 软编 默认硬编
//@property (nonatomic) CNCResolutionType resolution_type;//分辨率 默认 CNCResolution_4_3__640x480
@property (nonatomic) CNCENMDirectType direction;//横屏 竖屏 默认横屏
@property (nonatomic) AVCaptureDevicePosition camera_position;//摄像头位置  默认后置摄像头

@property (nonatomic) NSInteger video_bit_rate;//码率 默认 1000
@property (nonatomic) NSInteger video_fps;//视频帧率 默认25
@property (nonatomic) NSInteger audio_sample_rate;//音频采样率 默认 44100
@property (nonatomic) NSInteger audio_channel;//默认 1
@property (nonatomic, readonly) NSInteger max_fps;//最大帧率 默认 30
@property (nonatomic, readonly) NSInteger min_fps;//最小帧率 默认 10

@property (nonatomic) BOOL has_video;//是否有视频  默认YES
@property (nonatomic) BOOL has_audio;//是否有音频  默认YES
@property (nonatomic, assign, getter=isMuted) BOOL muted;//是否设置了静音 默认为NO

//这两个值都是按横屏的时候的算的 
@property (nonatomic, readonly) NSInteger custom_width;
@property (nonatomic, readonly) NSInteger custom_height;

//@property (nonatomic) CNCResolutionScale resolution_scale;//分辨率 比例

@property (nonatomic, readonly) CNCResolutionType camera_resolution_type;//摄像头分辨率 默认 CNCResolution_4_3__640x480

@property (nonatomic, readonly) CNCVideoResolutionType video_encoder_resolution_type;// 输出视频分辨率


/*! @brief 设置输出视频分辨率
 *
 *
 * @param video_resolution_type 输出视频分辨率
 
 * @return 无。
 */
- (void)set_video_resolution_type:(CNCVideoResolutionType)video_resolution_type;


/*! @brief 设置摄取像头分辨率 并以摄像头分辨率为输出视频的分辨率
 *
 *
 * @param resolution_type 摄像头分辨率
 
 * @return 无。
 */
- (void)set_camera_resolution_type:(CNCResolutionType)resolution_type;



/*! @brief 将一个CNCStreamCfg对像another值赋给self
 *
 *
 * @param another 另一个CNCStreamCfg对像
 
 * @return 无。
 */
- (void)set_value_by_another:(CNCStreamCfg *)another;

/*! @brief 设置码率自适应上下限 若设置上限边界越界则采用默认边界 单位kbs
 *
 * @param max_bit_rate 上限
 * @param min_bit_rate 下限
 * @return 设置结果。
 *
 */
- (BOOL)set_resolution_max_bit_rate:(int)max_bit_rate min_bit_rate:(int)min_bit_rate;

/*! @brief 获取当前码率自适应上下限 单位kbs
 *
 * @param &max_bit_rate 上限
 * @param &min_bit_rate 下限
 * @return 设置结果。
 *
 */
- (void)get_resolution_max_bit_rate:(int *)max_bit_rate min_bit_rate:(int *)min_bit_rate;
@end

@interface CNCRoomInfo : NSObject {
    
}

@property (nonatomic, retain) NSString *room_id;//直播房间ID
@property (nonatomic, retain) NSString *anchor_id;//主播ID
@property (nonatomic, retain) NSString *user_id;//当前用户ID

/*! @brief 将一个CNCRoomInfo对像another值赋给self
 *
 *
 * @param another 另一个CNCRoomInfo对像
 
 * @return 无。
 */
- (void)set_value_by_another:(CNCRoomInfo *)another;

@end

#define kCNC_Undef_video_w_h -1

@interface CNCVideoSourceCfg : NSObject {
    
}


@property (nonatomic, retain, setter=set_rtmp_url:) NSString *rtmp_url;//rtmp推流地址
@property (nonatomic) CNCENMEncoderType encoder_type;//硬编 软编 默认硬编

@property (nonatomic) NSInteger video_bit_rate;//码率 默认 1000
@property (nonatomic) NSInteger video_fps;//视频帧率 默认25
@property (nonatomic) NSInteger audio_sample_rate;//音频采样率 默认 44100
@property (nonatomic) NSInteger audio_channel;//默认 1

@property (nonatomic) BOOL has_video;//是否有视频  默认YES
@property (nonatomic) BOOL has_audio;//是否有音频  默认YES
@property (nonatomic, assign, getter=is_muted) BOOL muted;//是否设置了静音 默认为NO

@property (nonatomic) BOOL need_push_audio_BG;//后台保持推音频 默认NO

//以下两值如果用默认值 编码器将会根据传入的buf的宽高自动算出输出视频宽高
@property (nonatomic) NSInteger video_width;//编码后的视频宽 默认 kCNC_Undef_video_w_h
@property (nonatomic) NSInteger video_height;//编码后的视频高 默认 kCNC_Undef_video_w_h

@property (nonatomic) BOOL is_adaptive_bit_rate;//自适应码率 默认NO 开始推流后不能再改

@property (nonatomic, readonly) NSInteger max_fps;//最大帧率 默认 30
@property (nonatomic, readonly) NSInteger min_fps;//最小帧率 默认 10


- (void)set_value_by_another:(CNCVideoSourceCfg *)another;

//
///*! @brief 获取当前码率自适应上下限 单位kbs
// *
// * @param &max_bit_rate 上限
// * @param &min_bit_rate 下限
// * @return 设置结果。
// *
// */
- (void)get_resolution_max_bit_rate:(int *)max_bit_rate min_bit_rate:(int *)min_bit_rate;

@end


@interface CNCAudioBufInfo : NSObject {
    
}

@property (nonatomic) char *buf_base;
@property (nonatomic) unsigned int len;
@property (nonatomic) unsigned int time_stamp;

@end

@interface CNCCaptureInfo : NSObject {
    
}
@property (nonatomic) AVCaptureDevicePosition camera_position;//摄像头位置  默认后置摄像头
@property (nonatomic) NSInteger capture_width;//采集的宽
@property (nonatomic) NSInteger capture_height;//采集的高
@property (nonatomic) CNCENMDirectType direction;
@property (nonatomic) NSInteger video_fps;//视频帧率 默认25
@property (nonatomic) CNCENM_Buf_Format format_type;
@property (nonatomic) CNCENMEncoderType encoder_type;//硬编 软编 默认硬编

- (void)set_value_by_another:(CNCCaptureInfo *)another;

@end


@interface CNCRecordFileInfo : NSObject {
    
}
@property (nonatomic) BOOL has_video;//是否有视频  默认YES
@property (nonatomic) BOOL has_audio;//是否有音频  默认YES
@property (nonatomic) int video_width;
@property (nonatomic) int video_height;
@property (nonatomic) int video_spslen;
@property (nonatomic) char* video_sps;
@property (nonatomic) int video_ppslen;
@property (nonatomic) char* video_pps;
@property (nonatomic) int video_fps;
@property (nonatomic) int video_bitrate;
@property (nonatomic) int audio_channel;

@property (nonatomic) int audio_sample_rate;
@property (nonatomic) BOOL need_push_audio_BG;//后台保持推音频 默认NO



- (void)set_value_by_another:(CNCRecordFileInfo *)another;
@end
