//
//  CNCAppUserDataMng.m
//  CNCMobStreamDemo
//
//  Created by mfm on 16/9/20.
//  Copyright © 2016年 cad. All rights reserved.
//

#import "CNCAppUserDataMng.h"


@interface CNCAppUserDataMng() {
    dispatch_queue_t queue_do_req_loop_delegate_;
}

//@property(nonatomic, retain) NSString *user_id;
//@property(nonatomic, retain) NSString *room_id;

#define kCNCKey_cur_user_id @"kCNCKey_cur_user_id"
#define kCNCKey_self_room_id @"kCNCKey_self_room_id"

#define kCNCKey_other_anthor_id @"kCNCKey_other_anthor_id"
#define kCNCKey_other_room_id @"kCNCKey_other_room_id"

#define kCNCKey_push_url @"kCNCKey_push_url"
#define kCNCKey_pull_url @"kCNCKey_pull_url"

#define kCNCKey_link_mic_srv_url @"kCNCKey_link_mic_srv_url_demo"
#define kCNCKey_dispatch_srv_url @"kCNCKey_dispatch_srv_url_demo"
#define kCNCKey_app_host @"kCNCKey_app_host_demo"
//#define kCNCKey_link_mic_srv_loop_url @"kCNCKey_link_mic_srv_loop_url_demo"


#define kCNCKey_player_type @"kCNCKey_player_type"
#define kCNCKey_controller_type @"kCNCKey_controller_type"

#define kCNCKey_Normal_App_ID @"CNCMobSteamSDK_App_ID"
#define kCNCKey_Normal_Auth_Key @"CNCMobSteamSDK_Auth_Key"

#define kCNCKey_LinkMic_App_ID @"CNCMobLinkMicSteamSDK_App_ID"
#define kCNCKey_LinkMic_Auth_Key @"CNCMobLinkMicSteamSDK_Auth_Key"


@end

@implementation CNCAppUserDataMng

+ (CNCAppUserDataMng *)instance {
    static CNCAppUserDataMng* s_instance = nil;
    if (!s_instance) {
        @synchronized(self) {
            if (!s_instance) {
                s_instance = [[CNCAppUserDataMng alloc] init];
                [s_instance init_para];
            }
        }
    }
    
    return s_instance;
}

- (void)init_para {
    
}

- (NSString *)get_cur_user_id {
    return [self _get_value_by_key:kCNCKey_cur_user_id];
}

- (NSString *)get_self_room_id {
    return [self _get_value_by_key:kCNCKey_self_room_id];
}

- (BOOL)set_cur_user_id:(NSString *)user_id {
    return [self _set_value:user_id key:kCNCKey_cur_user_id];
}

- (BOOL)set_self_room_id:(NSString *)room_id {
    return [self _set_value:room_id key:kCNCKey_self_room_id];
}

- (NSString *)get_other_anchor_id {
    return [self _get_value_by_key:kCNCKey_other_anthor_id];
}

- (NSString *)get_other_room_id {
    return [self _get_value_by_key:kCNCKey_other_room_id];
}

- (BOOL)set_other_anchor_id:(NSString *)anchor_id {
    return [self _set_value:anchor_id key:kCNCKey_other_anthor_id];
}
- (BOOL)set_other_room_id:(NSString *)room_id {
    return [self _set_value:room_id key:kCNCKey_other_room_id];
}

- (NSString *)_get_value_by_key:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *value = [defaults stringForKey:key];
    if (value != nil && [value length] > 0) {
        return value;
    } else {
        return nil;
    }
}

- (BOOL)_set_value:(NSString *)value key:(NSString *)key {
    if (value == nil || [value length] == 0) {
        return NO;
    }
    
    if (key == nil || [key length] == 0) {
        return NO;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:key];
    [defaults synchronize];
    return YES;
}

//自己当主播时推流地址
- (NSString *)get_push_url {
    return [self _get_value_by_key:kCNCKey_push_url];
}

- (BOOL)set_push_url:(NSString *)url {
    NSString *pure_url = [CNCAppUserDataMng _get_pure_push_url:url];
    
    return [self _set_value:pure_url key:kCNCKey_push_url];
}

//自己当观众时主播的拉流地址
- (NSString *)get_other_host_pull_url {
    return [self _get_value_by_key:kCNCKey_pull_url];
}

- (BOOL)set_other_host_pull_url:(NSString *)url {
    return [self _set_value:url key:kCNCKey_pull_url];
}

//测试用 后续再改了
- (NSString *)get_link_mic_srv_url {
    return [self _get_value_by_key:kCNCKey_link_mic_srv_url];
}

- (BOOL)set_link_mic_srv_url:(NSString *)url {
    return [self _set_value:url key:kCNCKey_link_mic_srv_url];
}

- (NSString *)get_dispatch_srv_url {
    return [self _get_value_by_key:kCNCKey_dispatch_srv_url];
}
- (BOOL)set_dispatch_srv_url:(NSString *)url {
    return [self _set_value:url key:kCNCKey_dispatch_srv_url];
}


- (NSString *)get_app_host {
    return [self _get_value_by_key:kCNCKey_app_host];
}
- (BOOL)set_app_host:(NSString *)url {
    return [self _set_value:url key:kCNCKey_app_host];
}


