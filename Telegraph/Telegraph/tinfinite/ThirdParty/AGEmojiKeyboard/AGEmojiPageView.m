//
//  AGEmojiPageView.m
//  AGEmojiKeyboard
//
//  Created by Ayush on 09/05/13.
//  Copyright (c) 2013 Ayush. All rights reserved.
//

#import "AGEmojiPageView.h"
#import "AGEmojiKeyBoardView.h"

#define BUTTON_FONT_SIZE 32

@interface AGEmojiPageView ()

@property (nonatomic) CGSize buttonSize;
@property (nonatomic) NSMutableArray *buttons;
@property (nonatomic) NSUInteger columns;
@property (nonatomic) NSUInteger rows;

@property (nonatomic,strong) NSArray *emojiArray;
@property (nonatomic,assign) NSInteger index;
@property (nonatomic,strong) UILongPressGestureRecognizer *longPress;
@property (nonatomic,strong) UIImageView *zoomImageView;
@property (nonatomic,strong) UILabel *emojiLabel;

@end

@implementation AGEmojiPageView

- (id)initWithFrame:(CGRect)frame
         buttonSize:(CGSize)buttonSize
               rows:(NSUInteger)rows
            columns:(NSUInteger)columns {
    self = [super initWithFrame:frame];
    if (self) {
        _buttonSize = buttonSize;
        _columns = columns;
        _rows = rows;
        _buttons = [[NSMutableArray alloc] initWithCapacity:rows * columns];
        _longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressHandler:)];
        self.userInteractionEnabled = YES;
        [self addGestureRecognizer:_longPress];
        _longPress.minimumPressDuration = 0.05f;
        
        
    }
    return self;
}

- (void)setButtonTexts:(NSMutableArray *)buttonTexts {
    
    NSAssert(buttonTexts != nil, @"Array containing texts to be set on buttons is nil");
    _emojiArray = buttonTexts;
    
    if (([self.buttons count] - 1) == [buttonTexts count]) {
        // just reset text on each button
        for (NSUInteger i = 0; i < [buttonTexts count]; ++i) {
            [self.buttons[i] setTitle:buttonTexts[i] forState:UIControlStateNormal];
        }
    } else {
        [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        self.buttons = nil;
        self.buttons = [NSMutableArray arrayWithCapacity:self.rows * self.columns];
        for (NSUInteger i = 0; i < [buttonTexts count]; ++i) {
            UIButton *button = [self createButtonAtIndex:i];
            [button setTitle:buttonTexts[i] forState:UIControlStateNormal];
            [self addToViewButton:button];
            AGEmojiKeyboardView *keyboardView = (AGEmojiKeyboardView *)_delegate;
            [keyboardView.scrollView.panGestureRecognizer requireGestureRecognizerToFail:_longPress];
        }
    }
}

- (void)addToViewButton:(UIButton *)button {
    
    NSAssert(button != nil, @"Button to be added is nil");
    
    [self.buttons addObject:button];
    [self addSubview:button];
}

- (CGFloat)XMarginForButtonInColumn:(NSInteger)column {
    CGFloat padding = ((CGRectGetWidth(self.bounds) - self.columns * self.buttonSize.width) / self.columns);
    return (padding / 2 + column * (padding + self.buttonSize.width));
}

- (CGFloat)YMarginForButtonInRow:(NSInteger)rowNumber {
    CGFloat padding = ((CGRectGetHeight(self.bounds) - self.rows * self.buttonSize.height) / self.rows);
    return (padding / 2 + rowNumber * (padding + self.buttonSize.height)) - 8;
}

- (UIButton *)createButtonAtIndex:(NSUInteger)index {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.titleLabel.font = [UIFont fontWithName:@"Apple color emoji" size:BUTTON_FONT_SIZE];
    NSInteger row = (NSInteger)(index / self.columns);
    NSInteger column = (NSInteger)(index % self.columns);
    button.frame = CGRectIntegral(CGRectMake([self XMarginForButtonInColumn:column],
                                             [self YMarginForButtonInRow:row],
                                             self.buttonSize.width,
                                             self.buttonSize.height));
    [button addTarget:self action:@selector(emojiButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)emojiButtonPressed:(UIButton *)button {
    [self.delegate emojiPageView:self didUseEmoji:button.titleLabel.text];
}

- (void)longpressHandler:(UILongPressGestureRecognizer *)longGesture{
    CGPoint point = [longGesture locationInView:self];
    if (longGesture.state == UIGestureRecognizerStateBegan) {
        int x = point.x / ButtonWidth;
        int y = point.y / ButtonHeight;
        _index = x + y * _columns;
        [self showImageViewWithAtXIndex:x yIndex:y image:[UIImage imageNamed:@"emoji_touch"]];
    }else if (longGesture.state == UIGestureRecognizerStateChanged){
        int x = point.x / ButtonWidth;
        int y = point.y / ButtonHeight;
        if (_index != x + y * _columns) {
            _index = x + y * _columns;
            if(_index < 0 || _index >= _emojiArray.count){
                _zoomImageView.hidden = YES;
                return;
            }
            [self showImageViewWithAtXIndex:x yIndex:y image:[UIImage imageNamed:@"emoji_touch"]];
        }
    }else if (longGesture.state == UIGestureRecognizerStateEnded){
        if(_index < 0 || _index >= _emojiArray.count){
            _zoomImageView.hidden = YES;
            return;
        }
        _zoomImageView.hidden = YES;
        [self.delegate emojiPageView:self didUseEmoji:_emojiLabel.text];
        _index = -1;
    }
}

- (void)showImageViewWithAtXIndex:(NSUInteger)xIndex yIndex:(NSUInteger)yIndex image:(UIImage *)image {
    if (_index >= 0 && _index < _emojiArray.count) {
        if (_zoomImageView == nil) {
            _zoomImageView = [[UIImageView alloc] initWithImage:image];
            _zoomImageView.frame = CGRectZero;
            _emojiLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 8, 50, 50)];
            _emojiLabel.font = [UIFont fontWithName:@"Apple color emoji" size:40];
            _emojiLabel.textAlignment = NSTextAlignmentCenter;
            [_zoomImageView addSubview:_emojiLabel];
            _zoomImageView.hidden = YES;
            self.clipsToBounds = NO;
        }
        if (![self.subviews containsObject:_zoomImageView]) {
            [self addSubview:_zoomImageView];
        }
        _zoomImageView.frame = CGRectMake([self XMarginForButtonInColumn:xIndex] - 15, [self YMarginForButtonInRow:yIndex - 1] - 20, 77, 111);
        _zoomImageView.hidden = NO;
        _emojiLabel.text = _emojiArray[xIndex + yIndex * _columns];
    }
}

@end
