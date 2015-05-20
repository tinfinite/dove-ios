//
//  TGNodeForwardMsgView.h
//  Telegraph
//
//  Created by 琦张 on 15/4/2.
//
//

#import <UIKit/UIKit.h>
#import "TGNodeForwardMessageModel.h"
#import "TGNodeImageView.h"
#import "TTTAttributedLabel.h"

const CGFloat defaultHeight = 50.0f;

typedef void(^EnterUserBlock)(NSString *username);

@interface TGNodeForwardMsgView : UIView

@property (nonatomic,strong) TGNodeForwardMessageModel *msgModel;
@property (nonatomic,strong) UIButton *nameButton;
@property (nonatomic,strong) EnterUserBlock enterUser;

- (instancetype)initWithMessage:(TGNodeForwardMessageModel *)msgModel;

@end


@interface TGNodeForwardTextMsgView : TGNodeForwardMsgView<TTTAttributedLabelDelegate>

@property (nonatomic,strong) TTTAttributedLabel *contentLabel;

@end


@interface TGNodeForwardPhotoMsgView : TGNodeForwardMsgView

@property (nonatomic,strong) TGNodeImageView *imageView;

@end
