#import "TGModernDateViewModel.h"

#import "TGImageUtils.h"

#import <CoreText/CoreText.h>

#import "TGMessage.h"
#import "TGVoteInfoObject.h"

@interface TGModernDateViewModel ()
{
}

@end

@implementation TGModernDateViewModel

- (instancetype)initWithText:(NSString *)text textColor:(UIColor *)textColor daytimeVariant:(int)__unused daytimeVariant
{
    static CTFontRef dateFont = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        dateFont = CTFontCreateWithName(CFSTR("HelveticaNeue"), 11.0f, NULL);
    });
    
    self = [super initWithText:text textColor:textColor font:dateFont maxWidth:CGFLOAT_MAX];
    if (self != nil)
    {
        self.hasNoView = true;
    }
    return self;
}

- (instancetype)initWithText:(NSString *)text textColor:(UIColor *)textColor daytimeVariant:(int)daytimeVariant message:(TGMessage *)message
{
    NSString *finalText = [NSString stringWithFormat:@"%@%@",[message getPointsString],text];
    return [self initWithText:finalText textColor:textColor daytimeVariant:daytimeVariant];
}

- (void)setText:(NSString *)text daytimeVariant:(int)__unused daytimeVariant
{
    [self setText:text maxWidth:CGFLOAT_MAX];
}

@end
