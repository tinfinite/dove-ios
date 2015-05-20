//
//  TGLinkShowView.h
//  Telegraph
//
//  Created by 琦张 on 15/3/28.
//
//

#import <UIKit/UIKit.h>

typedef void(^linkUpdateBlock)(BOOL result);
typedef void(^linkDeleteBlock)();
typedef void(^linkOpenBlock)(NSString *urlStr);

@interface TGLinkShowView : UIView

@property (nonatomic,assign) BOOL ready;
@property (nonatomic,copy) NSString *linkUrl;
@property (nonatomic,copy) NSString *imgUrl;
@property (nonatomic,copy) NSString *titleStr;
@property (nonatomic,copy) NSString *desc;
@property (nonatomic,strong) linkUpdateBlock updateBlock;
@property (nonatomic,strong) linkDeleteBlock deleteBlock;
@property (nonatomic,strong) linkOpenBlock openBlock;

@property (nonatomic,strong) UIButton *deleteButton;
@property (nonatomic,strong) UIImageView *imgView;
@property (nonatomic,strong) UILabel *titleLabel;
@property (nonatomic,strong) UILabel *urlLabel;
@property (nonatomic,strong) UILabel *descriptionLabel;

- (void)configSubViews;
- (void)updateLinkUrl:(NSString *)url;

@end
