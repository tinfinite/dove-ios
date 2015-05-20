//
//  TGMyUpvotesController.m
//  Telegraph
//
//  Created by yewei on 15/3/19.
//
//

#import "TGMyUpvotesController.h"
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
#import "TGNodeStreamCell.h"
#import "TGNavigationController.h"
#import "TGUsernameController.h"
#import "TGReplyGroupViewController.h"
#import "TGNodeDetailViewController.h"
#import "TGNodeStreamController.h"
#import "TGTelegraphUserInfoController.h"
#import "TGNodeModel.h"
#import "TGNodeStreamCell.h"
#import "SVPullToRefresh.h"

typedef NS_ENUM(NSInteger, UpvoteType) {
    kUpvoteTypePost = 0,
    kUpvoteTypeMessage
};

@interface TGMyUpvotesController ()<UITableViewDataSource,UITableViewDelegate,TGNodeStreamCellImageTouchDelegate>
{
    TGConversation *_conversation;
    TGProgressWindow *_progressWindow;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *postModels;
@property (nonatomic, strong) NSMutableArray *messageModels;
@property (nonatomic, strong) NSArray *originData;
@property (nonatomic, strong) UIView *segmentView;
@property (nonatomic, assign) UpvoteType upvoteType;
@property (nonatomic, strong) NSString *searchUserName;

@property (nonatomic, strong) NSString *timestamp;
@property (nonatomic, assign) NSInteger currentPage;

@end

@implementation TGMyUpvotesController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"我赞的页面"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (instancetype)initConversation:(TGConversation *)conversation
{
    self = [super init];
    if (self) {
        _conversation = conversation;
        
        _postModels = [[NSMutableArray alloc] init];
        _messageModels = [[NSMutableArray alloc] init];
        
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:false];
        
        [self requestMyUpvoteMessages];
        [self requestMyUpvotePosts];
    }
    return self;
}

- (void)dealloc
{
    [_actionHandle reset];
    [ActionStageInstance() removeWatcher:self];
}

- (void)loadView
{
    [super loadView];
    
    self.view.backgroundColor = [TGInterfaceAssets listsBackgroundColor];
    
    [self setTitleText:TGLocalized(@"Settings.MyUpvotedMessages")];
    
    CGRect tableFrame = self.view.bounds;
    tableFrame.origin.y = 44;
    tableFrame.size.height -= 44;
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
    
    __weak typeof(self) weakSelf = self;
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf loadMoreMyUpvotePosts];
    }];
    
    [self.view addSubview:self.segmentView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)requestMyUpvoteMessages
{
    [T8VoteService getMyUpvoteMessagesWithSuccess:^(NSDictionary *dictRet) {
        
        NSMutableArray *mids = [[NSMutableArray alloc] init];
        
        NSArray *conversations = [dictRet objectForKey:@"data"];
        self.originData = [NSArray arrayWithArray:[dictRet objectForKey:@"data"]];
        for (NSDictionary *dict in conversations) {
            int mid = [[dict objectForKey:@"tg_message_id"] intValue];
            
            [mids addObject:@(mid)];
        }
        NSString *action = [[NSString alloc] initWithFormat:@"/tg/queryMessages/(%@)",@"myvote"];
        NSDictionary *options = @{@"mids": mids};
        
        [ActionStageInstance() requestActor:action options:options flags:0 watcher:self];
        [ActionStageInstance() requestActor:action options:options flags:0 watcher:TGTelegraphInstance];
    } failure:^(NSDictionary * __unused dictRet, NSError * __unused error) {
        
    }];
}

- (void)requestMyUpvotePosts
{
    self.currentPage = 1;
    self.timestamp = @"0";
    
    __weak typeof(self) weakSelf = self;
    [T8VoteService getMyUpvotePostsWithPage:self.currentPage limit:20 timestamp:self.timestamp success:^(NSDictionary *dictRet) {
        
        [T8Common storePostsWithSuccessData:dictRet streamType:StreamTypeGroup];
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSArray *array = dictRet[@"data"];
        for (NSDictionary *dict in array) {
            TGNodeModel *model = [[TGNodeModel alloc] initWithDict:dict];
            [strongSelf.postModels addObject:model];
        }
        
        [strongSelf.tableView reloadData];
        strongSelf.timestamp = ((NSNumber *)dictRet[@"timestamp"]).stringValue;
        if (array.count<20) {
            [strongSelf.tableView setShowsInfiniteScrolling:NO];
        }else{
            strongSelf.currentPage++;
        }
    } failure:^(NSDictionary __unused *dictRet, NSError __unused *error) {
        
    }];
}

