//
//  TGDiscoverCollectionItemView.m
//  Telegraph
//
//  Created by yewei on 15/4/7.
//
//

#import "TGDiscoverCollectionItemView.h"
#import "TGImageUtils.h"
#import "TGFont.h"

@interface TGDiscoverCollectionItemView ()
{
    UIImageView *_logoImageView;
    UILabel *_titleLabel;
    UILabel *_variantLabel;
    UILabel *_unreadCountLabel;
    UIImageView *_disclosureIndicator;
}

@end

@implementation TGDiscoverCollectionItemView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        _logoImageView = [[UIImageView alloc] init];
        [self addSubview:_logoImageView];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor blackColor];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.font = TGSystemFontOfSize(17);
        [self addSubview:_titleLabel];
        
        _variantLabel = [[UILabel alloc] init];
        _variantLabel.textColor = UIColorRGB(0x929297);
        _variantLabel.backgroundColor = [UIColor clearColor];
        _variantLabel.font = TGSystemFontOfSize(17);
        [self addSubview:_variantLabel];
        
        _unreadCountLabel = [[UILabel alloc] init];
        _unreadCountLabel.textColor = [UIColor whiteColor];
        _unreadCountLabel.backgroundColor = [UIColor redColor];
        _unreadCountLabel.textAlignment = NSTextAlignmentCenter;
        _unreadCountLabel.font = TGSystemFontOfSize(13);
        _unreadCountLabel.layer.masksToBounds = YES;
        _unreadCountLabel.layer.cornerRadius = 10;
        _unreadCountLabel.hidden = YES;
        [self addSubview:_unreadCountLabel];
        
        _disclosureIndicator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ModernListsDisclosureIndicator.png"]];
        [self addSubview:_disclosureIndicator];
    }
    return self;
}

- (void)setImageName:(NSString *)imageName
{
    _logoImageView.image = [UIImage imageNamed:imageName];
    [self setNeedsDisplay];
}

- (void)setTitle:(NSString *)title
{
    _titleLabel.text = title;
    [self setNeedsLayout];
}

- (void)setVariant:(NSString *)variant
{
    _variantLabel.text = variant;
    [self setNeedsLayout];
}

- (void)setUnreadCount:(NSString *)unreadCount
{
    if ([unreadCount integerValue] == 0) {
        _unreadCountLabel.hidden = YES;
        _disclosureIndicator.hidden = NO;
    }else{
        _unreadCountLabel.text = unreadCount;
        _unreadCountLabel.hidden = NO;
        _disclosureIndicator.hidden = YES;
    }
    
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect bounds = self.bounds;
    
    CGSize titleSize = [_titleLabel sizeThatFits:CGSizeMake(bounds.size.width, CGFLOAT_MAX)];
    CGSize variantSize = [_variantLabel sizeThatFits:CGSizeMake(bounds.size.width, CGFLOAT_MAX)];
    
    _logoImageView.frame = CGRectMake(15, 13, 25, 25);
    
    _disclosureIndicator.frame = CGRectMake(bounds.size.width - _disclosureIndicator.frame.size.width - 15, floorf((bounds.size.height - _disclosureIndicator.frame.size.height) / 2), _disclosureIndicator.frame.size.width, _disclosureIndicator.frame.size.height);
    
    if ([_unreadCountLabel.text integerValue] < 10) {
        _unreadCountLabel.frame = CGRectMake(bounds.size.width - 20 - 10, floorf((bounds.size.height - 20) / 2), 20, 20);
    }else if ([_unreadCountLabel.text integerValue] > 99){
        _unreadCountLabel.frame = CGRectMake(bounds.size.width - 30 - 10, floorf((bounds.size.height - 20) / 2), 30, 20);
    }else{
        _unreadCountLabel.frame = CGRectMake(bounds.size.width - 25 - 10, floorf((bounds.size.height - 20) / 2), 25, 20);
    }
    
    
    CGFloat startingX = 50.0f;
    CGFloat indicatorSpacing = 10.0f;
    CGFloat labelSpacing = 8.0f;
    CGFloat availableWidth = _disclosureIndicator.frame.origin.x - startingX - indicatorSpacing;
    
    CGFloat titleY =  CGFloor((bounds.size.height - titleSize.height) / 2.0f) + TGRetinaPixel;
    CGFloat variantY =  CGFloor((bounds.size.height - variantSize.height) / 2.0f) + TGRetinaPixel;
    
    if (titleSize.width + labelSpacing + variantSize.width <= availableWidth)
    {
        _titleLabel.frame = CGRectMake(startingX, titleY, titleSize.width, titleSize.height);
        _variantLabel.frame = CGRectMake(startingX + availableWidth - variantSize.width, variantY, variantSize.width, variantSize.height);
    }
    else if (titleSize.width > variantSize.width)
    {
        CGFloat titleWidth = CGFloor(availableWidth * 2.0f / 3.0f) - labelSpacing;
        _titleLabel.frame = CGRectMake(startingX, titleY, titleWidth, titleSize.height);
        CGFloat variantWidth = MIN(variantSize.width, availableWidth - titleWidth - labelSpacing);
        _variantLabel.frame = CGRectMake(startingX + availableWidth - variantWidth, variantY, variantWidth, variantSize.height);
    }
    else
    {
        CGFloat variantWidth = CGFloor(availableWidth / 2.0f) - labelSpacing;
        _variantLabel.frame = CGRectMake(startingX + availableWidth - variantWidth, variantY, variantWidth, variantSize.height);
        CGFloat titleWidth = MIN(titleSize.width, availableWidth - variantWidth - labelSpacing);
        _titleLabel.frame = CGRectMake(startingX, titleY, titleWidth, titleSize.height);
    }
}

@end
