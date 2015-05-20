#import "TGMainTabsController.h"

#import "TGViewController.h"

#import "TGNavigationBar.h"

#import "TGLabel.h"

#import <QuartzCore/QuartzCore.h>

#import <objc/runtime.h>

#import "TGHacks.h"

#import "FreedomUIKit.h"

#import "TGBackdropView.h"

#import "TGStringUtils.h"
#import "TGImageUtils.h"
#import "TGFont.h"

@protocol TGTabBarDelegate <NSObject>

- (void)tabBarSelectedItem:(int)index;

@end

@interface TGTabBar : UIView

@property (nonatomic, weak) id<TGTabBarDelegate> tabDelegate;

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *stripeView;

@property (nonatomic, strong) NSMutableArray *buttonViews;
@property (nonatomic, strong) NSMutableArray *labelViews;

@property (nonatomic, strong) UIView *unreadBadgeContainer;
@property (nonatomic, strong) UIImageView *unreadBadgeBackground;
@property (nonatomic, strong) UILabel *unreadBadgeLabel;

@property (nonatomic, strong) UIView *unreadBadgeContainerForGroup;
@property (nonatomic, strong) UIImageView *unreadBadgeBackgroundForGroup;
@property (nonatomic, strong) UILabel *unreadBadgeLabelForGroup;

@property (nonatomic, strong) UIView *unreadBadgeContainerForSingle;
@property (nonatomic, strong) UIImageView *unreadBadgeBackgroundForSingle;
@property (nonatomic, strong) UILabel *unreadBadgeLabelForSingle;

@property (nonatomic, strong) UIView *unreadBadgeContainerForMe;
@property (nonatomic, strong) UIImageView *unreadBadgeBackgroundForMe;
@property (nonatomic, strong) UILabel *unreadBadgeLabelForMe;

@property (nonatomic) int selectedIndex;

@end

@implementation TGTabBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        if ([TGViewController useExperimentalRTL])
            self.transform = CGAffineTransformMakeScale(-1.0f, 1.0f);
        
        self.multipleTouchEnabled = false;
        self.exclusiveTouch = true;
        
        if (TGBackdropEnabled())
        {
            _backgroundView = [[UIToolbar alloc] initWithFrame:self.bounds];
            [self addSubview:_backgroundView];
        }
        else
        {
            _backgroundView = [TGBackdropView viewWithLightNavigationBarStyle];
            _backgroundView.frame = self.bounds;
            _backgroundView.backgroundColor = UIColorRGB(0xf7f7f7);
            [self addSubview:_backgroundView];
            
            _stripeView = [[UIView alloc] init];
            _stripeView.backgroundColor = UIColorRGB(0xb2b2b2);
            [self addSubview:_stripeView];
        }
        
        _buttonViews = [[NSMutableArray alloc] init];
        
        UIImageView *groupsIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Tabbar_Groups"] highlightedImage:[UIImage imageNamed:@"Tabbar_GroupsHighlighted"]];
        [self addSubview:groupsIcon];
        [_buttonViews addObject:groupsIcon];

        UIImageView *streamIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Tabbar_Stream"] highlightedImage:[UIImage imageNamed:@"Tabbar_StreamHighlighted"]];
        [self addSubview:streamIcon];
        [_buttonViews addObject:streamIcon];
        
        UIImageView *chatsIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Tabbar_Chats"] highlightedImage:[UIImage imageNamed:@"Tabbar_ChatsHighlighted"]];
        [self addSubview:chatsIcon];
        [_buttonViews addObject:chatsIcon];
        
        UIImageView *meIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Tabbar_Me"] highlightedImage:[UIImage imageNamed:@"Tabbar_MeHighlighted"]];
        [self addSubview:meIcon];
        [_buttonViews addObject:meIcon];
        
        _labelViews = [[NSMutableArray alloc] init];
        
        NSArray *titles = @[TGLocalized(@"Groups.TabTitle"),
                            TGLocalized(@"Stream.TabTitle"),
                            TGLocalized(@"DialogList.TabTitle"),
                            TGLocalized(@"Me.TabTitle")];
        
        for (NSString *title in titles)
        {
            UILabel *label = [self createTabLabelWithText:title];
            [self addSubview:label];
            [_labelViews addObject:label];
        }
    }
    return self;
}

