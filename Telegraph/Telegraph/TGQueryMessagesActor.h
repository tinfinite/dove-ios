//
//  TGQueryMessagesActor.h
//  Telegraph
//
//  Created by yewei on 15/3/21.
//
//

#import "TGActor.h"
#import "TL/TLMetaScheme.h"

@interface TGQueryMessagesActor : TGActor

- (void)messagesRequestSuccess:(TLmessages_Messages *)result;
- (void)messagesRequestFailed;

@end
