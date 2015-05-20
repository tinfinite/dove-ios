//
//  T8BaseTableViewCell.m
//  tinfinite
//
//  Created by yewei on 14/12/25.
//  Copyright (c) 2014年 Tinfinite. All rights reserved.
//

#import "T8BaseTableViewCell.h"

static UILabel *label;

@implementation T8BaseTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {

    }
    
    return self;
}

- (void)setObject:(id)object {
    _object = object;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (CGFloat)tableView:(UITableView *) __unused tableView rowHeightForObject:(id) __unused object {
    return 44;
}

@end
