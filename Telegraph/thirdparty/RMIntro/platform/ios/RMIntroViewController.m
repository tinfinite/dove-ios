//
//  RMIntroViewController.m
//  IntroOpenGL
//
//  Created by Ilya Rimchikov on 19/01/14.
//
//

#define IPAD     UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad

#define dDeviceOrientation [[UIDevice currentDevice] orientation]
#define isPortrait  UIDeviceOrientationIsPortrait(dDeviceOrientation)
#define isLandscape UIDeviceOrientationIsLandscape(dDeviceOrientation)

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define _(n) NSLocalizedString(n, nil)

#import "RMGeometry.h"

#import "TGLoginPhoneController.h"
#import "TGModernButton.h"

#import "RMIntroViewController.h"
#import "RMIntroPageView.h"

#include "animations.h"
#include "objects.h"
#include "texture_helper.h"

#include "TGAppDelegate.h"

#import "TGTelegramNetworking.h"

@interface UIScrollView (CurrentPage)
- (int)currentPage;
- (void)setPage:(NSInteger)page;
- (int)currentPageMin;
- (int)currentPageMax;

@end
@implementation UIScrollView (CurrentPage)
- (int)currentPage{
    CGFloat pageWidth = self.frame.size.width;
    return floor((self.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
}

- (int)currentPageMin{
    CGFloat pageWidth = self.frame.size.width;
    return floor((self.contentOffset.x - pageWidth / 2 - pageWidth / 2) / pageWidth) + 1;
}

- (int)currentPageMax{
    CGFloat pageWidth = self.frame.size.width;
    return floor((self.contentOffset.x - pageWidth / 2 + pageWidth / 2 ) / pageWidth) + 1;
}

- (void)setPage:(NSInteger)page
{
    self.contentOffset = CGPointMake(self.frame.size.width*page, 0);
}
@end


@interface RMIntroViewController () <UIGestureRecognizerDelegate>
{
    id _didEnterBackgroundObserver;
    id _willEnterBackgroundObserver;
    
    UIImageView *_stillLogoView;
    bool _displayedStillLogo;
    
    UIButton *_switchToDebugButton;
    
    
}

@end

@implementation RMIntroViewController



@synthesize rootVC;
@synthesize draw_q;


- (id)init
{
    self = [super init];
    if (self) {
        
        if (iosMajorVersion() >= 7)
            self.automaticallyAdjustsScrollViewInsets = false;
        
        _headlines = @[_(@"Tour.Title1"), _(@"Tour.Title2"),  _(@"Tour.Title3"), _(@"Tour.Title4")];
        _descriptions = @[_(@"Tour.Text1"), _(@"Tour.Text2"),  _(@"Tour.Text3"), _(@"Tour.Text4")];
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
#if defined(DEBUG) || defined(INTERNAL_RELEASE)
    [self.view addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(switchToDebugPressed:)]];
#endif
}

- (void)switchToDebugPressed:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        if (_switchToDebugButton == nil)
        {
            _switchToDebugButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, self.view.frame.size.height - 45.0f, self.view.frame.size.width, 45.0f)];
            _switchToDebugButton.backgroundColor = [UIColor grayColor];
            [_switchToDebugButton setTitle:!TGAppDelegateInstance.useDifferentBackend ? @"Switch to production" : @"Switch to debug" forState:UIControlStateNormal];
            [_switchToDebugButton addTarget:self action:@selector(reallySwitchToDebugPressed) forControlEvents:UIControlEventTouchUpInside];
            [self.view removeGestureRecognizer:recognizer];
            [self.view addSubview:_switchToDebugButton];
        }
    }
}

- (void)reallySwitchToDebugPressed
{
    [[TGTelegramNetworking instance] switchBackends];
}

