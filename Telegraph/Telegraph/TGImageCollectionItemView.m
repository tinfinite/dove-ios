//
//  TGImageCollectionItemView.m
//  Telegraph
//
//  Created by yewei on 15/2/10.
//
//

#import "TGImageCollectionItemView.h"
#import "TGImageUtils.h"
#import "TGFont.h"

@interface TGImageCollectionItemView ()
{
    UILabel *_titleLabel;
    UIImageView *_accesoryImageView;
    UIImageView *_disclosureIndicator;
}

@end

@implementation TGImageCollectionItemView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor blackColor];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.font = TGSystemFontOfSize(17);
        [self addSubview:_titleLabel];
        
        _accesoryImageView = [[UIImageView alloc] init];
        [self addSubview:_accesoryImageView];
        
        _disclosureIndicator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ModernListsDisclosureIndicator.png"]];
        [self addSubview:_disclosureIndicator];
    }
    return self;
}

- (void)setTitle:(NSString *)title
{
    _titleLabel.text = title;
    [self setNeedsLayout];
}

- (void)setImage:(NSString *)image
{
    _accesoryImageView.image = [UIImage imageNamed:image];
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect bounds = self.bounds;
    
    CGSize titleSize = [_titleLabel sizeThatFits:CGSizeMake(bounds.size.width, CGFLOAT_MAX)];
    
    _disclosureIndicator.frame = CGRectMake(bounds.size.width - _disclosureIndicator.frame.size.width - 15, floorf((bounds.size.height - _disclosureIndicator.frame.size.height) / 2), _disclosureIndicator.frame.size.width, _disclosureIndicator.frame.size.height);
    
    _accesoryImageView.frame = CGRectMake(bounds.size.width - _disclosureIndicator.frame.size.width - 20 - 20, floorf((bounds.size.height - 20) / 2), 20, 20);
    
    CGFloat startingX = 15.0f;
    CGFloat indicatorSpacing = 10.0f;
    CGFloat labelSpacing = 8.0f;
    CGFloat availableWidth = _accesoryImageView.frame.origin.x - startingX - indicatorSpacing;
    
    CGFloat titleY =  CGFloor((bounds.size.height - titleSize.height) / 2.0f) + TGRetinaPixel;
    
    
    
    if (titleSize.width + labelSpacing  <= availableWidth)
    {
        _titleLabel.frame = CGRectMake(startingX, titleY, titleSize.width, titleSize.height);
    }
//    else if (titleSize.width > variantSize.width)
//    {
//        CGFloat titleWidth = CGFloor(availableWidth * 2.0f / 3.0f) - labelSpacing;
//        _titleLabel.frame = CGRectMake(startingX, titleY, titleWidth, titleSize.height);
//        CGFloat variantWidth = MIN(variantSize.width, availableWidth - titleWidth - labelSpacing);
//        _variantLabel.frame = CGRectMake(startingX + availableWidth - variantWidth, variantY, variantWidth, variantSize.height);
//    }
//    else
//    {
//        CGFloat variantWidth = CGFloor(availableWidth / 2.0f) - labelSpacing;
//        _variantLabel.frame = CGRectMake(startingX + availableWidth - variantWidth, variantY, variantWidth, variantSize.height);
//        CGFloat titleWidth = MIN(titleSize.width, availableWidth - variantWidth - labelSpacing);
//        _titleLabel.frame = CGRectMake(startingX, titleY, titleWidth, titleSize.height);
//    }
}

@end
