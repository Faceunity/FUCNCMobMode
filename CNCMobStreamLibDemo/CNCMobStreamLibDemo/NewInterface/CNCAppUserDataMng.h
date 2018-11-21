//
//  CNCAppUserDataMng.h
//  CNCMobStreamDemo
//
//  Created by mfm on 16/9/20.
//  Copyright © 2016年 cad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommonInclude.h"

//为了测试连麦 需要模拟一些用户数据

@interface CNCAppUserDataMng : NSObject {
    
}

+ (CNCAppUserDataMng *)instance;

//自己当主播
- (NSString *)get_cur_user_id;
- (NSString *)get_self_room_id;

- (BOOL)set_cur_user_id:(NSString *)user_id;
- (BOOL)set_self_room_id:(NSString *)room_id;

//自己不是主播时
- (NSString *)get_other_anchor_id;
- (NSString *)get_other_room_id;

- (BOOL)set_other_anchor_id:(NSString *)anchor_id;
- (BOOL)set_other_room_id:(NSString *)room_id;

//自己当主播时推流地址
- (NSString *)get_push_url;
- (BOOL)set_push_url:(NSString *)url;

//自己当观众时主播的拉流地址
- (NSString *)get_other_host_pull_url;
- (BOOL)set_other_host_pull_url:(NSString *)url;


//测试用 后续再改了
- (NSString *)get_link_mic_srv_url;
- (BOOL)set_link_mic_srv_url:(NSString *)url;

- (NSString *)get_dispatch_srv_url;
- (BOOL)set_dispatch_srv_url:(NSString *)url;

- (NSString *)get_app_host;
- (BOOL)set_app_host:(NSString *)url;

//鉴权相关
- (NSString *)get_auth_app_id;
- (NSString *)get_auth_app_key;

- (BOOL)set_auth_app_id:(NSString *)app_id;
- (BOOL)set_auth_app_key:(NSString *)app_key;



@end
