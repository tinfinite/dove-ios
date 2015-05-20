//
//  TGPraiseButton.h
//  Telegraph
//
//  Created by yewei on 15/3/29.
//
//

#import <UIKit/UIKit.h>

typedef void(^PraiseButtonActionBlock)();

@interface TGPraiseButton : UIButton

@property (nonatomic,copy) NSString *nodeID;
@property (nonatomic,copy) NSString *streamID;
@property (nonatomic,assign) BOOL isPraised;
@property (nonatomic,strong) PraiseButtonActionBlock praiseBlock;
@property (nonatomic,strong) PraiseButtonActionBlock unPraiseBlock;

@end
