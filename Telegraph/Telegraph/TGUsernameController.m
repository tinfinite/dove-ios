#import "TGUsernameController.h"

#import "TGProgressWindow.h"

#import "TGDatabase.h"
#import "TGTelegraph.h"
#import "ActionStage.h"

#import "TGCollectionMenuSection.h"
#import "TGCommentCollectionItem.h"
#import "TGUsernameCollectionItem.h"

#import "TGCollectionMenuLayout.h"

#import "TGAlertView.h"
#import "T8Common.h"
#import "TGAppDelegate.h"

typedef enum {
    TGUsernameControllerUsernameStateNone,
    TGUsernameControllerUsernameStateValid,
    TGUsernameControllerUsernameStateTooShort,
    TGUsernameControllerUsernameStateInvalidCharacters,
    TGUsernameControllerUsernameStateStartsWithNumber,
    TGUsernameControllerUsernameStateTaken,
    TGUsernameControllerUsernameStateChecking
} TGUsernameControllerUsernameState;

@interface TGUsernameController () <ASWatcher>
{
    TGUsernameCollectionItem *_usernameItem;
    TGCommentCollectionItem *_invalidUsernameItem;
    
    NSString *_currentCheckPath;
    TGProgressWindow *_progressWindow;
}

@property (nonatomic, strong) ASHandle *actionHandle;
@property (nonatomic, assign) UsernameControllerType type;

@end

@implementation TGUsernameController

- (instancetype)init
{
    return [self initWithType:UsernameControllerTypeNormal];
}

- (instancetype)initWithType:(UsernameControllerType)type
{
    self = [super init];
    if (self != nil)
    {
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
        
        self.title = TGLocalized(@"Username.Title");
        //        [self setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(cancelPressed)]];
        [self setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"Common.Done") style:UIBarButtonItemStyleDone target:self action:@selector(donePressed)]];
        
        TGUser *user = [TGDatabaseInstance() loadUser:TGTelegraphInstance.clientUserId];
        
        _usernameItem = [[TGUsernameCollectionItem alloc] init];
        _usernameItem.username = user.userName;
        _usernameItem.usernameValid = true;
        __weak TGUsernameController *weakSelf = self;
        _usernameItem.usernameChanged = ^(NSString *username)
        {
            __strong TGUsernameController *strongSelf = weakSelf;
            [strongSelf usernameChanged:username];
        };
        
        TGCommentCollectionItem *commentItem = [[TGCommentCollectionItem alloc] initWithFormattedText:TGLocalized(@"Username.Help")];
        commentItem.topInset = 1.0f;
        
        _invalidUsernameItem = [[TGCommentCollectionItem alloc] init];
        _invalidUsernameItem.topInset = 6.0f;
        _invalidUsernameItem.alpha = 0.0f;
        _invalidUsernameItem.hidden = true;
        
        TGCollectionMenuSection *section = [[TGCollectionMenuSection alloc] initWithItems:@[_usernameItem, _invalidUsernameItem, commentItem]];
        section.insets = UIEdgeInsetsMake(32.0f, 0.0f, 0.0f, 0.0f);
        [self.menuSections addSection:section];
        
        if (user.userName == nil || [user.userName isEqualToString:@""])
        {
            self.navigationItem.rightBarButtonItem.enabled  = NO;
            
            TGAlertView *alert = [[TGAlertView alloc] initWithTitle:TGLocalized(@"GroupInfo.NeedUsername") message:TGLocalized(@"GroupInfo.NeedUsernameNotice") cancelButtonTitle:nil okButtonTitle:TGLocalized(@"GroupInfo.OK") completionBlock:nil];
            [alert show];
        }
        
        self.type = type;
    }
    return self;
}

- (void)dealloc
{
    [_actionHandle reset];
    [ActionStageInstance() removeWatcher:self];
}

- (BOOL)shouldAutorotate
{
    return true;
}

- (void)cancelPressed
{
    [self.view endEditing:true];
    [self.presentingViewController dismissViewControllerAnimated:true completion:nil];
}

