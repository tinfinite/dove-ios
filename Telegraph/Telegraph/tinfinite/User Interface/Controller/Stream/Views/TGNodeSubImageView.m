//
//  TGNodeSubImageView.m
//  Telegraph
//
//  Created by yewei on 15/3/30.
//
//

#import "TGNodeSubImageView.h"
#import "UIImageView+AFNetworking.h"
#import "OLImageResponseSerializer.h"

#import "OLImageViewDelegate.h"

@interface TGNodeSubImageView ()<OLImageViewDelegate>

@property (nonatomic, strong) UIImageView *gifImageView;

@end

@implementation TGNodeSubImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentScaleFactor = [[UIScreen mainScreen]scale];
        self.contentMode = UIViewContentModeScaleAspectFill;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor colorWithRed:234.f/255.f green:234.f/255.f blue:238.f/255.f alpha:1.0];
        self.showImageView = [[OLImageView alloc]initWithFrame:self.bounds];
        self.showImageView.imageResponseSerializer = [OLImageResponseSerializer new];
        self.showImageView.delegate = self;
        [self addSubview:self.showImageView];
        self.showImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.exclusiveTouch = YES;
        
        self.gifImageView = [[UIImageView alloc] initWithFrame:CGRectMake(frame.size.width - 40, 10, 30, 15)];
        self.gifImageView.image = [UIImage imageNamed:@"overlay_gif"];
        self.gifImageView.hidden = YES;
        [self addSubview:self.gifImageView];
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    self.showImageView.frame = self.bounds;
}

- (void)addGestureToPhotoImageView
{
    self.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTouch:)];
    tapGesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tapGesture];
}

- (void)imageTouch:(UITapGestureRecognizer *)__unused tap
{
    if ([self.imageTouchDelegate respondsToSelector:@selector(touchImageView:WithPictureObject:)]) {
        
        [self.imageTouchDelegate touchImageView:self.showImageView WithPictureObject:self.pictureObject];
    }
}

- (void)setImageWithURLWithAnimation:(NSURL *)url
{
    if ([url.absoluteString containsString:@".gif"]) {
        self.gifImageView.hidden = NO;
    }else{
        self.gifImageView.hidden = YES;
    }
    self.showImageView.image = nil;
    [self.showImageView setImageWithURL:url placeholderImage:[UIImage imageNamed:@""]];
}
- (void)clearImage
{
    self.showImageView.image = nil;
}

-(BOOL)imageViewShouldStartAnimating:(OLImageView *) __unused imageView {
    
    return NO;
}

@end
