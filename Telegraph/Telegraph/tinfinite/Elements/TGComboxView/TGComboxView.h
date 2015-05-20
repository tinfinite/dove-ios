//
//  TGComboxView.h
//  Telegraph
//
//  Created by yewei on 15/4/27.
//
//

#import <UIKit/UIKit.h>

@interface TGComboxItem : NSObject

@property (readwrite, nonatomic, strong) UIImage *image;
@property (readwrite, nonatomic, strong) UIImage *highligtedImage;
@property (readwrite, nonatomic, strong) NSString *title;
@property (readwrite, nonatomic, weak) id target;
@property (readwrite, nonatomic) SEL action;
@property (readwrite, nonatomic, strong) UIColor *foreColor;
@property (readwrite, nonatomic) NSTextAlignment alignment;

+ (id) menuItem:(NSString *) title
          image:(UIImage *) image
highligtedImage:(UIImage *)image
         target:(id)target
         action:(SEL) action;

@end

@interface TGComboxView : UIView<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) UIView *backgroundView;
@property (nonatomic, retain) UITableView *tvCombox;
@property (nonatomic, retain) UIButton *btnAllWindow;
@property (nonatomic, retain) NSArray *items;

- (id)initWithItems:(NSArray *)items;

+ (void)showPopComBoxWithParentView:(UIView *)parentView items:(NSArray *)items xRightOffset:(CGFloat)xRightOffset yTopOffset:(CGFloat)yTopOffset;

@end
