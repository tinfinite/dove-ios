//
//  TGNodeDataManager.m
//  Telegraph
//
//  Created by 琦张 on 15/3/30.
//
//

#import "TGNodeDataManager.h"
#import "TGDatabase.h"

@interface TGNodeDataManager ()

@property (nonatomic,strong) NSMutableDictionary *publicCacheDict;
@property (nonatomic,strong) NSMutableDictionary *groupCacheDict;

@end

@implementation TGNodeDataManager

- (id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePostDeleteNotification:) name:Notification_Key_Post_Delete object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUserBlockNotification:) name:Notification_Key_User_Blocked object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNewPostNotification:) name:Notification_Key_New_Post object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:Notification_Key_Post_Delete object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:Notification_Key_User_Blocked object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:Notification_Key_New_Post object:nil];
}

DEF_SINGLETON(TGNodeDataManager)

#pragma mark - getter
- (NSMutableDictionary *)publicCacheDict
{
    if (!_publicCacheDict) {
        _publicCacheDict = [NSMutableDictionary dictionary];
    }
    return _publicCacheDict;
}

- (NSMutableDictionary *)groupCacheDict
{
    if (!_groupCacheDict) {
        _groupCacheDict = [NSMutableDictionary dictionary];
    }
    return _groupCacheDict;
}

#pragma mark - method
- (void)handleNewPostNotification:(NSNotification *)notification
{
    NSMutableDictionary *nodeInfo = notification.object;
    PostPublishType ispublic = [[nodeInfo objectForKey:@"ispublic"] integerValue];
    int64_t groupid = [[nodeInfo objectForKey:@"groupid"] int64Value];
    NSString *postid = [nodeInfo objectForKey:@"postid"];
    if (ispublic == PostPublishTypePublishStream || ispublic == PostPublishTypeBoth) {
        [self insertIDToStream:StreamTypePublic conversationId:groupid nodeID:postid];
    }
    if (ispublic == PostPublishTypeGroupBoard || ispublic == PostPublishTypeBoth) {
        [self insertIDToStream:StreamTypeGroup conversationId:groupid nodeID:postid];
    }
}

- (void)handleUserBlockNotification:(NSNotification *)notification
{
    NSMutableDictionary *dict = (NSMutableDictionary *)notification.object;
    NSString *t8id = [dict objectForKey:@"t8id"];
    NSString *tgid = [dict objectForKey:@"tgid"];
    [self.publicCacheDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL __unused *stop) {
        TGNodeModel *node = (TGNodeModel *)obj;
        if ([node.author.authorId isEqualToString:t8id] || [node.author.tgUserId isEqualToString:tgid]) {
            [self.publicCacheDict removeObjectForKey:key];
        }
    }];
    [self.groupCacheDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL __unused *stop) {
        TGNodeModel *node = (TGNodeModel *)obj;
        if ([node.author.authorId isEqualToString:t8id] || [node.author.tgUserId isEqualToString:tgid]) {
            [self.groupCacheDict removeObjectForKey:key];
        }
    }];
    
    [TGDatabaseInstance() blockUserWithT8id:t8id tgid:tgid.intValue];
}

- (void)handlePostDeleteNotification:(NSNotification *)notification
{
    NSString *postID = notification.object;
    [self.publicCacheDict removeObjectForKey:postID];
    [self.groupCacheDict removeObjectForKey:postID];
    [TGDatabaseInstance() deleteNodeWithID:postID];
}

- (void)storeStreamWithType:(StreamType)streamType conversationId:(int64_t)conversationId nodeIDs:(NSArray *)nodeIDs
{
    [TGDatabaseInstance() storeStreamWithConversationId:conversationId andStreamType:streamType nodeIDs:nodeIDs];
}

- (void)insertIDToStream:(StreamType)streamType conversationId:(int64_t)conversationId nodeID:(NSString *)nodeID
{
    [TGDatabaseInstance() insertIDToStream:conversationId andStreamType:streamType nodeID:nodeID];
}

- (NSArray *)loadStreamNodeIDs:(StreamType)streamType conversationId:(int64_t)conversationId
{
    return [TGDatabaseInstance() loadNodeIDsWithConversationId:conversationId andStreamType:streamType];
}

