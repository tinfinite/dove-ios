//
//  TGImagesShowView.m
//  Telegraph
//
//  Created by 琦张 on 15/3/26.
//
//

#import "TGImagesShowView.h"
#import "TGImageItemView.h"

@interface TGImagesShowView ()<TGImageItemViewDelegate>

@property (nonatomic,strong) NSMutableArray *imageViewsArray;

@end

@implementation TGImagesShowView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.showsHorizontalScrollIndicator = NO;
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

#pragma mark - setter
- (void)setImages:(NSMutableArray *)images
{
    if (images != _images) {
        _images = images;
    }
    
    [self updateUserInterface];
}

#pragma mark - getter
- (NSMutableArray *)imageViewsArray
{
    if (!_imageViewsArray) {
        _imageViewsArray = [NSMutableArray array];
    }
    return _imageViewsArray;
}

#pragma mark - method
- (void)updateUserInterface
{
    [UIView animateWithDuration:0.3 animations:^{
        [self.images enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL __unused *stop) {
            NSDictionary *imageDict = (NSDictionary *)obj;
            __block TGImageItemView *item = nil;
            [self.imageViewsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger __unused idx, BOOL *stop) {
                TGImageItemView *enumItem = (TGImageItemView *)obj;
                if (imageDict == enumItem.imageDict) {
                    item = enumItem;
                    *stop = YES;
                }
            }];
            if (item==nil) {
                item = [[TGImageItemView alloc] init];
                item.imageDict = imageDict;
                item.delegate = self;
                [self addSubview:item];
                [self.imageViewsArray addObject:item];
            }
            item.frame = CGRectMake(10+idx*(self.frame.size.height-10), 10, self.frame.size.height-20, self.frame.size.height-20);
        }];
        self.contentSize = CGSizeMake(10+(self.frame.size.height-10)*self.images.count, self.frame.size.height);
    }];
}

#pragma mark - TGImageItemViewDelegate
- (void)imageItemDelete:(TGImageItemView *)item
{
    item.delegate = nil;
    [self.images removeObject:item.imageDict];
    [self.imageViewsArray removeObject:item];
    [item removeFromSuperview];
    [self updateUserInterface];
    if (self.images.count == 0 && self.updateBlock) {
        self.updateBlock();
    }
}

@end
