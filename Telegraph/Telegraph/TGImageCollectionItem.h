//
//  TGImageCollectionItem.h
//  Telegraph
//
//  Created by yewei on 15/2/10.
//
//

#import "TGCollectionItem.h"

@interface TGImageCollectionItem : TGCollectionItem

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *image;
@property (nonatomic) SEL action;

- (instancetype)initWithTitle:(NSString *)title image:(NSString *)image action:(SEL)action;

@end
