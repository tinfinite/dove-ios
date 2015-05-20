//
//  T8ImageUploadItem.m
//  Telegraph
//
//  Created by 琦张 on 15/3/27.
//
//

#import "T8ImageUploadItem.h"
#import "QiniuSDK.h"
#import "NSDictionary+Ext.h"

@interface T8ImageUploadItem ()

@property (nonatomic,copy) NSString *tmpPath;
@property (nonatomic,copy) NSString *qiniuPath;

@end

@implementation T8ImageUploadItem

- (instancetype)initWithImageDict:(NSMutableDictionary *)imageDict uploadManager:(QNUploadManager *)manager token:(NSString *)token result:(itemUploadResult)resultBlock
{
    self = [super init];
    if (self) {
        self.imageDict = imageDict;
        self.uploadManager = manager;
        self.resultBlock = resultBlock;
        self.token = token;
    }
    return self;
}

- (void)startUpload
{
    __weak typeof(self) weakSelf = self;
    if ([self.imageDict objectForKey:ImageItemQiniuPath] && ((NSString *)[self.imageDict objectForKey:ImageItemQiniuPath]).length>0) {
        self.resultBlock(weakSelf,true);
    }
    NSDictionary *localImage = [self.imageDict objectForKey:@"localImage"];
    
    [self.uploadManager putData:[localImage objectForKey:@"imageData"] key:[self uploadKey] token:self.token complete:^(QNResponseInfo __unused *info, NSString __unused *key, NSDictionary *resp) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSString *qiniuPathKey = [resp stringForKey:@"key" withDefault:nil];
        if (qiniuPathKey && qiniuPathKey.length>0) {
            [strongSelf.imageDict setObject:[NSString stringWithFormat:@"http://tinfinite.qiniudn.com/%@",qiniuPathKey] forKey:ImageItemQiniuPath];
            strongSelf.resultBlock(strongSelf,true);
        }else{
            strongSelf.resultBlock(strongSelf,false);
        }
    } option:nil];
}

- (void)forwardImageUpload
{
    if ([[self.imageDict objectForKey:@"messagetype"] integerValue] == 2)
    {
        __weak typeof(self) weakSelf = self;
        if ([self.imageDict objectForKey:ImageItemQiniuPath] && ((NSString *)[self.imageDict objectForKey:ImageItemQiniuPath]).length>0) {
            self.resultBlock(weakSelf,true);
        }
        
        if ([[self.imageDict objectForKey:@"messagecontent"] isKindOfClass:[NSString class]]) {
            UIImage *image = [[UIImage alloc] initWithContentsOfFile:[self.imageDict objectForKey:@"messagecontent"]];
            [self.uploadManager putFile:[self.imageDict objectForKey:@"messagecontent"] key:[self forwardGIFImageUploadKeyWithImageSize:image.size] token:self.token complete:^(QNResponseInfo __unused *info, NSString __unused *key, NSDictionary *resp) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                NSString *qiniuPathKey = [resp stringForKey:@"key" withDefault:nil];
                if (qiniuPathKey && qiniuPathKey.length>0) {
                    [strongSelf.imageDict setObject:[NSString stringWithFormat:@"http://tinfinite.qiniudn.com/%@",qiniuPathKey] forKey:@"messagecontent"];
                    [strongSelf.imageDict removeObjectForKey:@"messageId"];
                    strongSelf.resultBlock(strongSelf,true);
                }else{
                    strongSelf.resultBlock(strongSelf,false);
                }
            } option:nil];
        }else{
            UIImage *image = [self.imageDict objectForKey:@"messagecontent"];
            if (image) {
                NSData *imageData = UIImageJPEGRepresentation(image, 0.3);
                
                [self.uploadManager putData:imageData key:[self forwardImageUploadKeyWithImageSize:image.size] token:self.token complete:^(QNResponseInfo __unused *info, NSString __unused *key, NSDictionary *resp) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    NSString *qiniuPathKey = [resp stringForKey:@"key" withDefault:nil];
                    if (qiniuPathKey && qiniuPathKey.length>0) {
                        [strongSelf.imageDict setObject:[NSString stringWithFormat:@"http://tinfinite.qiniudn.com/%@",qiniuPathKey] forKey:@"messagecontent"];
                        [strongSelf.imageDict removeObjectForKey:@"messageId"];
                        strongSelf.resultBlock(strongSelf,true);
                    }else{
                        strongSelf.resultBlock(strongSelf,false);
                    }
                } option:nil];
            }

        }
    }
}

- (NSString *)uploadKey
{
    NSDictionary *localImage = [self.imageDict objectForKey:@"localImage"];
    NSString *imageAssetUrl = [localImage objectForKey:@"assetUrl"];
    CGSize size = [[localImage objectForKey:@"imageSize"] CGSizeValue];
    NSString *key = [NSString stringWithFormat:@"%d%@%@",[T8CONTEXT tgUserId],[NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]],imageAssetUrl];
    NSString *uploadKey = [NSString stringWithFormat:@"dove/post/i/%@w%.0fh%.0f",[key md5],size.width,size.height];
    return uploadKey;
}

- (NSString *)forwardImageUploadKeyWithImageSize:(CGSize)imageSize
{
    NSString *key = [NSString stringWithFormat:@"%d%@%@",[T8CONTEXT tgUserId],[NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]],[self.imageDict objectForKey:@"messageId"]];
    NSString *uploadKey = [NSString stringWithFormat:@"dove/post/i/%@w%.0fh%.0f",[key md5],imageSize.width,imageSize.height];
    return uploadKey;
}

- (NSString *)forwardGIFImageUploadKeyWithImageSize:(CGSize)imageSize
{
    NSString *key = [NSString stringWithFormat:@"%d%@%@",[T8CONTEXT tgUserId],[NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]],[self.imageDict objectForKey:@"messageId"]];
    NSString *uploadKey = [NSString stringWithFormat:@"dove/post/i/%@w%.0fh%.0f.gif",[key md5],imageSize.width,imageSize.height];
    return uploadKey;
}

@end
