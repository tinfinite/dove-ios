//
//  TGImageItemView.m
//  Telegraph
//
//  Created by 琦张 on 15/3/26.
//
//

#import "TGImageItemView.h"
#import "TGImageInfo.h"

@interface TGImageItemView ()

@property (nonatomic,strong) UIButton *deleteButton;

@end

@implementation TGImageItemView

- (id)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor redColor];
        self.userInteractionEnabled = YES;
        self.contentMode = UIViewContentModeScaleAspectFill;
        self.clipsToBounds = YES;
        
        [self addSubview:self.deleteButton];
        
        [self.deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(5);
            make.right.equalTo(self).offset(-5);
        }];
    }
    return self;
}

#pragma mark - setter
- (void)setImageDict:(NSDictionary *)imageDict
{
    _imageDict = imageDict;
    if ([imageDict.allKeys containsObject:@"localImage"]) {
        NSDictionary *localImage = [imageDict objectForKey:@"localImage"];
        NSData *thumbData = [localImage objectForKey:@"thumbnailData"];
        self.image = [UIImage imageWithData:thumbData];
    }
}

#pragma mark - getter
- (UIButton *)deleteButton
{
    if (!_deleteButton) {
        _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_deleteButton setImage:[UIImage imageNamed:@"publish_image_delete"] forState:UIControlStateNormal];
        [_deleteButton addTarget:self action:@selector(deleteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteButton;
}

#pragma mark - method
- (void)deleteButtonPressed
{
    __strong id<TGImageItemViewDelegate> strongDelegate = self.delegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(imageItemDelete:)]) {
        [strongDelegate imageItemDelete:self];
    }
}

@end
