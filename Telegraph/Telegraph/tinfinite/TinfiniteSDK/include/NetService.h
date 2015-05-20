//
//  NetService.h
//  Tinfinite
//
//  Created by yewei on 14/11/20.
//  Copyright (c) 2014年 琦张. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetService : NSObject

- (id)initWithNetworkOperation: (MKNetworkOperation *)networkOperation;


#pragma mark -
#pragma mark - 对外接口

//取消网络请求
- (void)cancel;

//当前网络请求的返回是否是缓存数据
- (BOOL)isCachedResponse;

@end
