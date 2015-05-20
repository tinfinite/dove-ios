//
//  TGGroupInfoUpvoteMessageController.m
//  Telegraph
//
//  Created by yewei on 15/3/16.
//
//

#import "TGGroupInfoUpvoteMessageController.h"
#import "TGInterfaceAssets.h"
#import "TGListsTableView.h"
#import "TGDialogListCell.h"
#import "SGraphObjectNode.h"
#import "TGTelegraph.h"
#import "TGStringUtils.h"
#import "TGInterfaceManager.h"
#import "TGProgressWindow.h"
#import "TGUpvoteMessageTableViewCell.h"
#import "T8VoteService.h"

@interface TGGroupInfoUpvoteMessageController ()<UITableViewDataSource,UITableViewDelegate>
{
    TGConversation *_conversation;
    TGProgressWindow *_progressWindow;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *listModel;

@end

//NSString *authorNameYou = @"  __TGLocalized__YOU";

@implementation TGGroupInfoUpvoteMessageController

- (instancetype)initConversation:(TGConversation *)conversation
{
    self = [super init];
    if (self) {
        _conversation = conversation;
        
        _listModel = [[NSMutableArray alloc] init];
        
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:false];
        
        [self requestUpvotedMessages];
    }
    return self;
}

- (void)dealloc
{
    [_actionHandle reset];
    [ActionStageInstance() removeWatcher:self];
}

- (void)requestUpvotedMessages
{
    [T8VoteService getGroupUpvoteMessagesWithconversationID:_conversation.conversationId success:^(NSDictionary *dictRet) {
        
        TGUser *selfUser = [[TGDatabase instance] loadUser:TGTelegraphInstance.clientUserId];
        
        NSArray *conversations = [dictRet objectForKey:@"data"];
        for (NSDictionary *dict in conversations) {
            NSString *tgMessageKey = [dict objectForKey:@"tg_message_key"];
            NSArray *messageKeys = [tgMessageKey componentsSeparatedByString:@"_"];
            
            TGMessage *message = [TGDatabaseInstance() getSameSecondMessageWithFromUid:[messageKeys[0] integerValue] toUid:-[messageKeys[1] integerValue] date:[messageKeys[2] integerValue] index:[messageKeys[3] integerValue]];
            
            if (message) {
                TGConversation *conversation = [_conversation copy];
                
                NSInteger points = [dict[@"points"] integerValue];
                if (points > 1) {
                    conversation.points = [NSString stringWithFormat:@"%ld points",(long)points];
                }else{
                    conversation.points = [NSString stringWithFormat:@"%ld point",(long)points];
                }

                [conversation mergeMessage:message];
                conversation.additionalProperties = @{@"searchMessageId": @(message.mid)};
                
                [self initializeDialogListData:conversation customUser:nil selfUser:selfUser];
                [_listModel addObject:conversation];
            }
        }
        
        [_tableView reloadData];
    } failure:^(NSDictionary * __unused dictRet, NSError * __unused error) {
        
    }];
}

- (void)actorCompleted:(int)resultCode path:(NSString *)path result:(id)result
{
    if ([path hasPrefix:@"/tg/queryMessages/"]){
        if (resultCode == ASStatusSuccess) {
            TGUser *selfUser = [[TGDatabase instance] loadUser:TGTelegraphInstance.clientUserId];
            
            TGConversation *conversation = result[@"messagesByConversation"];
            [self initializeDialogListData:conversation customUser:nil selfUser:selfUser];
            [_listModel addObject:conversation];
            
            dispatch_async(dispatch_get_main_queue(), ^
                           {
                               [_tableView reloadData];
                           });
        }
    }
    else if ([path hasPrefix:@"/tg/loadConversationAndMessageForSearch/"])
    {
        TGDispatchOnMainThread(^
                               {
                                   [_progressWindow dismiss:true];
                                   _progressWindow = nil;
                                   
                                   if (resultCode == ASStatusSuccess)
                                   {
                                       int64_t conversationId = [result[@"peerId"] longLongValue];
                                       TGConversation *conversation = result[@"conversation"];
                                       int32_t messageId = [result[@"messageId"] intValue];
                                       
                                       [[TGInterfaceManager instance] navigateToConversationWithId:conversationId conversation:conversation performActions:nil atMessage:@{@"mid": @(messageId)} clearStack:true openKeyboard:false animated:true];
                                   }
                               });
    }
}

