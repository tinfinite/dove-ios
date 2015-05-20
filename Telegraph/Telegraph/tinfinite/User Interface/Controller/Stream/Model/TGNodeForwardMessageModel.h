//
//  TGNodeForwardMessageModel.h
//  Telegraph
//
//  Created by 琦张 on 15/3/30.
//
//

#import <Foundation/Foundation.h>
#import "TGNodeForwardedMessageAuthorModel.h"
#import "TGNodePhotoObject.h"

@interface TGNodeForwardMessageModel : NSObject

@property (nonatomic,assign) NSInteger msgPoint;
@property (nonatomic,assign) NSTimeInterval msgTime;
@property (nonatomic,assign) ForwardMessageType msgType;
@property (nonatomic,copy) NSString *msgContent;
@property (nonatomic,assign) CGFloat messageHeight;
@property (nonatomic,strong) TGNodePhotoObject *photoObj;

@property (nonatomic,strong) TGNodeForwardedMessageAuthorModel *author;

- (instancetype)initWithDict:(NSDictionary *)dict;

@end
