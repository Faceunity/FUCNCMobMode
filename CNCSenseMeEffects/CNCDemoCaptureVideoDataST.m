//
//  CNCDemoCaptureVideoDataST.m
//  senseMe_Demo
//
//  Created by 82008223 on 2017/12/15.
//  Copyright © 2017年 82008223. All rights reserved.
//
#import "CNCDemoCaptureVideoDataST.h"
#import "CNCGLPreview.h"


#define kCNCDemoSysVerson [[[UIDevice currentDevice] systemVersion] floatValue]

@interface CNCDemoCaptureVideoDataST() <AVCaptureVideoDataOutputSampleBufferDelegate,CNCSenseMeEffectsManagerDelegate> {
    
    dispatch_queue_t queue_video_data_;
    int capture_width;
    int capture_height;
    
    BOOL is_mirror;
    AVCaptureDevicePosition _currentCameraPosition;
    AVCaptureDeviceInput *_videoIn;
    AVCaptureDevice *_videoDevice;
    AVCaptureConnection *_videoConnection;
    AVCaptureVideoDataOutput *_capture_output;
    AVCaptureVideoOrientation _videoOrientation;
    CGFloat screen_width;
    CGFloat screen_height;
}

@property (nonatomic) CNCENMDirectType video_direct_type;//横竖屏

@property (nonatomic, retain) AVCaptureSession *capture_session;


@property (nonatomic, retain) AVCaptureVideoPreviewLayer *preview_layer;

@property (nonatomic, retain) UIView *preview;
@property (nonatomic, retain) NSLock *lock_oprt;
@property (nonatomic, retain) CNCSenseMeEffectsManager *st_manager;

@property (nonatomic, retain) UIButton *magic_wand_btn;
@property (nonatomic, retain) UIButton *btnChangeCamera;

@end

@implementation CNCDemoCaptureVideoDataST
{
    BOOL is_st_open;
}
- (id)init_with_preview:(UIView *)preview direct:(CNCENMDirectType)direct {
    self = [super init];
    if (self) {
        
        self.use_senseMe = YES;//默认开启商汤
        self.preview = preview;
        
        self.video_direct_type = direct;
        queue_video_data_ = dispatch_queue_create("com.cnc.CNCDemoCaptureVideoData.queue_video_data_", NULL);
        self.lock_oprt = [[[NSLock alloc] init] autorelease];
        [self init_para];
        [self init_instrument_view];
    }
    return self;
}
- (void)init_para {
    is_mirror = YES;
    screen_width = CGRectGetWidth(self.preview.frame);
    screen_height = CGRectGetHeight(self.preview.frame);
}
- (void)init_instrument_view {
    CGFloat fw = CGRectGetWidth(self.preview.frame);
    CGFloat fh = CGRectGetHeight(self.preview.frame);
    
    CGFloat buttonWidth = 50;
    CGFloat backViewHeight = (buttonWidth+5)*4+5;
//    UIScrollView *backView = [[[UIScrollView alloc] init] autorelease];
//    backView.frame = CGRectMake(fw-buttonWidth,(fh-backViewHeight)/2,buttonWidth+5,backViewHeight);
//    backView.backgroundColor = [UIColor blackColor];
//    backView.alpha = 0.7f;
//    [self.preview addSubview:backView];
    
    if (!_btnChangeCamera) {
        
        UIView *backview = [[[UIView alloc] initWithFrame:CGRectMake(fw - buttonWidth, (fh - backViewHeight)/2+12.5, buttonWidth, buttonWidth)] autorelease];
        backview.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
        backview.layer.cornerRadius = 5.0f;
        backview.tag = 100;
        [self.preview addSubview:backview];
        UIImage *image = [UIImage imageNamed:@"camera_rotate.png"];
        
        _btnChangeCamera = [[[UIButton alloc] initWithFrame:CGRectMake(fw - buttonWidth+10, (fh - backViewHeight)/2+22.5, 30, 30)] autorelease];
        [_btnChangeCamera setImage:image forState:UIControlStateNormal];
        [_btnChangeCamera addTarget:self action:@selector(swap_camera) forControlEvents:UIControlEventTouchUpInside];
        
    }
    [self.preview addSubview:self.btnChangeCamera];
}