- (UIFont *)tabLabelFont
{
    static UIFont *font = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            font = TGSystemFontOfSize(10);
        else
            font = TGSystemFontOfSize(14);
    });
    
    return font;
}

- (CGFloat)iconVerticalOffset
{
    static CGFloat offset = 0.0f;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            offset = 4.0f;
        else
            offset = 5.0f + TGRetinaPixel;
    });
    
    return offset;
}

- (CGFloat)labelVerticalOffset
{
    static CGFloat offset = 0.0f;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            offset = 35 - TGRetinaPixel;
        else
            offset = 36;
    });
    
    return offset;
}

- (CGFloat)sideIconOffsetForWidth:(CGFloat)width
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        return 0.0f;
    if (width < 320.0f + FLT_EPSILON)
        return 0.0f;
    
    return CGFloor(width / 21.5f);
}

- (UILabel *)createTabLabelWithText:(NSString *)text
{
    UILabel *label = [[UILabel alloc] init];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = UIColorRGB(0x929292);
    label.highlightedTextColor = TGAccentColor();
    label.font = [self tabLabelFont];
    label.text = text;
    [label sizeToFit];
    return label;
}

- (void)setSelectedIndex:(int)selectedIndex
{
    if (_selectedIndex >= 0 && _selectedIndex < (int)_buttonViews.count)
    {
        ((UIImageView *)[_buttonViews objectAtIndex:_selectedIndex]).highlighted = false;
        ((UILabel *)[_labelViews objectAtIndex:_selectedIndex]).highlighted = false;
    }
    
    _selectedIndex = selectedIndex;
    
    if (_selectedIndex >= 0 && _selectedIndex < (int)_buttonViews.count)
    {
        ((UIImageView *)[_buttonViews objectAtIndex:_selectedIndex]).highlighted = true;
        ((UILabel *)[_labelViews objectAtIndex:_selectedIndex]).highlighted = true;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    int index = MAX(0, MIN((int)_buttonViews.count - 1, (int)([touch locationInView:self].x / (self.frame.size.width / 4))));
    [self setSelectedIndex:index];
    
    __strong id<TGTabBarDelegate> delegate = _tabDelegate;
    [delegate tabBarSelectedItem:index];
}

- (void)loadUnreadBadgeView
{
    if (_unreadBadgeContainer != nil)
        return;
    
    _unreadBadgeContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    _unreadBadgeContainer.hidden = true;
    _unreadBadgeContainer.userInteractionEnabled = false;
    _unreadBadgeContainer.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self addSubview:_unreadBadgeContainer];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(18.0f, 18.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, UIColorRGB(0xff3b30).CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, 18.0f, 18.0f));
    UIImage *badgeImage = [UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:9.0f topCapHeight:0.0f];
    UIGraphicsEndImageContext();
    
    _unreadBadgeBackground = [[UIImageView alloc] initWithImage:badgeImage];
    [_unreadBadgeContainer addSubview:_unreadBadgeBackground];
    
    _unreadBadgeLabel = [[UILabel alloc] init];
    _unreadBadgeLabel.text = @"1";
    [_unreadBadgeLabel sizeToFit];
    _unreadBadgeLabel.text = nil;
    _unreadBadgeLabel.backgroundColor = [UIColor clearColor];
    _unreadBadgeLabel.textColor = [UIColor whiteColor];
    _unreadBadgeLabel.font = TGSystemFontOfSize(13);
    [_unreadBadgeContainer addSubview:_unreadBadgeLabel];
    
    [self setNeedsLayout];
}

