//
//  CNCMobStreamVideoDisplayer.h
//  CNCMobStreamDemo
//
//  Created by weiyansheng on 2017/4/24.
//  Copyright © 2017年 cad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "CNCMobComDef.h"

typedef NS_ENUM(NSUInteger, CNCDisplayFillModeType) {
    kCNCDisplayFillModeStretch,                       // Stretch to fill the full view, which may distort the image outside of its normal aspect ratio
    kCNCDisplayFillModePreserveAspectRatio,           // Maintains the aspect ratio of the source image, adding bars of the specified background color
    kCNCDisplayFillModePreserveAspectRatioAndFill     // Maintains the aspect ratio of the source image, zooming in on its center to fill the view
};

typedef NS_ENUM (NSUInteger, CNCDisplayType){
    kCNCDisplayNormal,
    kCNCDisplayTexture,
    kCNCDisplayPixelbuffer,
};

typedef struct CNCDisplayConfigs {
    /// 填充模式
    CNCDisplayFillModeType fill_mode;
    /// 数据是否为YUV格式
    BOOL bUseCaptureYUV;
    //  横竖屏
    CNCENMDirectType direction;
    CGFloat capture_width;
    CGFloat capture_height;
    CNCDisplayType displayType;
} CNCDisplayConfigs;

@interface CNCMobStreamVideoDisplayer : NSObject

@property (readonly) CNCDisplayConfigs displayConfigs;

/*! @brief 设置预览镜像
 *
 * @param is_mirror 镜像
 * @return 无
 */
- (void)set_display_mirror:(BOOL)is_mirror;

/*! @brief 初始化视图
 *
 * @param preview 父视图
 * @param fboDisplayConfigs CNCDisplayConfigs配置参数
 * @return 句柄
 */
- (instancetype)initWithView:(UIView *)preview displayConfigs:(CNCDisplayConfigs)fboDisplayConfigs;

/*! @brief 预览视频帧样本
 *
 * @param sampleBuffer 视频帧样本
 * @return 无
 */
- (void)processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/*! @brief 预览视频帧样本
 *
 * @param pixelBuffer 视频帧样本
 * @return 无
 */
- (void)processVideoImageBuffer:(CVPixelBufferRef)pixelBuffer;

/*! @brief 数据buf预览
 * @param buf 视频帧数据
 * @param bytesPerRow  视频帧样本行字节数
 * @param pHeight 视频帧样本高度
 * @return 无
 */
- (void)processVideoBufferData:(void *)buf bytesPerRow:(int)bytesPerRow planeHeight:(int)pHeight;

/*! @brief 纹理预览
 * @param texture buffer纹理
 * @param width  宽度
 * @param height 高度
 * @return 无
 */
- (void)renderTexture:(GLuint)texture width:(int)width height:(int)height;

/*! @brief 设置预览层水印
 * @param object 水印对象
 * @param scale 水印位置比例 (x,y,width,height) 范围为0~1
 * @return 设置结果
 */
- (BOOL)overlay_mask:(UIView *)object rect:(CGRect)scale;
@end
