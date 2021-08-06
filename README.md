# FUCNCMobMode 快速接入文档

FUCNCMobMode 是集成了 [Faceunity](https://github.com/Faceunity/FULiveDemo) 面部跟踪和虚拟道具功能 和 网宿推流 功能的 Demo。

**示例 Demo 只在 分层采集 里面加入了 FaceUnity 效果，如需更多接入，请用户参照本例自己接入。**

**本文是 FaceUnity SDK  快速对接 网宿推流 的导读说明**

**关于  FaceUnity SDK 的更多详细说明，请参看 [FULiveDemo](https://github.com/Faceunity/FULiveDemo)**

## 快速集成方法

### 一、导入 SDK

将  FaceUnity  文件夹全部拖入工程中，NamaSDK所需依赖库为 `OpenGLES.framework`、`Accelerate.framework`、`CoreMedia.framework`、`AVFoundation.framework`、`libc++.tbd`、`CoreML.framework`

- 备注: 运行在iOS11以下系统时,需要手动添加`CoreML.framework`,并在**TARGETS -> Build Phases-> Link Binary With Libraries**将`CoreML.framework`手动修改为可选**Optional**

### FaceUnity 模块简介

```objc
+ Abstract          // 美颜参数数据源业务文件夹
    + FUProvider    // 美颜参数数据源提供者
    + ViewModel     // 模型视图参数传递者
-FUManager          //nama 业务类
-authpack.h         //权限文件  
+FUAPIDemoBar     //美颜工具条,可自定义
+items            //美妆贴纸 xx.bundel文件

```

### 二、加入展示 FaceUnity SDK 美颜贴纸效果的  UI

1、在  CNCVideoLayeredViewControllerFU.mm  中添加头文件

```C
/**faceU */
#import "Masonry.h"
#import "FUManager.h"
#import "FUCamera.h"
#import "FUTestRecorder.h"
#import "UIViewController+FaceUnityUIExtension.h"
#import <FURenderKit/FUGLDisplayView.h>
```

2、在 `viewDidLoad` 方法中初始化FU `setupFaceUnity` 会初始化FUSDK,和添加美颜工具条,具体实现可查看 `UIViewController+FaceUnityUIExtension.m`
```objc
[self setupFaceUnity];
```

### 三、在视频数据回调中 加入 FaceUnity  的数据处理

在 FUCameraDelegate 代理方法中

```C
- (void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    int pix_width = (int) CVPixelBufferGetWidth(pixelBuffer);
    int pix_height = (int) CVPixelBufferGetWidth(pixelBuffer);
    long long ts = [self.timeGenerator generateVideoTimeStamp];
    if (!is_pause_opengl_view){
        if (is_fu_open) {
            
            [[FUTestRecorder shareRecorder] processFrameWithLog]; //测试阶段查看性能使用,正式环境请勿添加
            CVPixelBufferRef process_pixelbuffer = [[FUManager shareManager] renderItemsToPixelBuffer:pixelBuffer];
            
            CVPixelBufferRetain(process_pixelbuffer);
            CVPixelBufferLockBaseAddress(process_pixelbuffer,0);
            
            [self.preview displayPixelBuffer:process_pixelbuffer];
            
            //FU 编码
            [self do_encoder_fu:process_pixelbuffer format:CNCENM_buf_format_BGRA time_stamp:ts];
            
            // 测试阶段未检测到人脸人体提示语,正式环境请勿添加
            [self checkAI];
            
            CVPixelBufferUnlockBaseAddress(process_pixelbuffer, 0);
            CVPixelBufferRelease(process_pixelbuffer);
            
        } else {
            [self.preview displayPixelBuffer:pixelBuffer];
            
            //编码
            [self do_encoder_normal:pixelBuffer pix_width:pix_width pix_height:pix_height format:CNCENM_buf_format_BGRA time_stamp:ts];
        }
    }
}
                
```

### 四、销毁道具和切换摄像头

1 视图控制器生命周期结束时 `[[FUManager shareManager] destoryItems];`销毁道具。

2 切换摄像头需要调用 `[[FUManager shareManager] onCameraChange];`切换摄像头

### 关于 FaceUnity SDK 的更多详细说明，请参看 [FULiveDemo](https://github.com/Faceunity/FULiveDemo)