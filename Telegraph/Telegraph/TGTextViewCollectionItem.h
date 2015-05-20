#import "TGCollectionItem.h"

@interface TGTextViewCollectionItem : TGCollectionItem

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *placeHolder;
@property (nonatomic, copy) void (^textChanged)(NSString *);

- (instancetype)initWithNumberOfLines:(NSUInteger)numberOfLines;

@end
