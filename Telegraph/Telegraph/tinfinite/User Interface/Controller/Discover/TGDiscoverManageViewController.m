//
//  TGDiscoverManageViewController.m
//  Telegraph
//
//  Created by 琦张 on 15/2/15.
//
//

#import "TGDiscoverManageViewController.h"
#import "TGConversation.h"
#import "TGSwitchCollectionItem.h"
#import "TGTextViewCollectionItem.h"
#import "TGVariantCollectionItem.h"
#import "TGCommentCollectionItem.h"
#import "T8GroupAndCommunityService.h"
#import "TGDatabase.h"
#import "T8ImageUploadManager.h"
#import "TGPickerSheet.h"

@interface TGDiscoverManageViewController ()<UIScrollViewDelegate>
{
    int64_t _conversationId;
    TGConversation *_conversation;
    
    TGCollectionMenuSection *_discoverSection;
    TGSwitchCollectionItem *_discoverItem;
    
    TGCollectionMenuSection *_describeSection;
    TGTextViewCollectionItem *_describeItem;
    TGCommentCollectionItem *_describeCommentItem;
    
    TGCollectionMenuSection *_languageSection;
    TGVariantCollectionItem *_languageItem;
}

@property (nonatomic,strong) UIButton *doneButton;
@property (nonatomic,strong) TGVariantCollectionItem *languageItem;
@property (nonatomic,strong) TGPickerSheet *pickerSheet;
@property (nonatomic,copy) NSString *lanKey;
@property (nonatomic,strong) NSArray *languages;

@end

@implementation TGDiscoverManageViewController

- (instancetype)initWithConversationId:(int64_t)conversationId
{
    self = [super init];
    if (self) {
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
        
        _conversationId = conversationId;
        _conversation = [TGDatabaseInstance() loadConversationWithIdCached:_conversationId];
        
        [self setTitleText:TGLocalized(@"Discover.ShowInDiscover")];
        _doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_doneButton setTitle:TGLocalized(@"Common.Done") forState:UIControlStateNormal];
        [_doneButton sizeToFit];
        [_doneButton addTarget:self action:@selector(doneToShowAction:) forControlEvents:UIControlEventTouchUpInside];
        [self setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:_doneButton]];
        _doneButton.enabled = NO;
        
        __weak typeof(self) weakSelf = self;
        
        //discover部分
        GroupDiscoverPrivilege privilege = [TGDatabaseInstance() getPrivilegeWithConversationId:_conversationId];
        _discoverItem = [[TGSwitchCollectionItem alloc] initWithTitle:TGLocalized(@"Discover.ShowInDiscover") isOn:privilege==GroupDiscoverPrivilegePublic?true:false];
        _discoverItem.interfaceHandle = _actionHandle;
        
        _discoverSection = [[TGCollectionMenuSection alloc] initWithItems:@[_discoverItem]];
        UIEdgeInsets discoverInsets = _discoverSection.insets;
        discoverInsets.top = 30;
        discoverInsets.bottom = 16;
        _discoverSection.insets = discoverInsets;
        
        [self.menuSections addSection:_discoverSection];
        
        //描述部分
        _describeItem = [[TGTextViewCollectionItem alloc] initWithNumberOfLines:4];
        _describeItem.textChanged = ^(NSString *text)
        {
            __strong typeof(self) strongSelf = weakSelf;
            if (strongSelf != nil)
            {
                strongSelf.doneButton.enabled = (text.length != 0);
            }
        };
        _describeItem.text = [TGDatabaseInstance() getDescriptionWithConversationId:_conversationId];
        _describeItem.placeHolder = TGLocalized(@"Discover.DescribePlaceHolder");
        _doneButton.enabled = _describeItem.text.length != 0;
        
        _describeCommentItem = [[TGCommentCollectionItem alloc] initWithText:TGLocalized(@"Discover.Describe")];
        
        _describeSection = [[TGCollectionMenuSection alloc] initWithItems:@[_describeCommentItem,_describeItem]];
        UIEdgeInsets describeInsets = _describeSection.insets;
        describeInsets.bottom = 36;
        _describeSection.insets = describeInsets;
        
        [self.menuSections addSection:_describeSection];

        //语言部分
        _languageItem = [[TGVariantCollectionItem alloc] initWithTitle:TGLocalized(@"GroupInfo.Language") variant:@"" action:@selector(languageSelect)];
        
        _languageSection = [[TGCollectionMenuSection alloc] initWithItems:@[_languageItem]];
        
        [self.menuSections addSection:_languageSection];
        
        self.lanKey = [TGDatabaseInstance() getLanguageWithConversationId:_conversationId];
        if (self.lanKey.length==0) {
            NSString *systemLan = [NSLocale preferredLanguages].firstObject;
            if ([systemLan isEqualToString:@"zh-Hans"]) {
                systemLan = @"zh";
            }else{
                systemLan = @"en";
            }
            self.lanKey = systemLan;
        }
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - setter
- (void)setLanKey:(NSString *)lanKey
{
    _lanKey = lanKey;
    
    if (_languageItem) {
        _languageItem.variant = TGLocalized(lanKey);
    }
}

