//
//  UIView+Dove.m
//  Telegraph
//
//  Created by yewei on 15/2/12.
//
//

#import "UIView+Dove.h"

@implementation UIView (Dove)

- (UIImage *)snapshot
{
    CGFloat scale = [UIScreen mainScreen].scale;
    
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, scale);
    [self drawViewHierarchyInRect:CGRectMake(-17, -17, self.bounds.size.width+34, self.bounds.size.height+34) afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
