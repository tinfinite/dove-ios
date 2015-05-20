//
//  TGImagesShowView.h
//  Telegraph
//
//  Created by 琦张 on 15/3/26.
//
//

#import <UIKit/UIKit.h>

typedef void(^updateUserInterface)();

@interface TGImagesShowView : UIScrollView

@property (nonatomic,strong) NSMutableArray *images;
@property (nonatomic,strong) updateUserInterface updateBlock;

@end
