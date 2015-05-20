//
//  TGNodeCommentModel.h
//  Telegraph
//
//  Created by 琦张 on 15/4/1.
//
//

#import <Foundation/Foundation.h>

@interface TGNodeCommentModel : NSObject

@property (nonatomic,copy) NSString *commentId;
@property (nonatomic,copy) NSString *authorId;
@property (nonatomic,copy) NSString *authorAvatar;
@property (nonatomic,copy) NSString *authorUsername;
@property (nonatomic,copy) NSString *authorFirstname;
@property (nonatomic,copy) NSString *authorLastname;
@property (nonatomic,copy) NSString *content;
@property (nonatomic,copy) NSString *createTime;

@property (nonatomic,assign) CGFloat cellHeight;

- (instancetype)initWithDict:(NSDictionary *)dict;

+ (TGNodeCommentModel *)getDefaultCommentModel;

@end
