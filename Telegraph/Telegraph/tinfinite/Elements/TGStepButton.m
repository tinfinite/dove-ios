//
//  TGStepButton.m
//  Telegraph
//
//  Created by yewei on 15/3/29.
//
//

#import "TGStepButton.h"
#import "T8NodeHttpRequestService.h"
#import "NSDictionary+Ext.h"

@implementation TGStepButton

+ (id)buttonWithType:(UIButtonType)buttonType
{
    TGStepButton *button = [super buttonWithType:buttonType];
    [button addTarget:button action:@selector(touchAction) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

#pragma mark - setter
- (void)setIsSteped:(BOOL)isSteped
{
    _isSteped = isSteped;
    if (_isSteped) {
        self.tintColor = nil;
    }else{
        self.tintColor = UIColorRGB(0x9B9B9B);
    }
}

- (void)touchAction
{
    self.enabled = NO;
    __weak typeof(self) weakSelf = self;
    [T8NodeHttpRequestService stepNodeWithID:self.nodeId streamID:self.streamId successBlock:^(NSDictionary *dictRet) {
        __strong typeof(self) strongSelf = weakSelf;
        
        strongSelf.enabled = YES;
        NSString *action = [dictRet stringForKey:@"action" withDefault:@""];
        if ([action isEqualToString:@"down"]) {
            strongSelf.isSteped = YES;
            if (strongSelf.stepBlock) {
                strongSelf.stepBlock();
            }
        }else if ([action isEqualToString:@"cancel down"]){
            strongSelf.isSteped = NO;
            if (strongSelf.unStepBlock) {
                strongSelf.unStepBlock();
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
