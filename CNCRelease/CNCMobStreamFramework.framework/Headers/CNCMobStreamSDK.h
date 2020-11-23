//
//  CNCMobStreamSDK.h
//  CNCMobStreamDemo
//
//  Created by mfm on 16/4/21.
//  Copyright © 2016年 cad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "CNCMobStruct.h"
#import "CNCMobComDef.h"

#define CNC_Notification_MobStreamSDK_Init_DidFinished @"CNC_Notification_MobStreamSDK_Init_DidFinished"


///错误码消息通知
extern NSString *kMobStreamSDKReturnCodeNotification;
///直播推流速率通知
extern NSString *kMobStreamSDKSendSpeedNotification;

@interface CNCMobStreamSDK : NSObject {
    
}

#pragma mark 公共接口

/*! @brief 向CNC注册第三方应用。
 *
 * 需要在每次启动第三方应用程序时调用， 此接口为同步接口 网络情况不好时 可能会耗时较长。
 
 * @param   appid    CNC分配给客户的ID
 authKey  CNC分配给客户的key
 * @return 详见错误码CNC_Ret_Code定义。
 */
+ (CNC_Ret_Code)regist_app:(NSString *)app_id auth_key:(NSString *)auth_key;


/*! @brief 向CNC注册第三方应用。
 *
 * 需要在每次启动第三方应用程序时调用， 此接口为异步接口 请在调用前监听CNC_Notification_MobStreamSDK_Init_DidFinished 消息 将返回结果的 NSNotification中的object对象从NSNumber转化为CNC_Ret_Code 错误信息详见错误码CNC_Ret_Code定义 。
 
 * @param   appid    CNC分配给客户的ID
 authKey  CNC分配给客户的key
 * @return 无。
 */
+ (void)async_regist_app:(NSString *)app_id auth_key:(NSString *)auth_key;


/*! @brief 查询当前SDK版本号。
 *
 * @param
 * @return 版本号。
 */
+ (NSString *)get_sdk_version;

/*! @brief 是否开启日志系统。
 *
 * 默认为关闭日志系统
 * @return 无。
 */
+ (void)set_log_system_enable:(BOOL)enable;

#pragma mark 业务接口  以下接口在registApp成功后方可使用
/*! @brief 设置推流参数。
 *
 * @param 推流参数 详见CNCStreamCfg定义
 * @return 设置是否成功。
 */
+ (BOOL)set_stream_config:(CNCStreamCfg *)para;


/*! @brief 设置视频显示以及展示的view
 *
 * @param preview 展示的view
 * @return 开启是否成功
 */
+ (BOOL)set_show_video_preview:(UIView *)preview;


/*! @brief 开始推流
 *
 * @param 无
 * @return 开启是否成功
 */
+ (BOOL)start_push;

/*! @brief 暂停推流
 *
 * @param 无
 * @return 暂停是否成功
 * 注：并没有关闭摄像头。
 */
+ (BOOL)pause_push;

/*! @brief 停止推流
 *
 * @param 无
 * @return 停止是否成功
 * 注：关闭摄像头、释放内存。
 */
+ (BOOL)stop_push;

/*! @brief 推流过程中获取当前启用的摄像头位置
 *
 * @param 无
 * @return 当前启用的摄像头位置
 */
+ (AVCaptureDevicePosition)get_came_pos;

/*! @brief 推流过程中切换摄像头
 *
 * @param 无
 * @return
 */
+ (void)swap_cameras;

/*! @brief 推流过程中切换到指定位置的摄像头
 *
 * @param 目标摄像头位置
 * @return
 */
+ (void)reset_came_pos:(AVCaptureDevicePosition)new_position;


/*! @brief 获取当前推流码率自适应的码率 单位kbps
 *
 * @param
 * @return 当前推流码率自适应的码率 单位kbps
 */
+ (NSInteger)get_bit_rate;

