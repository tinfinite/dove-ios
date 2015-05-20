//
//  TGDiscoverCollectionItem.h
//  Telegraph
//
//  Created by yewei on 15/4/7.
//
//

#import "TGCollectionItem.h"

@interface TGDiscoverCollectionItem : TGCollectionItem

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *variant;
@property (nonatomic, strong) NSString *imageName;
@property (nonatomic, strong) NSString *unreadCount;
@property (nonatomic) SEL action;

- (instancetype)initWithTitle:(NSString *)title imageName:(NSString *)imageName action:(SEL)action;
- (instancetype)initWithTitle:(NSString *)title variant:(NSString *)variant imageName:(NSString *)imageName action:(SEL)action;

@end
