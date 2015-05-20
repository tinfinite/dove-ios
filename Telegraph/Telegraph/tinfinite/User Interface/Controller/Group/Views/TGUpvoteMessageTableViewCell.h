//
//  TGUpvoteMessageTableViewCell.h
//  Telegraph
//
//  Created by yewei on 15/3/18.
//
//

#import <UIKit/UIKit.h>

#import "TGDialogListCellAssetsSource.h"
#import "TGMessage.h"

@interface TGUpvoteMessageTableViewCell : UITableViewCell

@property (nonatomic, strong) id<TGDialogListCellAssetsSource> assetsSource;

@property (nonatomic) NSInteger reuseTag;
@property (nonatomic) int64_t conversationId;

@property (nonatomic, strong) NSString *pointText;
@property (nonatomic, strong) NSString *messageText;
@property (nonatomic, strong) NSArray *messageAttachments;
@property (nonatomic, strong) NSDictionary *users;

@property (nonatomic, strong) UIColor *titleColor;

@property (nonatomic) NSTimeInterval date;

@property (nonatomic, strong) NSString *avatarUrl;

@property (nonatomic) bool isGroupChat;

@property (nonatomic, strong) NSString *authorName;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier assetsSource:(id<TGDialogListCellAssetsSource>)assetsSource;

- (void)collectCachedPhotos:(NSMutableDictionary *)dict;

- (void)resetView:(bool)keepState;

- (void)resetLocalization;

@end
