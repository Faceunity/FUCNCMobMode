//
//  CNCVideoSourceInput.h
//  CNCMobStreamDemo
//
//  Created by mfm on 16/12/14.
//  Copyright © 2016年 cad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CNCMobStruct.h"
#import "CNCComDelegateDef.h"


@interface CNCVideoSourceInput : NSObject

/*! @brief 推流过程中参数设置
 *
 * @param para
 *
 * @return 设置结果
 */
- (BOOL)preset_para:(CNCVideoSourceCfg *)para;

/*! @brief 开启音频采集
 *
 */
- (void)start_audio_by_collect_type:(BOOL)is_enable_processing;

/*! @brief 开始推流
 *
 * @param 无
 * @return 开启是否成功
 */
- (BOOL)start_push;

/*! @brief 暂停推流
 *
 * @param 无
 * @return 暂停是否成功
 * 注：并没有关闭摄像头。
 */
- (BOOL)pause_push;

/*! @brief 停止推流
 *
 * @param 无
 * @return 停止是否成功
 * 注：关闭摄像头、释放内存。
 */
- (BOOL)stop_push;

/*! @brief 设置 开启或关闭 静音功能
 *
 * 默认为关闭静音
 * @return 无。
 */
- (void)set_muted_status:(BOOL)is_mute;

/*! @brief 获取  静音状态
 *
 * @return 静音状态。
 */
- (BOOL)get_is_muted;

/*! @brief 推流前重置推流地址url
 * 只可在开始推流前配置，推流过程中无法重置
 * @param 推流地址url
 * @return 布尔值
 */
- (BOOL)reset_url_string_before_pushing:(NSString *)urlString;

/*! @brief 推流过程中重置推流使用的码率
 *
 * @param 新的码率 单位kbps
 * @return 重置后推流使用的码率 单位kbps
 */
- (NSInteger)reset_bit_rate:(NSInteger)new_bit_rate;

/*! @brief 获取当前推流使用的url
 *
 * @param
 * @return 当前推流使用的url
 */
- (NSString *)get_rtmp_url_string;

/*! @brief 获取当前推流码率自适应的码率 单位kbps
 *
 * @param
 * @return 当前推流码率自适应的码率 单位kbps
 */
- (NSInteger)get_bit_rate;

/*! @brief 获取当前推流使用的帧率 单位fps
 *
 * @param
 * @return 当前推流使用的帧率 单位fps
 */
- (NSInteger)get_video_fps;

/*! @brief 将视频帧数据buf发给SDK用于编码及RTMP推流。
 *
 * @param buf 视频帧数据块起始地址
 * @param pix_width 数据块横向字节数
 * @param pix_height 数据块纵向字节数 pix_width*pix_height是BUF的总大小
 * @param format 数据块格式
 * @param ts 视频帧的时间戳
 * @return 无。
 */
- (void)send_frame_buf:(void *)buf pix_width:(int)pix_width pix_height:(int)pix_height format:(CNCENM_Buf_Format)format time_stamp:(long long)ts;

/*! @brief 将视频帧数据pixelBuffer发给SDK用于编码及RTMP推流。
 *
 * @param pixelBuffer 视频帧数据块起
 * @param format 数据块格式
 * @param ts 视频帧的时间戳
 * @return 无。
 */
- (void)send_frame_pixelBufferRef:(CVPixelBufferRef)pixelBuffer format:(CNCENM_Buf_Format)format time_stamp:(long long)ts;

// deprecated; use DeliverFrame instead
//+ (void)SendFrameNV21:(void *)nv21 width:(int)width height:(int)height rotation:(int)rotation timeStamp:(long long)ts;
//// deprecated; use DeliverFrame instead
//+ (void)SendFrameI420:(void *)i420 width:(int)width height:(int)height rotation:(int)rotation timeStamp:(long long)ts;
// deprecated; use DeliverFrame instead

/** Input a frame to engine
 *
 * width, height: size of 'buf' in pixels
 // * cropLeft: how many pixels to crop on the left boundary
 // * cropTop: how many pixels to crop on the top boundary
 // * cropRight: how many pixels to crop on the right boundary
 // * cropBottom: how many pixels to crop on the bottom boundary
 * rotation: 0, 90, 180, 270. See document for rotation calculation
 * ts: timestamp for this frame. in milli-second, since 1970
 * format: 1: I420 2: ARGB 3: NV21 4: RGBA
 *
 * width/height/cropLeft/cropTop/cropRight/cropBottom: specifying the rotated buffer,
 * not pre-rotate buffer
 */

#pragma mark - 音频相关
///切换到后台时，是否继续推流 默认为NO
- (BOOL)isContinuePushInBk;

