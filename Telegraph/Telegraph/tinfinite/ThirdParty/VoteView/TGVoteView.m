//
//  TGVoteView.m
//  Telegraph
//
//  Created by yewei on 15/3/23.
//
//

#import "TGVoteView.h"

CGRect TGScreenBounds()
{
    CGRect bounds = [UIScreen mainScreen].bounds;
    UIInterfaceOrientation orient = [UIApplication sharedApplication].statusBarOrientation;
    if (UIDeviceOrientationUnknown == orient)
        orient = UIInterfaceOrientationPortrait;
    
    if (UIInterfaceOrientationIsLandscape(orient))
    {
        CGFloat width = bounds.size.width;
        bounds.size.width = bounds.size.height;
        bounds.size.height = width;
    }
    return bounds;
}

@implementation TGVoteView
{
    UIButton *_coverView;
    UIView *_voteViewBg;
    UILabel *_titleLabel;
    UIButton *_upvoteButton;
    UIButton *_downvoteButton;
}

- (id)initWithUpvoteStatus:(BOOL)upvote downvoteStatus:(BOOL)downvote upvoteBlock:(TGUpvoteBlock)upvoteBlock downvoteBlock:(TGDownvoteBlock)downvoteBlock
{
    self = [super init];
    if (self) {
        CGRect screenBounds = TGScreenBounds();
        self.frame = screenBounds;
        
        NSString *upvoteImage = @"";
        NSString *upvoteInfoKey = @"";
        NSString *downvoteImage = @"";
        NSString *downvoteInfoKey = @"";
        if (upvote) {
            upvoteImage = @"upvoted";
            upvoteInfoKey = @"Vote.upvotedAction";
        }else{
            upvoteImage = @"upvote";
            upvoteInfoKey = @"Vote.upvoteAction";
        }
        if (downvote) {
            downvoteImage = @"downvoted";
            downvoteInfoKey = @"Vote.downvotedAction";
        }else{
            downvoteImage = @"downvote";
            downvoteInfoKey = @"Vote.downvoteAction";
        }
        
        self.upvoteBlock = upvoteBlock;
        self.downvoteBlock = downvoteBlock;
        
        if(!_coverView)
        {
            _coverView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, screenBounds.size.width, screenBounds.size.height)];
            _coverView.backgroundColor = [UIColor blackColor];
            _coverView.opaque = YES;
            _coverView.alpha = 0.5f;
            _coverView.userInteractionEnabled = YES;
            [_coverView addTarget:self action:@selector(coverViewPressed) forControlEvents:UIControlEventTouchUpInside];
        }
        [self addSubview:_coverView];
        
        if (!_voteViewBg) {
            _voteViewBg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 160)];
            _voteViewBg.center = self.center;
            _voteViewBg.backgroundColor = UIColorRGB(0Xf7f7f7);
            _voteViewBg.layer.masksToBounds = YES;
            _voteViewBg.layer.cornerRadius = 5.0f;
            _voteViewBg.layer.borderColor = UIColorRGB(0x979797).CGColor;
            _voteViewBg.layer.borderWidth = 0.5;
        }
        [self addSubview:_voteViewBg];
        
        if (!_titleLabel) {
            _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, 15, 130, 20)];
            _titleLabel.text = TGLocalized(@"Vote.voteActionInfo");
            _titleLabel.textColor = UIColorRGB(0x889199);
            _titleLabel.font = [UIFont systemFontOfSize:16.0f];
            _titleLabel.textAlignment = NSTextAlignmentCenter;
            [_voteViewBg addSubview:_titleLabel];
        }
        
        if (!_upvoteButton) {
            _upvoteButton = [[UIButton alloc] init];
            _upvoteButton.backgroundColor = [UIColor whiteColor];
            _upvoteButton.frame = CGRectMake(28, 50, 90, 90);
            _upvoteButton.layer.masksToBounds = YES;
            _upvoteButton.layer.cornerRadius = 5.0f;
            _upvoteButton.layer.borderColor = UIColorRGB(0xD0DDE9).CGColor;
            _upvoteButton.layer.borderWidth = 0.5;
            _upvoteButton.titleLabel.font = [UIFont systemFontOfSize:14];
            _upvoteButton.titleEdgeInsets = UIEdgeInsetsMake(50, 0, 0, 0);
            [_upvoteButton setBackgroundImage:[UIImage imageNamed:upvoteImage] forState:UIControlStateNormal];
            [_upvoteButton setTitle:TGLocalized(upvoteInfoKey) forState:UIControlStateNormal];
            [_upvoteButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            [_upvoteButton addTarget:self action:@selector(upvoteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
            [_voteViewBg addSubview:_upvoteButton];
        }
        
        if (!_downvoteButton) {
            _downvoteButton = [[UIButton alloc] init];
            _downvoteButton.backgroundColor = [UIColor whiteColor];
            _downvoteButton.frame = CGRectMake(152, 50, 90, 90);
            _downvoteButton.layer.masksToBounds = YES;
            _downvoteButton.layer.cornerRadius = 5.0f;
            _downvoteButton.layer.borderColor = UIColorRGB(0xD0DDE9).CGColor;
            _downvoteButton.layer.borderWidth = 0.5;
            _downvoteButton.titleLabel.font = [UIFont systemFontOfSize:14];
            _downvoteButton.titleEdgeInsets = UIEdgeInsetsMake(50, 0, 0, 0);
            [_downvoteButton setBackgroundImage:[UIImage imageNamed:downvoteImage] forState:UIControlStateNormal];
            [_downvoteButton setTitle:TGLocalized(downvoteInfoKey) forState:UIControlStateNormal];
            [_downvoteButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            [_downvoteButton addTarget:self action:@selector(downvoteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
            [_voteViewBg addSubview:_downvoteButton];
        }
    }
    return self;
}

- (void)coverViewPressed
{
    [self dismiss];
}

- (void)upvoteButtonPressed
{
    if (self.upvoteBlock) {
        self.upvoteBlock();
    }
    [self dismiss];
    
    NSMutableDictionary *event =
    [[GAIDictionaryBuilder createEventWithCategory:@"聊天页面"
                                            action:@"赞"
                                             label:@""
                                             value:nil] build];
    [[GAI sharedInstance].defaultTracker send:event];
    [[GAI sharedInstance] dispatch];
}

- (void)downvoteButtonPressed
{
    if (self.downvoteBlock) {
        self.downvoteBlock();
    }
    [self dismiss];
    
    NSMutableDictionary *event =
    [[GAIDictionaryBuilder createEventWithCategory:@"聊天页面"
                                            action:@"踩"
                                             label:@""
                                             value:nil] build];
    [[GAI sharedInstance].defaultTracker send:event];
    [[GAI sharedInstance] dispatch];
}

-(void)show
{
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if(!keyWindow)
    {
        NSArray *windows = [UIApplication sharedApplication].windows;
        if(windows.count > 0) keyWindow = [windows lastObject];
        keyWindow = [windows objectAtIndex:0];
    }
    UIView *containerView = [[keyWindow subviews] objectAtIndex:0];
    
    _coverView.alpha = 0.0f;
    CGRect frame = _voteViewBg.frame;
    frame.origin.y = -200;
    _voteViewBg.frame = frame;
    [containerView addSubview:self];
    
    [UIView animateWithDuration:0.2f animations:^{
        _coverView.alpha = 0.5f;
        _voteViewBg.center = CGPointMake(TGScreenBounds().size.width / 2, TGScreenBounds().size.height / 2);
    }completion:^(BOOL __unused finished) {
        
    }];
}

-(void)dismiss
{
    
    [UIView animateWithDuration:0.2f animations:^{
        _coverView.alpha = 0.0f;
        CGRect frame = _voteViewBg.frame;
        frame.origin.y = -200;
        _voteViewBg.frame = frame;
    }completion:^(BOOL __unused finished){
        [self removeFromSuperview];
        
    }];
}

@end
