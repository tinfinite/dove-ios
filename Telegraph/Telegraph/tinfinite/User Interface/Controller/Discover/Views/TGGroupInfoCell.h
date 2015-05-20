//
//  TGGroupInfoCell.h
//  Telegraph
//
//  Created by 琦张 on 15/2/15.
//
//

#import <UIKit/UIKit.h>
#import "TGLetteredAvatarView.h"

@interface TGGroupInfoCell : UITableViewCell

@property (nonatomic,strong) TGLetteredAvatarView *avatarView;
@property (nonatomic,strong) UILabel *nameLabel;
@property (nonatomic,strong) UILabel *descriptionLabel;
@property (nonatomic,strong) UILabel *pointsLabel;
@property (nonatomic,strong) UILabel *languageLabel;

+ (CGFloat)calculateHeightWithModel:(id)model;

- (void)bindModel:(id)model;

@end
