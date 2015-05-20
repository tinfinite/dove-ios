//
//  T8StickToTopManager.m
//  Telegraph
//
//  Created by 琦张 on 15/2/8.
//
//

#import "T8StickToTopManager.h"
#import "TGTelegraph.h"

@interface T8StickToTopManager ()

@property (nonatomic,strong) NSMutableArray *stickedGroups;   //conversation IDs
@property (nonatomic,strong) NSMutableArray *stickedUsers;    //user IDs

@property (nonatomic,strong) NSMutableArray *stickedConversations;    //conversation IDs

@end

@implementation T8StickToTopManager

DEF_SINGLETON(T8StickToTopManager)

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

#pragma mark - getter
- (NSMutableArray *)stickedGroups
{
    if (!_stickedGroups) {
        _stickedGroups = [[[NSUserDefaults standardUserDefaults] objectForKey:UserDefaultKey_StickedGroups] mutableCopy];
        if (!_stickedGroups) {
            _stickedGroups = [NSMutableArray array];
        }
    }
    return _stickedGroups;
}

- (NSMutableArray *)stickedUsers
{
    if (!_stickedUsers) {
        _stickedUsers = [[[NSUserDefaults standardUserDefaults] objectForKey:UserDefaultKey_StickedUsers] mutableCopy];
        if (!_stickedUsers) {
            _stickedUsers = [NSMutableArray array];
        }
    }
    return _stickedUsers;
}

- (NSMutableArray *)stickedConversations
{
    if (!_stickedConversations) {
        _stickedConversations = [[[NSUserDefaults standardUserDefaults] objectForKey:UserDefaultKey_StickedConversations] mutableCopy];
        if (!_stickedConversations) {
            _stickedConversations = [NSMutableArray array];
        }
    }
    return _stickedConversations;
}

- (void)stickGroupWithConversationID:(int64_t)conversationId action:(BOOL)stick
{
    if (stick) {
        [self.stickedGroups addObject:[NSString stringWithFormat:@"%lld",conversationId]];
    }else{
        [self.stickedGroups removeObject:[NSString stringWithFormat:@"%lld",conversationId]];
    }
    
    if (self.stickedGroups.count > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:self.stickedGroups forKey:UserDefaultKey_StickedGroups];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }else{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:UserDefaultKey_StickedGroups];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:Notification_Key_Stick_Changed object:nil];
}

- (void)stickUserWithUserID:(NSInteger)userId action:(BOOL)stick
{
    if (stick) {
        [self.stickedUsers addObject:[NSString stringWithFormat:@"%d",userId]];
    }else{
        [self.stickedUsers removeObject:[NSString stringWithFormat:@"%d",userId]];
    }
    
    if (self.stickedUsers.count > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:self.stickedUsers forKey:UserDefaultKey_StickedUsers];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }else{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:UserDefaultKey_StickedUsers];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:Notification_Key_Stick_Changed object:nil];
}

- (BOOL)checkIsStickedWithConversationID:(int64_t)conversationId andUserID:(int64_t)userId
{
    if ([self.stickedGroups containsObject:[NSString stringWithFormat:@"%lld",conversationId]]) {
        return YES;
    }
    if ([self.stickedUsers containsObject:[NSString stringWithFormat:@"%lld",userId]]) {
        return YES;
    }
    return NO;
}

- (void)stickConversationWithID:(NSString *)conversationId action:(BOOL)stick
{
    if (!conversationId) {
        return;
    }
    
    if (stick) {
        [self.stickedConversations addObject:conversationId];
    }else{
        [self.stickedConversations removeObject:conversationId];
    }
    
    if (self.stickedConversations.count > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:self.stickedConversations forKey:UserDefaultKey_StickedConversations];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }else{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:UserDefaultKey_StickedConversations];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:Notification_Key_Stick_Changed object:nil];
}

- (BOOL)checkConversationIsStickedWithID:(NSString *)conversationId
{
    if ([self.stickedConversations containsObject:conversationId]) {
        return YES;
    }
    return NO;
}

- (NSComparisonResult)compareConversationID:(NSString *)conversationOne with:(NSString *)conversationTwo
{
    NSUInteger indexOne = [self.stickedConversations indexOfObject:conversationOne];
    NSUInteger indexTwo = [self.stickedConversations indexOfObject:conversationTwo];
    if (indexOne > indexTwo) {
        return NSOrderedAscending;
    }else if (indexOne < indexTwo){
        return NSOrderedDescending;
    }else{
        return NSOrderedSame;
    }
}

@end
