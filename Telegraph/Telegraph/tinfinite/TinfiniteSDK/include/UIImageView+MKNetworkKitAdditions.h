//
//  UIImageView+MKNetworkKitAdditions.h
//  MKNetworkKit-iOS
//
//  Created by Mugunth Kumar (@mugunthkumar) on 18/01/13.
//  Copyright (C) 2011-2020 by Steinlogic Consulting and Training Pte Ltd

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <UIKit/UIKit.h>

extern const float kFromCacheAnimationDuration;
extern const float kFreshLoadAnimationDuration;

@class MKNetworkEngine;
@class MKNetworkOperation;

typedef void (^queryImageBlock)(UIImage *fetchedImage, NSURL *url, BOOL isInCache);
typedef void (^errorQueryBlock)(MKNetworkOperation *completedOperation, NSError *error);

@interface UIImageView (MKNetworkKitAdditions)
+(void) setDefaultEngine:(MKNetworkEngine*) engine;
-(MKNetworkOperation*) setImageFromURL:(NSURL*) url;
-(MKNetworkOperation*) setImageFromURL:(NSURL*) url placeHolderImage:(UIImage*) image;
-(MKNetworkOperation*) setImageFromURL:(NSURL*) url placeHolderImage:(UIImage*) image animation:(BOOL) yesOrNo;
-(MKNetworkOperation*) setImageFromURL:(NSURL*) url placeHolderImage:(UIImage*) image usingEngine:(MKNetworkEngine*) imageCacheEngine animation:(BOOL) yesOrNo;
-(MKNetworkOperation*) setImageFromURL:(NSURL*) url placeHolderImage:(UIImage*) image usingEngine:(MKNetworkEngine*) imageCacheEngine showSpinner:(BOOL)showSpinner animation:(BOOL) yesOrNo;

//jie.wang 从网络获取后台的原始图片，客户端根据原始图片大小进行页面布局
- (MKNetworkOperation*)setOriginImageFromURL:(NSURL *)url
                            placeHolderImage:(UIImage *)image
                             queryImageBlock:(queryImageBlock)queryImageBlock;
//add by lx @ 2013.8.13 从网络获取后台的原始图片，客户端处理获取成功、失败事件
- (MKNetworkOperation*)setOriginImageFromURL:(NSURL *)url
                            placeHolderImage:(UIImage *)image
                                 sucessBlock:(queryImageBlock)queryImageBlock
                                failureBlock:(errorQueryBlock)errorQueryBlock;

//yewei 不使用缓存
- (MKNetworkOperation*) setImageFromURL:(NSURL *) url
                       placeHolderImage:(UIImage *) image
                             usingCache:(BOOL)yesOrNo;

- (MKNetworkOperation*) setImageFromURL:(NSURL *) url
                       placeHolderImage:(UIImage *) image
                             usingCache:(BOOL)yesOrNo
                            usingEngine:(MKNetworkEngine*) imageCacheEngine
                              animation:(BOOL)animation;

@end