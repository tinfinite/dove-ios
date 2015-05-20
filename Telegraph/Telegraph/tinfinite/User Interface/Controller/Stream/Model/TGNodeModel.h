//
//  TGNodeStreamObject.h
//  Telegraph
//
//  Created by yewei on 15/3/29.
//
//

#import <Foundation/Foundation.h>
#import "TGNodeAuthorModel.h"
#import "TGNodePostModel.h"
#import "TGNodeForwardModel.h"

@interface TGNodeModel : NSObject

@property (nonatomic,copy) NSString *nodeId;
@property (nonatomic,assign) PostPublishType isPublic;
@property (nonatomic,assign) PostSourceType sourceType;
@property (nonatomic,assign) NSInteger totalScore;
@property (nonatomic,assign) NSInteger totalReply;
@property (nonatomic,copy) NSString *createTime;
@property (nonatomic,assign) BOOL isUpvote;
@property (nonatomic,assign) BOOL isDownvote;

@property (nonatomic,strong) TGNodeAuthorModel *author;
@property (nonatomic,strong) TGNodePostModel *post;
@property (nonatomic,strong) TGNodeForwardModel *forward;

@property (nonatomic,assign) CGFloat cellHeight;

@property (nonatomic,assign) BOOL synchronize;

- (instancetype)initWithDict:(NSDictionary *)dict;

@end