- (void)loadUnreadBadgeViewForGroup
{
    if (_unreadBadgeContainerForGroup != nil)
        return;
    
    _unreadBadgeContainerForGroup = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    _unreadBadgeContainerForGroup.hidden = true;
    _unreadBadgeContainerForGroup.userInteractionEnabled = false;
    _unreadBadgeContainerForGroup.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self addSubview:_unreadBadgeContainerForGroup];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(18.0f, 18.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, UIColorRGB(0xff3b30).CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, 18.0f, 18.0f));
    UIImage *badgeImage = [UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:9.0f topCapHeight:0.0f];
    UIGraphicsEndImageContext();
    
    _unreadBadgeBackgroundForGroup = [[UIImageView alloc] initWithImage:badgeImage];
    [_unreadBadgeContainerForGroup addSubview:_unreadBadgeBackgroundForGroup];
    
    _unreadBadgeLabelForGroup = [[UILabel alloc] init];
    _unreadBadgeLabelForGroup.text = @"1";
    [_unreadBadgeLabelForGroup sizeToFit];
    _unreadBadgeLabelForGroup.text = nil;
    _unreadBadgeLabelForGroup.backgroundColor = [UIColor clearColor];
    _unreadBadgeLabelForGroup.textColor = [UIColor whiteColor];
    _unreadBadgeLabelForGroup.font = TGSystemFontOfSize(13);
    [_unreadBadgeContainerForGroup addSubview:_unreadBadgeLabelForGroup];
    
    [self setNeedsLayout];
}

- (void)loadUnreadBadgeViewForSingle
{
    if (_unreadBadgeContainerForSingle != nil)
        return;
    
    _unreadBadgeContainerForSingle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    _unreadBadgeContainerForSingle.hidden = true;
    _unreadBadgeContainerForSingle.userInteractionEnabled = false;
    _unreadBadgeContainerForSingle.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self addSubview:_unreadBadgeContainerForSingle];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(18.0f, 18.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, UIColorRGB(0xff3b30).CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, 18.0f, 18.0f));
    UIImage *badgeImage = [UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:9.0f topCapHeight:0.0f];
    UIGraphicsEndImageContext();
    
    _unreadBadgeBackgroundForSingle = [[UIImageView alloc] initWithImage:badgeImage];
    [_unreadBadgeContainerForSingle addSubview:_unreadBadgeBackgroundForSingle];
    
    _unreadBadgeLabelForSingle = [[UILabel alloc] init];
    _unreadBadgeLabelForSingle.text = @"1";
    [_unreadBadgeLabelForSingle sizeToFit];
    _unreadBadgeLabelForSingle.text = nil;
    _unreadBadgeLabelForSingle.backgroundColor = [UIColor clearColor];
    _unreadBadgeLabelForSingle.textColor = [UIColor whiteColor];
    _unreadBadgeLabelForSingle.font = TGSystemFontOfSize(13);
    [_unreadBadgeContainerForSingle addSubview:_unreadBadgeLabelForSingle];
    
    [self setNeedsLayout];
}

- (void)loadUnreadBadgeViewForMe
{
    if (_unreadBadgeContainerForMe != nil)
        return;
    
    _unreadBadgeContainerForMe = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    _unreadBadgeContainerForMe.hidden = true;
    _unreadBadgeContainerForMe.userInteractionEnabled = false;
    _unreadBadgeContainerForMe.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self addSubview:_unreadBadgeContainerForMe];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(18.0f, 18.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, UIColorRGB(0xff3b30).CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, 18.0f, 18.0f));
    UIImage *badgeImage = [UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:9.0f topCapHeight:0.0f];
    UIGraphicsEndImageContext();
    
    _unreadBadgeBackgroundForMe = [[UIImageView alloc] initWithImage:badgeImage];
    [_unreadBadgeContainerForMe addSubview:_unreadBadgeBackgroundForMe];
    
    _unreadBadgeLabelForMe = [[UILabel alloc] init];
    _unreadBadgeLabelForMe.text = @"1";
    [_unreadBadgeLabelForMe sizeToFit];
    _unreadBadgeLabelForMe.text = nil;
    _unreadBadgeLabelForMe.backgroundColor = [UIColor clearColor];
    _unreadBadgeLabelForMe.textColor = [UIColor whiteColor];
    _unreadBadgeLabelForMe.font = TGSystemFontOfSize(13);
    [_unreadBadgeContainerForMe addSubview:_unreadBadgeLabelForMe];
    
    [self setNeedsLayout];
}

