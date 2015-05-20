//
//  T8ImageUploadManager.h
//  Telegraph
//
//  Created by 琦张 on 15/3/9.
//
//

#import <Foundation/Foundation.h>
#import "QiniuSDK.h"

typedef void(^uploadSuccess)(NSString *url);
typedef void(^uploadFailure)();
typedef void(^resultBlock)(BOOL result);

@interface T8ImageUploadManager : NSObject

@property (nonatomic,strong) QNUploadManager *uploadManager;

AS_SINGLETON(T8ImageUploadManager)

- (void)uploadImage:(UIImage *)image tmpName:(NSString *)tmpName successBlock:(uploadSuccess)success failureBlock:(uploadFailure)failure;

- (void)uploadImagesBatch:(NSMutableArray *)imageDicts result:(resultBlock)resultBlock;

- (void)uploadForwardImagesBatch:(NSMutableArray *)imageDicts result:(resultBlock)resultBlock;

@end