//
//  NSNumber+PSCoding.m
//  Telegraph
//
//  Created by 琦张 on 15/3/18.
//
//

#import "NSNumber+PSCoding.h"

@implementation NSNumber (PSCoding)

- (instancetype)initWithKeyValueCoder:(PSKeyValueCoder *)coder
{
    int32_t x = [coder decodeInt32ForKey:@"numbervalue"];
    NSLog(@"x:%d",x);
    self = [self initWithInt:x];
    return self;
}

- (void)encodeWithKeyValueCoder:(PSKeyValueCoder *)coder
{
    [coder encodeInt32:self.int32Value forKey:@"numbervalue"];
}

@end
