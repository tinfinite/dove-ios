//
//  TGQueryMessagesActor.m
//  Telegraph
//
//  Created by yewei on 15/3/21.
//
//

#import "TGQueryMessagesActor.h"

#import "ActionStage.h"

#import "TGTelegraph.h"

#import "TGMessage+Telegraph.h"

#import "TGDatabase.h"

#import "TGConversation+Telegraph.h"
#import "TGUserDataRequestBuilder.h"

@implementation TGQueryMessagesActor

+ (NSString *)genericPath
{
    return @"/tg/queryMessages/@";
}

- (void)execute:(NSDictionary *)options
{
    NSArray *mids = options[@"mids"];
    
    self.cancelToken = [TGTelegraphInstance doQueryMessages:mids actor:self];
}

- (void)messagesRequestSuccess:(TLmessages_Messages *)result
{
    NSMutableArray *combinedResults = [[NSMutableArray alloc] init];
    
    [TGUserDataRequestBuilder executeUserDataUpdate:result.users];
    
    NSMutableDictionary *chats = [[NSMutableDictionary alloc] init];
    TGConversation *conversation = nil;
    
    for (TLChat *chatDesc in result.chats)
    {
        conversation = [[TGConversation alloc] initWithTelegraphChatDesc:chatDesc];
        if (conversation != nil)
            [chats setObject:conversation forKey:[[NSNumber alloc] initWithLongLong:conversation.conversationId]];
    }
    
    for (TLMessage *messageDesc in result.messages)
    {
        TGMessage *message = [[TGMessage alloc] initWithTelegraphMessageDesc:messageDesc];
        if (message.mid != 0)
        {
            if (message.cid < 0)
                conversation = [chats[@(message.cid)] copy];
            else
            {
                conversation = [[TGConversation alloc] init];
                conversation.conversationId = message.cid;
            }
            
            if (conversation != nil)
            {
                [conversation mergeMessage:message];
                conversation.additionalProperties = @{@"searchMessageId": @(message.mid)};
            }
        }
        if (conversation) {
            [combinedResults addObject:conversation];
        }
    }
    if (conversation != nil) {
        [ActionStageInstance() actionCompleted:self.path result:@{@"messagesByConversation": combinedResults}];
    }
}

- (void)messagesRequestFailed
{
    [ActionStageInstance() actionFailed:self.path reason:-1];
}


@end
