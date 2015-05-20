//
//  GesturePasswordController.m
//  GesturePassword
//
//  Created by hb on 14-8-23.
//  Copyright (c) 2014年 黑と白の印记. All rights reserved.
//

#import <Security/Security.h>
#import <CoreFoundation/CoreFoundation.h>

#import "GesturePasswordController.h"
#import "TGAppDelegate.h"
#import "TGDatabase.h"
#import "TGBackdropView.h"

#import "KeychainItemWrapper/KeychainItemWrapper.h"

#define kGesturePassword @"kGesturePassword"

@interface GesturePasswordController ()

@property (nonatomic,strong) GesturePasswordView * gesturePasswordView;
@property (nonatomic,strong) UINavigationBar *navigationBar;

@end

@implementation GesturePasswordController {
    NSString * previousString;
    NSString * password;
    int32_t _uid;
    TGUser *_user;
}

@synthesize gesturePasswordView;

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationBar = self.navigationController.navigationBar;

    [self.navigationController.navigationBar.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger __unused idx, BOOL __unused *stop) {
        if ([obj isKindOfClass:[UIView class]]) {
            UIView *view = (UIView *)obj;
            [view.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger __unused idx, BOOL __unused *stop) {
                ((UIView *)obj).backgroundColor = [UIColor clearColor];
            }];
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController.navigationBar.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger __unused idx, BOOL __unused *stop) {
        if ([obj isKindOfClass:[UIView class]]) {
            UIView *view = (UIView *)obj;
            [view.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger __unused idx, BOOL __unused *stop) {
                if ([obj isKindOfClass:[TGBackdropView class]]) {
                    ((TGBackdropView *)obj).backgroundColor = UIColorRGBA(0x008DF2, 1.0f);
                }
            }];
        }
    }];

    
    [super viewWillDisappear:animated];
}

- (id)initWithUid:(int32_t)uid
{
    self = [super init];
    if (self) {
        _uid = uid;
    }
    return self;
}

- (id)initWithGesturePasswordType:(GesturePasswordType)type uid:(int32_t)uid
{
    self = [super init];
    if (self) {
        self.type = type;
        _uid = uid;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _user = [TGDatabaseInstance() loadUser:_uid];
    
    previousString = [NSString string];
    password = [[NSUserDefaults standardUserDefaults] objectForKey:kGesturePassword];
    if (!password) {
        
        [self reset];
    }
    else {
        [self verify];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - 验证手势密码
- (void)verify{
    gesturePasswordView = [[GesturePasswordView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    if (self.type == GesturePasswordTypeDelete) {
        [gesturePasswordView.state setTextColor:[UIColor whiteColor]];
        [gesturePasswordView.state setText:TGLocalized(@"GesturePassword.Notice_4")];
    }
    gesturePasswordView.user = _user;
    [gesturePasswordView.tentacleView setRerificationDelegate:self];
    [gesturePasswordView.tentacleView setStyle:1];
    [gesturePasswordView setGesturePasswordDelegate:self];
    [self.view addSubview:gesturePasswordView];
}

#pragma mark - 重置手势密码
- (void)reset{
    gesturePasswordView = [[GesturePasswordView alloc] initWithFrame:[UIScreen mainScreen].bounds];

    [gesturePasswordView.state setTextColor:[UIColor whiteColor]];
    [gesturePasswordView.state setText:TGLocalized(@"GesturePassword.Notice_1")];
    gesturePasswordView.user = _user;
    [gesturePasswordView.tentacleView setResetDelegate:self];
    [gesturePasswordView.tentacleView setStyle:2];
    [self.view addSubview:gesturePasswordView];
}

#pragma mark - 判断是否已存在手势密码
- (BOOL)exist{
//    KeychainItemWrapper * keychin = [[KeychainItemWrapper alloc]initWithIdentifier:@"Gesture" accessGroup:nil];
//    password = [keychin objectForKey:(__bridge id)kSecValueData];
    password = [[NSUserDefaults standardUserDefaults] objectForKey:kGesturePassword];
    if (!password)return NO;
    return YES;
}

#pragma mark - 清空记录
- (void)clear{
//    KeychainItemWrapper * keychin = [[KeychainItemWrapper alloc]initWithIdentifier:@"Gesture" accessGroup:nil];
//    [keychin resetKeychainItem];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kGesturePassword];
}

#pragma mark - 改变手势密码
- (void)change{
    
}

#pragma mark - 忘记手势密码
- (void)forget{
    
}

- (BOOL)verification:(NSString *)result{
    if ([result isEqualToString:password]) {
        [gesturePasswordView.state setTextColor:[UIColor colorWithRed:2/255.f green:174/255.f blue:240/255.f alpha:1]];
//        [gesturePasswordView.state setText:@"输入正确"];
        if (self.type == GesturePasswordTypeDelete) {
            [self clear];
            
            TGAppDelegateInstance.autoGesturePassword = false;
            [TGAppDelegateInstance saveSettings];

            [self.navigationController popViewControllerAnimated:YES];
        }
        [self dismissViewControllerAnimated:NO completion:nil];
        return YES;
    }
    [gesturePasswordView.state setTextColor:[UIColor redColor]];
    [gesturePasswordView.state setText:TGLocalized(@"GesturePassword.Notice_5")];
    return NO;
}

- (BOOL)resetPassword:(NSString *)result{
    if ([previousString isEqualToString:@""]) {
        previousString=result;
        [gesturePasswordView.tentacleView enterArgin];
        [gesturePasswordView.state setTextColor:[UIColor whiteColor]];
        [gesturePasswordView.state setText:TGLocalized(@"GesturePassword.Notice_2")];
        return YES;
    }
    else {
        if ([result isEqualToString:previousString]) {
//            KeychainItemWrapper * keychin = [[KeychainItemWrapper alloc]initWithIdentifier:@"Gesture" accessGroup:nil];
//            [keychin setObject:@"<帐号>" forKey:(__bridge id)kSecAttrAccount];
//            [keychin setObject:result forKey:(__bridge id)kSecValueData];
            [[NSUserDefaults standardUserDefaults] setObject:result forKey:kGesturePassword];
            [gesturePasswordView.state setTextColor:[UIColor colorWithRed:2/255.f green:174/255.f blue:240/255.f alpha:1]];
//            [gesturePasswordView.state setText:@"已保存手势密码"];
            
            TGAppDelegateInstance.autoGesturePassword = true;
            [TGAppDelegateInstance saveSettings];
            [self.navigationController popViewControllerAnimated:YES];
            return YES;
        }
        else{
            previousString =@"";
            [gesturePasswordView.state setTextColor:[UIColor redColor]];
            [gesturePasswordView.state setText:TGLocalized(@"GesturePassword.Notice_3")];
            return NO;
        }
    }
}

@end
