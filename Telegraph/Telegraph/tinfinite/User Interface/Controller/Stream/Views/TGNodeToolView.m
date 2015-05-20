//
//  TGNodeToolView.m
//  Telegraph
//
//  Created by yewei on 15/3/29.
//
//

#import "TGNodeToolView.h"
#import "TGAlertView.h"
#import "T8NodeHttpRequestService.h"
#import "TGActionSheet.h"
#import "T8GroupAndCommunityService.h"
#import "T8ReportHttpRequestService.h"

@implementation TGNodeToolView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self addSubview:self.recommendLabel];
        [self.recommendLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@60);
            make.centerY.equalTo(self);
        }];
        
        [self addSubview:self.recommendBtn];
        [self.recommendBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.mas_left).offset(41);
            make.centerY.equalTo(self);
            make.height.equalTo(self);
            make.right.equalTo(self.recommendLabel.mas_right).offset(10);
        }];
        
        [self addSubview:self.praiseLabel];
        [self.praiseLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.recommendBtn);
            make.centerX.equalTo(self);
        }];
        
        [self addSubview:self.praiseBtn];
        [self.praiseBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.recommendBtn);
            make.centerX.equalTo(self.praiseLabel.mas_left).offset(-23);
            make.height.equalTo(self);
            make.width.equalTo(@64);
        }];
        
        [self addSubview:self.stepBtn];
        [self.stepBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.recommendBtn);
            make.centerX.equalTo(self.praiseLabel.mas_right).offset(23);
            make.height.equalTo(self);
            make.width.equalTo(@44);
        }];
        
        [self addSubview:self.shareBtn];
        [self.shareBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.recommendBtn);
            make.centerX.equalTo(self.mas_right).offset(-50);
            make.height.equalTo(self);
            make.width.equalTo(@60);
        }];
    }
    return self;
}

- (void)dealloc
{
    [self finishObserveObjectProperty];
}

#pragma mark - method

- (void)setObject:(TGNodeModel *)object
{
    if (self.node != object) {
        if (self.node != nil) {
            [self finishObserveObjectProperty];
        }
        
        self.node = object;
        if (self.node != nil) {
            [self startObserveObjectProperty];
        }
    }
    self.node = object;
    self.praiseBtn.nodeID = object.nodeId;
    self.praiseBtn.streamID = @"0";
    self.praiseBtn.isPraised = object.isUpvote;
    self.stepBtn.nodeId = object.nodeId;
    self.stepBtn.streamId = @"0";
    self.stepBtn.isSteped = object.isDownvote;
    if (object.totalReply==0) {
        self.recommendLabel.text = @" ";
    }else{
        self.recommendLabel.text = [NSString stringWithFormat:@"%ld",(long)object.totalReply];
    }
    self.praiseLabel.text = [NSString stringWithFormat:@"%ld",(long)object.totalScore];
    if (object.isUpvote || object.isDownvote) {
        self.praiseLabel.textColor = self.praiseLabel.tintColor;
    }else{
        self.praiseLabel.textColor = UIColorRGB(0x9B9B9B);
    }
    
    if ([self.node.author.authorId isEqualToString:T8CONTEXT.t8UserId]) {
        [self.shareBtn removeTarget:self action:@selector(actionButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.shareBtn addTarget:self action:@selector(deleteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.shareBtn setImage:[UIImage imageNamed:@"cell_delete"] forState:UIControlStateNormal];
    }else{
        [self.shareBtn removeTarget:self action:@selector(deleteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.shareBtn addTarget:self action:@selector(actionButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.shareBtn setImage:[UIImage imageNamed:@"cell_share"] forState:UIControlStateNormal];
    }
}

- (void)deleteButtonPressed
{
    __weak typeof(self) weakSelf = self;
    TGAlertView *alertView = [[TGAlertView alloc] initWithTitle:TGLocalized(@"Stream.DeleteNodel") message:nil cancelButtonTitle:TGLocalized(@"Stream.Cancel") okButtonTitle:TGLocalized(@"Stream.Delete") completBlock:^(UIAlertView __unused *alert, bool okButtonPressed) {
        if (okButtonPressed) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [T8NodeHttpRequestService deleteNodeWithID:strongSelf.node.nodeId success:^(NSDictionary __unused *dictRet) {
                [T8HudHelper showHUDMessage:TGLocalized(@"Stream.DeleteSuccess")];
                [[NSNotificationCenter defaultCenter] postNotificationName:Notification_Key_Post_Delete object:strongSelf.node.nodeId];
            } failure:^(NSDictionary __unused *dictRet, NSError __unused *error) {
                [T8HudHelper showHUDMessage:TGLocalized(@"Stream.DeleteFailure")];
            }];
        }
    }];
    [alertView show];
}

- (void)actionButtonPressed
{
    NSMutableArray *actions = [[NSMutableArray alloc] init];
    
    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Stream.Report") action:@"report"]];
    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Stream.Block") action:@"block"]];
    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Common.Cancel") action:@"cancel" type:TGActionSheetActionTypeCancel]];

    TGActionSheet *actionSheet = [[TGActionSheet alloc] initWithTitle:nil actions:actions actionBlock:^(TGNodeToolView *target, NSString *action) {
        if ([action isEqualToString:@"report"]) {
            [target reportButtonPressed];
        }else if ([action isEqualToString:@"block"]){
            [target blockPressed];
        }
    } target:self];
    [actionSheet showInView:self];
}

- (void)blockPressed
{
    __weak typeof(self) weakSelf = self;
    TGAlertView *alert = [[TGAlertView alloc] initWithTitle:TGLocalized(@"Stream.BlockAsk") message:nil cancelButtonTitle:TGLocalized(@"Stream.Cancel") okButtonTitle:TGLocalized(@"Stream.Block") completBlock:^(UIAlertView __unused *alert, bool okButtonPressed) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (okButtonPressed) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setObject:strongSelf.node.author.authorId forKey:@"t8id"];
            [dict setObject:strongSelf.node.author.tgUserId forKey:@"tgid"];
            [[NSNotificationCenter defaultCenter] postNotificationName:Notification_Key_User_Blocked object:dict];
            [T8NodeHttpRequestService blockUserWithTGID:strongSelf.node.author.tgUserId andT8ID:strongSelf.node.author.authorId  blockAction:YES success:^(NSDictionary __unused *dictRet) {
                
            } failure:^(NSDictionary __unused *dictRet, NSError __unused *error) {
                
            }];
        }
    }];
    [alert show];
}

