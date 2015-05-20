//
//  NSMutableDictionary+Ext.h
//  Tinfinite
//
//  Created by yewei on 14/11/21.
//  Copyright (c) 2014年 Tinfinite. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (Ext)

/**
 *  如果object不为空，则向Dictionary添加一个对象
 */
- (void)addObject:(id)object forKey:(NSString *)keyValue;

@end
