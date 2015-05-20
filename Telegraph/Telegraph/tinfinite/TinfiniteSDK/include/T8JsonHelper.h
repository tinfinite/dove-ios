//
//  T8JsonHelper.h
//  tinfinite
//
//  Created by yewei on 14/12/9.
//  Copyright (c) 2014年 Tinfinite. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface T8JsonHelper : NSObject

// json string转成Object
+ (id)getObjectWithJsonString:(NSString *)jsonStr;

// Object转json string
+ (NSString *)getJsonStringWithObject:(id)object;

// json data转成Object
+ (id)getObjectWithJsonData:(NSData *)jsonData;

// Object转json data
+ (NSData *)getJsonDataWithObject:(id)object;

@end
