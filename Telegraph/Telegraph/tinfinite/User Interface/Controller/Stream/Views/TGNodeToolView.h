//
//  TGNodeToolView.h
//  Telegraph
//
//  Created by yewei on 15/3/29.
//
//

#import <UIKit/UIKit.h>
#import "TGPraiseButton.h"
#import "TGStepButton.h"
#import "TGNodeModel.h"

@interface TGNodeToolView : UIView

@property (nonatomic,strong) UIButton *recommendBtn;
@property (nonatomic,strong) UILabel *recommendLabel;
@property (nonatomic,strong) TGPraiseButton *praiseBtn;
@property (nonatomic,strong) TGStepButton *stepBtn;
@property (nonatomic,strong) UILabel *praiseLabel;
@property (nonatomic,strong) UIButton *shareBtn;
@property (nonatomic,strong) TGNodeModel *node;

- (void)setObject:(TGNodeModel *)object;

@end