- (void)initializeDialogListData:(TGConversation *)conversation customUser:(TGUser *)customUser selfUser:(TGUser *)selfUser
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    if (!conversation.isChat || conversation.isEncrypted)
    {
        int32_t userId = 0;
        if (conversation.isEncrypted)
        {
            if (conversation.chatParticipants.chatParticipantUids.count != 0)
                userId = [conversation.chatParticipants.chatParticipantUids[0] intValue];
        }
        else
            userId = (int)conversation.conversationId;
        
        TGUser *user = nil;
        if (customUser != nil && customUser.uid == userId)
            user = customUser;
        else
            user = [[TGDatabase instance] loadUser:(int)userId];
        
        NSString *title = nil;
        NSArray *titleLetters = nil;
        
        if ((user.phoneNumber.length != 0 && ![TGDatabaseInstance() uidIsRemoteContact:user.uid]) && user.uid != 333000)
            title = user.formattedPhoneNumber;
        else
            title = [user displayName];
        
        if (user.firstName.length != 0 && user.lastName.length != 0)
            titleLetters = [[NSArray alloc] initWithObjects:[user.firstName substringToIndex:1], [user.lastName substringToIndex:1], nil];
        else if (user.firstName.length != 0)
            titleLetters = [[NSArray alloc] initWithObjects:[user.firstName substringToIndex:1], nil];
        else if (user.lastName.length != 0)
            titleLetters = [[NSArray alloc] initWithObjects:[user.lastName substringToIndex:1], nil];
        
        if (title != nil)
            [dict setObject:title forKey:@"title"];
        
        if (titleLetters != nil)
            dict[@"titleLetters"] = titleLetters;
        
        dict[@"isEncrypted"] = [[NSNumber alloc] initWithBool:conversation.isEncrypted];
        if (conversation.isEncrypted)
        {
            dict[@"encryptionStatus"] = [[NSNumber alloc] initWithInt:conversation.encryptedData.handshakeState];
            dict[@"encryptionOutgoing"] = [[NSNumber alloc] initWithBool:conversation.chatParticipants.chatAdminId == TGTelegraphInstance.clientUserId];
            NSString *firstName = user.displayFirstName;
            dict[@"encryptionFirstName"] = firstName != nil ? firstName : @"";
            
            if (user.firstName != nil)
                dict[@"firstName"] = user.firstName;
            if (user.lastName != nil)
                dict[@"lastName"] = user.lastName;
        }
        dict[@"encryptedUserId"] = [[NSNumber alloc] initWithInt:userId];
        
        if (user.photoUrlSmall != nil)
            [dict setObject:user.photoUrlSmall forKey:@"avatarUrl"];
        [dict setObject:[NSNumber numberWithBool:false] forKey:@"isChat"];
        
        NSString *authorAvatarUrl = nil;
        if (selfUser != nil)
            authorAvatarUrl = selfUser.photoUrlSmall;
        
        if (authorAvatarUrl != nil)
            [dict setObject:authorAvatarUrl forKey:@"authorAvatarUrl"];
        
        if (conversation.media.count != 0)
        {
            NSString *authorName = nil;
            if (conversation.fromUid == selfUser.uid)
            {
                static NSString *youString = nil;
                if (youString == nil)
                    youString = TGLocalized(@"DialogList.You");
                
                authorName = youString;
            }
            else
            {
                if (conversation.fromUid != 0)
                {
                    TGUser *authorUser = [[TGDatabase instance] loadUser:conversation.fromUid];
                    if (authorUser != nil)
                    {
                        authorName = authorUser.displayName;
                    }
                }
            }
            
            if (authorName != nil)
                [dict setObject:authorName forKey:@"authorName"];
        }
    }
    else
    {
        dict[@"isBroadcast"] = @(conversation.isBroadcast);
        
        if (conversation.isBroadcast && conversation.chatTitle.length == 0)
            dict[@"title"] = [self stringForMemberCount:conversation.chatParticipantCount];
        else
            [dict setObject:(conversation.chatTitle == nil ? @"" : conversation.chatTitle) forKey:@"title"];
        
        if (conversation.chatPhotoSmall.length != 0)
            [dict setObject:conversation.chatPhotoSmall forKey:@"avatarUrl"];
        
        [dict setObject:[NSNumber numberWithBool:true] forKey:@"isChat"];
        
        NSString *authorName = nil;
        NSString *authorAvatarUrl = nil;
        if (conversation.fromUid == selfUser.uid)
        {
            authorAvatarUrl = selfUser.photoUrlSmall;
            
            static NSString *youString = nil;
            if (youString == nil)
                youString = TGLocalized(@"DialogList.You");
            
            if (conversation.text.length != 0 || conversation.media.count != 0)
                authorName = youString;
        }
        else
        {
            if (conversation.fromUid != 0)
            {
                TGUser *authorUser = [[TGDatabase instance] loadUser:conversation.fromUid];
                if (authorUser != nil)
                {
                    authorAvatarUrl = authorUser.photoUrlSmall;
                    authorName = authorUser.displayName;
                }
            }
        }
        
        if (authorAvatarUrl != nil)
            [dict setObject:authorAvatarUrl forKey:@"authorAvatarUrl"];
        if (authorName != nil)
            [dict setObject:authorName forKey:@"authorName"];
    }
    
    NSMutableDictionary *messageUsers = [[NSMutableDictionary alloc] init];
    for (TGMediaAttachment *attachment in conversation.media)
    {
        if (attachment.type == TGActionMediaAttachmentType)
        {
            TGActionMediaAttachment *actionAttachment = (TGActionMediaAttachment *)attachment;
            if (actionAttachment.actionType == TGMessageActionChatAddMember || actionAttachment.actionType == TGMessageActionChatDeleteMember)
            {
                NSNumber *nUid = [actionAttachment.actionData objectForKey:@"uid"];
                if (nUid != nil)
                {
                    TGUser *user = [TGDatabaseInstance() loadUser:[nUid intValue]];
                    if (user != nil)
                        [messageUsers setObject:user forKey:nUid];
                }
            }
            
            TGUser *user = conversation.fromUid == selfUser.uid ? selfUser : [TGDatabaseInstance() loadUser:(int)conversation.fromUid];
            if (user != nil)
            {
                [messageUsers setObject:user forKey:[[NSNumber alloc] initWithInt:user.uid]];
                [messageUsers setObject:user forKey:@"author"];
            }
        }
    }
    
    [dict setObject:[[NSNumber alloc] initWithBool:[TGDatabaseInstance() isPeerMuted:conversation.conversationId]] forKey:@"mute"];
    
    [dict setObject:messageUsers forKey:@"users"];
    conversation.dialogListData = dict;
}

