//
//  TGModernConversationPostPanel.h
//  Telegraph
//
//  Created by yewei on 15/5/11.
//
//

#import "TGModernConversationInputPanel.h"

@class TGModernConversationPostPanel;

@protocol TGModernConversationPostPanelDelegate <TGModernConversationInputPanelDelegate>

- (void)postPanelRequestedPostMessages:(TGModernConversationPostPanel *)postPanel;

@end

@interface TGModernConversationPostPanel : TGModernConversationInputPanel

@end
