//
//  TGWebViewController.m
//  Telegraph
//
//  Created by 琦张 on 15/3/25.
//
//

#import "TGWebViewController.h"
#import "TGBackdropView.h"

@interface TGWebViewController ()<UIWebViewDelegate>
{
    UIView *_background;
    UIActivityIndicatorView *_indicatorView;
}

@property (nonatomic,copy) NSString *urlStr;
@property (nonatomic,assign) WebViewControllerType type;
@property (nonatomic,strong) UILabel *titleLabel;

@end

@implementation TGWebViewController

- (id)initWithUrl:(NSString *)url andType:(WebViewControllerType)type
{
    self = [super init];
    if (self) {
        self.urlStr = url;
        self.type = type;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.type == WebViewControllerTypeLogin) {
        _background = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.width, [TGViewController isWidescreen] ? 131.0f : 90.0f)];
    }else{
        _background = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.width, 64.0f)];
    }
    //qi.zhang modify
    _background.backgroundColor = UIColorRGB(0x007de3);
    [self.view addSubview:_background];
    
    [_background addSubview:self.titleLabel];
    
    if (self.type == WebViewControllerTypeLogin) {
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(_background);
            make.centerY.equalTo(_background.mas_top).offset(85);
            make.width.equalTo(@([UIScreen mainScreen].bounds.size.width-160));
        }];
    }else{
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(_background);
            make.centerY.equalTo(_background.mas_top).offset(42);
            make.width.equalTo(@([UIScreen mainScreen].bounds.size.width-160));
        }];
        self.titleLabel.numberOfLines = 1;
        [self setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"· · ·" style:UIBarButtonItemStyleDone target:self action:@selector(sharePressed)]];
    }
    
    [self.view addSubview:self.webView];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.urlStr]]];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    _indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    _indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    _indicatorView.center = self.view.center;
    _indicatorView.hidesWhenStopped = YES;
    [_indicatorView startAnimating];
    [self.view addSubview:_indicatorView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.navigationController.navigationBar.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger __unused idx, BOOL __unused *stop) {
        if ([obj isKindOfClass:[UIView class]]) {
            UIView *view = (UIView *)obj;
            [view.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger __unused idx, BOOL __unused *stop) {
                if ([obj isKindOfClass:[TGBackdropView class]]) {
                    [(TGBackdropView *)obj setHidden:YES];
                }
            }];
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.navigationController.navigationBar.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger __unused idx, BOOL __unused *stop) {
        if ([obj isKindOfClass:[UIView class]]) {
            UIView *view = (UIView *)obj;
            [view.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger __unused idx, BOOL __unused *stop) {
                if ([obj isKindOfClass:[TGBackdropView class]]) {
                    [(TGBackdropView *)obj setHidden:NO];
                }
            }];
        }
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - getter
- (UIWebView *)webView
{
    if (!_webView) {
        _webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, _background.frame.size.height, self.view.bounds.size.width, self.view.bounds.size.height-_background.frame.size.height)];
        _webView.delegate = self;
        _webView.dataDetectorTypes = UIDataDetectorTypeNone;
        _webView.backgroundColor = [UIColor whiteColor];
        for (UIView *subView in [_webView subviews]) {
            if ([subView isKindOfClass:[UIScrollView class]]) {
                for (UIView *shadowView in [subView subviews]) {
                    if ([shadowView isKindOfClass:[UIImageView class]]) {
                        shadowView.hidden = YES;
                    }
                }
            }
        }
    }
    return _webView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:self.type==WebViewControllerTypeLogin?24.0f:20.0f];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.numberOfLines = 0;
    }
    return _titleLabel;
}

#pragma mark - UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // 禁用用户选择
    [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserSelect='none';"];
    
    // 禁用长按弹出框
    [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout='none';"];
    
    self.titleLabel.text = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    
    [_indicatorView stopAnimating];
}

#pragma mark - method
- (void)sharePressed
{
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL URLWithString:self.urlStr]] applicationActivities:nil];
    [self presentViewController:activity animated:YES completion:nil];
}

@end
