//
//  TGNodeAuthorModel.m
//  Telegraph
//
//  Created by 琦张 on 15/3/30.
//
//

#import "TGNodeAuthorModel.h"

@interface TGNodeAuthorModel ()


@end

@implementation TGNodeAuthorModel

- (instancetype)initWithDict:(NSDictionary *)dict
{
    if (dict==nil) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        self.dataDict = [dict copy];
        self.authorId = [dict stringForKey:@"id" withDefault:@""];
        self.locale = [dict stringForKey:@"locale" withDefault:@""];
        self.tgUserId = [dict stringForKey:@"tg_user_id" withDefault:@""];
        self.avatar = [dict stringForKey:@"avatar" withDefault:@""];
        self.name = [self name:dict];
        self.userName = [dict stringForKey:@"username" withDefault:@""];
    }
    return self;
}

- (NSString *)name:(NSDictionary *)dict
{
    NSString *name = [dict stringForKey:@"username" withDefault:@""];
    if (![name isEqualToString:@""]) {
        return name;
    }else{
        return [NSString stringWithFormat:@"%@ %@",[dict stringForKey:@"first_name" withDefault:@""],[dict stringForKey:@"last_name" withDefault:@""]];
    }
}

@end
