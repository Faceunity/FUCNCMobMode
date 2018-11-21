//
//  CNCMobStreamRtmpSender.h
//  CNCMobStreamDemo
//
//  Created by weiyansheng on 2017/5/3.
//  Copyright © 2017年 cad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "CNCMobStreamTimeStampGenerator.h"


@protocol CNCMobStreamRtmpSenderDelegate;

@interface CNCMobStreamRtmpSender : NSObject

///推流地址
@property (nonatomic, copy) NSString *rtmp_url;

///码率自适应回调
@property (nonatomic, assign) id<CNCMobStreamRtmpSenderDelegate> delegate;


/*! @brief 初始化方法
 *
 * @param urlString 推流地址
 * @return 句柄，失败返回nil
 */
- (instancetype)initWithRtmpUrlString:(NSString *)urlString;

/*! @brief 开始连接推流
 *
 * @param timeGenerator 时间戳管理器，用于控制帧的发送队列
 * @return 推流地址为空，推流失败返回NO，成功返回yes；
 */
- (BOOL)startConnect:(CNCMobStreamTimeStampGenerator *)timeGenerator;


/*! @brief 停止推流
 * @return 失败返回NO，成功返回yes
 */
- (BOOL)stopConnect;


/*! @brief 开启码率自适应
 *
 * @param minRate 最小码率
 * @param maxRate 最大码率
 * @param currentRate 初始化码率
 * @return 参数不对，设置失败返回NO，成功返回yes；
 */
- (BOOL)openVideoBitRateAutoFitWithMiniRate:(NSUInteger)minRate MaxiRate:(NSUInteger)maxRate CurrentRate:(NSUInteger)currentRate;

/*! @brief 关闭码率自适应
 * @return 无
 */
- (void)closeVideoBitRateAutoFit;

/*! @brief 发送meta data 头
 *
 * @param videoSize 视频分辨率 videoSize.witdh宽 videoSize.height高
 * @param frame_rate 视频帧率
 * @param video_bit_rate 视频码率
 * @param audio_rate 音频采样率
 * @param audio_channel 音频channel
 * @return 无；
 */
- (void)send_meta_data:(CGSize)videoSize frame_rate:(int)fps video_bit_rate:(int)video_bit_rate audio_rate:(int)rate audio_channel:(int)channel;

/*! @brief 发送视频头信息
 *
 * @param spsData
 * @param ppsData
 * @return 无；
 */
- (void)send_video_header:(NSData *)spsData PPS:(NSData *)ppsData;

/*! @brief 发送音频头信息
 *
 * @param rate 音频采样率
 * @param channel 音频声道数
 * @return 无；
 */
- (void)send_acc_header:(int)rate channel:(int)channel;

/*! @brief 发送视频帧数据
 *
 * @param (char *)sz H264数据
 * @param len H264数据长度
 * @param is_key 是否关键帧
 * @param width 视频图像的宽
 * @param height 视频图像的高
 * @param time_stamp 视频帧的时间戳
 * @return 无；
 */
- (void)send_video:(char *)sz len:(unsigned int)len is_key:(bool)is_key width:(int)width height:(int)height time_stamp:(unsigned int)time_stamp;

/*! @brief 发送音频帧数据
 *
 * @param (char *)src_sz AAC数据
 * @param len AAC数据长度
 * @param time_stamp 音频帧的时间戳
 * @return 无；
 */
- (void)send_audio:(char *)src_sz len:(unsigned int)len time_stamp:(unsigned int)time_stamp;

@end

@protocol CNCMobStreamRtmpSenderDelegate <NSObject>

@optional

///码率自适应回调，需要相应去设置视频编码器（CNCMobStreamVideoEncoder）的 real_bit_rate 属性
- (void)videoBitRateAdaptiveCorrection:(NSUInteger)bit_rate;

@end