- (void)donePressed
{
    if (TGStringCompare(_usernameItem.username, [TGDatabaseInstance() loadUser:TGTelegraphInstance.clientUserId].userName))
    {
        [self.view endEditing:true];
        [self.presentingViewController dismissViewControllerAnimated:true completion:nil];
    }
    else if (_usernameItem.username.length != 0 && ![self usernameIsValid:_usernameItem.username])
    {
        unichar c = [_usernameItem.username characterAtIndex:0];
        if (c >= '0' && c <= '9')
        {
            [[[TGAlertView alloc] initWithTitle:TGLocalized(@"Username.InvalidStartsWithNumber") message:nil cancelButtonTitle:TGLocalized(@"Common.Cancel") okButtonTitle:nil completionBlock:nil] show];
        }
        else
        {
            [[[TGAlertView alloc] initWithTitle:TGLocalized(@"Username.InvalidCharacters") message:nil cancelButtonTitle:TGLocalized(@"Common.Cancel") okButtonTitle:nil completionBlock:nil] show];
        }
    }
    else if (_usernameItem.username.length != 0 && _usernameItem.username.length < 5)
    {
        [[[TGAlertView alloc] initWithTitle:TGLocalized(@"Username.InvalidTooShort") message:nil cancelButtonTitle:TGLocalized(@"Common.Cancel") okButtonTitle:nil completionBlock:nil] show];
    }
    else
    {
        _progressWindow = [[TGProgressWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [_progressWindow show:true];
        
        [ActionStageInstance() requestActor:[[NSString alloc] initWithFormat:@"/tg/applyUsername/(%d)", [_usernameItem.username hash]] options:@{@"username": _usernameItem.username == nil ? @"" : _usernameItem.username} flags:0 watcher:self];
    }
}

- (void)setUsernameState:(TGUsernameControllerUsernameState)state username:(NSString *)username
{
    switch (state)
    {
        case TGUsernameControllerUsernameStateNone:
            break;
        case TGUsernameControllerUsernameStateValid:
            _invalidUsernameItem.showProgress = false;
            break;
        case TGUsernameControllerUsernameStateTooShort:
            _invalidUsernameItem.showProgress = false;
            break;
        case TGUsernameControllerUsernameStateInvalidCharacters:
            _invalidUsernameItem.showProgress = false;
            break;
        case TGUsernameControllerUsernameStateStartsWithNumber:
            _invalidUsernameItem.showProgress = false;
            break;
        case TGUsernameControllerUsernameStateTaken:
            _invalidUsernameItem.showProgress = false;
            break;
        case TGUsernameControllerUsernameStateChecking:
            _invalidUsernameItem.showProgress = true;
            break;
    }
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^
    {
        switch (state)
        {
            case TGUsernameControllerUsernameStateNone:
                _invalidUsernameItem.alpha = 0.0f;
                _invalidUsernameItem.hidden = true;
                break;
            case TGUsernameControllerUsernameStateValid:
                [_invalidUsernameItem setText:[[NSString alloc] initWithFormat:TGLocalized(@"Username.UsernameIsAvailable"), username]];
                _invalidUsernameItem.alpha = 1.0f;
                _invalidUsernameItem.hidden = false;
                _invalidUsernameItem.showProgress = false;
                [_invalidUsernameItem setTextColor:UIColorRGB(0x26972c)];
                break;
            case TGUsernameControllerUsernameStateTooShort:
                [_invalidUsernameItem setText:TGLocalized(@"Username.InvalidTooShort")];
                _invalidUsernameItem.alpha = 1.0f;
                _invalidUsernameItem.hidden = false;
                _invalidUsernameItem.showProgress = false;
                [_invalidUsernameItem setTextColor:UIColorRGB(0xcf3030)];
                break;
            case TGUsernameControllerUsernameStateInvalidCharacters:
                [_invalidUsernameItem setText:TGLocalized(@"Username.InvalidCharacters")];
                _invalidUsernameItem.alpha = 1.0f;
                _invalidUsernameItem.hidden = false;
                _invalidUsernameItem.showProgress = false;
                [_invalidUsernameItem setTextColor:UIColorRGB(0xcf3030)];
                break;
            case TGUsernameControllerUsernameStateStartsWithNumber:
                [_invalidUsernameItem setText:TGLocalized(@"Username.InvalidStartsWithNumber")];
                _invalidUsernameItem.alpha = 1.0f;
                _invalidUsernameItem.hidden = false;
                _invalidUsernameItem.showProgress = false;
                [_invalidUsernameItem setTextColor:UIColorRGB(0xcf3030)];
                break;
            case TGUsernameControllerUsernameStateTaken:
                [_invalidUsernameItem setText:TGLocalized(@"Username.InvalidTaken")];
                _invalidUsernameItem.alpha = 1.0f;
                _invalidUsernameItem.hidden = false;
                _invalidUsernameItem.showProgress = false;
                [_invalidUsernameItem setTextColor:UIColorRGB(0xcf3030)];
                break;
            case TGUsernameControllerUsernameStateChecking:
                [_invalidUsernameItem setText:[[NSString alloc] initWithFormat:@"       %@", TGLocalized(@"Username.CheckingUsername")]];
                _invalidUsernameItem.alpha = 1.0f;
                _invalidUsernameItem.hidden = false;
                _invalidUsernameItem.showProgress = true;
                [_invalidUsernameItem setTextColor:UIColorRGB(0x6d6d72)];
                break;
        }
        
        [self.collectionLayout invalidateLayout];
        [self.collectionView layoutSubviews];
    } completion:nil];
}

- (bool)usernameIsValid:(NSString *)username
{
    for (NSUInteger i = 0; i < username.length; i++)
    {
        unichar c = [username characterAtIndex:i];
        if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (i > 0 && c >= '0' && c <= '9') || c == '_'))
            return false;
    }
    
    return true;
}

