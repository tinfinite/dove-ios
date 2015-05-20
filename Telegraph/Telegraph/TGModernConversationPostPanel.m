//
//  TGModernConversationPostPanel.m
//  Telegraph
//
//  Created by yewei on 15/5/11.
//
//

#import "TGModernConversationPostPanel.h"

#import "TGImageUtils.h"
#import "TGModernButton.h"

#import "TGViewController.h"

@interface TGModernConversationPostPanel ()
{
    UIButton *_deleteButton;
    UIButton *_forwardButton;
    UIButton *_postButton;
    
    CALayer *_stripeLayer;
}

@end

@implementation TGModernConversationPostPanel

- (CGFloat)baseHeight
{
    static CGFloat value = 0.0f;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      value = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 45.0f : 56.0f;
                  });
    
    return value;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, [self baseHeight])];
    if (self)
    {
        self.backgroundColor = UIColorRGB(0x22C064);
        
        _postButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, frame.size.width, [self baseHeight])];
        _postButton.adjustsImageWhenDisabled = false;
        _postButton.adjustsImageWhenHighlighted = false;
        [_postButton setTitle:TGLocalized(@"Conversation.PostToBoard") forState:UIControlStateNormal];
        [_postButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_postButton addTarget:self action:@selector(postButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_postButton];
    }
    return self;
}

- (void)adjustForOrientation:(UIInterfaceOrientation)orientation keyboardHeight:(float)keyboardHeight duration:(NSTimeInterval)duration animationCurve:(int)animationCurve
{
    [self _adjustForOrientation:orientation keyboardHeight:keyboardHeight duration:duration animationCurve:animationCurve];
}

- (void)_adjustForOrientation:(UIInterfaceOrientation)orientation keyboardHeight:(float)keyboardHeight duration:(NSTimeInterval)duration animationCurve:(int)animationCurve
{
    dispatch_block_t block = ^
    {
        id<TGModernConversationInputPanelDelegate> delegate = self.delegate;
        CGSize messageAreaSize = [delegate messageAreaSizeForInterfaceOrientation:orientation];
        
        self.frame = CGRectMake(0, messageAreaSize.height - keyboardHeight - [self baseHeight], messageAreaSize.width, [self baseHeight]);
        [self layoutSubviews];
    };
    
    if (duration > DBL_EPSILON)
        [UIView animateWithDuration:duration delay:0 options:animationCurve << 16 animations:block completion:nil];
    else
        block();
}

- (void)changeOrientationToOrientation:(UIInterfaceOrientation)orientation keyboardHeight:(float)keyboardHeight duration:(NSTimeInterval)duration
{
    [self _adjustForOrientation:orientation keyboardHeight:keyboardHeight duration:duration animationCurve:0];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _postButton.frame = CGRectMake(0.0f, 0.0f, self.frame.size.width, [self baseHeight]);
}

#pragma mark -

- (void)postButtonPressed
{
    id<TGModernConversationPostPanelDelegate> delegate = (id<TGModernConversationPostPanelDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(postPanelRequestedPostMessages:)])
        [delegate postPanelRequestedPostMessages:self];
}


@end