- (void)reportButtonPressed
{
    NSMutableArray *actions = [[NSMutableArray alloc] init];
    
    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Report.Title1") action:@"Report1"]];
    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Report.Title2") action:@"Report2"]];
    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Report.Title3") action:@"Report3"]];
    
    [actions addObject:[[TGActionSheetAction alloc] initWithTitle:TGLocalized(@"Common.Cancel") action:@"cancel" type:TGActionSheetActionTypeCancel]];
    
    TGActionSheet *actionSheet = [[TGActionSheet alloc] initWithTitle:nil actions:actions actionBlock:^(TGNodeToolView __unused *controller, NSString *action)
                                  {
                                      if ([action isEqualToString:@"Report1"])
                                          [controller reportRequestWithReason:@"垃圾营销"];
                                      else if ([action isEqualToString:@"Report2"])
                                          [controller reportRequestWithReason:@"淫秽信息"];
                                      else if ([action isEqualToString:@"Report3"])
                                          [controller reportRequestWithReason:@"虚假信息"];
                                  } target:self];
    [actionSheet showInView:self];
}

- (void)reportRequestWithReason:(NSString *)reason
{
    [T8ReportHttpRequestService reportWithTargetId:self.node.nodeId reportType:ReportTypePost reason:reason successBlock:^(NSDictionary __unused *dictRet) {
        [T8HudHelper showHUDMessage:TGLocalized(@"Report.Success")];
    } failureBlock:^(NSDictionary *dictRet, NSError __unused *error) {
        if ([dictRet[@"code"] integerValue] == 100003) {
            [T8HudHelper showHUDMessage:TGLocalized(@"Report.Reported")];
        }else{
            [T8HudHelper showHUDMessage:TGLocalized(@"Report.Failure")];
        }
    }];
}