- (void)usernameChanged:(NSString *)username
{
    if (_currentCheckPath != nil)
    {
        [ActionStageInstance() removeWatcher:self fromPath:_currentCheckPath];
        _currentCheckPath = nil;
    }
    
    if (username.length == 0)
    {
        self.navigationItem.rightBarButtonItem.enabled  = NO;
        [self setUsernameState:TGUsernameControllerUsernameStateNone username:username];
    }
    else if (![self usernameIsValid:username])
    {
        unichar c = [username characterAtIndex:0];
        TGUsernameControllerUsernameState state;
        if (c >= '0' && c <= '9')
            state = TGUsernameControllerUsernameStateStartsWithNumber;
        else
            state = TGUsernameControllerUsernameStateInvalidCharacters;
        [self setUsernameState:state username:username];
    }
    else if (username.length < 5)
    {
        [self setUsernameState:TGUsernameControllerUsernameStateTooShort username:username];
    }
    else
    {
        [self setUsernameState:TGUsernameControllerUsernameStateChecking username:username];
        
        _currentCheckPath = [[NSString alloc] initWithFormat:@"/tg/checkUsernameAvailability/(%d)", (int)[_usernameItem.username hash]];
        [ActionStageInstance() requestActor:_currentCheckPath options:@{@"username": _usernameItem.username} flags:0 watcher:self];
    }
    
    if (username.length != 0) {
        self.navigationItem.rightBarButtonItem.enabled  = YES;
    }
}

- (void)actorCompleted:(int)status path:(NSString *)path result:(id)result
{
    if ([path isEqualToString:_currentCheckPath])
    {
        TGDispatchOnMainThread(^
        {
            _currentCheckPath = nil;
            
            _usernameItem.usernameChecking = false;
            
            if (status == ASStatusSuccess)
            {
                [self setUsernameState:[result[@"usernameValid"] boolValue] ? TGUsernameControllerUsernameStateValid : TGUsernameControllerUsernameStateTaken username:_usernameItem.username];
            }
            else
            {
                [self setUsernameState:TGUsernameControllerUsernameStateTaken username:_usernameItem.username];
            }
        });
    }
    else if ([path hasPrefix:@"/tg/applyUsername/"])
    {
        TGDispatchOnMainThread(^
        {
            if (status == ASStatusSuccess)
            {
                [_progressWindow dismissWithSuccess];
                
                if (TGTelegraphInstance.clientUserId != 0)
                {
                    TGUser *user = [TGDatabaseInstance() loadUser:TGTelegraphInstance.clientUserId];
                    T8CONTEXT.tgUserId = TGTelegraphInstance.clientUserId;
                    T8CONTEXT.phone = user.phoneNumber;
                    T8CONTEXT.username = user.userName;
                    T8CONTEXT.firstName = user.firstName;
                    T8CONTEXT.lastName = user.lastName;
                    T8CONTEXT.username = user.userName;
                    T8CONTEXT.photoUrlSmall = user.photoUrlSmall;
                    
                    [T8Common bindTinfiniteUser];
                }
                
                [self.view endEditing:true];
                [self.presentingViewController dismissViewControllerAnimated:true completion:nil];
                
                if (self.type == UsernameControllerTypeLogin) {
                    [TGAppDelegateInstance presentMainController];
                }
            }
            else
            {
                [_progressWindow dismiss:true];
                
                [[[TGAlertView alloc] initWithTitle:TGLocalized(@"Username.InvalidTaken") message:nil cancelButtonTitle:TGLocalized(@"Common.OK") okButtonTitle:nil completionBlock:nil] show];
            }
        });
    }
}

@end
