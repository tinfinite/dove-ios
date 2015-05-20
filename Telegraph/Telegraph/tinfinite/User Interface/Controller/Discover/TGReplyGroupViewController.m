//
//  TGReplyGroupViewController.m
//  Telegraph
//
//  Created by yewei on 15/3/10.
//
//

#import "TGReplyGroupViewController.h"
#import "TGConversation.h"
#import "TGDatabase.h"
#import "TGGroupInfoCollectionItem.h"
#import "TGTextViewCollectionItem.h"
#import "TGButtonCollectionItem.h"
#import "T8GroupHttpRequestService.h"
#import "TGCache.h"
#import "TGRemoteImageView.h"
#import "T8ImageUploadManager.h"
#import "TGUsernameController.h"
#import "TGNavigationController.h"
#import "TGActionSheet.h"
#import "TGInterfaceManager.h"
#import "T8GroupAndCommunityService.h"
#import "T8ReportHttpRequestService.h"
#import "TGObserverProxy.h"

@interface TGReplyGroupViewController ()
{
    int64_t _conversationId;
    TGConversation *_conversation;
    
    TGGroupInfoCollectionItem *_groupInfoItem;
    TGButtonCollectionItem *_joinGroupItem;
    TGCollectionMenuSection *_describeSection;
    TGTextViewCollectionItem *_describeItem;
    
    TGObserverProxy *_keyboardWillChangeFrameProxy;
}

@end

@implementation TGReplyGroupViewController

- (instancetype)initWithConversationId:(int64_t)conversationId groupName:(NSString *)groupName groupAvatar:(UIImage *)groupAvatar groupDescription:(NSString *)groupDescription
{
    self = [super init];
    if (self) {
        _keyboardWillChangeFrameProxy = [[TGObserverProxy alloc] initWithTarget:self targetSelector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification];
        
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
        
        _conversationId = conversationId;
        
        [self setTitleText:TGLocalized(@"GroupInfo.JoinRequestTitle")];
        
        [self setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Cancel") style:UIBarButtonItemStyleDone target:self action:@selector(cancelPressed)]];
        [self setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"GroupInfo.Report") style:UIBarButtonItemStyleDone target:self action:@selector(reportPressed)]];
        
        _groupInfoItem = [[TGGroupInfoCollectionItem alloc] init];
        [_groupInfoItem setUpdatingTitle:groupName];
        [_groupInfoItem setDescription:groupDescription];
        
        [_groupInfoItem setUpdatingAvatar:groupAvatar hasUpdatingAvatar:NO];
        [self.menuSections addSection:[[TGCollectionMenuSection alloc] initWithItems:@[          _groupInfoItem]]];
        
        _conversation = [TGDatabaseInstance() loadConversationWithId:_conversationId];
        
        if ([TGDatabaseInstance() containsConversationWithId:conversationId] && _conversation &&_conversation.leftChat == NO && _conversation.kickedFromChat == NO) {
            _joinGroupItem = [[TGButtonCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.EnterGroupChat") action:@selector(enterGroupChatPressed)];
        }else{
            _describeItem = [[TGTextViewCollectionItem alloc] initWithNumberOfLines:4];
            [_describeItem setPlaceHolder:TGLocalized(@"GroupInfo.SelfDescription")];
            _describeSection = [[TGCollectionMenuSection alloc] initWithItems:@[_describeItem]];
            
            UIEdgeInsets describeInsets = _describeSection.insets;
            describeInsets.top = -18;
            _describeSection.insets = describeInsets;
            [self.menuSections addSection:_describeSection];
            
            _joinGroupItem = [[TGButtonCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.Join") action:@selector(joinGroupPressed)];
        }
        
        _joinGroupItem.alignment = NSTextAlignmentCenter;
        _joinGroupItem.titleColor = UIColorRGBA(0x008DF2, 1.0f);
        _joinGroupItem.deselectAutomatically = true;
        
        [self.menuSections addSection:[[TGCollectionMenuSection alloc] initWithItems:@[          _joinGroupItem]]];
    }
    return self;
}

- (instancetype)initWithConversationId:(int64_t)conversationId groupName:(NSString *)groupName groupAvatarKey:(NSString *)groupAvatarKey groupDescription:(NSString *)groupDescription
{
    self = [self initWithConversationId:conversationId groupName:groupName groupAvatar:nil groupDescription:groupDescription];
    if (self) {
        TGConversation *conversation = [[TGConversation alloc] init];
        conversation.chatPhotoSmall = groupAvatarKey;
        [_groupInfoItem setConversation:conversation];
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)cancelPressed
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)enterGroupChatPressed
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [[TGInterfaceManager instance] navigateToConversationWithId:_conversationId conversation:nil];
    }];
}