//鉴权相关
- (NSString *)get_auth_app_id {
        return [self _get_value_by_key:kCNCKey_Normal_App_ID];
}

- (NSString *)get_auth_app_key {
        return [self _get_value_by_key:kCNCKey_Normal_Auth_Key];
}




- (BOOL)set_auth_app_id:(NSString *)app_id {
        return [self _set_value:app_id key:kCNCKey_Normal_App_ID];
}

- (BOOL)set_auth_app_key:(NSString *)app_key {
        return [self _set_value:app_key key:kCNCKey_Normal_Auth_Key];
}




//#pragma mark url相关
////加上这一串 wsLinkID=%@&wsLinkHost=1
//+ (NSString *)gen_host_push_url:(NSString *)src_url room_id:(NSString *)room_id {
//    NSString *dst_url = nil;
//    
//    NSString *pure_url = [CNCAppUserDataMng _get_pure_push_url:src_url];
//    
//    NSString *para = [NSString stringWithFormat:@"wsLinkID=%@&wsLinkHost=1", room_id];
//    
//    if ([self _is_url_has_para:pure_url]) {
//        dst_url = [NSString stringWithFormat:@"%@&%@", pure_url, para];
//    } else {
//        dst_url = [NSString stringWithFormat:@"%@?%@", pure_url, para];
//    }
//    
//    return dst_url;
//}
//
//
//+ (NSString *)gen_link_mic_push_url:(NSString *)host_push_url room_id:(NSString *)room_id to_user_id:(NSString *)to_user_id {
//    NSString *dst_url = nil;
//    
//    NSString *pure_url = [CNCAppUserDataMng _get_pure_push_url:host_push_url];
//    
//    NSString *query = @"";
//    NSRange r = [pure_url rangeOfString:@"?"];
//    if (r.location != NSNotFound) {
//        query = [pure_url substringFromIndex:r.location+1];
//    }
//    
//    NSString *para = [NSString stringWithFormat:@"wsLinkID=%@&wsLinkHost=0", room_id];
//    if ([query length] > 0) {
//        query = [NSString stringWithFormat:@"%@&%@", query, para];
//    } else {
//        query = para;
//    }
//    
//    NSString *url_without_query = [self _get_url_without_query:pure_url];
//    NSString *prefix = [self _get_prefix_url:url_without_query];
//
//    dst_url = [NSString stringWithFormat:@"%@%@?%@", prefix, to_user_id, query];
//    
//    return dst_url;
//}
//
////去除问号后面的值
//+ (NSString *)_get_url_without_query:(NSString *)src_url {
//    NSString *dst_url = src_url;
//    NSRange r = [src_url rangeOfString:@"?"];
//    if (r.location != NSNotFound) {
//        dst_url = [src_url substringToIndex:r.location];
//    }
//    
//    return dst_url;
//}
//
+ (NSArray *)_get_query_array:(NSString *)src_url {
    NSString *dst_url = src_url;
    NSRange r = [src_url rangeOfString:@"?"];
    
    NSMutableArray *array = [NSMutableArray array];
    
    if (r.location != NSNotFound) {
        dst_url = [src_url substringFromIndex:r.location+1];
        NSArray *tmp = [dst_url componentsSeparatedByString:@"&"];
        for (NSString *str in tmp) {
            if ([str length] > 0) {
                [array addObject:str];
            }
        }
    }
    
    return array;
}
//
//
//+ (BOOL)_is_url_has_para:(NSString *)src_url {
//    NSRange r = [src_url rangeOfString:@"?"];
//    return (r.location != NSNotFound);
//}
//
////去除流名 (要先去除问号后面的值）
//+ (NSString *)_get_prefix_url:(NSString *)src_url {
//    NSString *dst_url = src_url;
//    NSRange r = [src_url rangeOfString:@"/" options:NSBackwardsSearch];
//    if (r.location != NSNotFound) {
//        dst_url = [src_url substringToIndex:r.location+1];
//    }
//    
//    return dst_url;
//}
//
+ (NSString *)_get_pure_push_url:(NSString *)src_url {
    
    NSArray *array = [CNCAppUserDataMng _get_query_array:src_url];
    if (array == nil && [array count] == 0) {
        return src_url;
    }
    
    NSString *dst_url = nil;
    
    NSString *para = @"";
    for (NSString *str in array) {
        if ([str length] == 0) {
            continue;
        }
        
        NSRange r = [str rangeOfString:@"wsLinkID=" options:NSCaseInsensitiveSearch];
        if (r.location != NSNotFound) {
            continue;
        }
        
        r = [str rangeOfString:@"wsLinkHost=" options:NSCaseInsensitiveSearch];
        if (r.location != NSNotFound) {
            continue;
        }
        
        if ([para length] > 0) {
            para = [NSString stringWithFormat:@"%@&%@", para, str];
        } else {
            para = str;
        }
    }
    
    NSRange r = [src_url rangeOfString:@"?"];
    if (r.location == NSNotFound) {
        //这里不可能走这个分支
        return src_url;
    }
    NSString *uri = [src_url substringToIndex:r.location];
    if ([para length] > 0) {
        dst_url = [NSString stringWithFormat:@"%@?%@", uri, para];
    } else {
        dst_url = uri;
    }
    
    return dst_url;
}




@end
