//
//  TGNodeAuthorModel.h
//  Telegraph
//
//  Created by 琦张 on 15/3/30.
//
//

#import <Foundation/Foundation.h>

@interface TGNodeAuthorModel : NSObject

@property (nonatomic,strong) NSDictionary *dataDict;
@property (nonatomic,copy) NSString *authorId;
@property (nonatomic,copy) NSString *locale;
@property (nonatomic,copy) NSString *name;
@property (nonatomic,copy) NSString *tgUserId;
@property (nonatomic,copy) NSString *avatar;
@property (nonatomic,copy) NSString *userName;

- (instancetype)initWithDict:(NSDictionary *)dict;

@end
