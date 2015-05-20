//
//  TGNodePostModel.m
//  Telegraph
//
//  Created by 琦张 on 15/3/30.
//
//

#import "TGNodePostModel.h"
#import "NSString+Valid.h"
#import "TGNodePhotoObject.h"

@interface TGNodePostModel ()


@end

@implementation TGNodePostModel

- (instancetype)initWithDict:(NSDictionary *)dict
{
    if (dict == nil) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        self.dataDict = [dict copy];
        self.images = [self getImages:[dict stringForKey:@"image" withDefault:@""]];
        self.text = [dict stringForKey:@"text" withDefault:@""];
        self.url = [dict stringForKey:@"url" withDefault:@""];
        self.urlTitle = [dict stringForKey:@"url_title" withDefault:@""];
        self.urlImage = [dict stringForKey:@"url_image" withDefault:@""];
        self.urlDesc = [dict stringForKey:@"url_description" withDefault:@""];
        self.groupID = [dict stringForKey:@"third_group_id" withDefault:@""];
        self.groupName = [dict stringForKey:@"third_group_name" withDefault:@""];
        self.groupImage = [dict stringForKey:@"third_group_image" withDefault:@""];
        self.groupImageKey = [dict stringForKey:@"third_group_image_key" withDefault:@""];
        self.textHeight = [self getTextHeight];
    }
    return self;
}

- (NSArray *)getImages:(NSString *)imageString
{
    NSMutableArray *images = [[NSMutableArray alloc] init];
    if (imageString.length) {
        NSInteger index = 0;
        for (NSString *imageUrl in [imageString componentsSeparatedByString:@","])
        {
            TGNodePhotoObject *photoObject = [[TGNodePhotoObject alloc] initWithOriginUrl:imageUrl];
            photoObject.pictureIndexInPost = index;
            [images addObject:photoObject];
            index++;
        }
    }
    
    return images;
}

- (CGFloat)getTextHeight
{
    if (self.text.length) {
        return [self.text heightForSize:CGSizeMake(SCREEN_WIDTH - 30, 155) font:[UIFont systemFontOfSize:16.0f]];
    }else{
        return 0;
    }
}

@end