- (void)setUnreadCount:(int)unreadCount
{
    if (unreadCount <= 0 && _unreadBadgeLabel == nil)
        return;
    
    [self loadUnreadBadgeView];
    
    if (unreadCount <= 0)
        _unreadBadgeContainer.hidden = true;
    else
    {
        NSString *text = nil;
        
        if (TGIsLocaleArabic())
            text = [TGStringUtils stringWithLocalizedNumber:unreadCount];
        else
        {
            if (unreadCount < 1000)
                text = [[NSString alloc] initWithFormat:@"%d", unreadCount];
            else if (unreadCount < 1000000)
                text = [[NSString alloc] initWithFormat:@"%dK", unreadCount / 1000];
            else
                text = [[NSString alloc] initWithFormat:@"%dM", unreadCount / 1000000];
        }
        
        _unreadBadgeLabel.text = text;
        [_unreadBadgeLabel sizeToFit];
        _unreadBadgeContainer.hidden = false;
        
        CGRect frame = _unreadBadgeBackground.frame;
        CGFloat textWidth = _unreadBadgeLabel.frame.size.width;
        frame.size.width = MAX(18.0f, textWidth + 10.0f + TGRetinaPixel * 2.0f);
        frame.origin.x = _unreadBadgeBackground.superview.frame.size.width - frame.size.width;
        _unreadBadgeBackground.frame = frame;
        
        CGRect labelFrame = _unreadBadgeLabel.frame;
        labelFrame.origin.x = 5.0f + TGRetinaPixel + frame.origin.x;
        labelFrame.origin.y = 1;
        _unreadBadgeLabel.frame = labelFrame;
    }
}

- (void)setUnreadCountForGroup:(int)unreadCount
{
    if (unreadCount <= 0 && _unreadBadgeLabelForGroup == nil)
        return;
    
    [self loadUnreadBadgeViewForGroup];
    
    if (unreadCount <= 0)
        _unreadBadgeContainerForGroup.hidden = true;
    else
    {
        NSString *text = nil;
        
        if (TGIsLocaleArabic())
            text = [TGStringUtils stringWithLocalizedNumber:unreadCount];
        else
        {
            if (unreadCount < 1000)
                text = [[NSString alloc] initWithFormat:@"%d", unreadCount];
            else if (unreadCount < 1000000)
                text = [[NSString alloc] initWithFormat:@"%dK", unreadCount / 1000];
            else
                text = [[NSString alloc] initWithFormat:@"%dM", unreadCount / 1000000];
        }
        
        _unreadBadgeLabelForGroup.text = text;
        [_unreadBadgeLabelForGroup sizeToFit];
        _unreadBadgeContainerForGroup.hidden = false;
        
        CGRect frame = _unreadBadgeBackgroundForGroup.frame;
        CGFloat textWidth = _unreadBadgeLabelForGroup.frame.size.width;
        frame.size.width = MAX(18.0f, textWidth + 10.0f + TGRetinaPixel * 2.0f);
        frame.origin.x = _unreadBadgeBackgroundForGroup.superview.frame.size.width - frame.size.width;
        _unreadBadgeBackgroundForGroup.frame = frame;
        
        CGRect labelFrame = _unreadBadgeLabelForGroup.frame;
        labelFrame.origin.x = 5.0f + TGRetinaPixel + frame.origin.x;
        labelFrame.origin.y = 1;
        _unreadBadgeLabelForGroup.frame = labelFrame;
    }
}

- (void)setUnreadCountForSingle:(int)unreadCount
{
    if (unreadCount <= 0 && _unreadBadgeLabelForSingle == nil)
        return;
    
    [self loadUnreadBadgeViewForSingle];
    
    if (unreadCount <= 0)
        _unreadBadgeContainerForSingle.hidden = true;
    else
    {
        NSString *text = nil;
        
        if (TGIsLocaleArabic())
            text = [TGStringUtils stringWithLocalizedNumber:unreadCount];
        else
        {
            if (unreadCount < 1000)
                text = [[NSString alloc] initWithFormat:@"%d", unreadCount];
            else if (unreadCount < 1000000)
                text = [[NSString alloc] initWithFormat:@"%dK", unreadCount / 1000];
            else
                text = [[NSString alloc] initWithFormat:@"%dM", unreadCount / 1000000];
        }
        
        _unreadBadgeLabelForSingle.text = text;
        [_unreadBadgeLabelForSingle sizeToFit];
        _unreadBadgeContainerForSingle.hidden = false;
        
        CGRect frame = _unreadBadgeBackgroundForSingle.frame;
        CGFloat textWidth = _unreadBadgeLabelForSingle.frame.size.width;
        frame.size.width = MAX(18.0f, textWidth + 10.0f + TGRetinaPixel * 2.0f);
        frame.origin.x = _unreadBadgeBackgroundForSingle.superview.frame.size.width - frame.size.width;
        _unreadBadgeBackgroundForSingle.frame = frame;
        
        CGRect labelFrame = _unreadBadgeLabelForSingle.frame;
        labelFrame.origin.x = 5.0f + TGRetinaPixel + frame.origin.x;
        labelFrame.origin.y = 1;
        _unreadBadgeLabelForSingle.frame = labelFrame;
    }
}