- (void)joinGroupPressed
{
    if((T8CONTEXT.username == nil) || [T8CONTEXT.username isEqualToString:@""]){
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
        if (_describeItem.text.length < 10) {
            [T8HudHelper showHUDMessage:TGLocalized(@"GroupInfo.JoinDescription")];
            return;
        }
        
        [T8HudHelper showHUDActivity:TGLocalized(@"Discover.Waiting") parentView:self.view];
        
        __weak typeof(self) weakSelf = self;
        [T8GroupHttpRequestService applyJoinInGroupWithGroupId:@(_conversationId).stringValue tgUserId:T8CONTEXT.tgUserId username:T8CONTEXT.username avatar:nil message:_describeItem.text accessToken:T8CONTEXT.accessToken successBlock:^(NSDictionary __unused *dictRet) {
            [T8HudHelper hideHUDActivity:self.view];
            [T8HudHelper showHUDMessage:TGLocalized(@"GroupInfo.ApplySuccess")];
            [weakSelf cancelPressed];
        } failureBlock:^(NSDictionary __unused *dictRet, NSError __unused *error) {
            [T8HudHelper hideHUDActivity:self.view];
            [T8HudHelper showHUDMessage:TGLocalized(@"GroupInfo.ApplyFailuer")];
        }];

//        [[T8ImageUploadManager sharedInstance] uploadImage:avatarImage tmpName:@(T8CONTEXT.tgUserId).stringValue successBlock:^(NSString *url) {
//            
//        }failureBlock:^{
//            [T8HudHelper hideHUDActivity:self.view];
//            [T8HudHelper showHUDMessage:TGLocalized(@"GroupInfo.ApplyFailuer")];
//        }];
    }
}

- (void)reportPressed
{
    NSMutableArray *actions = [[NSMutableArray alloc] init];
    
    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Report.Title1") action:@"Report1"]];
    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Report.Title2") action:@"Report2"]];
    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Report.Title3") action:@"Report3"]];
    
    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Common.Cancel") action:@"cancel" type:TGActionSheetActionTypeCancel]];
    
    TGActionSheet *actionSheet = [[TGActionSheet alloc] initWithTitle:nil actions:actions actionBlock:^(TGReplyGroupViewController *controller, NSString *action)
                                  {
                                      if ([action isEqualToString:@"Report1"])
                                          [controller reportRequestWithReason:@"垃圾营销"];
                                      else if ([action isEqualToString:@"Report2"])
                                          [controller reportRequestWithReason:@"淫秽信息"];
                                      else if ([action isEqualToString:@"Report3"])
                                          [controller reportRequestWithReason:@"虚假信息"];
                                  } target:self];
    [actionSheet showInView:self.view];
}

- (void)reportRequestWithReason:(NSString *)reason
{
    [T8GroupAndCommunityService getGroupInfoWithID:_conversationId successBlock:^(NSDictionary *dictRet) {
        NSString *targetId = [[dictRet objectForKey:@"community"] objectForKey:@"id"];
        [T8ReportHttpRequestService reportWithTargetId:targetId reportType:ReportTypeGroup reason:reason successBlock:^(NSDictionary __unused *dictRet) {
            [T8HudHelper showHUDMessage:TGLocalized(@"Report.Success")];
        } failureBlock:^(NSDictionary __unused *dictRet, NSError __unused *error) {
            if ([dictRet[@"code"] integerValue] == 100003) {
                [T8HudHelper showHUDMessage:TGLocalized(@"Report.Reported")];
            }else{
                [T8HudHelper showHUDMessage:TGLocalized(@"Report.Failure")];
            }
        }];
    } failureBlock:^(NSDictionary __unused *dictRet, NSError __unused *error) {
        [T8HudHelper showHUDMessage:TGLocalized(@"Report.Failure")];
    }];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;

    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    void(^animations)() = ^{
        self.collectionView.contentOffset = CGPointMake(0, 0);
    };
    
    void(^completion)(BOOL) = ^(BOOL __unused finished){
    };
    
    [UIView animateWithDuration:duration delay:0.0f options:(curve << 16 | UIViewAnimationOptionBeginFromCurrentState) animations:animations completion:completion];
}

@end