- (CGRect)windowBounds
{
    CGRect r = CGRectZero;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        UIInterfaceOrientation isVertical = (self.view.bounds.size.height/self.view.bounds.size.width > 1.) ? YES : NO;
        
        if (isVertical) {
            r = CGRectMake(0, 0, 768, 1024);
        }
        else
        {
            r = CGRectMake(0, 0, 1024, 768);
        }
    }
    else
    {
        int max = (int)[[UIScreen mainScreen] bounds].size.height;

        switch (max) {
            case 480:
                _deviceScreen = Inch35;
                break;
            case 568:
                _deviceScreen = Inch4;
                break;
            case 667:
                _deviceScreen = Inch47;
                break;
            default:
                _deviceScreen = Inch55;
                break;
        }
        
        r = [[UIScreen mainScreen] bounds];
        
    }
    return r;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    _pageScrollView = [[UIScrollView alloc]initWithFrame:[self windowBounds]];
    _pageScrollView.clipsToBounds=YES;
    _pageScrollView.opaque=YES;
    _pageScrollView.clearsContextBeforeDrawing=NO;
    [_pageScrollView setShowsHorizontalScrollIndicator:NO];
    [_pageScrollView setShowsVerticalScrollIndicator:NO];
    _pageScrollView.pagingEnabled = YES;
    _pageScrollView.contentSize=CGSizeMake(_headlines.count*[self windowBounds].size.width, [self windowBounds].size.height);
    _pageScrollView.delegate = self;
    [self.view addSubview:_pageScrollView];
    
    
    _pageViews = [NSMutableArray array];
    for (NSUInteger i=0; i<_headlines.count; i++) {
        RMIntroPageView *p = [[RMIntroPageView alloc]initWithFrame:CGRectMake(i*[self windowBounds].size.width, 0, [self windowBounds].size.width, 0) headline:[_headlines objectAtIndex:i] description:[_descriptions objectAtIndex:i]];
        p.opaque=YES;
        p.clearsContextBeforeDrawing=NO;
        [_pageViews addObject:p];
        [_pageScrollView addSubview:p];
    }
    [_pageScrollView setPage:0];
    
    _startButton = [[TGModernButton alloc] init];
    ((TGModernButton *)_startButton).modernHighlight = true;
    [_startButton setTitle:_(@"Tour.StartButton") forState:UIControlStateNormal];
    [_startButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:IPAD? 55/2. : 21]];
    [_startButton setTitleColor:UIColorFromRGB(0x007ee5) forState:UIControlStateNormal];
    _startArrow = [[UIImageView alloc]initWithImage:[UIImage imageNamed:IPAD ? @"start_arrow_ipad.png" : @"start_arrow.png"]];
    _startButton.titleLabel.clipsToBounds=NO;
    
    
    _startArrow.frame = CGRectChangedOrigin(_startArrow.frame, CGPointMake([_startButton.titleLabel.text sizeWithFont:_startButton.font].width+ (IPAD ? 7 : 6), IPAD ? 6.5 : 4.5));
    [_startButton.titleLabel addSubview:_startArrow];
    [self.view addSubview:_startButton];
    
    
    _pageControl = [[UIPageControl alloc]init];
    _pageControl.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    _pageControl.userInteractionEnabled=NO;
    [_pageControl setPageIndicatorTintColor:[UIColor colorWithWhite:.85 alpha:1]];
    [_pageControl setCurrentPageIndicatorTintColor:[UIColor colorWithWhite:.2 alpha:1]];
    [_pageControl setNumberOfPages:4];
    [self.view addSubview:_pageControl];
    
    if (IPAD) {
        _separatorView = [[UIView alloc]init];
        _separatorView.backgroundColor = UIColorFromRGB(0xc8c8cc);
        [self.view addSubview:_separatorView];
    }
}

