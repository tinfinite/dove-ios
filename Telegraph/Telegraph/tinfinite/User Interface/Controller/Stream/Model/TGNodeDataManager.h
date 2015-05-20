//
//  TGNodeDataManager.h
//  Telegraph
//
//  Created by 琦张 on 15/3/30.
//
//

#import <Foundation/Foundation.h>
#import "TGNodeModel.h"

@interface TGNodeDataManager : NSObject

AS_SINGLETON(TGNodeDataManager)

- (void)storeNodes:(NSArray *)nodeArray streamType:(StreamType)streamType;

- (NSArray *)loadNodes:(NSArray *)nodeIdArray streamType:(StreamType)streamType;

- (TGNodeModel *)loadNodeWithId:(NSString *)nodeid streamType:(StreamType)streamType;

- (void)storeStreamWithType:(StreamType)streamType conversationId:(int64_t)conversationId nodeIDs:(NSArray *)nodeIDs;

- (NSArray *)loadStreamNodeIDs:(StreamType)streamType conversationId:(int64_t)conversationId;

//- (NSArray *)loadCachedMyPostsWithLimit:(NSInteger)limit;

@end
