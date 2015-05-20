//
//  TGAccountSettingsController.h
//  Telegraph
//
//  Created by yewei on 15/4/20.
//
//

#import "TGCollectionMenuController.h"

#import "ASWatcher.h"

@interface TGAccountSettingsController : TGCollectionMenuController<ASWatcher>

@property (nonatomic, strong) ASHandle *actionHandle;

- (id)initWithUid:(int32_t)uid;

@end
