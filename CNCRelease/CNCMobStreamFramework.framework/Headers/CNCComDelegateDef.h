//
//  CNCComDelegateDef.h
//  CNCMobStreamDemo
//
//  Created by mfm on 16/12/15.
//  Copyright © 2016年 cad. All rights reserved.
//

#ifndef CNCComDelegateDef_h
#define CNCComDelegateDef_h
#import "CNCMobStruct.h"
typedef struct {
    long actual_per_fps;
    long actual_total_send_frame;
    long beauty_before_fps;
    //    long beauty_before_total;
    long beauty_after_fps;
    //    long beauty_after_total;
    long drop_pakage_num;
    long drop_frame_num;
    
}realTimeLayeredFrame;

@protocol CNCDelegatePlayerOnFrame <NSObject>

//请delegate实现者
//1 先同步copy数据块内容 以防异步情况下数据块被原生成者释放
//2 然后异步处理copy走的数据据 以防影响原播放器处理流程 比如处理流程太长 导致播放卡顿


/*! @brief 视频帧处理
 *
 * @param
 * frame 的 Y、U、V
 * stride Y、U、V的宽度
 * width  height  frame的宽高
 * ts 时间戳
 * @return void
 */
- (void)on_video_frame_available:(unsigned char *)y ubuf:(unsigned char *)u vbuf:(unsigned char *)v ystride:(int)ystride ustride:(int)ustride vstride:(int)vstride width:(int)width height:(int)height time_stamp:(unsigned)ts;


/*! @brief 音频帧处理
 *
 * @param
 * buf  音频数据源
 * len  长度
 * ts   时间戳
 * sample_rate  采样率
 * channel  通道
 * @return void
 */
- (void)on_audio_frame_available:(unsigned char *)buf len:(int)len time_stamp:(unsigned)ts sample_rate:(int)sample_rate channel:(int)channel;

@end


//时间戳生成器 视频帧 音频帧生成时用
@protocol CNCDelegateTsForEncoder <NSObject>

- (unsigned int)get_video_time_stamp;
- (unsigned int)get_audio_time_stamp;

@end


//推流时 因为发送音视频帧时要保证时间戳全局是递增的 所有有一些需要处理的
@protocol CNCDelegateTsForPusher <NSObject>

//获取最早一个还未发送的视频帧时间戳
- (unsigned int)get_min_video_ts_no_send;
- (void)remove_no_send_video_ts_small_than_t:(unsigned int)t;

@end


//RTMP推流接口
@protocol CNCDelegateRtmpSender <NSObject>

- (int)send_video_meta_data:(int)w height:(int)h frame_rate:(int)rate video_bit_rate:(int)video_bit_rate time_stamp:(unsigned int)time_stamp;

- (int)send_video_header:(char *)sps spslen:(int)spslen pps:(char *)pps ppslen:(int)ppslen time_stamp:(unsigned int)time_stamp;

- (int)send_video:(char *)sz len:(unsigned int)len is_key:(bool)is_key width:(int)width height:(int)height time_stamp:(unsigned int)time_stamp;

- (int)send_acc_header:(int)rate channel:(int)channel time_stamp:(unsigned int)time_stamp;
- (int)send_audio:(char *)sz len:(unsigned int)len time_stamp:(unsigned int)time_stamp;

@end

//推流时 因为发送音视频帧时要保证时间戳全局是递增的 所有有一些需要处理的
@protocol CNCDelegatePushPara <NSObject>

@optional
//用SDK的采集需要如下接口
- (BOOL)set_video_frame_statistics_enable:(BOOL)enable;
- (realTimeLayeredFrame *)get_statictics_struct;
- (BOOL)get_is_support_layered_statictics;
- (void)set_adaptive_bit_rate:(BOOL)isAdaptive;
@required
- (NSString *)get_rtmp_url_string;
- (BOOL)reset_url_string_before_pushing:(NSString *)urlString;
- (NSInteger)get_bit_rate;
- (NSInteger)reset_bit_rate:(NSInteger)new_bit_rate;
- (NSInteger)get_audio_rate;
- (NSInteger)get_audio_channel;
- (NSInteger)get_video_fps;
- (void)set_muted:(BOOL)muted;
- (BOOL)is_muted;
- (BOOL)need_push_audio_BG;
- (NSInteger)get_video_width;
- (NSInteger)get_video_height;

- (BOOL)has_audio;
- (BOOL)has_video;
- (NSInteger)get_encoder_type;
@end



#endif /* CNCComDelegateDef_h */
