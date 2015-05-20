//
//  T8BaseTableViewCell.h
//  tinfinite
//
//  Created by yewei on 14/12/25.
//  Copyright (c) 2014年 Tinfinite. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface T8BaseTableViewCell : UITableViewCell
{
    id _object;
}

@property (nonatomic, strong) id		object;
@property (nonatomic, copy) NSIndexPath *indexPath;

+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)object;

@end
