//
//  T8Context.h
//  Telegraph
//
//  Created by yewei on 15/2/14.
//
//

#import <Foundation/Foundation.h>

@interface T8Context : NSObject

@property (nonatomic,copy) NSString *appKey;
@property (nonatomic,copy) NSString *appSecretKey;
@property (nonatomic)      int tgUserId;
@property (nonatomic,copy) NSString *t8UserId;
@property (nonatomic,copy) NSString *phone;
@property (nonatomic,copy) NSString *username;
@property (nonatomic,copy) NSString *firstName;
@property (nonatomic,copy) NSString *lastName;
@property (nonatomic,copy) NSString *photoUrlSmall;
@property (nonatomic,copy) NSString *accessToken;
@property (nonatomic,assign) BOOL isNewer;              //是否是第一次绑定
@property (nonatomic,assign) BOOL anonymous;    //匿名总开关

+ (T8Context *)getInstance;

@end
