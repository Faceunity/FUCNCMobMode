//
//  CNCMobStreamAudioEngine.h
//  CNCMobStreamDemo
//
//  Created by weiyansheng on 2017/5/9.
//  Copyright © 2017年 cad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreFoundation/CFNotificationCenter.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/AudioFile.h>
#import <AudioToolbox/AUGraph.h>
#import "CNCComDelegateDef.h"

typedef NS_ENUM(NSUInteger, AudioEngineOption) {
    ///是否静音
    AudioEngineOptionIsMute,
    ///是否后台继续推流
    AudioEngineOptionContinueWorkingInBK,
    ///是否正在推流
    AudioEngineOptionIsPushing
};

//Transport state enum
typedef CF_OPTIONS(UInt32, AudioEngineStateFlags) {
    AudioEngineStateStopped       = 0,
    AudioEngineStateRecording     = (1UL << 0),
    AudioEngineStatePlaying       = (1UL << 1),
    AudioEngineStatePaused        = (1UL << 2),
    AudioEngineStateWritting      = (1UL << 3),
};

typedef NS_ENUM(NSUInteger, AudioComponentSubType) {
    AudioComponentSubTypeRemoteIO,
    AudioComponentSubTypeVoiceProcessingIO
};

@protocol CNCMobStreamAudioEngineDelegate;

@interface CNCMobStreamAudioEngine : NSObject <AVAudioSessionDelegate> {
    
    Float64                         graphSampleRate;                // audio graph sample rate
    
}

///初始化音频类时必须设置
@property (nonatomic, assign) id<CNCMobStreamAudioEngineDelegate> delegate;

@property (nonatomic, readonly, getter=isGraphStarted) Boolean graphStarted;

@property (assign, readonly, getter=currentAudioSampleRate) Float64 graphSampleRate;

@property (assign, readonly, getter=currentAudioInputChannels) int displayNumberOfInputChannels;

@property (assign, readonly, getter=currentHumanVolume) Float32 humanVolume;    //[0~1],default 1.0

@property (assign, readonly, getter=currentMusicVolume) Float32 musicVolume;    //[0~1],default 0.3

@property (assign, readonly, getter=currentOutPutVolume) Float32 outputVolume;  //[0~1],default 1.0

@property (assign, readonly, getter=currentHumanDryWet) Float32 humanDryWet;  //[0~100],default 0

@property (assign, readonly, getter=currentPlayMusicEnable) BOOL bPlayMusicEnable;  //default No

@property (assign, readonly, getter=isLoopEnable) BOOL bLoopEnable;  //default No

@property (assign, readonly, getter=currentAudioComponentSubType) AudioComponentSubType audioComponentSubType;


//默认type=AudioComponentSubTypeRemoteIO
- (instancetype)init;

/**
 @abstract 初始化方法
 @param type AudioComponentSubType类型
 */
- (instancetype)initWithComponentSubType:(AudioComponentSubType)type;

/**
 @abstract 是否播放采集的声音 (又称"耳返")
 @warning 如果在没有插入耳机的情况下启动, 容易出现很刺耳的声音
 */
@property(nonatomic, assign, readonly, getter=isMicVoicePlayBack) BOOL bPlayMicVoice; //default YES


- (void)setMicVoicePlaybackEnable:(BOOL)enable;

///设置人声大小
- (void)setHumanVolume:(AudioUnitParameterValue)value;

///设置音乐大小
- (void)setMusicVolume:(AudioUnitParameterValue)value;

///设置总输出音量大小
- (void)setOutPutVolume:(AudioUnitParameterValue)value;

///传入播放音乐
- (BOOL)loadAudioFile:(NSString *)filePath  loopEnable:(BOOL)enable;

///开始播放音乐
- (BOOL)startPlayMusic;

///结束播放音乐
- (void)stopPlayMusic;

///暂停播放
- (void)pausePlayMusic;

///是否正在播放音乐
- (BOOL)isPlayingMusicNow;

///开始录音
- (void)startRecording;

///结束录音
- (void)stopRecording;


///开始推音频流-发送音频头部需要
- (void)startAudioPush;

///混响接口
- (void)setReverbRoomType:(AUReverbRoomType)type;

// CrossFade, 0->100, 100
- (void)setReverbDryWetMix:(AudioUnitParameterValue)value;

///参数获取
- (SInt64)getAmountPlayed;

///音乐总时长
- (NSString *)getDurationString;

///当前播放时间字符串
- (NSString*)getPlayTimeString;

///播放进度【0~1】
- (float)getPlayProgress;

//从哪里开始播放
- (void)seekPlayheadTo:(CGFloat)position;

///是否开启回音消除功能，默认开启；关闭后，可能会有环境噪声
- (BOOL)setAecEnable:(BOOL)bEnable;

///是否开启环境音自动增益减益功能，默认开启，开启时，人声大小会触发自动调节环境音量大小
- (BOOL)setAgcEnable:(BOOL)bEnable;

@end


#pragma mark delegate

@protocol CNCMobStreamAudioEngineDelegate <NSObject>

@required

///音频帧时间戳获取
- (unsigned int)timestampForCurrentAudioFrame;

@optional

///获取 静音状态、后台是否推流、是否正在推流状态 参数返回值
- (BOOL)audioEngine:(CNCMobStreamAudioEngine *)audioEng valueForOption:(AudioEngineOption)option withDefault:(BOOL)defaultValue;

///编码后的AAC数据回调接口
- (void)audioEngine:(CNCMobStreamAudioEngine *)audioEng sendAudioBufferData:(char *)src_sz len:(unsigned int)len time_stamp:(unsigned int)time_stamp;

///请求发送audio header
- (void)audioEngine:(CNCMobStreamAudioEngine *)audioEng sendAudioHeaderRate:(int)rate channel:(int)channel time_stamp:(unsigned int)time_stamp;


@end
