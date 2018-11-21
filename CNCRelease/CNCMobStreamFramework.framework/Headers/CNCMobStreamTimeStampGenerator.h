//
//  CNCMobStreamTimeStampGenerator.h
//  CNCMobStreamDemo
//
//  Created by weiyansheng on 2017/5/9.
//  Copyright © 2017年 cad. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CNCMobStreamTimeStampGenerator : NSObject

///重置时间戳生成器
- (void)resetGeneratorZero;

///生成一个视频时间戳
- (unsigned int)generateVideoTimeStamp;

///生产一个音频时间戳
- (unsigned int)generateAudioTimeStamp;

///获取视频时间戳队列最小时间戳
- (unsigned int)popTheMinimumInVideoTimeStampArray;

///移除时间时间戳队列比当前发送时间戳小的元素
- (void)removeSmallThanInVideoTimeStampArray:(unsigned int)currentTimeStamp;


@end
