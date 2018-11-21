//
//  ViewController.h
//
//  Created by HaifengMay on 16/11/7.
//  Copyright © 2016年 SenseTime. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "CommonInclude.h"
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
@protocol CNCSenseMeEffectsManagerDelegate <NSObject>

/**预处理结果**/
- (void)do_sense_data:(void *)src_buf pix_width:(int)pix_width pix_height:(int)pix_height format:(CNCENM_Buf_Format)format time_stamp:(long long)ts;
- (void)do_sense_set_ges:(BOOL)is_open;
@end

@interface CNCSenseMeEffectsManager : NSObject
@property (nonatomic, assign) id<CNCSenseMeEffectsManagerDelegate> delegate;
@property (nonatomic) CNCENMDirectType video_direct_type;//横竖屏
@property (nonatomic, assign)BOOL isFrontCamera;
@property (nonatomic, assign)BOOL isVideoMirrored;
- (instancetype)initWith:(UIView *)preview direct:(CNCENMDirectType)direct width:(int)w height:(int)h;
- (void)captureSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)onBtnChangeCamera;
- (void)releaseResources;
- (void)reset_glPreview:(CGSize)new_size;
@end
