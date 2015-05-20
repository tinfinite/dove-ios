/************************************************************
 *  * EaseMob CONFIDENTIAL
 * __________________
 * Copyright (C) 2013-2014 EaseMob Technologies. All rights reserved.
 *
 * NOTICE: All information contained herein is, and remains
 * the property of EaseMob Technologies.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from EaseMob Technologies.
 */

#import "NSString+Valid.h"

@implementation NSString (Valid)

-(BOOL)isChinese{
    NSString *match=@"(^[\u4e00-\u9fa5]+)$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF matches %@", match];
    return [predicate evaluateWithObject:self];
}

- (BOOL)hasChinese{
    BOOL zh = NO;
    for (NSUInteger i=0; i<self.length; i++) {
        int a = [self characterAtIndex:i];
        if (a > 0x4e00 && a < 0x9fff) {
            zh = YES;
            break;
        }
    }
    return zh;
}

- (CGFloat)heightForSize:(CGSize)size font:(UIFont *)font
{
    CGSize stringSize = [self boundingRectWithSize:size
                                    options:NSStringDrawingTruncatesLastVisibleLine |
                   NSStringDrawingUsesLineFragmentOrigin |
                   NSStringDrawingUsesFontLeading
                                 attributes:@{ NSFontAttributeName: font }
                                    context:nil].size;
    return stringSize.height;
}

@end
