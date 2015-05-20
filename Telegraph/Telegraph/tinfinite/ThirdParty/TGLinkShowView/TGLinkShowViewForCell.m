//
//  TGLinkShowViewForCell.m
//  Telegraph
//
//  Created by 琦张 on 15/4/2.
//
//

#import "TGLinkShowViewForCell.h"

@implementation TGLinkShowViewForCell



- (void)configSubViews
{
    self.backgroundColor = UIColorRGB(0xffffff);
    self.layer.borderColor = [UIColorRGB(0xd0dde9) CGColor];
    self.layer.borderWidth = 0.5f;
    
    self.ready = NO;
    
    self.deleteButton.hidden = YES;
    
    [self.imgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self);
        make.top.equalTo(self);
        make.height.equalTo(@(self.frame.size.height));
        make.width.equalTo(@(self.frame.size.height));
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.imgView.mas_right).offset(8);
        make.top.equalTo(self).offset(8);
        make.right.equalTo(self).offset(-8);
    }];
    
    [self.urlLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.titleLabel);
        make.top.equalTo(self).offset(27);
        make.right.equalTo(self).offset(-8);
    }];
    
    self.descriptionLabel.numberOfLines = 3;
    [self.descriptionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.titleLabel);
        make.top.equalTo(self).offset(45);
        make.right.equalTo(self).offset(-8);
    }];
}

@end
