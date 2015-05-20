//
//  T8HudHelper.h
//  Telegraph
//
//  Created by yewei on 15/2/12.
//
//

#import <Foundation/Foundation.h>

@interface T8HudHelper : NSObject

+ (UIWindow *)getTopWindow;
+ (void)showHUDMessage:(NSString *)message;
+ (void)showHUDMessage:(NSString *)message detail:(NSString *)detail;
+ (void)showHUDImage:(NSString *)imageName;
+ (void)showHudMessage:(NSString *)message image:(NSString *)imageName;
+ (void)showHudMessage:(NSString *)message detail:(NSString *)detail image:(NSString *)imageName;

+ (void)showHUDActivity:(UIView *)parentView;
+ (void)showHUDActivity:(NSString *)message parentView:(UIView *)parentView;
+ (void)hideHUDActivity:(UIView *)parentView;
+ (void)hideHUDActivityWithoutAnimation:(UIView *)parentView;

@end