//- (UIButton *)btnChangeCamera {
//
//
//
//    return _btnChangeCamera;
//}
- (void)swap_camera {
    if (_currentCameraPosition == AVCaptureDevicePositionBack) {
        _currentCameraPosition = AVCaptureDevicePositionFront;
        is_mirror = YES;
        self.st_manager.isFrontCamera = YES;
        self.st_manager.isVideoMirrored = YES;
    } else {
        _currentCameraPosition = AVCaptureDevicePositionBack;
        is_mirror = NO;
        self.st_manager.isFrontCamera = NO;
        self.st_manager.isVideoMirrored = NO;
    }
    [self setDevicePosition:_currentCameraPosition];
}
- (void)setDevicePosition:(AVCaptureDevicePosition)devicePosition
{
    if (devicePosition != AVCaptureDevicePositionUnspecified) {
        
        if (self.capture_session) {
            
            AVCaptureDevice *targetDevice = [self cameraDeviceWithPosition:devicePosition];
            
            if (targetDevice && [self judgeCameraAuthorization]) {
                
                NSError *error = nil;
                AVCaptureDeviceInput *deviceInput = [[[AVCaptureDeviceInput alloc] initWithDevice:targetDevice error:&error] autorelease];
                
                if(!deviceInput || error) {
                    
                    NSLog(@"Error creating capture device input: %@", error.localizedDescription);
                    return;
                }
                
                
                
                [self.capture_session beginConfiguration];
                
                [self.capture_session removeInput:_videoIn];
                
                if ([self.capture_session canAddInput:deviceInput]) {
                    
                    [self.capture_session addInput:deviceInput];
                    
                    _videoIn = deviceInput;
                    _videoDevice = targetDevice;
                    
                    _currentCameraPosition = devicePosition;
                }
                
                _videoConnection =  [_capture_output connectionWithMediaType:AVMediaTypeVideo];
                
                if ([_videoConnection isVideoOrientationSupported]) {
                    
                    [_videoConnection setVideoOrientation:_videoOrientation];
                }
                
                if ([_videoConnection isVideoMirroringSupported]) {
                    
                    [_videoConnection setVideoMirrored:is_mirror];
                    
                }
                
                [self.capture_session commitConfiguration];
                
                deviceInput = nil;
            }
        }
    }
}
- (BOOL)judgeCameraAuthorization
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"请打开相机权限" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        
        [alert show];
        
        return NO;
    }
    
    return YES;
}
- (AVCaptureDevice *)cameraDeviceWithPosition:(AVCaptureDevicePosition)position
{
    AVCaptureDevice *deviceRet = nil;
    
    if (position != AVCaptureDevicePositionUnspecified) {
        
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        
        for (AVCaptureDevice *device in devices) {
            
            if ([device position] == position) {
                
                deviceRet = device;
            }
        }
    }
    
    return deviceRet;
}
- (BOOL)start_capture {
    NSError *error;
    
    self.capture_session = [[[AVCaptureSession alloc] init] autorelease];
    
    _videoDevice = [self camera_with_position:AVCaptureDevicePositionFront];
    
    _videoIn = [AVCaptureDeviceInput deviceInputWithDevice:_videoDevice error:&error];
    
    if (error) {
        return NO;
    }
    
    if (![self.capture_session canAddInput:_videoIn]) {
        return NO;
    }
    
    [self.capture_session addInput:_videoIn];
    
    
    
    _capture_output = [[AVCaptureVideoDataOutput alloc] init];
//    kCVPixelFormatType_32BGRA
//    kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
    NSDictionary *settings = [[[NSDictionary alloc] initWithObjectsAndKeys:
                               [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],                                   kCVPixelBufferPixelFormatTypeKey,
                               nil] autorelease];
    
    
    
    _capture_output.videoSettings = settings;
    _capture_output.alwaysDiscardsLateVideoFrames = YES;
    
    
    [_capture_output setSampleBufferDelegate:self queue:queue_video_data_];
    [self.capture_session addOutput:_capture_output];
    
    _videoConnection = [_capture_output connectionWithMediaType:AVMediaTypeVideo];
    if ([_videoConnection isVideoOrientationSupported]) {
        if (self.video_direct_type == CNC_ENM_Direct_Vertical) {
            _videoOrientation = AVCaptureVideoOrientationPortrait;
        }else {
            _videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        }
        [_videoConnection setVideoOrientation:_videoOrientation];
    }
    if ([_videoConnection isVideoMirroringSupported]) {
        
        [_videoConnection setVideoMirrored:is_mirror];
        
    }
    
    if (kCNCDemoSysVerson >= 8) {
        AVCaptureVideoStabilizationMode stabilizationMode = AVCaptureVideoStabilizationModeCinematic;
        if ([_videoDevice.activeFormat isVideoStabilizationModeSupported:stabilizationMode]) {
            [_videoConnection setPreferredVideoStabilizationMode:stabilizationMode];
        }
    }
    
    self.capture_session.sessionPreset = AVCaptureSessionPreset640x480;
//    self.capture_session.sessionPreset = AVCaptureSessionPreset1280x720;
    
    if(self.use_senseMe){
        if (self.st_manager == nil) {
            [self check_capture_width_and_height];
            self.st_manager = [[[CNCSenseMeEffectsManager alloc] initWith:self.preview direct:self.video_direct_type width:capture_width height:capture_height] autorelease];
            self.st_manager.delegate = self;
            self.st_manager.isFrontCamera = YES;
            self.st_manager.isVideoMirrored = YES;
        }
//        [self init_control_UI];
        
        
    } else {
        if (self.preview) {//预览
            dispatch_async(dispatch_get_main_queue(), ^(){
                
                self.preview_layer = [[[AVCaptureVideoPreviewLayer alloc] initWithSession:self.capture_session] autorelease];
                self.preview_layer.frame = self.preview.bounds;
                self.preview_layer.contentsGravity = kCAGravityCenter;
                self.preview_layer.videoGravity = AVLayerVideoGravityResizeAspect;
                
                [self.preview.layer insertSublayer:self.preview_layer atIndex:0];
                if (self.video_direct_type == CNC_ENM_Direct_Vertical) {
                    self.preview_layer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
                }else {
                    self.preview_layer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
                }
            });
        }
    }
    
    
    if (kCNCDemoSysVerson >= 7) {
        
        int32_t video_fps = 25;
        
        NSError *error;
        CMTime frameDuration = CMTimeMake(1, video_fps);
        NSArray *supportedFrameRateRanges = [_videoDevice.activeFormat videoSupportedFrameRateRanges];
        BOOL frameRateSupported = NO;
        for (AVFrameRateRange *range in supportedFrameRateRanges) {
            if (CMTIME_COMPARE_INLINE(frameDuration, >=, range.minFrameDuration) &&
                CMTIME_COMPARE_INLINE(frameDuration, <=, range.maxFrameDuration)) {
                frameRateSupported = YES;
            }
        }
        
        if (frameRateSupported && [_videoDevice lockForConfiguration:&error]) {
            [_videoDevice setActiveVideoMaxFrameDuration:frameDuration];
            [_videoDevice setActiveVideoMinFrameDuration:frameDuration];
            
            //            videoDevice.smoothAutoFocusEnabled = YES;
            
            [_videoDevice unlockForConfiguration];
        }
    }
    
    
    [self.lock_oprt lock];
    [self.capture_session startRunning];
    [self.lock_oprt unlock];
    
//    NSLog(@"self.capture_session.sessionPreset = %@", self.capture_session.sessionPreset);
    
    return YES;
}
- (void)check_capture_width_and_height {
    
    if ([self.capture_session.sessionPreset isEqualToString:AVCaptureSessionPreset352x288]) {

        if(self.video_direct_type == CNC_ENM_Direct_Horizontal) {
            capture_width = 352;
            capture_height = 288;
        } else {
            capture_width = 352;
            capture_height = 288;
        }
    }
    
    if ([self.capture_session.sessionPreset isEqualToString:AVCaptureSessionPreset640x480]) {

        if(self.video_direct_type == CNC_ENM_Direct_Horizontal) {
            capture_width = 640;
            capture_height = 480;
        } else {
            capture_width = 480;
            capture_height = 640;
        }
    }
    
    if ([self.capture_session.sessionPreset isEqualToString:AVCaptureSessionPresetiFrame960x540]) {

        if(self.video_direct_type == CNC_ENM_Direct_Horizontal) {
            capture_width = 960;
            capture_height = 540;
        } else {
            capture_width = 540;
            capture_height = 960;
        }
    }
    
    if ([self.capture_session.sessionPreset isEqualToString:AVCaptureSessionPreset1280x720]) {

        if(self.video_direct_type == CNC_ENM_Direct_Horizontal) {
            capture_width = 1280;
            capture_height = 720;
        } else {
            capture_width = 720;
            capture_height = 1280;
        }
    }
    

}
- (void)init_control_UI {
    CGFloat buttonWidth = 50;
    UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.preview.frame)-buttonWidth, CGRectGetHeight(self.preview.frame) - buttonWidth, buttonWidth, buttonWidth)] autorelease];
    
    btn.backgroundColor = [UIColor clearColor];
    [btn setImage:[UIImage imageNamed:@"ic_beauty_off"] forState:UIControlStateNormal];
    [btn setImage:[UIImage imageNamed:@"ic_beauty_on"] forState:UIControlStateSelected];
    btn.selected = NO;
    [btn addTarget:self action:@selector(open_openGLView:) forControlEvents:UIControlEventTouchUpInside];
    self.magic_wand_btn = btn;
    [self.preview.superview addSubview:self.magic_wand_btn];
    
}
- (void)open_openGLView:(UIButton *)sender {
    
    is_st_open = YES;
    if (is_st_open) {
        [UIView animateWithDuration:0.3 animations:^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(get_senseMe_work:)]) {
                [self.delegate get_senseMe_work:is_st_open];
            }
            self.magic_wand_btn.hidden = YES;
            
        } completion:^(BOOL finished) {
            
        }];
    }
}

