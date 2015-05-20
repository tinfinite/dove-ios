//
//  TGNodeForwardedMessageAuthorModel.m
//  Telegraph
//
//  Created by 琦张 on 15/3/30.
//
//

#import "TGNodeForwardedMessageAuthorModel.h"

@implementation TGNodeForwardedMessageAuthorModel

- (instancetype)initWithDict:(NSDictionary *)dict
{
    if (dict == nil) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        self.userid = [dict stringForKey:@"user_id" withDefault:@""];
        self.username = [dict stringForKey:@"username" withDefault:@""];
        self.firstname = [dict stringForKey:@"first_name" withDefault:@""];
        self.lastname = [dict stringForKey:@"last_name" withDefault:@""];
        if (self.username.length) {
            self.name = [NSString stringWithFormat:@"@%@",self.username];
        }else{
            self.name = [NSString stringWithFormat:@"@%@ %@",self.firstname,self.lastname];
        }
        self.anonymous = [dict intValueForKey:@"anonymous" withDefault:0];
    }
    return self;
}

@end
