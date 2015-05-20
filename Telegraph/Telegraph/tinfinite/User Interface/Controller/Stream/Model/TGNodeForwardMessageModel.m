//
//  TGNodeForwardMessageModel.m
//  Telegraph
//
//  Created by 琦张 on 15/3/30.
//
//

#import "TGNodeForwardMessageModel.h"
#import "NSString+Valid.h"

@implementation TGNodeForwardMessageModel

- (instancetype)initWithDict:(NSDictionary *)dict
{
    if (dict == nil) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        self.msgPoint = [dict intValueForKey:@"messagepoint" withDefault:0];
        self.msgTime = [dict floatForKey:@"messagetime" withDefault:0];
        self.msgType = [dict intValueForKey:@"messagetype" withDefault:0];
        self.msgContent = [dict stringForKey:@"messagecontent" withDefault:@""];
        self.messageHeight = [self getMessageHeight];
        self.author = [[TGNodeForwardedMessageAuthorModel alloc] initWithDict:[dict dictForKey:@"user" withDefault:nil]];
    }
    return self;
}

- (CGFloat)getMessageHeight
{
    if (self.msgContent.length) {
        return [self.msgContent heightForSize:CGSizeMake(SCREEN_WIDTH - 30, 176) font:[UIFont systemFontOfSize:15.0f]];
    }
    return 0;
}


@end
