#import <Foundation/Foundation.h>

typedef enum {
    PickerSheetTypeTime = 1,
    PickerSheetTypeLanguage = 2
}PickerSheetType;

@interface TGPickerSheet : NSObject

@property (nonatomic, strong) NSString *emptyValue;
@property (nonatomic, assign) NSUInteger selectedIndex;

- (instancetype)initWithItems:(NSArray *)items selectedIndex:(NSUInteger)selectedIndex action:(void (^)(id item))action;
- (instancetype)initWithItems:(NSArray *)items selectedIndex:(NSUInteger)selectedIndex type:(PickerSheetType)type action:(void (^)(id item))action;

- (void)show;
- (void)showFromRect:(CGRect)rect inView:(UIView *)view;
- (void)dismiss;

@end