- (void)loadMoreMyUpvotePosts
{
    __weak typeof(self) weakSelf = self;
    [T8VoteService getMyUpvotePostsWithPage:self.currentPage limit:20 timestamp:self.timestamp success:^(NSDictionary *dictRet) {
        
        [T8Common storePostsWithSuccessData:dictRet streamType:StreamTypeGroup];

        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        NSArray *array = dictRet[@"data"];
        for (NSDictionary *dict in array) {
            TGNodeModel *model = [[TGNodeModel alloc] initWithDict:dict];
            [strongSelf.postModels addObject:model];
        }
        
        [strongSelf.tableView reloadData];
        strongSelf.timestamp = dictRet[@"timestamp"];
        [strongSelf.tableView.infiniteScrollingView stopAnimating];
        
        if (array.count<20) {
            [strongSelf.tableView setShowsInfiniteScrolling:NO];
        }else{
            strongSelf.currentPage++;
        }
    } failure:^(NSDictionary __unused *dictRet, NSError __unused *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.tableView.infiniteScrollingView stopAnimating];
    }];
}

- (void)searchForeignWithUserName:(NSString *)username
{
    NSString *searchPath = [NSString stringWithFormat:@"/tg/contacts/search/(%ld)", (long)[username hash]];
    [ActionStageInstance() requestActor:searchPath options:[NSDictionary dictionaryWithObjectsAndKeys:username, @"query",[[NSNumber alloc] initWithBool:false], @"searchPhonebook", nil] watcher:self];
}

#pragma mark - ASWatcher
- (void)actorMessageReceived:(NSString *)path messageType:(NSString *)messageType message:(id)message
{
    if ([path hasPrefix:@"/tg/contacts/search"])
    {
        NSArray *users = [message objectForKey:@"users"];
        if (users.count) {
            for (TGUser *user in users) {
                if ([user.userName isEqualToString:self.searchUserName]) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        TGTelegraphUserInfoController *userInfoController = [[TGTelegraphUserInfoController alloc] initWithUid:user.uid];
                        [self.navigationController pushViewController:userInfoController animated:true];
                    });
                    break;
                }
            }
        }
    }
}