/*! @brief 获取当前推流使用的帧率 单位fps
 *
 * @param
 * @return 当前推流使用的帧率 单位fps
 */
+ (NSInteger)get_video_fps;

/*! @brief 推流过程中重置推流使用的码率
 *
 * @param 新的码率 单位kbps
 * @return 重置后推流使用的码率 单位kbps
 */
+ (NSInteger)reset_bit_rate:(NSInteger)new_bit_rate;

/*! @brief 设置 开启或关闭 闪光灯
 *
 * 默认为关闭闪光灯
 * @return 无。
 */
+ (void)set_torch_mode:(BOOL)enable;

/*! @brief 设置 开启或关闭 静音功能
 *
 * 默认为关闭静音
 * @return 无。
 */
+ (void)set_muted_statu:(BOOL)isMute;


/*! @brief 静音功能是否开启
 *
 * @return 静音状态。
 */
+ (BOOL)isMuted;

/*! @brief 设置 开启或关闭 码率自适应功能
 *
 * 默认为关闭码率自适应
 * @return 无。
 */
+ (void)set_adaptive:(BOOL)isAdaptive;

/*! @brief  重置预览界面
 *
 * @param frame 预览界面frame
 *
 *
 */
+ (void)reset_preview_frame:(CGRect)frame;

/*! @brief 设置水印 仅支持图片UIImageView及文字UILabel
 *
 * @param object 添加的水印 设置为nil为清除水印
 * @param scale 水印位置比例 (x,y,width,height) 范围为0~1
 * @param updateBlock 更新block 支持在block内对水印内容及图片进行修改
 * @return 添加水印结果
 */
+ (BOOL)overlayMaskWithObject:(UIView *)object rect:(CGRect)scale block:(void (^)(void))updateBlock;


/*! @brief 推流前 预览时中重置横竖屏 且要同时重置预览页 
 * 这个接口要和reset_preview_frame配合着用 因为旋转之后必然伴随着preview的frame发生变化 如长宽对换 另 如有水印也要重新设置
 *
 * @param new_direct 新的方向
 * @return 设置结果 成功为YES 失败为NO
 */
+ (BOOL)reset_direct:(CNCENMDirectType)new_direct;

/*! @brief 根据手机性能设置动态设置摄像头采集帧率
 *
 * @param auto_fps 开启动态设置
 *
 */
+ (void)global_enable_capture_auto_fps:(BOOL)auto_fps;

#pragma mark 镜像
/*! @brief 设置编码层镜像及预览层镜像
 *
 * @param source_mirror 编码层镜像
 * @param preview_mirror 预览层镜像
 *
 */
+ (void)set_source_mirror:(BOOL)source_mirror preview_mirror:(BOOL)preview_mirror;

#pragma mark 软编 质量/码率优先
/*! @brief 选择软编编码控制类型。
 *
 * @param nType 质量优先:1 码率优先:2
 * @return 无。
 */
+ (void)set_sw_encoder_priority_type:(int)nType;

#pragma mark 软编使用SEI
/*! @brief 软编编码开启SEI。
 *
 * @param json_str 发送字段
 * @return 无。
 */
+ (void)set_sw_encoder_push_time_stamp:(NSString *)json_str;
#pragma mark- 美颜方法
/*! @brief  美颜磨皮
 *
 * @param beauty 磨皮等级参数 值域为0~2.0 默认为1.0
 * @param effect 附加效果  值域为0~1.0 默认为0.5          (若无附加效果 此参数设置无效)
 * @param filter_effect 滤镜效果 值域为0~1.0 默认为0.5 （若滤镜效果不可调节 此参数设置无效）
 *
 */
+ (void)set_beauty_with:(CGFloat)beauty effect:(CGFloat)effect filter_effect:(CGFloat)fliter_effect;

/*! @brief  美颜样式选择
 *
 * @param type  CNCBEAUTY
 *
 
 */
+ (void)set_beauty_filter_with_type:(CNCBEAUTY)type;

