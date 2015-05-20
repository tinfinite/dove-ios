//
//  TGImageItemView.h
//  Telegraph
//
//  Created by 琦张 on 15/3/26.
//
//

#import <UIKit/UIKit.h>
#import "TGImageView.h"

@class TGImageItemView;

@protocol TGImageItemViewDelegate <NSObject>

- (void)imageItemDelete:(TGImageItemView *)item;

@end

@interface TGImageItemView : TGImageView

@property (nonatomic,weak) id<TGImageItemViewDelegate> delegate;
@property (nonatomic,strong) NSDictionary *imageDict;

@end
