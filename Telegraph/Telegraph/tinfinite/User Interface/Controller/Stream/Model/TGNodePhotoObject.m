//
//  TGNodeImageObject.m
//  Telegraph
//
//  Created by yewei on 15/3/30.
//
//

#import "TGNodePhotoObject.h"

@implementation TGNodePhotoObject

- (id)initWithOriginUrl:(NSString *)originUrl
{
    self = [super init];
    if (self) {
        self.originUrl = originUrl;
        self.largeWidth = [self getPhotoWidth];
        self.largeHeight = [self getPhotoHeight];
    }
    return self;
}

- (NSNumber *)getPhotoWidth
{
    NSNumber *width;
    
    NSRange widthRange = [self.originUrl rangeOfString:@"w" options:NSBackwardsSearch];
    NSRange heightRange = [self.originUrl rangeOfString:@"h" options:NSBackwardsSearch];
    
    if (widthRange.location != NSNotFound && heightRange.location != NSNotFound)
    {
        NSUInteger length = heightRange.location - widthRange.location;
        if (length > 0)
        {
            NSRange range = NSMakeRange(widthRange.location+1, length-1);
            NSString *widthString = [self.originUrl substringWithRange:range];
            if ([self isPureCGFloat:widthString])
            {
                width = [NSNumber numberWithDouble:[widthString doubleValue]];
            }else{
                width = [NSNumber numberWithDouble:SCREEN_WIDTH];
            }
        }
    }else{
        width = [NSNumber numberWithDouble:SCREEN_WIDTH];
    }

    return width;
}

- (NSNumber *)getPhotoHeight
{
    NSNumber *height;
    
    NSRange heightRange = [self.originUrl rangeOfString:@"h" options:NSBackwardsSearch];
    
    if (heightRange.location != NSNotFound)
    {
        if (heightRange.location + 1 < self.originUrl.length) {
            NSString *heightString = [self.originUrl substringFromIndex:heightRange.location + 1];
            if ([heightString containsString:@".gif"]) {
                heightString = [heightString stringByReplacingOccurrencesOfString:@".gif" withString:@""];
            }
            if ([self isPureCGFloat:heightString])
            {
                height = [NSNumber numberWithDouble:[heightString doubleValue]];
            }
        }else{
            height = [NSNumber numberWithDouble:SCREEN_WIDTH];
        }
    }else{
        height = [NSNumber numberWithDouble:SCREEN_WIDTH];
    }
    
    return height;
}

- (BOOL)isPureCGFloat:(NSString*)string
{
    NSScanner* scan = [NSScanner scannerWithString:string];
    CGFloat val;
    return[scan scanDouble:&val] && [scan isAtEnd];
}

@end