- (void)setUnreadCountForMe:(int)unreadCount
{
    if (unreadCount <= 0 && _unreadBadgeLabelForMe == nil)
        return;
    
    [self loadUnreadBadgeViewForMe];
    
    if (unreadCount <= 0)
        _unreadBadgeContainerForMe.hidden = true;
    else
    {
        NSString *text = nil;
        
        if (TGIsLocaleArabic())
            text = [TGStringUtils stringWithLocalizedNumber:unreadCount];
        else
        {
            if (unreadCount < 1000)
                text = [[NSString alloc] initWithFormat:@"%d", unreadCount];
            else if (unreadCount < 1000000)
                text = [[NSString alloc] initWithFormat:@"%dK", unreadCount / 1000];
            else
                text = [[NSString alloc] initWithFormat:@"%dM", unreadCount / 1000000];
        }
        
        _unreadBadgeLabelForMe.text = text;
        [_unreadBadgeLabelForMe sizeToFit];
        _unreadBadgeContainerForMe.hidden = false;
        
        CGRect frame = _unreadBadgeBackgroundForMe.frame;
        CGFloat textWidth = _unreadBadgeLabelForMe.frame.size.width;
        frame.size.width = MAX(18.0f, textWidth + 10.0f + TGRetinaPixel * 2.0f);
        frame.origin.x = _unreadBadgeBackgroundForMe.superview.frame.size.width - frame.size.width;
        _unreadBadgeBackgroundForMe.frame = frame;
        
        CGRect labelFrame = _unreadBadgeLabelForMe.frame;
        labelFrame.origin.x = 5.0f + TGRetinaPixel + frame.origin.x;
        labelFrame.origin.y = 1;
        _unreadBadgeLabelForMe.frame = labelFrame;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGSize viewSize = self.frame.size;
    
    _backgroundView.frame = CGRectMake(0, 0, viewSize.width, viewSize.height);
    CGFloat stripeHeight = TGIsRetina() ? 0.5f : 1.0f;
    _stripeView.frame = CGRectMake(0, -stripeHeight, viewSize.width, stripeHeight);
    
    float indicatorWidth = floorf((float)viewSize.width / 4);
    if (((int)indicatorWidth) % 2 != 0)
        indicatorWidth -= 1;
    
    float paddingLeft = floorf((float)(viewSize.width - indicatorWidth * 4) / 3);
    float additionalWidth = 0;
    float additionalOffset = 0;
    if (_selectedIndex == 0 || _selectedIndex == 3)
        additionalWidth += paddingLeft + 1;
    if (_selectedIndex == 0)
        additionalOffset += -paddingLeft - 1;
    
    CGFloat iconVerticalOffset = [self iconVerticalOffset];
    CGFloat labelVerticalOffset = [self labelVerticalOffset];
    
    int index = -1;
    for (UIView *iconView in _buttonViews)
    {
        index++;
        
        CGFloat horizontalOffset = 0.0f;
        if (index == 0 || index == 2 || index == 3)
            horizontalOffset = [self sideIconOffsetForWidth:viewSize.width] * (index == 0 ? 1 : -1);
        
        CGRect frame = iconView.frame;
        frame.origin.x = paddingLeft + index * indicatorWidth + floorf((float)(indicatorWidth - frame.size.width) / 2) + horizontalOffset;
        frame.origin.y = iconVerticalOffset;
        
        iconView.frame = frame;
        
        if (index == 0)
        {
            if (_unreadBadgeContainerForGroup != nil)
            {
                CGRect unreadBadgeContainerFrame = _unreadBadgeContainerForGroup.frame;
                unreadBadgeContainerFrame.origin.x = frame.origin.x + frame.size.width - 9;
                unreadBadgeContainerFrame.origin.y = 2;
                _unreadBadgeContainerForGroup.frame = unreadBadgeContainerFrame;
            }
        }
        if (index == 2) {
            if (_unreadBadgeContainerForSingle != nil)
            {
                CGRect unreadBadgeContainerFrame = _unreadBadgeContainerForSingle.frame;
                unreadBadgeContainerFrame.origin.x = frame.origin.x + frame.size.width - 9;
                unreadBadgeContainerFrame.origin.y = 2;
                _unreadBadgeContainerForSingle.frame = unreadBadgeContainerFrame;
            }
        }
        if (index == 3) {
            if (_unreadBadgeContainerForMe != nil)
            {
                CGRect unreadBadgeContainerFrame = _unreadBadgeContainerForMe.frame;
                unreadBadgeContainerFrame.origin.x = frame.origin.x + frame.size.width - 9;
                unreadBadgeContainerFrame.origin.y = 2;
                _unreadBadgeContainerForMe.frame = unreadBadgeContainerFrame;
            }
        }
        
        UILabel *labelView = [_labelViews objectAtIndex:index];
        
        CGRect labelFrame = labelView.frame;
        labelFrame.origin.x = paddingLeft + index * indicatorWidth + floorf((float)(indicatorWidth - labelFrame.size.width) / 2) + horizontalOffset;
        labelFrame.origin.y = labelVerticalOffset;
        labelView.frame = labelFrame;
    }
}

@end

#pragma mark -

@interface TGTabsContainerSubview : UIView

@end

@implementation TGTabsContainerSubview

- (void)layoutSubviews
{
    static void (*nativeImpl)(id, SEL) = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        nativeImpl = (void (*)(id, SEL))freedomNativeImpl([self class], _cmd);
    });
    
    if (nativeImpl != NULL)
        nativeImpl(self, _cmd);
    
    CGSize screenSize = [TGViewController screenSizeForInterfaceOrientation:self.frame.size.width > 320.0f + FLT_EPSILON ? UIInterfaceOrientationLandscapeLeft : UIInterfaceOrientationPortrait];
    
    for (UIView *subview in self.subviews)
    {
        subview.frame = CGRectMake(0.0f, 0.0f, self.frame.size.width, screenSize.height);
    }
}

