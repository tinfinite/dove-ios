//
//  TGComboxView.m
//  Telegraph
//
//  Created by yewei on 15/4/27.
//
//

#import "TGComboxView.h"

const CGFloat kArrowSize = 12.f;
const CGFloat kComboxItemHeight = 50.f;
const CGFloat kComboxItemWidth = 200.f;

@implementation TGComboxItem

+ (instancetype) menuItem:(NSString *) title
                    image:(UIImage *) image
          highligtedImage:(UIImage *)highligtedImage
                   target:(id)target
                   action:(SEL) action
{
    return [[TGComboxItem alloc] init:title
                                image:image
                      highligtedImage:(UIImage *)highligtedImage
                               target:target
                               action:action];
}

- (id) init:(NSString *) title
      image:(UIImage *) image
highligtedImage:(UIImage *)highligtedImage
     target:(id)target
     action:(SEL) action
{
    NSParameterAssert(title.length || image);
    
    self = [super init];
    if (self) {
        
        _title = title;
        _image = image;
        _highligtedImage = highligtedImage;
        _target = target;
        _action = action;
    }
    return self;
}

- (BOOL) enabled
{
    return _target != nil && _action != NULL;
}

- (void) performAction
{
    __strong id target = self.target;
    
    if (target && [target respondsToSelector:_action]) {
        
        [target performSelectorOnMainThread:_action withObject:self waitUntilDone:YES];
    }
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<%@ #%p %@>", [self class], self, _title];
}
@end

@implementation TGComboxView

- (id)initWithItems:(NSArray *)items
{
    CGRect frame = CGRectMake(0, 0, kComboxItemWidth, items.count * kComboxItemHeight + 10);
    if(self = [super initWithFrame:frame])
    {
        self.items = items;
        frame.origin.y = 10;
        frame.size.height -= 10;
        self.tvCombox = [[UITableView alloc] initWithFrame:frame];
        self.tvCombox.dataSource = self;
        self.tvCombox.delegate = self;
        self.tvCombox.backgroundColor = [UIColor clearColor];
        self.tvCombox.backgroundView = nil;
        self.tvCombox.rowHeight = kComboxItemHeight;
        self.tvCombox.scrollEnabled = NO;
        [self addSubview:self.tvCombox];
        
        UIImage *image = [UIImage imageNamed:@"combox_bg"];
        UIImageView *iv = [[UIImageView alloc] initWithImage:image];
        iv.frame = self.frame;
        self.backgroundView = iv;
        
        self.backgroundColor = [UIColor clearColor];
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = [UIScreen mainScreen].bounds;
        [btn addTarget:self action:@selector(btnAllWindowTouchDown:) forControlEvents:UIControlEventTouchDown];
        self.btnAllWindow = btn;
        
        [self addSubview:self.backgroundView];
        [self addSubview:self.tvCombox];
        
        return self;
        
    }
    return self;
}

+ (void)showPopComBoxWithParentView:(UIView *)parentView items:(NSArray *)items xRightOffset:(CGFloat)xRightOffset yTopOffset:(CGFloat)yTopOffset
{
//    CGRect frame1;
//    CGRect frame2;
//    CGRect frame3;
//    CGRect frame4;
//    CGRect frame5;
//    CGRect frame6;
    TGComboxView *jwcv = [[TGComboxView alloc] initWithItems:items];
    CGRect frame = jwcv.frame;
    frame.origin.x = SCREEN_WIDTH - frame.size.width - xRightOffset;
    frame.origin.y = yTopOffset;
    jwcv.frame = frame;
    CGAffineTransform scale = CGAffineTransformMakeScale(0.3, 0.3);
    CGAffineTransform translate = CGAffineTransformMakeTranslation(50, -50);
    jwcv.transform = CGAffineTransformConcat(scale, translate);
    jwcv.alpha = 0;
//    frame1 = frame;
//    frame2 = frame;
//    frame1.size.height = 10;
//    jwcv.frame = frame1;
//    
//    frame5 = jwcv.backgroundView.frame;
//    frame6 = frame5;
//    frame5.size.height = 10;
//    jwcv.backgroundView.frame = frame5;
//    frame3 = jwcv.tvCombox.frame;
//    frame4 = frame3;
//    frame3.size.height = 0;
//    jwcv.tvCombox.frame = frame3;
    
    [parentView addSubview:jwcv.btnAllWindow];
    [parentView addSubview:jwcv];
    
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//        jwcv.frame = frame2;
//        jwcv.backgroundView.frame = frame6;
//        jwcv.tvCombox.frame = frame4;
        CGAffineTransform scale = CGAffineTransformMakeScale(1, 1);
        CGAffineTransform translate = CGAffineTransformMakeTranslation(0, 0);
        jwcv.transform = CGAffineTransformConcat(scale, translate);
        jwcv.alpha = 1;
    } completion:nil];
}

