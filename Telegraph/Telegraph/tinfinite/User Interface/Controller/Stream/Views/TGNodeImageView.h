//
//  TGNodeImageView.h
//  Telegraph
//
//  Created by yewei on 15/3/30.
//
//

#import <UIKit/UIKit.h>
#import "TGNodePhotoObject.h"

@class TGNodePhotoObject;
@class TGNodeSubImageView;

@protocol TGNodeImageTouchActionDelegate <NSObject>

@optional

- (void)touchImageView:(UIImageView *)imageView WithPictureObject:(id)pictureObj;

@end

@interface TGNodeImageView : UIView

@property (nonatomic, assign) NSInteger maxImageCount;
@property (nonatomic, assign) CGFloat  postImageEdgeSize;

- (id)initWithFrame:(CGRect)frame withImageCount:(NSInteger)imageCount;

- (CGFloat)setImagesWithArray:(NSArray *)imageArrays;

- (void)setDelegate:(id)delegate;

- (void)addGestureToPhotoImageView:(TGNodeSubImageView *)imageView withPhotoObject:(TGNodePhotoObject *)Obj;

+ (CGFloat)getNodeImageViewHeightByPhotoArray:(NSArray *)photoArray;

@end
