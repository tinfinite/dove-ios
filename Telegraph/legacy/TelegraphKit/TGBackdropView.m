/*
 * This is the source code of Telegram for iOS v. 1.1
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Peter Iakovlev, 2013.
 */

#import "TGBackdropView.h"

@implementation TGBackdropView

+ (TGBackdropView *)viewWithLightNavigationBarStyle
{
    TGBackdropView *view = [[TGBackdropView alloc] init];
    view.backgroundColor = UIColorRGBA(0x008DF2, 1.0f);
    return view;
}

@end
