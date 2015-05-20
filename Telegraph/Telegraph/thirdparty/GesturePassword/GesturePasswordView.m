//
//  GesturePasswordView.m
//  GesturePassword
//
//  Created by hb on 14-8-23.
//  Copyright (c) 2014年 黑と白の印记. All rights reserved.
//

#import "GesturePasswordView.h"
#import "GesturePasswordButton.h"
#import "TentacleView.h"

@implementation GesturePasswordView {
    NSMutableArray * buttonArray;
    
    CGPoint lineStartPoint;
    CGPoint lineEndPoint;
    
}

@synthesize tentacleView;
@synthesize state;
@synthesize gesturePasswordDelegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        buttonArray = [[NSMutableArray alloc]initWithCapacity:0];
        
        UIView * view = [[UIView alloc]initWithFrame:CGRectMake(frame.size.width/2-140, frame.size.height/2-50, 280, 280)];
        for (int i=0; i<9; i++) {
            NSInteger row = i/3;
            NSInteger col = i%3;
            // Button Frame
            
            NSInteger distance = 280/3;
            NSInteger size = distance/1.5;
            NSInteger margin = size/4;
            GesturePasswordButton * gesturePasswordButton = [[GesturePasswordButton alloc]initWithFrame:CGRectMake(col*distance+margin, row*distance, size, size)];
            [gesturePasswordButton setTag:i];
            [view addSubview:gesturePasswordButton];
            [buttonArray addObject:gesturePasswordButton];
        }
        frame.origin.y=0;
        [self addSubview:view];
        tentacleView = [[TentacleView alloc]initWithFrame:view.frame];
        [tentacleView setButtonArray:buttonArray];
        [tentacleView setTouchBeginDelegate:self];
        [self addSubview:tentacleView];
        
        _avatarView = [[TGLetteredAvatarView alloc] initWithFrame:CGRectMake(frame.size.width/2-35, frame.size.width/2-80, 70, 70)];
        [_avatarView setSingleFontSize:17.0f doubleFontSize:17.0f useBoldFont:true];
        _avatarView.fadeTransition = true;
        [_avatarView.layer setCornerRadius:35];
        [_avatarView.layer setBorderColor:[UIColor whiteColor].CGColor];
        [_avatarView.layer setBorderWidth:1];
        [self addSubview:_avatarView];
        
        CGFloat stateOriginY = _avatarView.frame.origin.y + _avatarView.frame.size.height +5;
        
        state = [[UILabel alloc]initWithFrame:CGRectMake(frame.size.width/2-140, stateOriginY, 280, 35)];
        state.numberOfLines = 2;
        [state setTextAlignment:NSTextAlignmentCenter];
        [state setFont:[UIFont systemFontOfSize:14.f]];
        [self addSubview:state];
        
        
    }
    
    return self;
}

- (void)setUser:(TGUser *)user
{
    _user = user;
    
    CGFloat diameter = 70;
    
    static UIImage *placeholder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      UIGraphicsBeginImageContextWithOptions(CGSizeMake(diameter, diameter), false, 0.0f);
                      CGContextRef context = UIGraphicsGetCurrentContext();
                      
                      //!placeholder
                      CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
                      CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, diameter, diameter));
                      CGContextSetStrokeColorWithColor(context, UIColorRGB(0xd9d9d9).CGColor);
                      CGContextSetLineWidth(context, 1.0f);
                      CGContextStrokeEllipseInRect(context, CGRectMake(0.5f, 0.5f, diameter - 1.0f, diameter - 1.0f));
                      
                      placeholder = UIGraphicsGetImageFromCurrentImageContext();
                      UIGraphicsEndImageContext();
                  });
    
    NSString *_avatarUrl = user.photoUrlSmall;
    if (_avatarUrl.length != 0)
    {
        _avatarView.fadeTransitionDuration = 0.14;
        if (![_avatarUrl isEqualToString:_avatarView.currentUrl])
        {
            [_avatarView loadImage:_avatarUrl filter:@"circle:70x70" placeholder:placeholder];
        }
    }
    else
    {
        [_avatarView loadUserPlaceholderWithSize:CGSizeMake(diameter, diameter) uid:(int32_t)1111 firstName:_user.firstName lastName:_user.lastName placeholder:placeholder];
    }
}

- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    CGFloat colors[] =
    {
        56  / 255.0f, 174 / 255.0f, 225 / 255.0f, 1.00,
        27  / 255.0f, 134 / 255.0f, 191 / 255.0f, 1.00,
    };
    CGGradientRef gradient = CGGradientCreateWithColorComponents
    (rgb, colors, NULL, sizeof(colors)/(sizeof(colors[0])*4));
    CGColorSpaceRelease(rgb);
    CGContextDrawLinearGradient(context, gradient,CGPointMake
                                (0.0,0.0) ,CGPointMake(0.0,self.frame.size.height),
                                kCGGradientDrawsBeforeStartLocation);
}

- (void)gestureTouchBegin {
    [self.state setText:@""];
}

-(void)forget{
    [gesturePasswordDelegate forget];
}

-(void)change{
    [gesturePasswordDelegate change];
}


@end
