//
//  TGNodeImageObject.h
//  Telegraph
//
//  Created by yewei on 15/3/30.
//
//

#import <Foundation/Foundation.h>

@interface TGNodePhotoObject : NSObject

@property (nonatomic, copy) NSString *originUrl;
@property (nonatomic, strong) NSNumber *largeWidth;
@property (nonatomic, strong) NSNumber *largeHeight;
@property (nonatomic, assign) NSInteger pictureIndexInPost;

- (id)initWithOriginUrl:(NSString *)originUrl;

@end
