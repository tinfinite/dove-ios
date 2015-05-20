//
//  TGNodeForwardModel.h
//  Telegraph
//
//  Created by 琦张 on 15/3/30.
//
//

#import <Foundation/Foundation.h>
#import "TGNodeForwardMessageModel.h"

@interface TGNodeForwardModel : NSObject

@property (nonatomic,strong) NSDictionary *dataDict;
@property (nonatomic,copy) NSString *comment;
@property (nonatomic,copy) NSString *groupId;
@property (nonatomic,copy) NSString *groupName;
@property (nonatomic,copy) NSString *groupAvatar;
@property (nonatomic,copy) NSString *groupAvatarKey;

@property (nonatomic,strong) NSMutableArray *messages;
@property (nonatomic,strong) NSMutableArray *textMsgs;
@property (nonatomic,strong) NSMutableArray *photoMsgs;
@property (nonatomic,assign) CGFloat commentHeight;

- (instancetype)initWithDict:(NSDictionary *)dict;

@end
