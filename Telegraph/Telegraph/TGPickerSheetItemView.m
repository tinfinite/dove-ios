//
//  TGPickerSheetItemView.m
//  Telegraph
//
//  Created by 琦张 on 15/3/11.
//
//

#import "TGPickerSheetItemView.h"
#import "TGFont.h"
#import "TGStringUtils.h"

@interface TGPickerSheetItemView ()
{
    UILabel *_titleLabel;
}

@end

@implementation TGPickerSheetItemView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.backgroundColor = nil;
        _titleLabel.opaque = false;
        _titleLabel.font = TGSystemFontOfSize(24.0f);
        [self addSubview:_titleLabel];
    }
    return self;
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    
    _titleLabel.text = TGLocalized(title);
    
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [_titleLabel sizeToFit];
    
//    _titleLabel.frame = (CGRect){{self.frame.size.width / 2.0f - 20.0f - _titleLabel.frame.size.width, CGFloor((self.frame.size.height - _titleLabel.frame.size.height) / 2.0f)}, _titleLabel.frame.size};
    _titleLabel.center = self.center;
}

@end