/*! @brief  滤镜选择
 *
 * @param type  CNCCOMBINE
 *
 */
+ (void)set_combine_filter_with_type:(CNCCOMBINE)type;

#pragma mark- 推流前重置参数

/*! @brief 推流前重置推流地址url
 * 只可在开始推流前配置，推流过程中无法重置
 * @param urlString  推流地址url
 * @return 布尔值
 */
+ (BOOL)reset_url_string_before_pushing:(NSString *)urlString;


/*! @brief 获取当前推流使用的url
 *
 * @param
 * @return 当前推流使用的url
 */
+ (NSString *)get_rtmp_url_string;


#pragma mark - 聚焦变焦

/*! @brief 手动聚焦
 *
 * @param 传入聚焦的坐标
 * @return 是否设置成功
 */
+ (BOOL)tapFocusAtPoint:(CGPoint)point;

/*! @brief 变焦-拉远拉近、放大缩小
 *
 * @param 改变的倍数 值域 1.0~videoZoomFactorUpscaleThreshold
 * @return
 */
+ (void)videoZoomFactorWithScale:(CGFloat)effectiveScale;

/*! @brief 获取当前相机的最大放大倍数
 *
 * @param
 * @return videoZoomFactorUpscaleThreshold 上限阈值
 */
+ (CGFloat)get_current_camera_upscale;

#pragma mark - 调试信息帧统计开关

/*! @brief 获取视频帧统计信息。
 *
 * 默认为nil
 * @return 成功返回realTimeFrame，失败返回nil。
 */
+ (realTimeFrame *)get_statistics_message;


#pragma mark - 后台推流开关相关

///切换到后台时，是否继续推流 默认为NO
+ (BOOL)isContinuePushInBk;

/*! @brief 设置应用切换到后台时，推拉流是否继续
 * 注：后台继续推流以及后台继续拉流的状态必须统一
 * @param enable 继续推流传YES,终止推流传NO
 * 不设置时，默认为NO
 * @return 成功返回yes，失败返回NO。
 */
+ (BOOL)set_whether_continue_push_inBk:(BOOL)enable;


/*! @brief 设置全局音频默认输出到扬声器
 * 注：设置为NO时，可解决某些设备音频采集会有'哒哒哒'破音问题，
 * 同时音乐播放的声音从听筒出来会造成声音小问题
 * @param enable 扬声器传YES, 听筒传NO
 * 不设置时，默认为YES，即音频输出到扬声器
 * @return 无。
 */
+ (void)globalSetAudioExportDefaultToSpeaker:(BOOL)enable;


/*! @brief 设置应用音频采集的模式
 * @param mode CNCAudioSessionMode类型
 * 不设置时，默认为CNCAudioSessionModeDefault（VoIp）
 * @return 无。
 */
+ (void)globalSetAudioSessionMode:(CNCAudioSessionMode)mode;

#pragma mark - 音频相关

/*! @brief 采集是否开启降噪消回音自动增益等功能
 *
 * @param  enable 默认为关闭, 若需开启，传yes
 * 注：需在set_show_video_preview之前调用，否则无效
 * @return。
 */
+ (void)set_audio_process_enable:(BOOL)enable;

/**
 @abstract  查询当前是否有耳机
 */
+ (BOOL)is_headset_plugged_in;

// 是否开启耳返
+ (BOOL)isOpenMicVoiceReturnBack;

/*! @brief 是否开启耳返
 *
 * 默认为关闭,耳返功能只适用插入耳机的情况
 * @return。
 */
+ (void)set_audio_returnback:(BOOL)enable;

// 开启新音频采集，默认为开启状态
+ (void)setUsingAudioManagerEnable:(BOOL)enable;

///设置人声大小 0->1,默认 1.0f
+ (void)setHumanVolume:(Float32)value;

///设置音乐大小 0->1,默认 0.3f
+ (void)setMusicVolume:(Float32)value;