- (void)storeNodes:(NSArray *)nodeArray streamType:(StreamType)streamType
{
    NSMutableArray *nodeModelArray = [NSMutableArray array];
    [nodeArray enumerateObjectsUsingBlock:^(id obj, NSUInteger __unused idx, BOOL __unused *stop) {
        NSDictionary *nodeDict = (NSDictionary *)obj;
        TGNodeModel *nodeModel = [[TGNodeModel alloc] initWithDict:nodeDict];
        [nodeModelArray addObject:nodeModel];
    }];
    [TGDatabaseInstance() storeNodeList:nodeModelArray streamType:streamType];
    
    NSMutableArray *nodeToFilter = [nodeModelArray mutableCopy];
    [TGDatabaseInstance() filterBlockedNodes:nodeToFilter];
    [nodeToFilter enumerateObjectsUsingBlock:^(id obj, NSUInteger __unused idx, BOOL __unused *stop) {
        TGNodeModel *node = (TGNodeModel *)obj;
        [self cacheNode:node streamType:streamType];
    }];
}

- (NSArray *)loadNodes:(NSArray *)nodeIdArray streamType:(StreamType)streamType
{
    if (nodeIdArray && nodeIdArray.count > 0) {
        NSMutableArray *noCacheNodeIds = [NSMutableArray array];
        NSMutableDictionary *cacheDict = streamType==StreamTypePublic?self.publicCacheDict:self.groupCacheDict;
        [nodeIdArray enumerateObjectsUsingBlock:^(id obj, NSUInteger __unused idx, BOOL __unused *stop) {
            NSString *nodeid = (NSString *)obj;
            if (![cacheDict.allKeys containsObject:nodeid]) {
                [noCacheNodeIds addObject:nodeid];
            }
        }];
        if (noCacheNodeIds.count > 0) {
            NSArray *nodesFromDB = [TGDatabaseInstance() loadNodesWithIDs:noCacheNodeIds streamType:streamType];
            [nodesFromDB enumerateObjectsUsingBlock:^(id obj, NSUInteger __unused idx, BOOL __unused *stop) {
                TGNodeModel *node = (TGNodeModel *)obj;
                [self cacheNode:node streamType:streamType];
            }];
        }
        return [self loadCachedNodes:nodeIdArray streamType:streamType];
    }
    return nil;
}

- (NSArray *)loadCachedNodes:(NSArray *)nodeIdArray streamType:(StreamType)streamType
{
    NSMutableArray *nodeArray = [NSMutableArray array];
    [nodeIdArray enumerateObjectsUsingBlock:^(id obj, NSUInteger __unused idx, BOOL __unused *stop) {
        NSString *nodeid = (NSString *)obj;
        TGNodeModel *node = [self getNodeFromCache:nodeid streamType:streamType];
        if (node) {
            [nodeArray addObject:node];
        }
    }];
    return [NSArray arrayWithArray:nodeArray];
}

- (TGNodeModel *)loadNodeWithId:(NSString *)nodeid streamType:(StreamType)streamType
{
    TGNodeModel *node = [self getNodeFromCache:nodeid streamType:streamType];
    if (node) {
        return node;
    }
    
    node = [TGDatabaseInstance() loadNodeWithID:nodeid streamType:streamType];
    if (node) {
        [self cacheNode:node streamType:streamType];
        return node;
    }
    
    return nil;
}

- (void)cacheNode:(TGNodeModel *)node streamType:(StreamType)streamType
{
    NSMutableDictionary *cacheDict = streamType==StreamTypePublic?self.publicCacheDict:self.groupCacheDict;
    
    if ([cacheDict.allKeys containsObject:node.nodeId]) {
        TGNodeModel *cachedNode = [cacheDict objectForKey:node.nodeId];
        cachedNode.synchronize = NO;
        cachedNode.totalScore = node.totalScore;
        cachedNode.totalReply = node.totalReply;
        cachedNode.isUpvote = node.isUpvote;
        cachedNode.isDownvote = node.isDownvote;
        cachedNode.synchronize = YES;
        cachedNode.author = node.author;
        cachedNode.forward = node.forward;
    }else{
        [cacheDict setObject:node forKey:node.nodeId];
    }
}

- (TGNodeModel *)getNodeFromCache:(NSString *)nodeid streamType:(StreamType)streamType
{
    NSMutableDictionary *cacheDict = streamType==StreamTypePublic?self.publicCacheDict:self.groupCacheDict;
    
    return [cacheDict objectForKey:nodeid];
}

//- (NSArray *)loadCachedMyPostsWithLimit:(NSInteger)limit
//{
//    
//}

@end
