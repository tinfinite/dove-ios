//
//  TGMyCommentedModel.h
//  Telegraph
//
//  Created by yewei on 15/4/22.
//
//

#import <Foundation/Foundation.h>

@interface TGMyCommentedModel : NSObject

@property (nonatomic, copy) NSString *commentContent;
@property (nonatomic, copy) NSString *commentCreateTime;
@property (nonatomic, copy) NSString *commentId;

@property (nonatomic, copy) NSString *postImage;
@property (nonatomic, copy) NSString *postText;
@property (nonatomic, copy) NSString *postCreateTime;
@property (nonatomic, copy) NSString *postId;

@property (nonatomic, copy) NSString *userAvatar;
@property (nonatomic, copy) NSString *userFirstName;
@property (nonatomic, copy) NSString *userLastName;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *userTgId;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, copy) NSString *name;

- (id)initWithDict:(NSDictionary *)dict;

@end
