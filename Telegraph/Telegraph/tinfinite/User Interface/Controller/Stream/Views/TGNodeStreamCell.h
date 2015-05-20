//
//  TGNodeStreamCell.h
//  Telegraph
//
//  Created by yewei on 15/3/28.
//
//

#import <UIKit/UIKit.h>
#import "T8BaseTableViewCell.h"
#import "TGNodeModel.h"
#import "TGNodePhotoObject.h"

typedef NS_ENUM(NSInteger, EnterType) {
    EnterTypeUserInfo,
    EnterTypeGroupInfo
};

typedef void(^T8NodeTopicCellUserBlock)(EnterType enterType,NSString *enterId,NSString *groupName,NSString *groupAvatarKey);
typedef void(^T8NodeTopicCellRecommandBlock)(TGNodeModel *nodeObject);
typedef void(^T8NodeTopicCellCommunityBlock)(NSString *communityId,NSString *communityName);
typedef void(^T8NodeTopicCellForwardBlock)(NSString *userId);

@protocol TGNodeStreamCellImageTouchDelegate;

@interface TGNodeStreamCell : T8BaseTableViewCell

@property (nonatomic,strong) T8NodeTopicCellUserBlock userBlock;
@property (nonatomic,strong) T8NodeTopicCellRecommandBlock recommandBlock;
@property (nonatomic,strong) T8NodeTopicCellCommunityBlock communityBlock;
@property (nonatomic,strong) T8NodeTopicCellForwardBlock forwardBlock;
@property (nonatomic,assign) StreamType streamType;
@property (nonatomic,assign) id <TGNodeStreamCellImageTouchDelegate> delegate;

+ (CGFloat)tableView:(UITableView *)tableView rowHeightForObject:(id)object;

@end

@protocol TGNodeStreamCellImageTouchDelegate <NSObject>

- (void)touchImageView:(UIImageView *)imageView pictureObject:(TGNodePhotoObject *)pictureObj pictures:(NSArray *)pictures;

@end