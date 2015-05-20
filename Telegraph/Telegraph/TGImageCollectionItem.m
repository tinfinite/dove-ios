//
//  TGImageCollectionItem.m
//  Telegraph
//
//  Created by yewei on 15/2/10.
//
//

#import "TGImageCollectionItem.h"

#import "TGImageCollectionItemView.h"

@implementation TGImageCollectionItem

- (instancetype)initWithTitle:(NSString *)title image:(NSString *)image action:(SEL)action
{
    self = [super init];
    if (self != nil)
    {
        _title = title;
        _image = image;
        _action = action;
    }
    return self;
}

- (Class)itemViewClass
{
    return [TGImageCollectionItemView class];
}

- (CGSize)itemSizeForContainerSize:(CGSize)containerSize
{
    return CGSizeMake(containerSize.width, 44);
}

- (void)bindView:(TGCollectionItemView *)view
{
    [super bindView:view];
    
    [((TGImageCollectionItemView *)view) setTitle:_title];
    [((TGImageCollectionItemView *)view) setImage:_image];
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

- (void)setTitle:(NSString *)title
{
    if (!TGStringCompare(_title, title))
    {
        _title = title;
        
        if ([self boundView] != nil)
            [((TGImageCollectionItemView *)[self boundView]) setTitle:_title];
    }
}

- (void)setImage:(NSString *)image
{
    if (!TGStringCompare(_image, image))
    {
        _image = image;
        
        if ([self boundView] != nil)
            [((TGImageCollectionItemView *)[self boundView]) setImage:_image];
    }
}

@end
