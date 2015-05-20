//
//  T8ImageUploadManager.m
//  Telegraph
//
//  Created by 琦张 on 15/3/9.
//
//

#import "T8ImageUploadManager.h"
#import "T8GroupAndCommunityService.h"
#import "NSDictionary+Ext.h"
#import "T8ImageUploadItem.h"

@interface T8ImageUploadManager ()

@property (nonatomic,strong) NSString *accessToken;
@property (nonatomic,strong) NSString *tmpPath;
@property (nonatomic,strong) NSString *qiniuPath;
@property (nonatomic,strong) uploadSuccess successBlock;
@property (nonatomic,strong) uploadFailure failureBlock;
@property (nonatomic,strong) NSMutableArray *batchUploadItems;

@end

@implementation T8ImageUploadManager

DEF_SINGLETON(T8ImageUploadManager)

#pragma mark - method
- (void)uploadImage:(UIImage *)image tmpName:(NSString *)tmpName successBlock:(uploadSuccess)success failureBlock:(uploadFailure)failure
{
    self.successBlock = success;
    self.failureBlock = failure;
    
    //处理图片，将图片压缩后写入临时文件
    NSString *tmpDir = NSTemporaryDirectory();
    self.tmpPath = [tmpDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg",tmpName.length>0?tmpName:@"defaultTmpImage"]];
    NSData *picData = UIImageJPEGRepresentation(image, 0.3f);
    [picData writeToFile:self.tmpPath atomically:YES];
    
    //从服务器获取七牛的access token
    __weak typeof(self) weakSelf = self;
    [T8GroupAndCommunityService getQiniuAccessTokenWithSuccessBlock:^(NSDictionary *dictRet) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.accessToken = [dictRet stringForKey:@"qnUptoken" withDefault:@""];
        [strongSelf uploadPicToQiniu];
    } failureBlock:^(NSDictionary __unused *dictRet, NSError __unused *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf fail];
    }];
}

- (void)uploadImagesBatch:(NSMutableArray *)imageDicts result:(resultBlock)resultBlock
{
    //从服务器获取七牛的access token
    __weak typeof(self) weakSelf = self;
    __block NSUInteger successCount = 0;
    [T8GroupAndCommunityService getQiniuAccessTokenWithSuccessBlock:^(NSDictionary *dictRet) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.accessToken = [dictRet stringForKey:@"qnUptoken" withDefault:@""];
        [imageDicts enumerateObjectsUsingBlock:^(id obj, NSUInteger __unused idx, BOOL __unused *stop) {
            NSMutableDictionary *imageDict = (NSMutableDictionary *)obj;
            T8ImageUploadItem *item = [[T8ImageUploadItem alloc] initWithImageDict:imageDict uploadManager:strongSelf.uploadManager token:strongSelf.accessToken result:^(T8ImageUploadItem *item,BOOL success) {
                if (!success) {
                    if (resultBlock) {
                        resultBlock(false);
                    }
                }else{
                    successCount++;
                    if (successCount == imageDicts.count) {
                        if (resultBlock) {
                            resultBlock(true);
                        }
                    }
                }
                [strongSelf.batchUploadItems removeObject:item];
            }];
            [strongSelf.batchUploadItems addObject:item];
            [item startUpload];
        }];
    } failureBlock:^(NSDictionary __unused *dictRet, NSError __unused *error) {
        if (resultBlock) {
            resultBlock(false);
        }
    }];
}

- (void)uploadForwardImagesBatch:(NSMutableArray *)imageDicts result:(resultBlock)resultBlock
{
    __weak typeof(self) weakSelf = self;
    __block NSUInteger successCount = 0;
    [T8GroupAndCommunityService getQiniuAccessTokenWithSuccessBlock:^(NSDictionary *dictRet) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.accessToken = [dictRet stringForKey:@"qnUptoken" withDefault:@""];
        [imageDicts enumerateObjectsUsingBlock:^(id obj, NSUInteger __unused idx, BOOL __unused *stop) {
            NSMutableDictionary *imageDict = (NSMutableDictionary *)obj;
            T8ImageUploadItem *item = [[T8ImageUploadItem alloc] initWithImageDict:imageDict uploadManager:strongSelf.uploadManager token:strongSelf.accessToken result:^(T8ImageUploadItem *item,BOOL success) {
                if (!success) {
                    if (resultBlock) {
                        resultBlock(false);
                    }
                }else{
                    successCount++;
                    if (successCount == imageDicts.count) {
                        if (resultBlock) {
                            resultBlock(true);
                        }
                    }
                }
                [strongSelf.batchUploadItems removeObject:item];
            }];
            [strongSelf.batchUploadItems addObject:item];
            [item forwardImageUpload];
        }];
    } failureBlock:^(NSDictionary __unused *dictRet, NSError __unused *error) {
        if (resultBlock) {
            resultBlock(false);
        }
    }];
}

//将图片上传到七牛并获取url
- (void)uploadPicToQiniu
{
    __weak typeof(self) weakSelf = self;
    [self.uploadManager putFile:self.tmpPath key:[self avatarUploadKey] token:self.accessToken complete:^(QNResponseInfo __unused *info, NSString __unused *key, NSDictionary *resp) {
        NSLog(@"resp:%@",resp);
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ([resp stringForKey:@"key" withDefault:nil]) {
            strongSelf.qiniuPath = [NSString stringWithFormat:@"http://tinfinite.qiniudn.com/%@",[resp stringForKey:@"key" withDefault:nil]];
            [strongSelf success];
        }else{
            [strongSelf fail];
        }
    } option:nil];
}

- (void)success
{
    if (self.successBlock) {
        self.successBlock(self.qiniuPath.length>0?self.qiniuPath:@"");
    }
}

- (void)fail
{
    if (self.failureBlock) {
        self.failureBlock();
    }
}

- (NSString *)avatarUploadKey
{
    NSString *key = [NSString stringWithFormat:@"%d%@",[T8CONTEXT tgUserId],[NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]]];
    NSString *uploadKey = [NSString stringWithFormat:@"dove/avatar/i/%@",[key md5]];
    return uploadKey;
}

#pragma mark - getter
- (QNUploadManager *)uploadManager
{
    if (!_uploadManager) {
        _uploadManager = [[QNUploadManager alloc] init];
    }
    return _uploadManager;
}

- (NSMutableArray *)batchUploadItems
{
    if (!_batchUploadItems) {
        _batchUploadItems = [NSMutableArray array];
    }
    return _batchUploadItems;
}

@end
