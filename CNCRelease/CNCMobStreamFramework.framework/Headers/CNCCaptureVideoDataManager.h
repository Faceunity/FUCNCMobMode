//
//  CNCCaptureVideoDataManager.h
//  CNCMobStreamDemo
//
//  Created by 82008223 on 2017/4/11.
//  Copyright © 2017年 cad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CNCMobStruct.h"
#import "CNCComDelegateDef.h"

@protocol CNCCaptureVideoDataManagerDelegate <NSObject>
///采集sample_buf输出
- (void)capture_sample_bufferRef_data:(CMSampleBufferRef)sample_buf time_stamp:(unsigned int)time_stamp;
///采集pixelBuffer输出
- (void)capture_pixel_bufferRef_data:(CVPixelBufferRef)pixelBuffer time_stamp:(unsigned int)time_stamp;
///采集buf输出
- (void)video_capture_buf:(void *)buf pix_width:(int)pix_width pix_height:(int)pix_height format:(CNCENM_Buf_Format)format time_stamp:(long long)ts;
///添加水印buf输出
- (void)overlayMask_buf:(void *)buf pix_width:(int)pix_width pix_height:(int)pix_height format:(CNCENM_Buf_Format)format time_stamp:(long long)time_stamp;
@end



@interface CNCCaptureVideoDataManager : NSObject

@property (nonatomic, assign) id<CNCCaptureVideoDataManagerDelegate> delegate;

/*! @brief 设置视频显示以及展示的view
 *
 * @param width 展示的view的宽
 * @param height 展示的view的高
 * @return 开启是否成功
 */
- (BOOL)init_capture_width:(int)width height:(int)height;
#pragma mark capture

/*! @brief 预设摄像头参数
 *
 * @param para CNCCaptureInfo类型的摄像头参数
 * @return 设置摄像头参数是否成功
 */
- (BOOL)preset_para:(CNCCaptureInfo *)para;

/*! @brief 启动摄像头采集
 * @return 是否启动成功
 */
- (BOOL)start_capture;

/*! @brief 停止摄像头采集
 * @return 无
 */
- (void)stop_capture;

/*! @brief 暂停摄像头采集
 * @return 无
 */
- (void)pause_capture;

/*! @brief 恢复摄像头采集
 * @return 无
 */
- (void)resume_capture;

/*! @brief 闪光灯开启或关闭
 *
 * @param enable YES:开启，NO：关闭
 * @return 无
 */
- (void)set_torch_mode:(BOOL)enable;

/*! @brief 设置美颜效果
 *
 * @param type CNCBEAUTY类型美颜效果值
 * @return 无
 */
- (void)set_beauty_filter_with_type:(CNCBEAUTY)type;

/*! @brief 设置美颜滤镜种类类型
 *
 * @param type CNCCOMBINE类型滤镜值
 * @return 无
 */
- (void)set_combine_filter_with_type:(CNCCOMBINE)type;

/*! @brief  美颜磨皮
 *
 * @param beauty 磨皮等级参数 值域为0~2.0 默认为1.0
 * @param effect 附加效果  值域为0~1.0 默认为0.5          (若无附加效果 此参数设置无效)
 * @param filter_effect 滤镜效果 值域为0~1.0 默认为0.5 （若滤镜效果不可调节 此参数设置无效）
 *
 */
- (void)set_beauty_with:(CGFloat)beauty effect:(CGFloat)effect filter_effect:(CGFloat)filter_effect;

/*! @brief  重设采集frame大小
 *
 * @param new_frame CGRect
 *
 */
- (void)resetFilterViewFrame:(CGRect)new_frame;

/*! @brief 推流过程中切换摄像头
 *
 * @param 无
 * @return
 */
- (void)swap_cameras;

/*! @brief 推流过程中切换到指定位置的摄像头
 *
 * @param 目标摄像头位置
 * @return
 */
- (void)reset_came_pos:(AVCaptureDevicePosition)new_position;

/*! @brief 获取采集摄像头位置
 *
 * @return目标摄像头位置
 */
- (AVCaptureDevicePosition)get_came_pos;
#pragma mark - 聚焦变焦

/*! @brief 手动聚焦
 *
 * @param 传入聚焦的坐标
 * @return 是否设置成功
 */
- (BOOL)tapFocusAtPoint:(CGPoint)point;

/*! @brief 变焦-拉远拉近、放大缩小
 *
 * @param 改变的倍数 值域 1.0~videoZoomFactorUpscaleThreshold
 * @return
 */
- (void)videoZoomFactorWithScale:(CGFloat)effectiveScale;

/*! @brief 获取当前相机的最大放大倍数
 *
 * @param
 * @return videoZoomFactorUpscaleThreshold 上限阈值
 */
- (CGFloat)get_current_camera_upscale;

#pragma mark - 水印
/*! @brief 设置水印 仅支持图片UIImageView及文字UILabel
 *
 * @param object 添加的水印 设置为nil为清除水印
 * @param scale 水印位置比例 (x,y,width,height) 范围为0~1
 * @param updateBlock 更新block 支持在block内对水印内容及图片进行修改
 * @return 添加水印结果
 */
- (BOOL)overlayMaskWithObject:(UIView *)object rect:(CGRect)scale block:(void (^)(void))updateBlock;

/*! @brief  截屏
 *
 * @param path 截屏文件存储地址
 * @return 截屏是否成功
 *
 */
- (BOOL)screen_shot:(NSString *)path;

/*! @brief  返回context_queue
 *
 * @return
 *
 */
- (dispatch_queue_t)get_context_queue;

/*! @brief  返回当前context
 *
 * @return
 *
 */
- (EAGLContext*)get_readonly_context;

/*! @brief  预处理后视频帧添加水印
 * @param pixelbuffer 视频帧
 * @param buffer_time 采集样本时间戳 CMSampleBufferGetPresentationTimeStamp
 * @param time_stamp  编码统一时间戳
 * @return
 *
 */
- (void)overlay_pixelbuffer:(CVImageBufferRef)pixelbuffer time:(CMTime)buffer_time time_stamp:(unsigned int)time_stamp;
#pragma mark - 镜像

/*! @brief  采集流镜像
 * @param source_mirror 视频采集源镜像
 *
 * @return
 *
 */
- (void)set_source_mirror:(BOOL)source_mirror;
@end