@end

#pragma mark -

@interface TGMainTabsController () <UITabBarControllerDelegate, TGTabBarDelegate>
{
    int _unreadCount;
    int _unreadCountForGroup;
    int _unreadCountForSingle;
    int _unreadCountForMe;
}

@property (nonatomic, strong) TGTabBar *customTabBar;

@end

@implementation TGMainTabsController

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        self.delegate = self;
        
        if ([self respondsToSelector:@selector(setAutomaticallyAdjustsScrollViewInsets:)])
            [self setAutomaticallyAdjustsScrollViewInsets:false];
        
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:nil style:UIBarButtonItemStylePlain target:nil action:nil];
        self.navigationItem.backBarButtonItem.possibleTitles = [NSSet setWithObject:TGLocalized(@"Common.Back")];
    }
    return self;
}

- (void)loadView
{
    [super loadView];

    if (iosMajorVersion() <= 6 && [NSStringFromClass([self.view.subviews.firstObject class]) isEqualToString:TGEncodeText(@"VJUsbotjujpoWjfx", -1)])
    {
        Class subclass = freedomMakeClass([self.view.subviews.firstObject class], [TGTabsContainerSubview class]);
        object_setClass(self.view.subviews.firstObject, subclass);
    }
}

- (CGFloat)tabBarHeight
{
    static CGFloat height = 0.0f;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
            height = 49.0f;
        else
            height = 56.0f;
    });
    
    return height;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _customTabBar = [[TGTabBar alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - [self tabBarHeight], self.view.frame.size.width, [self tabBarHeight])];
    _customTabBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    _customTabBar.tabDelegate = self;
    [self.view insertSubview:_customTabBar aboveSubview:self.tabBar];
    
    //_customTabBar.alpha = 0.5f;
    
    self.tabBar.hidden = true;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [TGViewController autorotationAllowed] && (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (BOOL)shouldAutorotate
{
    return [TGViewController autorotationAllowed];
}

- (UIBarStyle)requiredNavigationBarStyle
{
    if (self.selectedViewController == nil)
        return UIBarStyleDefault;
    else if ([self.selectedViewController conformsToProtocol:@protocol(TGViewControllerNavigationBarAppearance)])
        return [(id<TGViewControllerNavigationBarAppearance>)self.selectedViewController requiredNavigationBarStyle];
    else
        return UIBarStyleDefault;
}

- (bool)navigationBarShouldBeHidden
{
    if (self.selectedViewController == nil)
        return false;
    else if ([self.selectedViewController conformsToProtocol:@protocol(TGViewControllerNavigationBarAppearance)])
        return [(id<TGViewControllerNavigationBarAppearance>)self.selectedViewController navigationBarShouldBeHidden];
    else
        return false;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.view layoutIfNeeded];
    
    [super viewWillAppear:animated];
}

