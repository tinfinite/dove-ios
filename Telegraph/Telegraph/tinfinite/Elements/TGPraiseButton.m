//
//  TGPraiseButton.m
//  Telegraph
//
//  Created by yewei on 15/3/29.
//
//

#import "TGPraiseButton.h"
#import "T8NodeHttpRequestService.h"
#import "NSDictionary+Ext.h"

@implementation TGPraiseButton

+ (id)buttonWithType:(UIButtonType)buttonType
{
    TGPraiseButton *button = [super buttonWithType:buttonType];
    [button addTarget:button action:@selector(touchAction) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

#pragma mark - setter
- (void)setIsPraised:(BOOL)isPraised
{
    _isPraised = isPraised;
    if (_isPraised) {
        self.tintColor = nil;
    }else{
        self.tintColor = UIColorRGB(0x9B9B9B);
    }
}

- (void)touchAction
{
    self.enabled = NO;
    __weak typeof(self) weakSelf = self;
    [T8NodeHttpRequestService praiseNodeWithID:self.nodeID streamID:self.streamID successBlock:^(NSDictionary *dictRet) {
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.enabled = YES;
        NSString *action = [dictRet stringForKey:@"action" withDefault:@""];
        if ([action isEqualToString:@"up"]) {
            strongSelf.isPraised = YES;
            if (strongSelf.praiseBlock) {
                strongSelf.praiseBlock();
            }
        }else if ([action isEqualToString:@"cancel up"]){
            strongSelf.isPraised = NO;
            if (strongSelf.unPraiseBlock) {
                strongSelf.unPraiseBlock();
            }
        }
    } failureBlock:^(NSDictionary *dictRet, NSError __unused *error) {
        __strong typeof(self) strongSelf = weakSelf;
        if (dictRet) {
            [T8HudHelper showHUDMessage:[dictRet stringForKey:@"message" withDefault:@"data error"]];
        }
        strongSelf.enabled = YES;
    }];
}

@end
