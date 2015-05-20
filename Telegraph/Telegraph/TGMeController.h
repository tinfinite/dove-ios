//
//  TGMeController.h
//  Telegraph
//
//  Created by yewei on 15/4/19.
//
//

#import "TGCollectionMenuController.h"

#import "ASWatcher.h"

@interface TGMeController : TGCollectionMenuController <ASWatcher>

@property (nonatomic, strong) ASHandle *actionHandle;

- (id)initWithUid:(int32_t)uid;

- (void)_updateProfileImage:(UIImage *)image;

@end
