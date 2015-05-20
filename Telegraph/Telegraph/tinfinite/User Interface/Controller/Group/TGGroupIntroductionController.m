//
//  TGGroupIntroductionControllerViewController.m
//  Telegraph
//
//  Created by 琦张 on 15/4/24.
//
//

#import "TGGroupIntroductionController.h"
#import "TGTextViewCollectionItem.h"
#import "TGDatabase.h"
#import "T8GroupAndCommunityService.h"

@interface TGGroupIntroductionController ()<UIScrollViewDelegate>
{
    int64_t _conversationId;
    
    TGCollectionMenuSection *_introSection;
    TGTextViewCollectionItem *_introItem;
}

@end

@implementation TGGroupIntroductionController

- (instancetype)initWithConversationId:(int64_t)conversationId
{
    self = [super init];
    if (self) {
        _conversationId = conversationId;
        
        [self setTitleText:TGLocalized(@"GroupInfo.Introduction")];
        [self setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:TGLocalized(@"GroupInfo.IntroSave") style:UIBarButtonItemStylePlain target:self action:@selector(saveButtonPressed)]];
        
        __weak typeof(self) weakSelf = self;
        _introItem = [[TGTextViewCollectionItem alloc] initWithNumberOfLines:6];
        _introItem.placeHolder = TGLocalized(@"Discover.DescribePlaceHolder");
        _introItem.textChanged = ^(NSString *text){
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.navigationItem.rightBarButtonItem.enabled = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length>0;
        };
        _introItem.text = [TGDatabaseInstance() getDescriptionWithConversationId:_conversationId];
        _introItem.textChanged(_introItem.text);
        
        _introSection = [[TGCollectionMenuSection alloc] initWithItems:@[_introItem]];
        _introSection.insets = UIEdgeInsetsMake(25, 0, 0, 0);
        
        [self.menuSections addSection:_introSection];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - method
- (void)saveButtonPressed
{
    NSString *text = [_introItem.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    __weak typeof(self) weakSelf = self;
    [T8GroupAndCommunityService createCommunityWithThirdGroupID:_conversationId createrID:T8CONTEXT.t8UserId image:nil memberCount:-1 privilege:GroupDiscoverPrivilegeUnknow name:nil description:text language:nil imageKey:nil success:^(NSDictionary __unused *dictRet) {
        [T8HudHelper showHUDMessage:TGLocalized(@"GroupInfo.SaveSuccess")];
        [TGDatabaseInstance() storeConversationInfoWithId:_conversationId privilege:GroupDiscoverPrivilegeUnknow description:text language:nil];
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.navigationController popViewControllerAnimated:YES];
    } failure:^(NSDictionary __unused *dictRet, NSError __unused *error) {
        [T8HudHelper showHUDMessage:TGLocalized(@"GroupInfo.SaveFailed")];
    }];
}

#pragma mark - scrollview
- (void)scrollViewWillBeginDragging:(UIScrollView *) __unused scrollView
{
    [self.view endEditing:YES];
}

@end