/*! @brief 设置应用切换到后台时，推拉流是否继续
 * 继续推流传YES,终止推流传NO
 * 不设置时，默认为NO
 * @return 成功返回yes，失败返回NO。
 * 注：后台继续推流以及后台继续拉流的状态必须统一
 */
- (BOOL)set_whether_continue_push_inBk:(BOOL)enable;


/**
 @abstract  查询当前是否有耳机
 */
- (BOOL)is_headset_plugged_in;

// 是否开启耳返
- (BOOL)isOpenMicVoiceReturnBack;

/*! @brief 是否开启耳返
 *
 * 默认为关闭,耳返功能只适用插入耳机的情况
 * @return。
 */
- (void)set_audio_returnback:(BOOL)enable;


///设置人声大小 0->1,默认 1.0f
- (void)setHumanVolume:(Float32)value;

///设置音乐大小 0->1,默认 0.3f
- (void)setMusicVolume:(Float32)value;

///设置总输出音量大小 0->1,默认 1.0f
- (void)setOutPutVolume:(Float32)value;

///开始播放音乐或恢复播放音乐
- (void)startPlayMusic;

///结束播放音乐
- (void)stopPlayMusic;

///暂停播放
- (void)pausePlayMusic;

/*!@brief  调节播放
 *
 * @param  position  0->1，传入进度条的位置值
 *
 */
- (void)seekPlayheadTo:(CGFloat)position;


/*!@brief  传入播放音乐的地址，并设置是否循环播放
 *
 * @param  filePath  传入音乐文件的存放路径
 * @param  enable  是否循环播放
 *
 */
- (BOOL)setUpAUFilePlayer:(NSString *)filePath loopEnable:(BOOL)enable;


/*! @brief  设置混响房间大小类型
 *
 * @param type  CNCAudioRoomType
 *
 */
- (void)setAudioRoomType:(CNCAudioRoomType)type;


/*! @brief  设置混响影响因子
 *
 * @param value  [0->100], 默认60
 *
 */
- (void)setAudioMixReverb:(Float32)value;

///获取状态
///当前人声音量大小
- (Float32)currentHumanVolume;
///当前音乐音量大小
- (Float32)currentMusicVolume;
///当前输出音量大小
- (Float32)currentOutPutVolume;
///当前混响因子大小
- (Float32)currentAudioMixReverb;
///音乐总时长 格式：0:00
- (NSString *)getDurationString;

///当前播放时间字符串 格式：0:00
- (NSString*)getPlayTimeString;

///当前播放进度【0~1】
- (float)getPlayProgress;

/*! @brief 获取视频帧统计信息。
 *
 * 默认为nil
 * @return 成功返回realTimeFrame，失败返回nil。
 */
- (realTimeLayeredFrame *)get_statistics_message;
#pragma mark - 录制、截屏功能
/*! @brief 录制开始
 *  录制分为长短视频、GIF录制，其中视频录制又细分为flv、MP4两种。其中短视频、GIF录制可以设置录制时长控制，长视频录制可设置大小控制。
 *  当录制时长、大小达到预设值时自动结束当前录制并保存结果。
 *  另有提示码提示录制结果 录制开始前请监听返回码 CNC_Notification_MobStreamSDK_ReturnCode
 * @param path 录制文件存储地址
 * @param type 录制文件类型
 * @param max_time 录制时长 短视频录制时长控制值域为 3.0s~60.0s。GIF录制时长值域为100.0ms~5.0s。
 * @param long_store 录制长、短视频类型
 * @param size 录制文件大小 长视频录制大小控制最小值为100kb，不足最小值以最小值为准。
 * @param return_id 确认ID 随同录制结束返回
 *
 * @return 录制start结果
 */
- (BOOL)start_store_video:(NSString *)path fileType:(CNCRecordVideoType)type max_time:(NSInteger)max_time long_store:(BOOL)long_store size:(uint64_t)size return_id:(NSString *)return_id;

/*! @brief 录制停止
 *
 * @return 录制文件存储路径
 */
- (NSString *)stop_store_video;

/*! @brief 录制状态获取
 *
 * @return 是否处于录制状态
 */
- (BOOL)is_doing_store;

/*! @brief 选择软编编码控制类型。
 *
 * @param nType 质量优先:1 码率优先:2
 * @return 无。
 */
- (void)set_sw_encoder_priority_type:(int)nType;

/*! @brief 软编编码开启SEI。
 *
 * @param json_str 发送字段
 * @return 无。
 */
- (void)set_sw_encoder_push_time_stamp:(NSString *)json_str;
@end