- (void)stop_capture {
    
    [self.lock_oprt lock];
    
    BOOL isRunning = self.capture_session.isRunning;
    
    if (isRunning) {
        [self.capture_session stopRunning];
    }
    
    [self.lock_oprt unlock];
    
}

- (AVCaptureDevice *)camera_with_position:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices ) {
        if ( device.position == position ) {
            
            return device;
        }
    }
    
    return nil;
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if ([captureOutput isKindOfClass:[AVCaptureVideoDataOutput class]]) {
        
//        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//
//        if (self.use_senseMe) {
//            if(CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly) != kCVReturnSuccess) {
//                return;
//            }
//
//
//            [self frame_YUV:imageBuffer time_stamp:0];
//
//            CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
//        } else {
//            [self frame_YUV:imageBuffer time_stamp:0];
//        }
        if (self.use_senseMe) {
            [self.st_manager captureSampleBuffer:sampleBuffer];
        }
    }
}
- (void)frame_YUV:(CVImageBufferRef)imageBuffer time_stamp:(long)time_stamp {
    
    if(CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly) != kCVReturnSuccess) {
        return;
    }
    
    const int kYPlaneIndex = 0;
    const int kUVPlaneIndex = 1;
    
    //NV12 TO I420
    uint8_t *baseAddress = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, kYPlaneIndex);
    uint8_t *uvAddress = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, kUVPlaneIndex);
    size_t yPlaneBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, kYPlaneIndex);
    size_t uvPlaneBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, kUVPlaneIndex);
    
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    int msize = (int)(yPlaneBytesPerRow * height *3 / 2);
    if (0 == msize) {
        NSLog(@"got zero size!");
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
        return;
    }
    
    UInt8 *pY = (UInt8 *)malloc(msize);
    UInt8 *pU = pY + width*height;
    UInt8 *pV = pU + width*height/4;
    
    for (int row = 0; row < height; ++row) {
        for (int col = 0; col < width; ++col) {
            pY[row*width + col] = baseAddress[row*yPlaneBytesPerRow + col];
        }
    }
    
    NSInteger width_u = width/2;
    NSInteger height_u = height/2;
    uint8_t*pSrcUV = uvAddress;
    
    for (int row = 0; row < height_u; ++row) {
        for (int col = 0; col < width_u; ++col) {
            pU[row*width_u + col] = pSrcUV[row*uvPlaneBytesPerRow + col*2];
            pV[row*width_u + col] = pSrcUV[row*uvPlaneBytesPerRow + col*2 + 1];
        }
    }
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    //    [self.rtc_kit send_frame_buf:pY pix_width:(int)width pix_height:(int)height*3/2 time_stamp:time_stamp];
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(video_capture_st:buf:pix_width:pix_height:format: time_stamp:)]) {
        [self.delegate video_capture_st:self buf:pY pix_width:(int)width pix_height:(int)height*3/2 format:CNCENM_buf_format_I420 time_stamp:time_stamp];
    }
    
    
    free(pY);
    pY = NULL;
    
}
#pragma mark- CNCSenseMeEffectsManagerDelegate
- (void)do_sense_set_ges:(BOOL)is_open {
    if (self.delegate && [self.delegate respondsToSelector:@selector(capture_view_set_ges:)]) {
        [self.delegate capture_view_set_ges:is_open];
    }
}
- (void)do_sense_data:(void *)src_buf pix_width:(int)pix_width pix_height:(int)pix_height format:(CNCENM_Buf_Format)format time_stamp:(long long)ts {
    if (self.delegate && [self.delegate respondsToSelector:@selector(video_capture_st:buf:pix_width:pix_height:format:time_stamp:)]) {
        [self.delegate video_capture_st:self buf:src_buf pix_width:pix_width pix_height:pix_height format:format time_stamp:ts];
    }
}
- (CVPixelBufferRef)copyDataFromBuffer:(void *)buffer toYUVPixelBufferWithWidth:(size_t)width Height:(size_t)height
{
    height = height/3*2;
    //生成i420
    CVPixelBufferRef pixelBuffer = NULL;
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSDictionary dictionary], kCVPixelBufferIOSurfacePropertiesKey,
                                nil];
    CVPixelBufferCreate(NULL, width, height, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, (__bridge CFDictionaryRef)(dictionary), &pixelBuffer);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    size_t bytesrow0 = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer,0);
    size_t bytesrow1 = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer,1);
    
    if (bytesrow0 != width || bytesrow1 != width) {
        
        unsigned char* dstY  = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        unsigned char* dstUV = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
        
        UInt8 *src = (UInt8 *)buffer;
        
        for (unsigned int y = 0; y < height; ++y, dstY += bytesrow0, src += width) {
            memcpy(dstY, src, width);
        }
        
        size_t srcPlaneSize = width*height/4;
        size_t dstPlaneSize = bytesrow1*height/2;
        
        UInt8 *pY = (UInt8 *)buffer;
        UInt8 *pU = pY + width*height;
        UInt8 *pV = pU + width*height/4;
        
        uint8_t *dstPlane = (uint8_t *)malloc(dstPlaneSize);
        
        unsigned long k = 0, j = 0;
        
        for(int i = 0; i<srcPlaneSize; i++){
            // These might be the wrong way round.
            if ((2*i)%width == 0 && i!=0) {
                k++;
            }
            
            j = 2*i + k*(bytesrow1 - width);
            
            dstPlane[j  ] = pU[i];
            dstPlane[j+1] = pV[i];
        }
        
        memcpy(dstUV, dstPlane, dstPlaneSize);
        
        free(dstPlane);
        
    } else {
        UInt8 *pY = (UInt8 *)buffer;
        UInt8 *pU = pY + width*height;
        UInt8 *pV = pU + width*height/4;
        
        size_t srcPlaneSize = width*height/4;
        size_t dstPlaneSize = srcPlaneSize * 2;
        
        uint8_t *dstPlane = (uint8_t *)malloc(dstPlaneSize);
        
        for(size_t i = 0; i<srcPlaneSize; i++){
            // These might be the wrong way round.
            dstPlane[2*i  ] = pU[i];
            dstPlane[2*i+1] = pV[i];
        }
        
        uint8_t* addressY  = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        uint8_t* addressUV = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
        
        memcpy(addressY, buffer, width * height);
        memcpy(addressUV, dstPlane, dstPlaneSize);
        
        free(dstPlane);
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return pixelBuffer;
}
- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.magic_wand_btn = nil;
    self.capture_session = nil;
    //    self.rtc_kit = nil;
    self.preview = nil;
    self.preview_layer = nil;
    self.lock_oprt = nil;
    
    dispatch_release(queue_video_data_);
    queue_video_data_ = NULL;
    self.btnChangeCamera = nil;
    [self.st_manager releaseResources];
    self.st_manager = nil;

    
    [super dealloc];
}

- (void)reset_preview_size:(CGSize)new_size {
    //MFM-TODO
    UIView *back_view = [self.preview viewWithTag:100];
    dispatch_async(dispatch_get_main_queue(), ^{

        if (new_size.width != screen_width || new_size.height != screen_height){
//            小窗
            self.btnChangeCamera.hidden = YES;
            back_view.hidden = YES;
        } else {
//            大窗
            self.btnChangeCamera.hidden = NO;
            back_view.hidden = NO;
        }
        
        self.preview_layer.frame = CGRectMake(0, 0, new_size.width, new_size.height);
        
        
        {
            [self.st_manager reset_glPreview:new_size];
        }
    });
    
}

@end
