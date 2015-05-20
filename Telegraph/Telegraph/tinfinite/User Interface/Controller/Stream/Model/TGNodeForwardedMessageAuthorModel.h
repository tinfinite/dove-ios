//
//  TGNodeForwardedMessageAuthorModel.h
//  Telegraph
//
//  Created by 琦张 on 15/3/30.
//
//

#import <Foundation/Foundation.h>

@interface TGNodeForwardedMessageAuthorModel : NSObject

@property (nonatomic,copy) NSString *username;
@property (nonatomic,copy) NSString *lastname;
@property (nonatomic,copy) NSString *firstname;
@property (nonatomic,copy) NSString *name;
@property (nonatomic,copy) NSString *userid;
@property (nonatomic,assign) BOOL anonymous;

- (instancetype)initWithDict:(NSDictionary *)dict;

@end
