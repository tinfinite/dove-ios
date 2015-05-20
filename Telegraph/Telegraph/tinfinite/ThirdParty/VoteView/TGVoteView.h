//
//  TGVoteView.h
//  Telegraph
//
//  Created by yewei on 15/3/23.
//
//

#import <Foundation/Foundation.h>

CGRect TGScreenBounds();

typedef void (^TGUpvoteBlock)();
typedef void (^TGDownvoteBlock)();

@interface TGVoteView : UIView

@property (nonatomic, copy) TGUpvoteBlock upvoteBlock;
@property (nonatomic, copy) TGDownvoteBlock downvoteBlock;

- (id)initWithUpvoteStatus:(BOOL)upvote downvoteStatus:(BOOL)downvote upvoteBlock:(TGUpvoteBlock)upvoteBlock downvoteBlock:(TGDownvoteBlock)downvoteBlock;
- (void)show;

@end
