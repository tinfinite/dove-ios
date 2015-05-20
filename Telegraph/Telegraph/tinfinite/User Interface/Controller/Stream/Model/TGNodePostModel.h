//
//  TGNodePostModel.h
//  Telegraph
//
//  Created by 琦张 on 15/3/30.
//
//

#import <Foundation/Foundation.h>

@interface TGNodePostModel : NSObject

@property (nonatomic,strong) NSDictionary *dataDict;
@property (nonatomic,strong) NSArray *images;
@property (nonatomic,copy) NSString *text;
@property (nonatomic,copy) NSString *url;
@property (nonatomic,copy) NSString *urlTitle;
@property (nonatomic,copy) NSString *urlImage;
@property (nonatomic,copy) NSString *urlDesc;
@property (nonatomic,copy) NSString *groupID;
@property (nonatomic,copy) NSString *groupName;
@property (nonatomic,copy) NSString *groupImage;
@property (nonatomic,copy) NSString *groupImageKey;
@property (nonatomic,assign) CGFloat textHeight;

- (instancetype)initWithDict:(NSDictionary *)dict;

@end
