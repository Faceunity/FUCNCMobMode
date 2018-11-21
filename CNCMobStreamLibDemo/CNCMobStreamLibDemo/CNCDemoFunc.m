//
//  CNCDemoFunc.m
//  CNCMobStreamLibDemo
//
//  Created by 82008223 on 2018/1/23.
//  Copyright © 2018年 chinanetcenter. All rights reserved.
//

#import "CNCDemoFunc.h"

@implementation CNCDemoFunc
+ (NSDictionary *)read_question_file:(NSString *)path
{
    NSString *content = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSDictionary *dictionary = [[[NSDictionary alloc] initWithDictionary:[CNCDemoFunc jsonStringToKeyValues:content]] autorelease];
    [content release];
    return dictionary;
    
}

//json字符串转化成OC键值对
+ (NSDictionary *)jsonStringToKeyValues:(NSString *)JSONString {
    NSData *JSONData = [JSONString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *responseJSON = nil;
    if (JSONData) {
        responseJSON = [NSJSONSerialization JSONObjectWithData:JSONData options:NSJSONReadingMutableContainers error:nil];
    }
    
    return responseJSON;
}
+ (NSArray *)get_folder_list_with_name:(NSString *)folder_name {
    
    NSString *directory = [CNCDemoFunc get_folder_directory_with_name:folder_name];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:directory]) {
        NSError *err = nil;
        
        if (![[NSFileManager defaultManager] createDirectoryAtPath:directory
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&err]) {
            NSLog(@"DDFileLogManagerDefault: Error creating logsDirectory: %@", err);
        }
    }
    
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:nil];
    
    return fileNames;
}
+ (NSString *)get_folder_directory_with_name:(NSString *)folder_name {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *baseDir = paths.firstObject;
    NSString *directory = [baseDir stringByAppendingPathComponent:folder_name];
    
    return directory;
}
+ (NSString*)convertToJSONData:(id)infoDict
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:infoDict
                                                       options:0
                                                         error:&error];
    
    NSString *jsonString = @"";
    
    if (! jsonData)
    {
        NSLog(@"Got an error: %@", error);
    }else
    {
        jsonString = [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] autorelease];
    }
    
//    jsonString = [jsonString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//    [jsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    return jsonString;
}
@end
