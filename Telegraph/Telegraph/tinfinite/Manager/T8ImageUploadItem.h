//
//  T8ImageUploadItem.h
//  Telegraph
//
//  Created by 琦张 on 15/3/27.
//
//

#import <Foundation/Foundation.h>

#define ImageItemQiniuPath @"ImageItemQiniuPath"

@class QNUploadManager;
@class T8ImageUploadItem;

typedef void(^itemUploadResult)(T8ImageUploadItem *item,BOOL success);

@interface T8ImageUploadItem : NSObject

@property (nonatomic,strong) NSMutableDictionary *imageDict;
@property (nonatomic,strong) QNUploadManager *uploadManager;
@property (nonatomic,strong) itemUploadResult resultBlock;
@property (nonatomic,copy) NSString *token;

- (instancetype)initWithImageDict:(NSMutableDictionary *)imageDict uploadManager:(QNUploadManager *)manager token:(NSString *)token result:(itemUploadResult)resultBlock;

- (void)startUpload;

- (void)forwardImageUpload;

@end
