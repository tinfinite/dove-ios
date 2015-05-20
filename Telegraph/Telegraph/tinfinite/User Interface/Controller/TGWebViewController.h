//
//  TGWebViewController.h
//  Telegraph
//
//  Created by 琦张 on 15/3/25.
//
//

#import "TGViewController.h"

typedef enum {
    WebViewControllerTypeLogin = 1,
    WebViewControllerTypeNormal = 2
}WebViewControllerType;

@interface TGWebViewController : TGViewController

@property (nonatomic,strong) UIWebView *webView;

- (id)initWithUrl:(NSString *)url andType:(WebViewControllerType)type;

@end
