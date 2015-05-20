//
//  TGNodeDetailCommentCell.h
//  Telegraph
//
//  Created by 琦张 on 15/3/31.
//
//

#import "T8BaseTableViewCell.h"
#import "TGNodeCommentHeadView.h"

@interface TGNodeDetailCommentCell : T8BaseTableViewCell

@property (nonatomic,strong) TGNodeCommentHeadView *headView;
@property (nonatomic,strong) UILabel *contentLabel;

@end
