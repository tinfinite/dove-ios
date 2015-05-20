//
//  T8ReportHttpRequestService.h
//  Telegraph
//
//  Created by yewei on 15/3/15.
//
//

#import <Foundation/Foundation.h>
#import "T8HttpClient.h"

typedef NS_ENUM(NSInteger, ReportType)
{
    ReportTypePost = 0,
    ReportTypeGroup = 1,
    ReportTypeUser = 2
};

@interface T8ReportHttpRequestService : NSObject

+ (void)reportWithTargetId:(NSString *)targetId
                reportType:(ReportType)reportType
                    reason:(NSString *)reason
              successBlock:(RequestSuccess)successBlock
              failureBlock:(RequestFailuer)failureBlock;

@end
