//
//  TGVoteForMeCell.m
//  Telegraph
//
//  Created by 琦张 on 15/4/28.
//
//

#import "TGVoteForMeCell.h"
#import "TGNotificationMsgModel.h"

@implementation TGVoteForMeCell

- (void)setObject:(id)object
{
    _object = object;
    if ([object isKindOfClass:[TGNotificationMsgModel class]]) {
        TGNotificationMsgModel *model = (TGNotificationMsgModel *)object;
        [self.avatarView loadImage:model.userAvatar filter:@"circle:64x64" placeholder:[UIImage imageNamed:@"default_profile_img_s"]];
        self.nameLabel.text = model.name;
        
        self.commentLabel.textColor = UIColorRGB(0xa0a0a4);
        if ([model.voteAction isEqualToString:@"up"]) {
            self.commentLabel.text = TGLocalized(@"Settings.UpvotedMe");
        }else if ([model.voteAction isEqualToString:@"down"]){
            self.commentLabel.text = TGLocalized(@"Settings.DownvotedMe");
        }
        
        self.timeLabel.text = [[NSDate getDateFromT8TimeStamp:model.msgCreateTime] timeIntervalDescription];
        
        self.contentLabel.text = model.postText;
    }
}

+ (CGFloat)tableView:(UITableView *) __unused tableView rowHeightForObject:(id) __unused object
{
    return 115.0f;
}

@end
