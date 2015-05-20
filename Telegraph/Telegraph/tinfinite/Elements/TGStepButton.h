//
//  TGStepButton.h
//  Telegraph
//
//  Created by yewei on 15/3/29.
//
//

#import <UIKit/UIKit.h>

typedef void(^StepButtonActionBlock)();

@interface TGStepButton : UIButton

@property (nonatomic,copy) NSString *nodeId;
@property (nonatomic,copy) NSString *streamId;
@property (nonatomic,assign) BOOL isSteped;
@property (nonatomic,strong) StepButtonActionBlock stepBlock;
@property (nonatomic,strong) StepButtonActionBlock unStepBlock;


@end
