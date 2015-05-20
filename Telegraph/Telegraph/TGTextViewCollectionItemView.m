#import "TGTextViewCollectionItemView.h"

#import "TGFont.h"
#import "SZTextView.h"

@interface TGTextViewCollectionItemView () <UITextViewDelegate>
{
    SZTextView *_textView;
}

@end

@implementation TGTextViewCollectionItemView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        _textView = [[SZTextView alloc] init];
        _textView.backgroundColor = [UIColor clearColor];
        _textView.textColor = [UIColor blackColor];
        _textView.font = TGSystemFontOfSize(16.0f);
        _textView.delegate = self;
        
        [self.contentView addSubview:_textView];
        
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _textView.frame = CGRectMake(4.0f, 0.0f, self.contentView.bounds.size.width - 8.0f, self.contentView.bounds.size.height);
}

- (void)setText:(NSString *)__unused text
{
    _textView.text = text;
}

- (void)setPlaceHolder:(NSString *)placeHolder
{
    _textView.placeholder = placeHolder;
}

- (void)textViewDidChange:(UITextView *)__unused textView
{
    if (_textChanged)
        _textChanged(_textView.text);
}

@end
