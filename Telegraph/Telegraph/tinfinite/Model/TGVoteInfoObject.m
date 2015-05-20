//
//  TGVoteInfoObject.m
//  Telegraph
//
//  Created by 琦张 on 15/3/18.
//
//

#import "TGVoteInfoObject.h"

@implementation TGVoteInfoObject

- (id)init
{
    self = [super init];
    if (self) {
        self.count = 0;
        self.upvote = NO;
        self.downvote = NO;
    }
    return self;
}

- (instancetype)initWithKeyValueCoder:(PSKeyValueCoder *)coder
{
    TGVoteInfoObject *obj = [[TGVoteInfoObject alloc] init];
    
    obj.count = [coder decodeInt32ForKey:@"count"];
    obj.upvote = [coder decodeInt32ForKey:@"upvote"];
    obj.downvote = [coder decodeInt32ForKey:@"downvote"];
    
    return obj;
}

- (void)encodeWithKeyValueCoder:(PSKeyValueCoder *)coder
{
    [coder encodeInt32:self.count forKey:@"count"];
    [coder encodeInt32:self.upvote forKey:@"upvote"];
    [coder encodeInt32:self.downvote forKey:@"downvote"];
}

@end
