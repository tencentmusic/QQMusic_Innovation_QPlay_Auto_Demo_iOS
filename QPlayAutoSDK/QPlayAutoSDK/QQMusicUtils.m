//
//  QQMusicUtils.m
//  QPlayAutoSDK
//
//  Created by travisli(李鞠佑) on 2018/11/7.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#import "QQMusicUtils.h"
#import <UIKit/UIApplication.h>

@implementation QQMusicUtils

+ (NSDictionary *)paserURLParam:(NSURL *)url
{
    NSLog(@"URL PARAMTER STR:%@",url);
    NSString *strURL = [url absoluteString];
    
    NSRange range = [strURL rangeOfString:@"?"];
    if (range.location == NSNotFound) {
        range = [strURL rangeOfString:@"://"];
        if (range.location == NSNotFound) {
            return nil;
        }
    }
    NSString *argString = [strURL substringFromIndex:(range.location + range.length)];
    
    NSMutableDictionary* ret = [NSMutableDictionary dictionary];
    NSArray* components = [argString componentsSeparatedByString:@"&"];
    // Use reverse order so that the first occurrence of a key replaces
    // those subsequent.
    for(NSString* component in [components reverseObjectEnumerator]) {
        if ([component length] == 0)
            continue;
        NSRange pos = [component rangeOfString:@"="];
        NSString *key;
        NSString *val;
        if (pos.location == NSNotFound) {
            key = [component stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            val = @"";
        } else {
            key = [[component substringToIndex:pos.location]
                   stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            val = [[component substringFromIndex:pos.location + pos.length]
                   stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
        // gtm_stringByUnescapingFromURLArgument returns nil on invalid UTF8
        // and NSMutableDictionary raises an exception when passed nil values.
        if (!key) key = @"";
        if (!val) val = @"";
        [ret setObject:val forKey:key];
    }
    NSLog(@"URL PARAMTER:%@",ret);
    return ret;
}

+ (NSMutableDictionary *)parseQueryComponentsFromQueryString:(NSString *)queryStr
{
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    if (nil == queryStr || queryStr.length == 0)
    {
        return results;
    }
    
    NSArray *components = [queryStr componentsSeparatedByString:@"&"];
    for (NSString *component in components) {
        //检查kv的长度，有可能没value甚至没key
        /*NSArray *kv = [component componentsSeparatedByString:@"="];
         NSString *key = kv.count > 0 ? [kv objectAtIndex:0] : nil;
         NSString *value = kv.count > 1 ? [kv objectAtIndex:1] : nil;*/
        NSRange range = [component rangeOfString:@"="];
        NSString *key, *value;
        if (range.location == NSNotFound) {
            key = component;
            value = @"";
        }
        else {
            key = [component substringToIndex:range.location];
            value = [component substringFromIndex:range.location + 1];
        }
        if (value == nil) value = @"";
        //必须至少有个key，value默认为空字符串
        if (key && key.length && value) {
            id existedValue = [results objectForKey:key];
            if (existedValue) {
                if ([existedValue isMemberOfClass:[NSMutableArray class]]) {
                    [existedValue addObject:value];
                }
                else {
                    [results setObject:[NSMutableArray arrayWithObjects:existedValue, value, nil] forKey:key];
                }
            }
            else {
                [results setObject:value forKey:key];
            }
        }
    }
    
    return results;
}

+ (NSMutableDictionary *)queryComponents:(NSURL*)url
{
    return [QQMusicUtils parseQueryComponentsFromQueryString:url.query];
}

+ (NSString *)queryComponent:(NSURL*)url Named:(NSString *)name index:(NSInteger)index
{
    NSMutableDictionary *dict = [QQMusicUtils queryComponents:url];
    id result = [dict objectForKey:name];
    if ([result isKindOfClass:[NSArray class]])
    {
        NSArray *ayResult = (NSArray *)result;
        if (ayResult.count>0 && [ayResult[0] isKindOfClass:[NSString class]])
        {
            return ayResult[0];
        }
    }
    return result;
}

+ (NSString *)queryComponent:(NSURL*)url Named:(NSString *)name
{
    return [QQMusicUtils queryComponent:url Named:name index:0];
}


+ (id)objectWithJsonData:(NSData *)data error:(__autoreleasing NSError **)error targetClass:(Class)targetClass
{
    NSError * __autoreleasing errStub;
    if (nil == error)
    {
        error = &errStub;
    }
    if (data == nil)
    {
        NSLog(@"data:(%@)", data);
        return nil;
    }
    id obj = nil;
    @try{
        obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:error];
    }
    @catch (NSException *exception) {
        NSLog(@"json exception:%@", exception);
        NSAssert(NO, @"got a exception!");
    }
    
    if (nil != *error)
    {
        NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"parse json error(%@), data:(%@)", *error, json);
    }
    if ((nil != obj)
        && (Nil != targetClass)
        && (NO == [obj isKindOfClass:targetClass]))
    {
        NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"parse json expect class:(%@), actually:(%@) data:(%@)", targetClass, [obj class], json);
        
        obj = nil;  // 类型不对，返回nil
    }
    return obj;
}

+ (NSString *)strWithJsonObject:(id)object
{
    NSError *error = nil;
    
    if ([NSJSONSerialization isValidJSONObject:object])
    {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:&error];
        
        if (!error)
        {
            NSString *json = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
            return json;
        }
    }
    
    NSLog(@"-JSONRepresentation failed. Error is: %@", error);
    return nil;
}


+ (void)openUrl:(NSString*)strUrl
{
    if (@available(iOS 10.0, *))
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:strUrl] options:@{} completionHandler:^(BOOL success) {
            if (!success)
            {
                NSLog(@"openUrl失败,%@",strUrl);
            }
        }];
    }
    else
    {
        if (NO ==[[UIApplication sharedApplication] openURL:[NSURL URLWithString:strUrl]])
        {
            NSLog(@"openUrl失败,%@",strUrl);
        }
    }
}

@end
