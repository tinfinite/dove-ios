//
//  TGJoinRequestTableViewCell.h
//  Telegraph
//
//  Created by yewei on 15/2/16.
//
//

#import <UIKit/UIKit.h>
#import "T8BaseTableViewCell.h"

@protocol TGJoinRequestTableViewCellDelegate;

@interface TGJoinRequestTableViewCell : T8BaseTableViewCell

@property (nonatomic, weak) id<TGJoinRequestTableViewCellDelegate> delegate;

@end

@protocol TGJoinRequestTableViewCellDelegate <NSObject>

- (void)didPressApproveButton:(NSIndexPath *)indexPath;

@end