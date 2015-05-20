//
//  TGNodeSubImageView.h
//  Telegraph
//
//  Created by yewei on 15/3/30.
//
//

#import <UIKit/UIKit.h>
#import "TGNodeImageView.h"
#import "OLImageView.h"

@interface TGNodeSubImageView : UIView

@property (nonatomic, strong) id pictureObject;
@property (nonatomic, strong) OLImageView *showImageView;
@property (nonatomic, weak) id<TGNodeImageTouchActionDelegate> imageTouchDelegate;

- (void)addGestureToPhotoImageView;
- (void)setImageWithURLWithAnimation:(NSURL *)url;
- (void)clearImage;

@end
