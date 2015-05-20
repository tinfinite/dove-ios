//
//  TGGroupModel.h
//  Telegraph
//
//  Created by 琦张 on 15/2/15.
//
//

#import <Foundation/Foundation.h>

@interface TGGroupObject : NSObject

@property (nonatomic,copy) NSString *t8CommunityId;
@property (nonatomic,assign) int64_t conversationId;
@property (nonatomic,copy) NSString *creatorId;
@property (nonatomic,assign) GroupDiscoverPrivilege privilege;
@property (nonatomic,copy) NSString *groupDesc;
@property (nonatomic,copy) NSString *createTime;
@property (nonatomic,copy) NSString *imageUrl;
@property (nonatomic,assign) NSInteger memberCount;
@property (nonatomic,copy) NSString *groupName;
@property (nonatomic,copy) NSString *language;
@property (nonatomic,assign) NSInteger points;
@property (nonatomic,copy) NSString *avatarKey;

- (instancetype)initWithDict:(NSDictionary *)dict;

@end
