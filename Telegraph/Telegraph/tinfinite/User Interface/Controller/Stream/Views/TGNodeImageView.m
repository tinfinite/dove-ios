//
//  TGNodeImageView.m
//  Telegraph
//
//  Created by yewei on 15/3/30.
//
//

#import "TGNodeImageView.h"
#import "TGNodeSubImageView.h"
#import "UIViewAdditions.h"

const CGFloat kTGNodeCellImageEdgeSize = 70.f;
const CGFloat kTGNodeCellImageGap = 5.0f;

@implementation TGNodeImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.maxImageCount = 5;
        self.postImageEdgeSize = kTGNodeCellImageEdgeSize;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame withImageCount:(NSInteger)imageCount
{
    if (self = [super initWithFrame:frame]) {
        self.maxImageCount = imageCount;
        self.postImageEdgeSize = kTGNodeCellImageEdgeSize;
    }
    return self;
}

- (CGFloat)setImagesWithArray:(NSArray *)imageArrays
{
    [self removeSubviews];
    
    self.userInteractionEnabled = YES;
    
    if (imageArrays.count <= 0) {
        return 0;
    }else if (imageArrays.count == 1) {
        TGNodePhotoObject *photoObj = [imageArrays objectAtIndex:0];
        if (photoObj.largeHeight == 0)
        {
            photoObj.largeHeight = [NSNumber numberWithDouble:SCREEN_WIDTH - 20];
            photoObj.largeWidth = [NSNumber numberWithDouble:SCREEN_WIDTH - 20];
        }
        CGSize imageSize = CGSizeZero;
        
        NSString *url = photoObj.originUrl;
        
        imageSize = [self getImageSize:photoObj];
        TGNodeSubImageView *photoImageView = [[TGNodeSubImageView alloc]initWithFrame:CGRectMake(0, 0, imageSize.width, imageSize.height)];
        [self addGestureToPhotoImageView:photoImageView withPhotoObject:photoObj];
        [photoImageView setImageWithURLWithAnimation:[NSURL URLWithString:url]];
        [self addSubview:photoImageView];
        return imageSize.height;
    }else {
        CGFloat width = 0.f;
        NSInteger verticalRow = 0;//图片有几列
        NSInteger  row = 0;
        if (imageArrays.count == 2 || imageArrays.count == 4) {
            width = (self.width - kTGNodeCellImageGap)/2.f;
            verticalRow = 2;
            row = imageArrays.count/2;
        }else{
            width = (self.width - kTGNodeCellImageGap*2)/3.f;
            verticalRow = 3;
            row = ceil((CGFloat)imageArrays.count/3.f);
        }
        CGFloat height = width;
        [imageArrays enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL __unused *stop) {
            TGNodePhotoObject *photoObj = (TGNodePhotoObject *)obj;
            CGRect rect = CGRectMake( (idx%verticalRow)*(kTGNodeCellImageGap+width),(idx/verticalRow)*(kTGNodeCellImageGap +height), width, height);
            TGNodeSubImageView *imageView = [[TGNodeSubImageView alloc]initWithFrame:rect];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            [self addGestureToPhotoImageView:imageView withPhotoObject:photoObj];
            [imageView setImageWithURLWithAnimation:[NSURL URLWithString:photoObj.originUrl]];
            [self addSubview:imageView];
        }];
        return (row * height + (row - 1)*kTGNodeCellImageGap);
    }
    return 0;
}

- (void)addGestureToPhotoImageView:(TGNodeSubImageView *)imageView withPhotoObject:(TGNodePhotoObject *)photoObj
{
    [imageView setPictureObject:photoObj];
    [imageView addGestureToPhotoImageView];
}

- (void)setDelegate:(id)delegate
{
    for (NSUInteger index = 0; index < self.subviews.count; index ++)
    {
        UIImage *subView = [self.subviews objectAtIndex:index];
        if ([subView isKindOfClass:[TGNodeSubImageView class]])
        {
            ((TGNodeSubImageView *)subView).imageTouchDelegate = delegate;
        } 
    }
}

