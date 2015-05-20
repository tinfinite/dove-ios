//
//  TGNodeStreamObject.m
//  Telegraph
//
//  Created by yewei on 15/3/29.
//
//

#import "TGNodeModel.h"
#import "TGDatabase.h"

@implementation TGNodeModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.synchronize = YES;
    }
    return self;
}

- (instancetype)initWithDict:(NSDictionary *)dict
{
    if (dict==nil) {
        return nil;
    }
    self = [super init];
    if (self) {
        self.synchronize = NO;
        
        self.nodeId = [dict stringForKey:@"id" withDefault:@""];
        self.sourceType = [dict intValueForKey:@"type" withDefault:0];
        self.isPublic = [dict intValueForKey:@"is_public" withDefault:-1];
        self.createTime = [dict stringForKey:@"create_at" withDefault:@""];
        self.totalScore = [dict intValueForKey:@"total_score" withDefault:0];
        self.totalReply = [dict intValueForKey:@"total_reply" withDefault:0];
        self.isUpvote = [dict intValueForKey:@"is_upvote" withDefault:0];
        self.isDownvote = [dict intValueForKey:@"is_downvote" withDefault:0];
        
        self.author = [[TGNodeAuthorModel alloc] initWithDict:[dict dictForKey:@"author" withDefault:nil]];
        self.post = [[TGNodePostModel alloc] initWithDict:[dict dictForKey:@"post" withDefault:nil]];
        self.forward = [[TGNodeForwardModel alloc] initWithDict:[dict dictForKey:@"forward" withDefault:nil]];
        
        self.synchronize = YES;
    }
    return self;
}

#pragma mark - setter
- (void)setTotalReply:(NSInteger)totalReply
{
    _totalReply = totalReply;
    if (self.synchronize) {
        [TGDatabaseInstance() storeNodeInfoWithID:self.nodeId reply:_totalReply];
    }
}

- (void)setTotalScore:(NSInteger)totalScore
{
    _totalScore = totalScore;
    if (self.synchronize) {
        [TGDatabaseInstance() storeNodeInfoWithID:self.nodeId score:_totalScore];
    }
}

- (void)setIsUpvote:(BOOL)isUpvote
{
    _isUpvote = isUpvote;
    if (self.synchronize) {
        [TGDatabaseInstance() storeNodeInfoWithID:self.nodeId upvote:_isUpvote];
    }
}

- (void)setIsDownvote:(BOOL)isDownvote
{
    _isDownvote = isDownvote;
    if (self.synchronize) {
        [TGDatabaseInstance() storeNodeInfoWithID:self.nodeId downvote:_isDownvote];
    }
}

@end
