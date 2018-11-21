//
//  CNCRecordFileSeesionManager.h
//  CNCMobStreamDemo
//
//  Created by 82008223 on 2017/6/27.
//  Copyright © 2017年 cad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CNCMobStruct.h"
@interface CNCRecordFileSeesionManager : NSObject

/*! @brief 录制开始
 *  录制分为长短视频、GIF录制，其中视频录制又细分为flv、MP4两种。其中短视频、GIF录制可以设置录制时长控制，长视频录制可设置大小控制。
 *  当录制时长、大小达到预设值时自动结束当前录制并保存结果。
 *  另有提示码提示录制结果 录制开始前请监听返回码 CNC_Notification_MobStreamSDK_ReturnCode
 * @param path 录制文件存储地址
 * @param record_info 录制参数设置 具体格式详见 CNCRecordFileInfo
 * @param type 录制文件类型
 * @param max_time 录制时长 短视频录制时长控制值域为 3.0s~60.0s。GIF录制时长值域为100.0ms~5.0s。
 * @param long_store 录制长、短视频类型
 * @param size 录制文件大小 长视频录制大小控制最小值为100kb，不足最小值以最小值为准。
 * @param return_id 确认ID 随同录制结束返回
 *
 * @return 录制start结果
 */
-(BOOL)start_store_video:(NSString *)path info:(CNCRecordFileInfo *)record_info fileType:(CNCRecordVideoType)type max_time:(NSInteger)max_time long_store:(BOOL)long_store size:(uint64_t)size return_id:(NSString *)return_id;

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

/*! @brief gif录制
 *
 * @param buf 未编码前数据
 * @param pix_width 数据宽度
 * @param pix_height 数据高度
 * @param format 采集格式
 * @param time_stamp 时间戳
 * @return 此帧是否成功加入录制队列
 */
- (BOOL)store_gif_record:(void *)buf pix_width:(int)pix_width pix_height:(int)pix_height format:(CNCENM_Buf_Format)format time_stamp:(long long)ts;

/*! @brief 音频数据传入
 *
 * @param sz 编码后音频数据
 * @param len 数据长度
 * @param time_stamp 时间戳
 * @return 此帧是否成功加入录制队列
 */
- (BOOL)do_store_audio:(char*)sz len:(unsigned int)len time_stamp:(unsigned int)time_stamp;

/*! @brief 视频数据传入
 *
 * @param sz 编码后音频数据
 * @param len 数据长度
 * @param is_key 是否为关键帧
 * @param time_stamp 时间戳
 * @return 此帧是否成功加入录制队列
 */
- (BOOL)do_store_video:(char*)sz len:(unsigned int)len is_key:(bool)is_key width:(int)width height:(int)height time_stamp:(unsigned int)time_stamp;
@end