- (NSString *)stringForMemberCount:(int)memberCount
{
    if (memberCount == 1)
        return TGLocalizedStatic(@"Conversation.StatusRecipients_1");
    else if (memberCount == 2)
        return TGLocalizedStatic(@"Conversation.StatusRecipients_2");
    else if (memberCount >= 3 && memberCount <= 10)
        return [[NSString alloc] initWithFormat:TGLocalizedStatic(@"Conversation.StatusRecipients_3_10"), [TGStringUtils stringWithLocalizedNumber:memberCount]];
    else
        return [[NSString alloc] initWithFormat:TGLocalizedStatic(@"Conversation.StatusRecipients_any"), [TGStringUtils stringWithLocalizedNumber:memberCount]];
}

- (void)didSelectedConversation:(TGConversation *)conversation atMessageId:(int)messageId
{
    if ([TGDatabaseInstance() loadMessageWithMid:messageId] != nil)
    {
        int64_t conversationId = conversation.conversationId;
        [[TGInterfaceManager instance] navigateToConversationWithId:conversationId conversation:conversation performActions:nil atMessage:@{@"mid": @(messageId)} clearStack:true openKeyboard:false animated:true];
    }
    else
    {
        _progressWindow = [[TGProgressWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [_progressWindow show:true];
        
        [ActionStageInstance() requestActor:[[NSString alloc] initWithFormat:@"/tg/loadConversationAndMessageForSearch/(%" PRId64 ", %" PRId32 ")", conversation.conversationId, messageId] options:@{@"peerId": @(conversation.conversationId), @"messageId": @(messageId)} flags:0 watcher:self];
    }
}

- (void)didSelectedConversation:(TGConversation *)conversation
{
    int64_t conversationId = conversation.conversationId;
    [[TGInterfaceManager instance] navigateToConversationWithId:conversationId conversation:conversation];
}

- (void)loadView
{
    [super loadView];
    
    self.view.backgroundColor = [TGInterfaceAssets listsBackgroundColor];
    
    [self setTitleText:TGLocalized(@"UpvoteMessages.Title")];
    
    CGRect tableFrame = self.view.bounds;
    _tableView = [[TGListsTableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.opaque = true;
    _tableView.backgroundColor = nil;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.alwaysBounceVertical = true;
    _tableView.bounces = true;
    
    [self.view addSubview:_tableView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table logic
- (NSInteger)numberOfSectionsInTableView:(UITableView *)__unused tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)__unused tableView numberOfRowsInSection:(NSInteger)__unused section
{
    return _listModel.count;
}

- (CGFloat)tableView:(UITableView *)__unused tableView heightForRowAtIndexPath:(NSIndexPath *)__unused indexPath
{
    return 76;
}

- (void)prepareCell:(TGUpvoteMessageTableViewCell *)cell forConversation:(TGConversation *)conversation animated:(bool)animated
{
    if (cell.reuseTag != (NSInteger)conversation || cell.conversationId != conversation.conversationId)
    {
        cell.reuseTag = (NSInteger)conversation;
        cell.conversationId = conversation.conversationId;
        
        cell.date = conversation.date;
        
        NSDictionary *dialogListData = conversation.dialogListData;
        
        NSNumber *nIsChat = [dialogListData objectForKey:@"isChat"];
        if (nIsChat != nil && [nIsChat boolValue])
        {
            cell.isGroupChat = true;
            cell.avatarUrl = [dialogListData objectForKey:@"authorAvatarUrl"];
            
            NSString *authorName = [dialogListData objectForKey:@"authorName"];
            cell.authorName = authorName;
        }
        else
        {
            cell.avatarUrl = [dialogListData objectForKey:@"avatarUrl"];
            cell.isGroupChat = false;
            
            NSString *authorName = [dialogListData objectForKey:@"authorName"];
            cell.authorName = authorName;
        }
        
        cell.messageText = conversation.text;
        cell.messageAttachments = conversation.media;
        cell.users = [dialogListData objectForKey:@"users"];
        cell.pointText = conversation.points;
        
        [cell resetView:animated];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TGConversation *conversation = [_listModel objectAtIndex:indexPath.row];
    
    static NSString *MessageCellIdentifier = @"MessageCellIdentifier";
    TGUpvoteMessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MessageCellIdentifier];
    
    if (cell == nil)
    {
        cell = [[TGUpvoteMessageTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MessageCellIdentifier assetsSource:[TGInterfaceAssets instance]];
    }
    
    [self prepareCell:cell forConversation:conversation animated:false];
    
    return cell;
}

- (void)tableView:(UITableView *) __unused tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TGConversation *conversation = [_listModel objectAtIndex:indexPath.row];
    
    if ([conversation.additionalProperties objectForKey:@"searchMessageId"] != nil)
    {
        [self didSelectedConversation:conversation atMessageId:[[conversation.additionalProperties objectForKey:@"searchMessageId"] intValue]];
    }else{
        [self didSelectedConversation:conversation];
    }
    
}

@end
