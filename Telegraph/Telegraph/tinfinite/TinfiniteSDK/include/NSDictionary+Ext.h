//
//  NSDictionary+Ext.h
//  Tinfinite
//
//  Created by yewei on 14/11/21.
//  Copyright (c) 2014年 Tinfinite. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Ext)

/**
 返回指定key的字符串值
 没有指定key的值，返回默认值
 */
-(NSString *)stringForKey:(NSString *)key withDefault:(NSString *)defVal;
/**
 返回指定key的字典
 没有指定key的值，返回默认值
 */
-(NSDictionary *)dictForKey:(NSString *)key withDefault:(NSDictionary *)defVal;
/**
 返回指定key的数组
 没有指定key的值，返回默认值
 */
-(NSArray *)arrayForKey:(NSString *)key withDefault:(NSArray *)defVal;
/**
 返回指定key的float值
 没有指定key的值，返回默认值
 */
-(CGFloat)floatForKey:(NSString *)key withDefault:(CGFloat)defVal;
/**
 返回指定key的timeInterval值
 没有指定key的值，返回默认值
 */
-(NSTimeInterval)timeIntervalForKey:(NSString *)key withDefault:(NSTimeInterval)defVal;
/**
 返回指定key的integer值
 没有指定key的值，返回默认值
 */
-(NSInteger)intForKey:(NSString *)key withDefault:(NSInteger)defVal;
/**
 返回指定key的long long值
 没有指定key的值，返回默认值
 */
-(long long)longLongForKey:(NSString *)key withDefault:(long long)defVal;
/**
 返回指定key的long值
 没有指定key的值，返回默认值
 */
-(long)longForKey:(NSString *)key withDefault:(long)defVal;
/**
 返回指定key的int值
 没有指定key的值，返回默认值
 */
-(int)intValueForKey:(NSString *)key withDefault:(int)defVal;


@end
