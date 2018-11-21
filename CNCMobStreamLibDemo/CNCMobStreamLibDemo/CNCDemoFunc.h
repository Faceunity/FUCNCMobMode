//
//  CNCDemoFunc.h
//  CNCMobStreamLibDemo
//
//  Created by 82008223 on 2018/1/23.
//  Copyright © 2018年 chinanetcenter. All rights reserved.
//

#import <Foundation/Foundation.h>
#define RECORD_CODE_COUNT 50
#define RECORDCOLOR [UIColor colorWithRed:252.f/255 green:51.f/255 blue:66.f/255 alpha:0.3f]
@interface CNCDemoFunc : NSObject
+ (NSArray *)get_folder_list_with_name:(NSString *)folder_name;
+ (NSString *)get_folder_directory_with_name:(NSString *)folder_name;
+ (NSDictionary *)read_question_file:(NSString *)path;
+ (NSString*)convertToJSONData:(id)infoDict;
@end