- (void)startObserveObjectProperty
{
    if (self.node) {
        [self.node addObserver:self forKeyPath:@"totalScore" options:NSKeyValueObservingOptionNew context:nil];
        [self.node addObserver:self forKeyPath:@"totalReply" options:NSKeyValueObservingOptionNew context:nil];
        [self.node addObserver:self forKeyPath:@"isUpvote" options:NSKeyValueObservingOptionNew context:nil];
        [self.node addObserver:self forKeyPath:@"isDownvote" options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)finishObserveObjectProperty
{
    if (self.node) {
        [self.node removeObserver:self forKeyPath:@"totalScore"];
        [self.node removeObserver:self forKeyPath:@"totalReply"];
        [self.node removeObserver:self forKeyPath:@"isUpvote"];
        [self.node removeObserver:self forKeyPath:@"isDownvote"];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)__unused object
                        change:(NSDictionary *)__unused change
                       context:(void *)__unused context
{
    if ([keyPath isEqual:@"totalScore"])
    {
        self.praiseLabel.text = [NSString stringWithFormat:@"%ld",(long)self.node.totalScore];
        [self setNeedsDisplay];
    }
    if ([keyPath isEqual:@"totalReply"])
    {
        self.recommendLabel.text = [NSString stringWithFormat:@"%ld",(long)self.node.totalReply];
        [self setNeedsDisplay];
    }
    if ([keyPath isEqual:@"isUpvote"])
    {
        self.praiseBtn.isPraised = self.node.isUpvote;
        [self setNeedsDisplay];
    }
    if ([keyPath isEqual:@"isDownvote"])
    {
        self.stepBtn.isSteped = self.node.isDownvote;
        [self setNeedsDisplay];
    }
    
    if (self.node.isUpvote || self.node.isDownvote) {
        self.praiseLabel.textColor = self.praiseLabel.tintColor;
    }else{
        self.praiseLabel.textColor = UIColorRGB(0x9B9B9B);
    }
}

/**
 *  根据model中的赞和踩的信息更新praise label中的数据
 */
- (void)refreshStatus
{
    self.recommendLabel.text = [NSString stringWithFormat:@"%ld",(long)self.node.totalReply];
    self.praiseLabel.text = [NSString stringWithFormat:@"%ld",(long)self.node.totalScore];
}

- (void)tintColorDidChange
{
    if (self.node.isUpvote || self.node.isDownvote) {
        self.praiseLabel.textColor = self.praiseLabel.tintColor;
    }else{
        self.praiseLabel.textColor = UIColorRGB(0x9B9B9B);
    }
}

#pragma mark - getter
- (UIButton *)recommendBtn
{
    if (!_recommendBtn) {
        _recommendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_recommendBtn setImage:[UIImage imageNamed:@"cell_conversation"] forState:UIControlStateNormal];
    }
    return _recommendBtn;
}

- (UILabel *)recommendLabel
{
    if (!_recommendLabel) {
        _recommendLabel = [[UILabel alloc] init];
        _recommendLabel.textColor = UIColorRGB(0x9B9B9B);
        _recommendLabel.font = [UIFont systemFontOfSize:14];
    }
    return _recommendLabel;
}

- (TGPraiseButton *)praiseBtn
{
    if (!_praiseBtn) {
        _praiseBtn = [TGPraiseButton buttonWithType:UIButtonTypeSystem];
        [_praiseBtn setImage:[UIImage imageNamed:@"cell_up"] forState:UIControlStateNormal];
        __weak typeof(self) weakSelf = self;
        _praiseBtn.praiseBlock = ^(){
            __strong typeof(self) strongSelf = weakSelf;
            if (strongSelf.node) {
                strongSelf.node.isUpvote = YES;
                strongSelf.node.totalScore++;
                if (strongSelf.node.isDownvote) {
                    strongSelf.node.totalScore ++;
                    strongSelf.node.isDownvote = NO;
                }
            }
        };
        _praiseBtn.unPraiseBlock = ^(){
            __strong typeof(self) strongSelf = weakSelf;
            if (strongSelf.node) {
                strongSelf.node.isUpvote = NO;
                strongSelf.node.totalScore--;
            }
        };
    }
    return _praiseBtn;
}

- (TGStepButton *)stepBtn
{
    if (!_stepBtn) {
        _stepBtn = [TGStepButton buttonWithType:UIButtonTypeSystem];
        [_stepBtn setImage:[UIImage imageNamed:@"cell_down"] forState:UIControlStateNormal];
        __weak typeof(self) weakSelf = self;
        _stepBtn.stepBlock = ^(){
            __strong typeof(self) strongSelf = weakSelf;
            if (strongSelf.node) {
                strongSelf.node.isDownvote = YES;
                strongSelf.node.totalScore--;
                if (strongSelf.node.isUpvote) {
                    strongSelf.node.isUpvote = NO;
                    strongSelf.node.totalScore --;
                }
            }
        };
        _stepBtn.unStepBlock = ^(){
            __strong typeof(self) strongSelf = weakSelf;
            if (strongSelf.node) {
                strongSelf.node.isDownvote = NO;
                strongSelf.node.totalScore++;
            }
        };
    }
    return _stepBtn;
}

- (UILabel *)praiseLabel
{
    if (!_praiseLabel) {
        _praiseLabel = [[UILabel alloc] init];
        _praiseLabel.textColor = UIColorRGB(0x9B9B9B);
        _praiseLabel.font = [UIFont systemFontOfSize:14];
    }
    return _praiseLabel;
}

- (UIButton *)shareBtn
{
    if (!_shareBtn) {
        _shareBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_shareBtn setImage:[UIImage imageNamed:@"cell_share"] forState:UIControlStateNormal];
    }
    return _shareBtn;
}


@end
