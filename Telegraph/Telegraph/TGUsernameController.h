#import "TGCollectionMenuController.h"

typedef enum {
    UsernameControllerTypeNormal = 1,
    UsernameControllerTypeLogin = 2
}UsernameControllerType;

@interface TGUsernameController : TGCollectionMenuController

- (id)initWithType:(UsernameControllerType)type;

@end