- (void)actorCompleted:(int)resultCode path:(NSString *)path result:(id)result
{
    if ([path hasPrefix:@"/tg/queryMessages/"]){
        if (resultCode == ASStatusSuccess) {
            NSArray *conversations = result[@"messagesByConversation"];
            for (TGConversation *conversation in conversations) {
                TGUser *selfUser = [[TGDatabase instance] loadUser:TGTelegraphInstance.clientUserId];
                
                [self initializeDialogListData:conversation customUser:nil selfUser:selfUser];
                
                for (NSDictionary *dict in self.originData) {
                    if ([dict[@"tg_message_id"] integerValue] == conversation.mid)
                    {
                        NSInteger points = [dict[@"points"] integerValue];
                        if (points > 1) {
                            conversation.points = [NSString stringWithFormat:@"%ld points",(long)points];
                        }else{
                            conversation.points = [NSString stringWithFormat:@"%ld point",(long)points];
                        }
                    }
                }
                
                
                [_messageModels addObject:conversation];
            }
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

#pragma mark - getter

- (UIView *)segmentView
{
    if (!_segmentView) {
        _segmentView = [[UIView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, 44)];
        _segmentView.backgroundColor = UIColorRGB(0x008DF2);
        
        NSArray *segmentedArray = [[NSArray alloc]initWithObjects:TGLocalized(@"Settings.SegmentPost"), TGLocalized(@"Settings.SegmentMessage"),nil];
        UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:segmentedArray];
        segmentedControl.frame = CGRectMake(44, 7, self.view.frame.size.width - 88, 30.0);
        segmentedControl.selectedSegmentIndex = 0;
        [segmentedControl addTarget:self action:@selector(segmentAction:)forControlEvents:UIControlEventValueChanged];
        segmentedControl.tintColor = [UIColor whiteColor];
        [_segmentView addSubview:segmentedControl];
    }
    return _segmentView;
}

-(void)segmentAction:(UISegmentedControl *)Seg
{
    [self.tableView.infiniteScrollingView stopAnimating];
    
    NSInteger Index = Seg.selectedSegmentIndex;
    self.upvoteType = Index;
    
    if (Index == kUpvoteTypePost) {
        [self.tableView setShowsInfiniteScrolling:YES];
    }else{
        [self.tableView setShowsInfiniteScrolling:NO];
    }
    
    [self.tableView reloadData];
}

#pragma mark - Table logic
- (NSInteger)numberOfSectionsInTableView:(UITableView *)__unused tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)__unused tableView numberOfRowsInSection:(NSInteger)__unused section
{
    if (self.upvoteType == kUpvoteTypePost) {
        return _postModels.count;
    }else{
        return _messageModels.count;
    }
}

- (CGFloat)tableView:(UITableView *)__unused tableView heightForRowAtIndexPath:(NSIndexPath *)__unused indexPath
{
    if (self.upvoteType == kUpvoteTypePost) {
        TGNodeModel *model = _postModels[indexPath.row];
        return [TGNodeStreamCell tableView:tableView rowHeightForObject:model];
    }else{
        return 76;
    }
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
    if (self.upvoteType == kUpvoteTypePost) {
        static NSString *TGGroupInfoJoinRequestCellIdentifier = @"TGNodeStreamCellIdentifier";
        TGNodeStreamCell *cell = [tableView dequeueReusableCellWithIdentifier:TGGroupInfoJoinRequestCellIdentifier];
        if (cell == nil)
        {
            cell = [[TGNodeStreamCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:TGGroupInfoJoinRequestCellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            __weak typeof(self) weakSelf = self;
            cell.userBlock = ^(EnterType enterType,NSString *enterId,NSString *groupName,NSString *groupAvatarKey){
                if (enterType == EnterTypeUserInfo) {
                    self.searchUserName = enterId;
                    [self searchForeignWithUserName:enterId];
                }else if (enterType == EnterTypeGroupInfo){
                    if ((T8CONTEXT.username == nil) || [T8CONTEXT.username isEqualToString:@""])
                    {
                        TGUsernameController *usernameController = [[TGUsernameController alloc] init];
                        
                        TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[usernameController]];
                        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
                            navigationController.restrictLandscape = false;
                        else
                        {
                            navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
                            navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
                        }
                        
                        [self presentViewController:navigationController animated:true completion:nil];
                    }else{
                        TGReplyGroupViewController *replyGroupController = [[TGReplyGroupViewController alloc] initWithConversationId:-enterId.longLongValue groupName:groupName groupAvatarKey:groupAvatarKey groupDescription:nil];
                        
                        TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[replyGroupController]];
                        
                        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
                        {
                            navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
                            navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
                        }
                        
                        [self presentViewController:navigationController animated:true completion:nil];
                    }
                }
            };
            cell.recommandBlock = ^(TGNodeModel *nodeObject){
                __strong typeof(self) strongSelf = weakSelf;
                
                StreamType streamType = [strongSelf isMemberOfClass:[TGNodeStreamController class]]?StreamTypePublic:StreamTypeGroup;
                
                TGNodeDetailViewController *nodeDetail = [[TGNodeDetailViewController alloc] initWithNodeID:nodeObject.nodeId groupId:0 streamType:streamType];
                
                [strongSelf.navigationController pushViewController:nodeDetail animated:YES];
            };
            cell.forwardBlock = ^(NSString *userId){
                __strong typeof(self) strongSelf = weakSelf;
                TGTelegraphUserInfoController *userInfoController = [[TGTelegraphUserInfoController alloc] initWithUid:[userId intValue]];
                [strongSelf.navigationController pushViewController:userInfoController animated:true];
            };
            
            cell.delegate = self;
        }
        
        cell.indexPath = indexPath;
        cell.object = [_postModels objectAtIndex:indexPath.row];
        
        return cell;
    }else{
        TGConversation *conversation = [_messageModels objectAtIndex:indexPath.row];
        
        static NSString *MessageCellIdentifier = @"MessageCellIdentifier";
        TGUpvoteMessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MessageCellIdentifier];
        
        if (cell == nil)
        {
            cell = [[TGUpvoteMessageTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MessageCellIdentifier assetsSource:[TGInterfaceAssets instance]];
        }
        
        [self prepareCell:cell forConversation:conversation animated:false];
        
        return cell;
    }
}

- (void)tableView:(UITableView *) __unused tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.upvoteType == kUpvoteTypePost) {
        TGNodeModel *nodeObject = _postModels[indexPath.row];
        StreamType streamType = [self isMemberOfClass:[TGNodeStreamController class]]?StreamTypePublic:StreamTypeGroup;
        
        TGNodeDetailViewController *nodeDetail = [[TGNodeDetailViewController alloc] initWithNodeID:nodeObject.nodeId groupId:0 streamType:streamType];
        
        [self.navigationController pushViewController:nodeDetail animated:YES];
    }else{
        TGConversation *conversation = [_messageModels objectAtIndex:indexPath.row];
        
        if ([conversation.additionalProperties objectForKey:@"searchMessageId"] != nil)
        {
            [self didSelectedConversation:conversation atMessageId:[[conversation.additionalProperties objectForKey:@"searchMessageId"] intValue]];
        }else{
            [self didSelectedConversation:conversation];
        }
    }
}


@end
