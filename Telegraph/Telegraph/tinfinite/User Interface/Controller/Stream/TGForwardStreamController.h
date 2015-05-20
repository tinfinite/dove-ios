//
//  TGForwardStreamController.h
//  Telegraph
//
//  Created by yewei on 15/3/25.
//
//

#import "TGViewController.h"

@interface TGForwardStreamController : TGViewController

- (id)initWithPostMessages:(NSArray *)postMessages conversationId:(int64_t)conversationId groupAvatar:(UIImage *)groupAvatar;

@end