- (BOOL)tabBarController:(UITabBarController *)__unused tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    if (viewController == self.selectedViewController)
        return false;
    
    return true;
}

- (void)tabBarSelectedItem:(int)index
{
    if ((int)self.selectedIndex != index)
    {
        [self tabBarController:self shouldSelectViewController:[self.viewControllers objectAtIndex:index]];
        [self setSelectedIndex:index];
    }
    else
    {
        if ([self.selectedViewController respondsToSelector:@selector(scrollToTopRequested)])
            [self.selectedViewController performSelector:@selector(scrollToTopRequested)];
    }
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    [super setSelectedIndex:selectedIndex];
    
    [self _updateNavigationItemOverride:selectedIndex];
    
    [_customTabBar setSelectedIndex:selectedIndex];
}

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated
{
    [super setViewControllers:viewControllers animated:animated];
    
    [self _updateNavigationItemOverride:self.selectedIndex];
}

- (void)_updateNavigationItemOverride:(NSUInteger)selectedIndex
{
    int index = -1;
    for (UIViewController *viewController in self.viewControllers)
    {
        index++;
        
        if ([viewController isKindOfClass:[TGViewController class]])
        {
            if (index == (int)selectedIndex)
                [(TGViewController *)viewController setTargetNavigationItem:self.navigationItem titleController:self];
            else
                [(TGViewController *)viewController setTargetNavigationItem:nil titleController:nil];
        }
    }
}

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    
    NSString *backTitle = title == nil || ![title isEqualToString:TGLocalized(@"DialogList.Title")] ? TGLocalized(@"Common.Back") : title;
    
    if (!TGStringCompare(self.navigationItem.backBarButtonItem.title, backTitle))
        self.navigationItem.backBarButtonItem.title = backTitle;
}

- (void)setUnreadCount:(int)unreadCount
{
    _unreadCount = unreadCount;
    [_customTabBar setUnreadCount:unreadCount];
}

- (void)setUnreadCountForGroup:(int)unreadCount
{
    _unreadCountForGroup = unreadCount;
    [_customTabBar setUnreadCountForGroup:unreadCount];
}

- (void)setUnreadCountForSingle:(int)unreadCount
{
    _unreadCountForSingle = unreadCount;
    [_customTabBar setUnreadCountForSingle:unreadCount];
}

- (void)setUnreadCountForMe:(int)unreadCount
{
    _unreadCountForMe = unreadCount;
    [_customTabBar setUnreadCountForMe:unreadCount];
}


- (void)localizationUpdated
{
    _customTabBar.tabDelegate = nil;
    [_customTabBar removeFromSuperview];
    
    _customTabBar = [[TGTabBar alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - [self tabBarHeight], self.view.frame.size.width, [self tabBarHeight])];
    _customTabBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    _customTabBar.tabDelegate = self;
    [self.view insertSubview:_customTabBar aboveSubview:self.tabBar];
    
    [_customTabBar setSelectedIndex:self.selectedIndex];
//    [_customTabBar setUnreadCount:_unreadCount];
    [_customTabBar setUnreadCountForGroup:_unreadCountForGroup];
    [_customTabBar setUnreadCountForSingle:_unreadCountForSingle];
    [_customTabBar setUnreadCountForMe:_unreadCountForMe];
    
    for (TGViewController *controller in self.viewControllers)
    {
        [controller localizationUpdated];
    }
}

@end
