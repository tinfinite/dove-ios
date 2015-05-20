//
//  TGVoteInfoObject.h
//  Telegraph
//
//  Created by 琦张 on 15/3/18.
//
//

#import <Foundation/Foundation.h>
#import "PSKeyValueCoder.h"

@interface TGVoteInfoObject : NSObject<PSCoding>

@property (nonatomic,assign) int count;
@property (nonatomic,assign) BOOL upvote;
@property (nonatomic,assign) BOOL downvote;

@end