#pragma mark - getter
- (TGPickerSheet *)pickerSheet
{
    if (!_pickerSheet) {
        
        __weak typeof(self) weakSelf = self;
        _pickerSheet = [[TGPickerSheet alloc] initWithItems:self.languages selectedIndex:0 type:PickerSheetTypeLanguage action:^(NSString *lan)
                                      {
                                          __strong typeof(weakSelf) strongSelf = weakSelf;
                                          strongSelf.lanKey = lan;
                                      }];
    }
    return _pickerSheet;
}

- (NSArray *)languages
{
    if (!_languages) {
        _languages = [NSArray arrayWithObjects:@"zh", @"en", nil];
    }
    return _languages;
}

#pragma mark - method
- (void)doneToShowAction:(id)__unused sender
{
    __weak typeof(self) weakSelf = self;
    [T8GroupAndCommunityService createCommunityWithThirdGroupID:_conversationId createrID:T8CONTEXT.t8UserId image:nil memberCount:_conversation.chatParticipantCount privilege:_discoverItem.isOn?GroupDiscoverPrivilegePublic:GroupDiscoverPrivilegePrivate name:_conversation.chatTitle description:_describeItem.text language:self.lanKey imageKey:_conversation.chatPhotoSmall success:^(NSDictionary __unused *dictRet) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.navigationController popViewControllerAnimated:YES];
        [strongSelf showSuccess];
    } failure:^(NSDictionary __unused *dictRet, NSError __unused *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf showFailed];
    }];
    
//    __weak typeof(self) weakSelf = self;
//    [T8HudHelper showHUDActivity:TGLocalized(@"Discover.Waiting") parentView:self.view];
//    [[T8ImageUploadManager sharedInstance] uploadImage:self.groupAvatar tmpName:@(_conversationId).stringValue successBlock:^(NSString *url) {
//        __strong typeof(weakSelf) strongSelf = weakSelf;
//        [T8GroupAndCommunityService createCommunityWithThirdGroupID:_conversationId createrID:T8CONTEXT.t8UserId image:url memberCount:_conversation.chatParticipantCount privilege:_discoverItem.isOn?GroupDiscoverPrivilegePublic:GroupDiscoverPrivilegePrivate name:_conversation.chatTitle description:_describeItem.text language:strongSelf.lanKey imageKey:_conversation.chatPhotoSmall success:^(NSDictionary __unused *dictRet) {
//            [TGDatabaseInstance() storeConversationPrivilegeWithId:_conversationId privilege:GroupDiscoverPrivilegePublic];
//            __strong typeof(weakSelf) strongSelf = weakSelf;
//            [strongSelf.navigationController popViewControllerAnimated:YES];
//            [strongSelf showSuccess];
//        } failure:^(NSDictionary __unused *dictRet, NSError __unused *error) {
//            __strong typeof(weakSelf) strongSelf = weakSelf;
//            [strongSelf showFailed];
//        }];
//    } failureBlock:^{
//        __strong typeof(weakSelf) strongSelf = weakSelf;
//        [strongSelf showFailed];
//    }];
}

- (void)showSuccess
{
    [TGDatabaseInstance() storeConversationInfoWithId:_conversationId privilege:_discoverItem.isOn?GroupDiscoverPrivilegePublic:GroupDiscoverPrivilegePrivate description:_describeItem.text language:self.lanKey];
    
    [T8HudHelper hideHUDActivity:self.view];
}

- (void)showFailed
{
    [T8HudHelper hideHUDActivity:self.view];
}

- (void)languageSelect
{
    //取消选中状态
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:_languageItem.view];
    [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
    [self.collectionView endEditing:YES];
    
    self.pickerSheet.selectedIndex = [self.languages indexOfObject:_lanKey]==NSNotFound?0:[self.languages indexOfObject:_lanKey];
    [self.pickerSheet show];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)__unused scrollView
{
    [self.collectionView endEditing:YES];
}

@end
