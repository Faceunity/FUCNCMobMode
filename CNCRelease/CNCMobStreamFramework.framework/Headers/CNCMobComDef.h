//
//  CNCMobComDef.h
//  CNCMobStreamDemo
//
//  Created by mfm on 16/4/27.
//  Copyright © 2016年 cad. All rights reserved.
//

#ifndef CNCMobComDef_h
#define CNCMobComDef_h

#import <UIKit/UIKit.h>

#define kCNCSysVerson [[[UIDevice currentDevice] systemVersion] floatValue]
#define CNC_Notification_MobStreamSDK_ReturnCode @"CNC_Notification_MobStreamSDK_ReturnCode"
#define CNC_Notification_MobStreamSDK_SendSpeed @"CNC_Notification_MobStreamSDK_SendSpeed"

#pragma mark cfg param

/// 软硬编选择，硬编优先于软编
typedef NS_ENUM(NSUInteger, CNCENMEncoderType)
{
    CNC_ENM_Encoder_HW = 1,
    CNC_ENM_Encoder_SW = 2,
};

/// 选择横竖屏
typedef NS_ENUM(NSUInteger, CNCENMDirectType)
{
    CNC_ENM_Direct_Horizontal = 1,
    CNC_ENM_Direct_Vertical = 2,
};


/// 采集分辨率，默认为 4 : 3 宽高比，640 x 480 分辨率
typedef NS_ENUM(NSUInteger, CNCResolutionType) {
    /// 5 : 4 宽高比，352 x 288 分辨率
    CNCResolution_5_4__352x288 =0,
    /// 4 : 3 宽高比，640 x 480 分辨率
    CNCResolution_4_3__640x480,
    /// 16 : 9 宽高比，960 x 540 分辨率
    CNCResolution_16_9__960x540,
    /// 16 : 9 宽高比，1280 x 720 分辨率
    CNCResolution_16_9__1280x720,
    /// 16 : 9 宽高比，1920 x 1080 分辨率
    CNCResolution_16_9__1920x1080
};


///混音混响房间类型
typedef CF_ENUM(UInt32, CNCAudioRoomType) {
    CNCAudioRoomType_SmallRoom		= 0,
    CNCAudioRoomType_MediumRoom		= 1,
    CNCAudioRoomType_LargeRoom		= 2,
    CNCAudioRoomType_MediumHall		= 3,
    CNCAudioRoomType_LargeHall		= 4,
    CNCAudioRoomType_Plate			= 5,
    CNCAudioRoomType_MediumChamber	= 6,
    CNCAudioRoomType_LargeChamber	= 7,
    CNCAudioRoomType_Cathedral		= 8,
    CNCAudioRoomType_LargeRoom2		= 9,
    CNCAudioRoomType_MediumHall2	= 10,
    CNCAudioRoomType_MediumHall3	= 11,
    CNCAudioRoomType_LargeHall2		= 12
};

///输出分辨率
typedef NS_ENUM(NSUInteger, CNCVideoResolutionType) {
    // 4 : 3 宽高比，360P
    CNCVideoResolution_360P_4_3 = 1,
    // 16 : 9 宽高比，360P
    CNCVideoResolution_360P_16_9 = 2,
    
    // 4 : 3 宽高比，480P
    CNCVideoResolution_480P_4_3 = 3,
    // 16 : 9 宽高比，480P
    CNCVideoResolution_480P_16_9 = 4,
    
    // 4 : 3 宽高比，540P
    CNCVideoResolution_540P_4_3 = 5,
    // 16 : 9 宽高比，360P
    CNCVideoResolution_540P_16_9 = 6,
    
    // 4 : 3 宽高比，720P
    CNCVideoResolution_720P_4_3 = 7,
    // 16 : 9 宽高比，720P
    CNCVideoResolution_720P_16_9 = 8,
};

/// 选择录制视频存储格式
typedef NS_ENUM(NSUInteger, CNCRecordVideoType) {
    CNCRecordVideoType_Error = 0,
    CNCRecordVideoType_FLV = 1,
    CNCRecordVideoType_GIF = 2,
    CNCRecordVideoType_MP4 = 3,
    CNCRecordVideoType_JPG = 4,
};

