//
//  TGJoinRequestModel.h
//  Telegraph
//
//  Created by yewei on 15/2/16.
//
//

#import <Foundation/Foundation.h>

@interface TGJoinRequestObject : NSObject

@property (nonatomic,copy) NSString *joinRequestId;
@property (nonatomic,copy) NSString *message;
@property (nonatomic,copy) NSString *groupId;
@property (nonatomic,copy) NSString *userId;
@property (nonatomic,copy) NSString *username;
@property (nonatomic,copy) NSString *avatar;
@property (nonatomic,copy) NSString *creatTime;

- (id)initWithDict:(NSDictionary *)dict;

@end