#pragma mark - Property
- (void)setBackgroundView:(UIView *)backgroundView
{
    if (backgroundView != _backgroundView) {
        [_backgroundView removeFromSuperview];
        _backgroundView = nil;
        if (backgroundView != nil) {
            _backgroundView = backgroundView;
            [self insertSubview:_backgroundView atIndex:0];
        }
    }
}

#pragma mark - 事件响应方法
- (void)btnAllWindowTouchDown:(id)sender
{
    [self closeWithAnimation:YES];
}

#pragma mark - 辅助方法
- (void)closeWithAnimation:(BOOL)showAnimation
{
    [self.btnAllWindow removeFromSuperview];
    
    if(showAnimation)
    {
//        CGRect frame1 = self.frame;
//        frame1.size.height = 10;
//        CGRect frame2 = self.backgroundView.frame;
//        frame2.size.height = 0;
//        CGRect frame3 = self.tvCombox.frame;
//        frame3.size.height = 0;
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//            self.frame = frame1;
//            self.backgroundView.frame = frame2;
//            self.tvCombox.frame = frame3;
            CGAffineTransform scale = CGAffineTransformMakeScale(0.3, 0.3);
            CGAffineTransform translate = CGAffineTransformMakeTranslation(50, -50);
            self.transform = CGAffineTransformConcat(scale, translate);
            self.alpha = 0;
        } completion:^(BOOL __unused finished) {
            [self removeFromSuperview];
        }];
    }
    else
    {
        [self removeFromSuperview];
    }
}

#pragma mark - UITableViewDatasource methods
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CELLIDENTIFIER = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELLIDENTIFIER];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CELLIDENTIFIER];
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    if ((NSUInteger)indexPath.row >= self.items.count) {
        return cell;
    }
    
    TGComboxItem *jwci = [self.items objectAtIndex:indexPath.row];
    UIImageView *iv = [[UIImageView alloc] initWithImage:jwci.image];
    iv.highlightedImage = jwci.highligtedImage;
    if (indexPath.row == 0) {
        iv.frame = CGRectMake(13, 10, 30, 30);
    }else{
        iv.frame = CGRectMake(15, 13, 24, 24);
    }
    [cell addSubview:iv];
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(55, 16, 150, 18)];
    lbl.text = jwci.title;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont systemFontOfSize:16];
    [cell addSubview:lbl];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)__unused tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)__unused tableView numberOfRowsInSection:(NSInteger)__unused section
{
    return self.items.count;
}

#pragma mark - UITableViewDelegate methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((NSUInteger)indexPath.row >= self.items.count) {
        return;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    TGComboxItem *jwci = [self.items objectAtIndex:indexPath.row];
    if([jwci.target respondsToSelector:jwci.action])
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [jwci.target performSelector:jwci.action withObject:jwci];  //加这些奇怪的pragma，只是为了去掉编译器的警告
#pragma clang diagnostic pop
    }
    [self closeWithAnimation:NO];
}

- (void)dealloc
{
    self.tvCombox.delegate = nil;
    self.tvCombox.dataSource = nil;
}

@end
