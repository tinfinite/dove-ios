//
//  TGDiscoverCollectionItem.m
//  Telegraph
//
//  Created by yewei on 15/4/7.
//
//

#import "TGDiscoverCollectionItem.h"
#import "TGDiscoverCollectionItemView.h"

@implementation TGDiscoverCollectionItem

- (instancetype)initWithTitle:(NSString *)title imageName:(NSString *)imageName action:(SEL)action
{
    return [self initWithTitle:title variant:nil imageName:imageName action:action];
}

- (instancetype)initWithTitle:(NSString *)title variant:(NSString *)variant imageName:(NSString *)imageName action:(SEL)action
{
    self = [super init];
    if (self != nil)
    {
        _imageName = imageName;
        _title = title;
        _variant = variant;
        _action = action;
    }
    return self;
}

- (Class)itemViewClass
{
    return [TGDiscoverCollectionItemView class];
}

- (CGSize)itemSizeForContainerSize:(CGSize)containerSize
{
    return CGSizeMake(containerSize.width, 52);
}

- (void)bindView:(TGCollectionItemView *)view
{
    [super bindView:view];
    
    [((TGDiscoverCollectionItemView *)view) setImageName:_imageName];
    [((TGDiscoverCollectionItemView *)view) setTitle:_title];
    [((TGDiscoverCollectionItemView *)view) setVariant:_variant];
    [((TGDiscoverCollectionItemView *)view) setUnreadCount:_unreadCount];
}

- (void)itemSelected:(id)actionTarget
{
    if (_action != NULL && [actionTarget respondsToSelector:_action])
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [actionTarget performSelector:_action];
#pragma clang diagnostic pop
    }
}

- (void)setImageName:(NSString *)imageName
{
    if (!TGStringCompare(_imageName, imageName))
    {
        _imageName = imageName;
        
        if ([self boundView] != nil)
            [((TGDiscoverCollectionItemView *)[self boundView]) setImageName:_imageName];
    }

}

- (void)setTitle:(NSString *)title
{
    if (!TGStringCompare(_title, title))
    {
        _title = title;
        
        if ([self boundView] != nil)
            [((TGDiscoverCollectionItemView *)[self boundView]) setTitle:_title];
    }
}

- (void)setVariant:(NSString *)variant
{
    if (!TGStringCompare(_variant, variant))
    {
        _variant = variant;
        
        if ([self boundView] != nil)
            [((TGDiscoverCollectionItemView *)[self boundView]) setVariant:_variant];
    }
}

- (void)setUnreadCount:(NSString *)unreadCount
{
    if (!TGStringCompare(_unreadCount, unreadCount))
    {
        _unreadCount = unreadCount;
        
        if ([self boundView] != nil)
            [((TGDiscoverCollectionItemView *)[self boundView]) setUnreadCount:_unreadCount];
    }
}

@end
