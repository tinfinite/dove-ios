//
//  TGDiscoverCollectionItemView.h
//  Telegraph
//
//  Created by yewei on 15/4/7.
//
//

#import "TGCollectionItemView.h"

@interface TGDiscoverCollectionItemView : TGCollectionItemView

- (void)setImageName:(NSString *)imageName;
- (void)setTitle:(NSString *)title;
- (void)setVariant:(NSString *)variant;
- (void)setUnreadCount:(NSString *)unreadCount;

@end