/// 磨皮美颜效果
typedef NS_ENUM(NSUInteger,CNCBEAUTY) {
    //无磨皮
    CNCBEAUTY_NONE          = 0,
    //仅磨皮
    CNCBEAUTY_POLISH        = 1,
    //磨皮+皮肤美白
    CNCBEAUTY_SKIN_LIGHTEN  = 2,
    //磨皮+皮肤红润
    CNCBEAUTY_SKIN_RUDDY    = 3,
    //磨皮+全屏美白
    CNCBEAUTY_BRIGHTEN      = 4,
    //美肤
    CNCBEAUTY_SKIN_POLISH   = 5
};

typedef NS_ENUM(NSUInteger,CNCCOMBINE) {
    //无滤镜
    CNCCOMBINE_NONE         = 0,
    //怀旧
    CNCCOMBINE_SOFT         = 1,
    //曝光
    CNCCOMBINE_EXPOSURE     = 2,
    //对比度
    CNCCOMBINE_CONTRAST     = 3,
    //浓度
    CNCCOMBINE_CHROMA       = 4,
    //加深
    CNCCOMBINE_DEEPEN       = 5,
    //阴霾
    CNCCOMBINE_HAZE       = 6,
    //底片
    CNCCOMBINE_FILM         = 7,
    //单色
    CNCCOMBINE_MONOCHROME   = 8,
    //阴影
    CNCCOMBINE_SHADOW       = 9,
    //色度
    CNCCOMBINE_HUE          = 10,
    //漫画
    CNCCOMBINE_CARTOON          = 11,
    //素描
    CNCCOMBINE_SKETCH          = 12,
    //马赛克
    CNCCOMBINE_MOSAIC = 13,
    //旋涡
    CNCCOMBINE_SWIRL          = 14,
    //晕影
    CNCCOMBINE_VIGNETTE          = 15,
    //鱼眼
    CNCCOMBINE_FISHEYE          = 16,
    //哈哈镜
    CNCCOMBINE_DISTORTION          = 17,
    //分离
    CNCCOMBINE_SEPARATE         = 18,
    //浮雕
    CNCCOMBINE_RELIEF        = 19,
    //锐化
    CNCCOMBINE_SHARPEN          = 20,
};

#pragma mark - return code