- (void)viewWillLayoutSubviews
{
    UIInterfaceOrientation isVertical = (self.view.bounds.size.height/self.view.bounds.size.width > 1.) ? YES : NO;
    int originY;
    
    int status_height = [[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] integerValue] >=7 ? 0 : 20;
    int w = 1046/2;
    
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    _separatorView.frame = CGRectMake([self windowBounds].size.width/2-w/2, [self windowBounds].size.height-248/2 - status_height, w, (screenScale>1) ? .5 : 1.);
    _separatorView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    
    originY = 162/2;
    if (IPAD)
    {
        originY = 386/2;
    }
    else
    {
        switch (_deviceScreen) {
            case Inch35:
                originY = 162/2;
                break;
            case Inch4:
                originY = 162/2;
                break;
            case Inch47:
                originY = 162/2+10;
                break;
            case Inch55:
                originY = 162/2+20;
                break;
            default:
                break;
        }
    }
    _pageControl.frame = CGRectMake(0, [self windowBounds].size.height - originY - status_height, [self windowBounds].size.width, 7);
    
    originY = 62;
    if (IPAD)
    {
        if (isVertical) {
            originY = 121+90;
        }
        else
        {
            originY = 121;
        }
    }
    else
    {
        switch (_deviceScreen) {
            case Inch35:
                NSLog(@"Inch35");
                originY = 62-20;
                break;
            case Inch4:
                NSLog(@"Inch4");
                originY = 62;
                break;
            case Inch47:
                NSLog(@"Inch47");
                originY = 62+25;
                break;
            case Inch55:
                NSLog(@"Inch55");
                originY = 62+45;
                break;
            default:
                break;
        }
    }
    
    _glkView.frame = CGRectChangedOriginY(_glkView.frame, originY - status_height);
    
    originY = 75;
    if (IPAD)
    {
        originY = 120;//99;
    }
    else
    {
        switch (_deviceScreen) {
            case Inch35:
                originY = 75;
                break;
            case Inch4:
                originY = 75;
                break;
            case Inch47:
                originY = 75+5;
                break;
            case Inch55:
                originY = 75+20;
                break;
            default:
                break;
        }
    }
    _startButton.frame = CGRectMake(0-9, [self windowBounds].size.height - originY - status_height, [self windowBounds].size.width, originY-4);
    [_startButton addTarget:self action:@selector(startButtonPress) forControlEvents:UIControlEventTouchUpInside];
    
    _pageScrollView.frame=CGRectMake(0, 20, [self windowBounds].size.width, [self windowBounds].size.height - 20);
    _pageScrollView.contentSize=CGSizeMake(_headlines.count*[self windowBounds].size.width, 150);
    _pageScrollView.contentOffset = CGPointMake(_currentPage*[self windowBounds].size.width, 0);
    
    
    int i=0;
    
    originY = 245;
    if (IPAD)
    {
        if (isVertical) {
            originY = 485;
        }
        else
        {
            originY = 335;
        }
    }
    else
    {
        switch (_deviceScreen) {
            case Inch35:
                originY = 215;
                break;
            case Inch4:
                originY = 245;
                break;
            case Inch47:
                originY = 245+50;
                break;
            case Inch55:
                originY = 245+85;
                break;
            default:
                break;
        }
    }
    
    for (RMIntroPageView *p in _pageViews) {
        p.frame = CGRectMake(i*[self windowBounds].size.width, (originY-status_height), [self windowBounds].size.width, 150);
        i++;
    }
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_stillLogoView == nil && !_displayedStillLogo)
    {
        _displayedStillLogo = true;
        
        CGFloat verticalOffset = 0.0f;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        {
            if ([TGViewController isWidescreen])
                verticalOffset = 87.0f;
            else
                verticalOffset = 67.0f;
        }
        else
        {
            verticalOffset = (self.view.frame.size.width > 768 + FLT_EPSILON) ? 131.0f : 221.0f;
        }
        
        _stillLogoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"dove_logo_still.png"]];
        _stillLogoView.contentMode = UIViewContentModeCenter;
        _stillLogoView.bounds = CGRectMake(0, 0, 200, 200);
        _stillLogoView.frame = (CGRect){CGPointMake((self.view.frame.size.width - _stillLogoView.frame.size.width) / 2.0f, verticalOffset), _stillLogoView.frame.size};
        
        UIInterfaceOrientation isVertical = (self.view.bounds.size.height/self.view.bounds.size.width > 1.) ? YES : NO;
        
        int status_height = [[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] integerValue] >=7 ? 0 : 20;
        
        int originY;
        originY = 62;
        if (IPAD)
        {
            if (isVertical) {
                originY = 121+90;
            }
            else
            {
                originY = 121;
            }
        }
        else
        {
            switch (_deviceScreen) {
                case Inch35:
                    //NSLog(@"Inch35");
                    originY = 62-20;
                    break;
                case Inch4:
                    //NSLog(@"Inch4");
                    originY = 62;
                    break;
                case Inch47:
                    //NSLog(@"Inch47");
                    originY = 62+25;
                    break;
                case Inch55:
                    //NSLog(@"Inch55");
                    originY = 62+45;
                    break;
                default:
                    break;
            }
        }
        