///设置总输出音量大小 0->1,默认 1.0f
+ (void)setOutPutVolume:(Float32)value;

///开始播放音乐或恢复播放音乐
+ (void)startPlayMusic;

///结束播放音乐
+ (void)stopPlayMusic;

///暂停播放
+ (void)pausePlayMusic;

/*!@brief  调节播放
 *
 * @param  position  0->1，传入进度条的位置值
 *
 */
+ (void)seekPlayheadTo:(CGFloat)position;


/*!@brief  传入播放音乐的地址，并设置是否循环播放
 *
 * @param  filePath  传入音乐文件的存放路径
 * @param  enable  是否循环播放
 *
 */
+ (BOOL)setUpAUFilePlayer:(NSString *)filePath loopEnable:(BOOL)enable;


/*! @brief  设置混响房间大小类型
 *
 * @param type  CNCAudioRoomType
 *
 */
+ (void)setAudioRoomType:(CNCAudioRoomType)type;


/*! @brief  设置混响影响因子
 *
 * @param value  [0->100], 默认60
 *
 */
+ (void)setAudioMixReverb:(Float32)value;

///获取状态
///当前人声音量大小
+ (Float32)currentHumanVolume;
///当前音乐音量大小
+ (Float32)currentMusicVolume;
///当前输出音量大小
+ (Float32)currentOutPutVolume;
///当前混响因子大小
+ (Float32)currentAudioMixReverb;
///音乐总时长 格式：0:00
+ (NSString *)getDurationString;

///当前播放时间字符串 格式：0:00
+ (NSString*)getPlayTimeString;

///当前播放进度【0~1】
+ (float)getPlayProgress;


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
+ (BOOL)start_store_video:(NSString *)path fileType:(CNCRecordVideoType)type max_time:(NSInteger)max_time long_store:(BOOL)long_store size:(uint64_t)size return_id:(NSString *)return_id;

/*! @brief 录制停止
 *
 * @return 录制文件存储路径
 */
+ (NSString *)stop_store_video;

/*! @brief 录制状态获取
 *
 * @return 是否处于录制状态
 */
+ (BOOL)is_doing_store;

/*! @brief  截屏
 *
 * @param path 截屏文件存储地址
 * @return 截屏是否成功
 *
 */
+ (BOOL)screen_shot:(NSString *)path;


#pragma mark - Socks5 相关

/*! @brief  是否打开Socket5
 */
+ (BOOL)isUseSocks5Push;


/*! @brief 打开Socks5推流
 * @param ip    代理IP地址
 * @param port  IP端口号
 * @param userName 用户名
 * @param passw    密码
 *
 * @return 是否设置参数成功；（并不对用户名以及密码做验证）；
 */
+ (BOOL)openSocks5WithIp:(NSString *)ip withPort:(NSInteger)port withUser:(NSString *)userName withPass:(NSString *)passw;


/*! @brief  关闭Socks5
 */
+ (void)closeSocks5;


#pragma mark --加强版镜像相关接口
/*! @brief 设置视频显示以及展示的view
 *
 * @param preview 展示的view
 * @param source_mirror 编码层镜像
 * @param preview_mirror 预览层镜像
 * @return 开启是否成功
 */
+ (BOOL)set_show_video_preview:(UIView *)preview source_mirror:(BOOL)source_mirror preview_mirror:(BOOL)preview_mirror;

/*! @brief 推流过程中切换摄像头
 *
 * @param source_mirror 编码层镜像
 * @param preview_mirror 预览层镜像
 * @return
 */
+ (void)swap_cameras:(BOOL)source_mirror preview_mirror:(BOOL)preview_mirror;

/*! @brief 查询当前编码层是否镜像
*
* @return 编码层镜像值
*/
+ (BOOL)get_cur_source_mirror;

/*! @brief 查询当前预览层是否镜像
*
* @return 预览层镜像值
*/
+ (BOOL)get_cur_preview_mirror;
@end