/// 返回码
typedef NS_ENUM(NSUInteger, CNC_Ret_Code) {

    //通用
    /// SDK正在初始化
    CNC_RCode_Com_SDK_Doing_Init = 1000,
    /// SDK初始化成功
    CNC_RCode_Com_SDK_Init_Success = 1001,
    /// 输入参数错误
    CNC_RCode_Com_Input_Para_Error = 1101,
    /// SDK工作异常
    CNC_RCode_Com_SDK_Work_Error = 1103,
    /// SDK初始化失败
    CNC_RCode_Com_SDK_Init_Fail = 1104,
    /// 服务器响应错误
    CNC_RCode_Com_Srv_Response_Error = 1105,
    /// SDK未初始化
    CNC_RCode_Com_SDK_UnInit = 1106,
    /// 服务器响应超时
    CNC_RCode_Com_Srv_Response_Timeout = 1107,
    ///无效URL
    CNC_RCode_Com_Invalid_URL = 1108,
    ///域名解析错误
    CNC_RCode_Com_URL_Unresolved = 1109,
    /// 代理接口连接失败
    CNC_RCode_Com_Proxy_Connect_Failed = 1116,
    /// 未知错误
    CNC_RCode_Com_Unknown_Error = 1199,
    
    
    //用户鉴权 错误级别返回码
    /// 正在鉴权中…
    CNC_RCode_Auth_Authorizing = 2001,
    /// 过期
    CNC_RCode_Auth_OutOfDate = 2101,
    /// SDK版本过低
    CNC_RCode_Auth_Ver_IsNotTheLatest = 2102,
    /// SDK类型不匹配
    CNC_RCode_Auth_SDK_Unmatched = 2103,
    /// AppID类型不匹配
    CNC_RCode_Auth_AppID_Unmatched = 2104,
    /// authKey不匹配
    CNC_RCode_Auth_AuthKey_Unmatched = 2105,
    /// 网络异常
    CNC_RCode_Auth_Network_Error = 2106,
    /// 鉴权服务器响应错误
    CNC_RCode_Auth_Response_Error = 2151,
    /// 未知鉴权错误
    CNC_RCode_Auth_Unknown_Error = 2199,
    
    
    
    /// 推流器
    /// 推流成功
    CNC_RCode_Pushstream_Success = 5301,
    /// 推流初始化失败
    CNC_RCode_Push_Init_Fail = 3302,
    /// 推流连接失败
    CNC_RCode_Push_Connect_Fail = 3303,
    /// 数据发送失败
    CNC_RCode_Push_Tranmiss_Fail = 3304,
    /// 推流已断开
    CNC_RCode_Push_Disconnect = 3305,
    /// 网络环境差
    CNC_RCode_Poor_Network_Condition = 1503,
    /// 无法支持设定分辨率
    CNC_RCode_Video_Camera_Not_Support_Resolution = 4302,
    /// 实时传输码率
    CNC_Record_Realtime_Transfer_Bitrate = 5302,
    /// 混音加载成功
    CNC_Record_BGM_Load_Succeed = 5303,
    /// 混音加载失败
    CNC_Record_BGM_Load_Failed = 3375,
    /// 伴奏曲目结束
    CNC_Record_Accompanying_Item_Ends = 5309,
    /// 实时传输帧率
    CNC_Record_Realtime_Transfer_Frame_Rate = 5304,
    /// 实时编码帧率
    CNC_Record_Realtime_Encode_Frame_Rate = 5305,
    /// 摄像头开启成功
    CNC_Record_Camera_Open_Succeed = 5306,
    /// 摄像头切换成功
    CNC_Record_Camera_Switch_Succeed = 5307,
    /// 分辨率切换
    CNC_Record_Resolution_Is_Switched = 5308,

  
    /// 视频编码
    /// 相机权限错误
    CNC_RCode_Video_Camera_Auth_Error = 3341,
    /// 硬件错误
    CNC_Hardware_Error = 3342,
    
    /// 硬编码器初始化失败
    CNC_RCode_Video_HwEncoder_Init_Failed = 3343,
    /// 软编码器初始化失败
    CNC_RCode_Video_SwEncoder_Init_Failed = 3344,
    /// 视频编码失败
    CNC_RCode_Video_Encoder_Failed = 3345,
    
    
    /// 音频编码
    /// 麦克风权限错误
    CNC_RCode_Audio_Mic_Auth_Error = 3371,
    /// 启动麦克风失败
//    CNC_RCode_Audio_Mic_Launch_Failed = 3372,
    /// 音频编码器初始化失败
    CNC_RCode_Audio_Encoder_Init_Failed = 3373,
    /// 音频编码失败
    CNC_RCode_Audio_Encoder_Failed = 3374,
    
    //录制
    //录制成功
    CNC_Record_Succeed = 1002,
    //录制完成
    CNC_Record_Complete = 1003,
    //录制失败
    CNC_Record_Failed = 1110,
//    //录制时间低于阈值
//    CNC_Record_Period_Not_Enough = 1111,
//    //录制时间超过阈值
//    CNC_Record_Period_Exceeds_Limit = 1112,
    //截图失败
    CNC_Record_Screen_Shot_Failed = 1113,
    //磁盘空间不足
    CNC_Record_No_Enough_Space = 1114,
    //系统版本不满足要求
    CNC_System_Version_Error = 1115,
    //存储路径无效
    CNC_Record_Invalid_Storage_Path = 1501,
    //行为提前结束风险
    CNC_Record_Early_Termination_Risk = 1502
    
    
    
};

typedef struct {
    long actual_per_fps;
    long actual_total_send_frame;
    long beauty_before_fps;
//    long beauty_before_total;
    long beauty_after_fps;
//    long beauty_after_total;
    long drop_pakage_num;
    long drop_frame_num;

}realTimeFrame;

typedef NS_ENUM(NSUInteger, CNCENM_Buf_Format) {
    CNCENM_buf_format_I420 = 1,
    CNCENM_buf_format_NV12 = 2,
    CNCENM_buf_format_NV21 = 3,
    CNCENM_buf_format_BGRA = 4,
    
};

typedef NS_ENUM(NSUInteger, CNCAudioSessionMode) {
    CNCAudioSessionModeDefault = 1,
    CNCAudioSessionModeVoiceChat = 2,
    CNCAudioSessionModeVideoChat = 3,
    CNCAudioSessionModeVideoRecording = 4,
};

#endif /* CNCMobComDef_h */