//        _stillLogoView.frame = CGRectChangedOriginY(_glkView.frame, originY - status_height);
        
        [self.view addSubview:_stillLogoView];
    }
}

- (void)startButtonPress
{
    TGLoginPhoneController *phoneController = [[TGLoginPhoneController alloc] init];
    [self.navigationController pushViewController:phoneController animated:true];
}

- (NSString*)convertOrientationToString:(UIInterfaceOrientation)orientation {
    NSString *result = nil;
    
    typedef NS_ENUM(NSInteger, UIInterfaceOrientation) {
        UIInterfaceOrientationPortrait           = UIDeviceOrientationPortrait,
        UIInterfaceOrientationPortraitUpsideDown = UIDeviceOrientationPortraitUpsideDown,
        UIInterfaceOrientationLandscapeLeft      = UIDeviceOrientationLandscapeRight,
        UIInterfaceOrientationLandscapeRight     = UIDeviceOrientationLandscapeLeft
    };
    
    switch(orientation) {
        case UIInterfaceOrientationPortrait:
            result = @"UIInterfaceOrientationPortrait";
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            result = @"UIInterfaceOrientationPortraitUpsideDown";
            break;
        case UIInterfaceOrientationLandscapeLeft:
            result = @"UIInterfaceOrientationLandscapeLeft";
            break;
        case UIInterfaceOrientationLandscapeRight:
            result = @"UIInterfaceOrientationLandscapeRight";
            break;
            
        default:
            result = @"unknown";
    }
    
    return result;
}

static CGFloat x;
static bool justEndDragging;


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    x=scrollView.contentOffset.x;
    justEndDragging=YES;
}

int _current_page_end;

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    float offset = (scrollView.contentOffset.x - _currentPage*[self windowBounds].size.width)/self.view.frame.size.width;
    
    set_scroll_offset(offset);
    
    if (justEndDragging) {
        justEndDragging=NO;
        
        CGFloat page = scrollView.contentOffset.x/[self windowBounds].size.width;
        CGFloat sign = scrollView.contentOffset.x - x;
        
        if (sign>0) {
            if (page>_currentPage) {
                _currentPage++;
            }
        }
        
        if (sign<0) {
            if (page<_currentPage) {
                _currentPage--;
            }
        }
        
        _currentPage = MAX(0, MIN(4, _currentPage));
        _current_page_end = _currentPage;
    }
    else
    {
        if (_pageScrollView.contentOffset.x > _current_page_end*_pageScrollView.frame.size.width) {
            if (_pageScrollView.currentPageMin > _current_page_end) {
                _currentPage = [_pageScrollView currentPage];
                _current_page_end = _currentPage;
            }
        }
        else
        {
            if (_pageScrollView.currentPageMax < _current_page_end) {
                _currentPage = [_pageScrollView currentPage];
                _current_page_end = _currentPage;
            }
        }
    }
    
    if (_currentPage == 1) {
        _stillLogoView.image = [UIImage imageNamed:@"telegram_logo_still"];
    }else{
        _stillLogoView.image = [UIImage imageNamed:@"dove_logo_still"];
    }
    
    [_pageControl setCurrentPage:_currentPage];
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
