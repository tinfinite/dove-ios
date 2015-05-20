//
//  TGNodeCommentModel.m
//  Telegraph
//
//  Created by 琦张 on 15/4/1.
//
//

#import "TGNodeCommentModel.h"
#import "TGDatabase.h"

@implementation TGNodeCommentModel

- (instancetype)initWithDict:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        self.commentId = [dict stringForKey:@"id" withDefault:@""];
        self.content = [dict stringForKey:@"content" withDefault:@""];
        self.createTime = [dict stringForKey:@"create_at" withDefault:@""];
        NSDictionary *authorDict = [dict dictForKey:@"author" withDefault:[NSDictionary dictionary]];
        self.authorId = [authorDict stringForKey:@"id" withDefault:@""];
        self.authorAvatar = [authorDict stringForKey:@"avatar" withDefault:@""];
        self.authorUsername = [authorDict stringForKey:@"username" withDefault:@""];
        self.authorFirstname = [authorDict stringForKey:@"first_name" withDefault:@""];
        self.authorLastname = [authorDict stringForKey:@"last_name" withDefault:@""];
        
        self.cellHeight = 0;
    }
    return self;
}

+ (TGNodeCommentModel *)getDefaultCommentModel
{
    TGNodeCommentModel *comment = [[TGNodeCommentModel alloc] init];
    comment.cellHeight = 0;
    comment.commentId = @"";
    comment.content = @"";
    comment.createTime = [NSDate getT8TimeStamp];
    comment.authorId = T8CONTEXT.t8UserId;
    comment.authorUsername = T8CONTEXT.username;
    comment.authorFirstname = T8CONTEXT.firstName;
    comment.authorLastname = T8CONTEXT.lastName;
    TGUser *user = [TGDatabaseInstance() loadUser:T8CONTEXT.tgUserId];
    comment.authorAvatar = user.photoUrlSmall;
    return comment;
}

@end
