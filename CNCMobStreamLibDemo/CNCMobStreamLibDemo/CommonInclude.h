//
//  CommonInclude.h
//  CNCMobStreamLibDemo
//
//  Created by weiyansheng on 16/8/3.
//  Copyright © 2016年 chinanetcenter. All rights reserved.
//

#ifndef CommonInclude_h
#define CommonInclude_h

#ifdef kCNC_Demo_Inner

#import "CNCMobComDef.h"
#import "CNCMobStruct.h"
#import "CNCMobStreamSDK.h"
#import "CNCVideoSourceInput.h"
#import "CNCComDelegateDef.h"


#import "CNCCaptureVideoDataManager.h"
#import "CNCMobStreamVideoDisplayer.h"
#import "CNCMobStreamTimeStampGenerator.h"
#import "CNCMobStreamAudioEngine.h"
#import "CNCMobStreamRtmpSender.h"
#import "CNCMobStreamVideoEncoder.h"
#import "CNCRecordFileSeesionManager.h"

#else

#import <CNCMobStreamFramework/CNCMobStreamFramework.h>

#endif



#endif /* CommonInclude_h */
