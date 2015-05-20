//
//  extError.h
//  Telegraph
//
//  Created by yewei on 15/2/14.
//
//

#import <Foundation/Foundation.h>

@interface extError : NSError

/**
 * 返回由NSError构建的错误对象.
 */
+ (extError*)errorWithNSError:(NSError*)error;

/**
 * 构造错误对象。
 *
 * @param code 错误代码
 * @param errorMessage 错误信息
 *
 * 返回错误对象.
 */
+ (extError*)errorWithCode:(NSInteger)code errorMessage:(NSString*)errorMessage;

/**
 * 返回用于展现给用户的错误提示标题
 */
- (NSString*)titleForError;

@end
