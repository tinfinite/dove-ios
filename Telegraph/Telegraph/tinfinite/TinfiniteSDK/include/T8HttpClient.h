//
//  T8BaseService.h
//  Telegraph
//
//  Created by 琦张 on 15/4/4.
//
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"
#import "extError.h"

typedef NS_ENUM(NSInteger, RequestStatus)
{
    RequestStatusSuccess,
    RequestStatusFailure
};

typedef NS_ENUM(NSInteger, HttpMethod) {
    HttpMethodGet,
    HttpMethodPost,
    HttpMethodPut,
    HttpMethodDelete,
    HttpMethodPatch,
    HttpMethodHead
};

typedef void(^RequestComplete)(RequestStatus status, NSDictionary *data, extError *errorMsg);

@interface T8HttpClient : NSObject

+ (AFHTTPRequestOperationManager *)shareInstance;

+ (void)sendRequestUrlPath:(NSString *)strUrlPath
                                    httpMethod:(HttpMethod)httpMethod
                                    dictParams:(NSMutableDictionary *)dictParams
                                 completeBlock:(RequestComplete)completeBlock;

+ (NSString *)getRequestUrl:(NSString *)path;
+ (void)signRequestParams:(NSMutableDictionary *)mutDict;
+ (BOOL)checkAccessToken;
+ (BOOL)updateAccessToken;

@end
