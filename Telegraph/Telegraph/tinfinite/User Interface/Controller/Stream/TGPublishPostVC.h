//
//  TGPublishPostVC.h
//  Telegraph
//
//  Created by 琦张 on 15/3/24.
//
//

#import "TGViewController.h"
#import "T8NodeHttpRequestService.h"

@interface TGPublishPostVC : TGViewController

- (id)initWithEnteranceType:(PublishEnteranceType)enteranceType andGroupId:(int64_t)groupId;

@end
