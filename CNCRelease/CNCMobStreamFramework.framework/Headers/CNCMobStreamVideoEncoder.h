//
//  CNCMobStreamVideoEncoder.h
//  CNCMobStreamDemo
//
//  Created by weiyansheng on 2017/5/2.
//  Copyright © 2017年 cad. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>

#import "CNCMobComDef.h"



@protocol CNCMobStreamVideoEncoderDelegate <NSObject>

@required
///视频帧时间戳来源
- (unsigned int)timeStampForCurrentVideoFrame;

@optional

///SPS、PPS数据回调出口，用于RTMP发送videoHeader;
- (void)outPutH264SPS:(NSData *)spsData PPS:(NSData *)ppsData;

///请求发送meta data头信息
- (void)requireSendMetaDataWithVideoSize:(CGSize)size bitRate:(int)rate videoFPS:(int)fps;

///H264编码数据回调
- (void)didEncodedCallBack:(char *)compressData dataLength:(int)length frameSize:(CGSize)size isKey:(BOOL)isKey timestamp:(unsigned int)timestamp;

@end



@interface CNCMobStreamVideoEncoder : NSObject

#pragma mark - 以下三个参数是需要在初始化后设置的。

@property (nonatomic, assign) id<CNCMobStreamVideoEncoderDelegate> delegate;

///实时码率，如果开启码率自适应的时候，要相应更新该参数
@property (nonatomic, assign) NSUInteger real_bit_rate;

///实时帧率
@property (nonatomic, assign) NSUInteger real_fps;


#pragma mark - 唯一初始化方法
/*! @brief 初始化方法
 *
 * @param bounds 视频分辨率宽高
 * @return CNCMobStreamVideoEncoder句柄
 */
- (instancetype)initWithVideoSize:(CGSize)bounds;

/*! @brief 开始编码
 *
 * @param type CNCENMEncoderType 软硬编选择
 * @return 无
 */
- (void)startEncodedWithType:(CNCENMEncoderType)type;

/*! @brief 停止编码
 * @return 无
 */
- (void)stopEncoded;

/*! @brief 传入帧数据，开始编码
 *
 * @param buffer image buffer data
 * @param pix_width bytesPerRow
 * @param pix_height planeTotalHeight
 * @param format 图像数据的格式
 * @param ts 时间戳
 * @return 无
 */
- (void)inputFrameBuffer:(void *)buffer pix_width:(int)pix_width pix_height:(int)pix_height format:(CNCENM_Buf_Format)format time_stamp:(unsigned int)ts;

/*! @brief 将视频帧数据pixelBuffer发给SDK用于编码及RTMP推流。
 *
 * @param pixelBuffer 视频帧数据块起
 * @param format 数据块格式
 * @param ts 视频帧的时间戳
 * @return 无。
 */
- (void)send_frame_pixelBufferRef:(CVPixelBufferRef)pixelBuffer format:(CNCENM_Buf_Format)format time_stamp:(long long)ts;

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
