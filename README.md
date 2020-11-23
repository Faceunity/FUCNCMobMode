# FUCNCMobMode 快速接入文档

FUCNCMobMode 是集成了 [Faceunity](https://github.com/Faceunity/FULiveDemo/tree/dev) 面部跟踪和虚拟道具功能 和 网宿推流 功能的 Demo。

**示例 Demo 只在 分层采集 里面加入了 FaceUnity 效果，如需更多接入，请用户参照本例自己接入。**

**本文是 FaceUnity SDK  快速对接 网宿推流 的导读说明**

**关于  FaceUnity SDK 的更多详细说明，请参看 [FULiveDemo](https://github.com/Faceunity/FULiveDemo/tree/dev)**



## 快速集成方法

### 一、导入 SDK
将  FaceUnity  文件夹全部拖入工程中，NamaSDK所需依赖库为 `OpenGLES.framework`、`Accelerate.framework`、`CoreMedia.framework`、`AVFoundation.framework`、`libc++.tbd`、`CoreML.framework`

- 备注: 上述NamaSDK 依赖库使用 Pods 管理 会自动添加依赖,运行在iOS11以下系统时,需要手动添加`CoreML.framework`,并在**TARGETS -> Build Phases-> Link Binary With Libraries**将`CoreML.framework`手动修改为可选**Optional**

### FaceUnity 模块简介
```C
-FUManager              //nama 业务类
-FUCamera               //视频采集类(示例程序未用到)    
-authpack.h             //权限文件
+FUAPIDemoBar     //美颜工具条,可自定义
+items       //贴纸和美妆资源 xx.bundel文件
      
```


### 二、加入展示 FaceUnity SDK 美颜贴纸效果的  UI

1、在  CNCVideoLayeredViewControllerFU.mm  中添加头文件，并创建页面属性

```C
/**------   FaceUnity   ------**/
#import "FUManager.h"
#import "FUAPIDemoBar.h"

@property (nonatomic, strong) FUAPIDemoBar *demoBar ;
```

2、遵循代理  FUAPIDemoBarDelegate ，实现代理方法 `bottomDidChange:` 切换贴纸 和 `filterValueChange:` 更新美颜参数。

#### 切换贴纸

```C
// 切换贴纸
-(void)bottomDidChange:(int)index{
    if (index < 3) {
        [[FUManager shareManager] setRenderType:FUDataTypeBeautify];
    }
    if (index == 3) {
        [[FUManager shareManager] setRenderType:FUDataTypeStrick];
    }
    
    if (index == 4) {
        [[FUManager shareManager] setRenderType:FUDataTypeMakeup];
    }
    if (index == 5) {
        [[FUManager shareManager] setRenderType:FUDataTypebody];
    }
}

```

#### 更新美颜参数

```C
// 更新美颜参数    
- (void)filterValueChange:(FUBeautyParam *)param{
    [[FUManager shareManager] filterValueChange:param];
}
```

### 三、在 `viewDidLoad:` 中调用 `setupFaceUnity` 初始化 SDK  并将  demoBar 添加到页面上

```C

/// FUSDK初始化
- (void)setupFaceUnity{
    
    [[FUManager shareManager] loadFilter];
    [FUManager shareManager].isRender = YES;
    [FUManager shareManager].flipx = YES;
    [FUManager shareManager].trackFlipx = YES;
    [[FUManager shareManager] setAsyncTrackFaceEnable:NO];
    
    self.demoBar = [[FUAPIDemoBar alloc] init];
    [self.view addSubview:self.demoBar];
    self.demoBar.mDelegate = self;
    
    [self.demoBar mas_makeConstraints:^(MASConstraintMaker *make) {
        
        if (@available(iOS 11.0, *)) {
            make.left.mas_equalTo(self.view.mas_safeAreaLayoutGuideLeft);
            make.right.mas_equalTo(self.view.mas_safeAreaLayoutGuideRight);
            make.bottom.mas_equalTo(self.view.mas_safeAreaLayoutGuideBottom)
            .mas_equalTo(-50);
            
        } else {
           
            make.left.right.mas_equalTo(0);
            make.bottom.mas_equalTo(-50);
            
        }
        make.height.mas_equalTo(195);
        
    }];
    
    
}

```

### 四、在视频数据回调中 加入 FaceUnity  的数据处理

在 CNCCaptureVideoDataManagerDelegate 代理方法中

```C
///采集buf输出
- (void)video_capture_buf:(void *)buf pix_width:(int)pix_width pix_height:(int)pix_height format:(CNCENM_Buf_Format)format time_stamp:(long long)ts;
```
```C
- (void)video_capture_buf:(void *)buf pix_width:(int)pix_width pix_height:(int)pix_height format:(CNCENM_Buf_Format)format time_stamp:(long long)ts {

      if (is_fu_open) {
                
                CVPixelBufferRef process_pixelbuffer = [[FUManager shareManager] renderItemsToPixelBuffer:pixelBuffer];
                
                CVPixelBufferRetain(process_pixelbuffer);
                CVPixelBufferLockBaseAddress(process_pixelbuffer,0);
                
                [self.displayer processVideoImageBuffer:process_pixelbuffer];
                
```

### 五、销毁道具和切换摄像头

1 视图控制器生命周期结束时 `[[FUManager shareManager] destoryItems];`销毁道具。

2 切换摄像头需要调用 `[[FUManager shareManager] onCameraChange];`切换摄像头

### 关于 FaceUnity SDK 的更多详细说明，请参看 [FULiveDemo](https://github.com/Faceunity/FULiveDemo/tree/dev)