- (CGSize)getImageSize:(TGNodePhotoObject *)photoObj
{
    const CGFloat kSinglePhotoMaxWidth = (SCREEN_WIDTH - 30);
    const CGFloat kSinglePhotoMaxHeight = (SCREEN_WIDTH - 30);
    
    CGFloat imageWidth = photoObj.largeWidth.intValue;
    CGFloat imageHeight = photoObj.largeHeight.intValue;
    
    CGFloat ratio = imageWidth/imageHeight;//宽高比
    
    if (ratio <= (1.0/3.0))
    {
        if (imageHeight > kSinglePhotoMaxHeight) {
            imageHeight = kSinglePhotoMaxHeight;
            imageWidth = imageHeight * ratio;
            return CGSizeMake(imageWidth, imageHeight);
        }
    }else if(ratio >= 3.0 ){
        if (imageWidth > kSinglePhotoMaxWidth) {
            imageWidth = kSinglePhotoMaxWidth;
            imageHeight = imageWidth / ratio;
            return CGSizeMake(imageWidth, imageHeight);
        }
    }else if(ratio >= 1){
        if (imageWidth > kSinglePhotoMaxHeight) {
            CGFloat scale = photoObj.largeWidth.intValue/kSinglePhotoMaxWidth;
            imageWidth = kSinglePhotoMaxWidth;
            imageHeight = photoObj.largeHeight.integerValue/scale;
            return CGSizeMake(imageWidth, imageHeight);
        }
    }
    
    if (imageHeight > kSinglePhotoMaxHeight) {
        CGFloat h_scale = photoObj.largeHeight.intValue/kSinglePhotoMaxHeight;
        imageHeight = kSinglePhotoMaxHeight;
        imageWidth = photoObj.largeWidth.intValue/h_scale;
    }
    
    return CGSizeMake(imageWidth, imageHeight);
}

+ (CGFloat)getNodeImageViewHeightByPhotoArray:(NSArray *)photoArray
{
    NSInteger photoCount = photoArray.count;
    CGFloat height = 0.f;
    switch (photoCount) {
        case 0:
            height = 0.f;
        case 1:
        {
            const CGFloat kSinglePhotoMaxWidth = (SCREEN_WIDTH - 30);
            const CGFloat kSinglePhotoMaxHeight = (SCREEN_WIDTH - 30);

            TGNodePhotoObject *photoObj = [photoArray objectAtIndex:0];
            
            CGFloat imageWidth = photoObj.largeWidth.intValue;
            CGFloat imageHeight = photoObj.largeHeight.intValue;
            
            CGFloat ratio = imageWidth/imageHeight;//宽高比
            
            if (ratio <= (1.0/3.0))
            {
                if (imageHeight > kSinglePhotoMaxHeight) {
                    return kSinglePhotoMaxHeight;
                }
            }else if(ratio >= 3.0 ){
                if (imageWidth > kSinglePhotoMaxWidth) {
                    imageHeight = kSinglePhotoMaxHeight / ratio;
                }
            }else if(ratio >= 1){
                if (imageWidth > kSinglePhotoMaxHeight) {
                    CGFloat scale = photoObj.largeWidth.intValue/kSinglePhotoMaxWidth;
                    imageWidth = kSinglePhotoMaxWidth;
                    imageHeight = photoObj.largeHeight.integerValue/scale;
                    return imageHeight;
                }
            }
            
            if (imageHeight > kSinglePhotoMaxHeight) {
                return kSinglePhotoMaxHeight;
            }
            
            return imageHeight;
        }
            break;
        default:{
            CGFloat imageHeight = 0.f;
            NSInteger verticalRow = 0;//图片有几列
            NSInteger  row = 0;
            if (photoCount == 2 || photoCount == 4) {
                imageHeight = (SCREEN_WIDTH - 30 - kTGNodeCellImageGap)/2.f;
                verticalRow = 2;
                row = photoCount/2;
            }else{
                imageHeight = (SCREEN_WIDTH - 30 - kTGNodeCellImageGap*2)/3.f;
                verticalRow = 3;
                row = ceil((CGFloat)photoCount/3.f);
            }
            height = (row * imageHeight + (row - 1)*kTGNodeCellImageGap);
        }
            break;
    }
    return height;
}

@end
