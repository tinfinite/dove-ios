//
//  T8HudHelper.m
//  Telegraph
//
//  Created by yewei on 15/2/12.
//
//

#import "T8HudHelper.h"
#import "MBProgressHUD.h"

@implementation T8HudHelper

+ (UIWindow *)getTopWindow
{
    for (NSUInteger i = 0; i < [UIApplication sharedApplication].windows.count; ++i) {
        UIWindow *window = [[UIApplication sharedApplication].windows objectAtIndex:i];
        if([[window description]hasPrefix:@"<UITextEffectsWindow"]) {
            return window;
        }
    }
    if (![UIApplication sharedApplication].keyWindow) {
        return [[UIApplication sharedApplication].delegate window];
    }
    return [UIApplication sharedApplication].keyWindow;
}

+ (void)showHUDMessage:(NSString *)message
{
    UIWindow *window = [T8HudHelper getTopWindow];
    MBProgressHUD *hud = [[MBProgressHUD alloc]initWithView:window];
    [window addSubview:hud];
    hud.removeFromSuperViewOnHide = YES;
    hud.labelText = message;
    hud.mode = MBProgressHUDModeText;
    [hud showWhileExecuting:@selector(delayTask) onTarget:self withObject:nil animated:YES];
}

+ (void)showHUDMessage:(NSString *)message detail:(NSString *)detail
{
    UIWindow *window = [T8HudHelper getTopWindow];
    MBProgressHUD *hud = [[MBProgressHUD alloc]initWithView:window];
    [window addSubview:hud];
    hud.removeFromSuperViewOnHide = YES;
    hud.labelText = message;
    hud.detailsLabelText = detail;
    hud.mode = MBProgressHUDModeText;
    [hud showWhileExecuting:@selector(delayTask) onTarget:self withObject:nil animated:YES];
}

+ (void)showHUDImage:(NSString *)imageName
{
    UIWindow *window = [T8HudHelper getTopWindow];
    MBProgressHUD *hud = [[MBProgressHUD alloc]initWithView:window];
    [window addSubview:hud];
    hud.removeFromSuperViewOnHide = YES;
    hud.mode = MBProgressHUDModeCustomView;
    hud.customView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:imageName]];
    [hud showWhileExecuting:@selector(delayTask) onTarget:self withObject:nil animated:YES];
}

+ (void)showHudMessage:(NSString *)message image:(NSString *)imageName
{
    UIWindow *window = [T8HudHelper getTopWindow];
    MBProgressHUD *hud = [[MBProgressHUD alloc]initWithView:window];
    [window addSubview:hud];
    hud.removeFromSuperViewOnHide = YES;
    hud.mode = MBProgressHUDModeCustomView;
    hud.labelText = message;
    hud.customView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:imageName]];
    [hud showWhileExecuting:@selector(delayTask) onTarget:self withObject:nil animated:YES];
}

+ (void)showHudMessage:(NSString *)message detail:(NSString *)detail image:(NSString *)imageName
{
    UIWindow *window = [T8HudHelper getTopWindow];
    MBProgressHUD *hud = [[MBProgressHUD alloc]initWithView:window];
    [window addSubview:hud];
    hud.removeFromSuperViewOnHide = YES;
    hud.mode = MBProgressHUDModeCustomView;
    hud.labelText = message;
    hud.detailsLabelText = detail;
    hud.customView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:imageName]];
    [hud showWhileExecuting:@selector(delayTask) onTarget:self withObject:nil animated:YES];
}

+ (void)delayTask
{
    [NSThread sleepForTimeInterval:0.8];
}

+ (void)showHUDActivity:(UIView *)parentView
{
    UIView *window = (parentView == nil ? [T8HudHelper getTopWindow] : parentView);
    MBProgressHUD *hud = [[MBProgressHUD alloc]initWithView:window];
    [window addSubview:hud];
    hud.removeFromSuperViewOnHide = YES;
    [hud show:YES];
}

+ (void)showHUDActivity:(NSString *)message parentView:(UIView *)parentView
{
    UIView *window = (parentView == nil ? [T8HudHelper getTopWindow] : parentView);
    MBProgressHUD *hud = [[MBProgressHUD alloc]initWithView:window];
    [window addSubview:hud];
    hud.removeFromSuperViewOnHide = YES;
    hud.labelText = message;
    [hud show:YES];
}
+ (void)hideHUDActivityWithoutAnimation:(UIView *)parentView{
    UIView *window = (parentView == nil ? [T8HudHelper getTopWindow] : parentView);
    [MBProgressHUD hideAllHUDsForView:window animated:NO];
}
+ (void)hideHUDActivity:(UIView *)parentView
{
    UIView *window = (parentView == nil ? [T8HudHelper getTopWindow] : parentView);
    [MBProgressHUD hideAllHUDsForView:window animated:YES];
}


@end
