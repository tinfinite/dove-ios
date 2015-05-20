//
//  TGNodeDetailViewController.m
//  Telegraph
//
//  Created by 琦张 on 15/3/31.
//
//

#import "TGNodeDetailViewController.h"
#import "TGNodeModel.h"
#import "TGNodeDataManager.h"
#import "TGNodeHeadView.h"
#import "TGNodeToolView.h"
#import "T8NodeHttpRequestService.h"
#import "TGNodeCommentModel.h"
#import "TGNodeDetailCommentCell.h"
#import "DXMessageToolBar.h"
#import "TGDatabase.h"
#import "TGRemoteImageView.h"
#import "NSString+Valid.h"
#import "TGNodeImageView.h"
#import "TGLinkShowViewForCell.h"
#import "TGNodeForwardMsgView.h"
#import "SVPullToRefresh.h"
#import "TTTAttributedLabel.h"
#import "IDMPhotoBrowser.h"
#import "TGTelegraphUserInfoController.h"
#import "TGUsernameController.h"
#import "TGNavigationController.h"
#import "TGReplyGroupViewController.h"
#import "TGApplication.h"
#import "T8Common.h"

@interface TGNodeDetailViewController ()<DXChatBarMoreViewDelegate,TTTAttributedLabelDelegate,IDMPhotoBrowserDelegate>

@property (nonatomic,strong) TGNodeModel *nodeModel;

@property (nonatomic,strong) UIView *tableViewHeadView;
@property (nonatomic,strong) TGNodeHeadView *headView;
@property (nonatomic,strong) TTTAttributedLabel *postCommentLabel;
@property (nonatomic,strong) NSMutableArray *forwardMsgs;
@property (nonatomic,strong) UILabel *commentTitleLabel;
@property (nonatomic,strong) UILabel *pointTitleLabel;
@property (nonatomic,strong) TGNodeToolView *toolView;
@property (nonatomic,strong) DXMessageToolBar *chatToolBar;
@property (nonatomic,strong) UIView *noCommentsView;
@property (nonatomic,strong) UIView *noNetworkView;
@property (nonatomic,strong) UIView *noNodeView;
@property (nonatomic,strong) UILabel *forwardByLabel;
@property (nonatomic,strong) UIButton *forwardByButton;

@property (nonatomic,assign) StreamType streamType;
@property (nonatomic,copy) NSString *currentUserWanted;
@property (nonatomic,assign) int64_t groupId;
@property (nonatomic,copy) NSString *nodeId;

@end

@implementation TGNodeDetailViewController

- (id)init
{
    self = [super init];
    if (self) {
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
    }
    return self;
}

- (id)initWithNodeID:(NSString *)nodeId groupId:(int64_t)groupId streamType:(StreamType)streamType
{
    self = [self init];
    if (self) {
        self.streamType = streamType;
        self.groupId = groupId;
        self.nodeId = nodeId;
        self.nodeModel = [[TGNodeDataManager sharedInstance] loadNodeWithId:nodeId streamType:streamType];
        if (self.nodeModel) {
            [self.nodeModel addObserver:self forKeyPath:@"totalReply" options:NSKeyValueObservingOptionNew context:nil];
            [self.nodeModel addObserver:self forKeyPath:@"totalScore" options:NSKeyValueObservingOptionNew context:nil];
        }else{
            __weak typeof(self) weakSelf = self;
            [T8NodeHttpRequestService getNodeStreamWithNodeIds:@[nodeId] isPublic:streamType successBlock:^(NSDictionary __unused *dictRet) {
                
                [T8Common storeNodesAfterGetNodeStreamWithNodeIds:@[nodeId] isPublic:streamType successData:dictRet];
                
                __strong typeof(weakSelf) strongSelf = weakSelf;
                strongSelf.nodeModel = [[TGNodeDataManager sharedInstance] loadNodeWithId:nodeId streamType:streamType];
                strongSelf.tableView.tableHeaderView = self.tableViewHeadView;
                strongSelf.chatToolBar.userInteractionEnabled = strongSelf.nodeModel;
                if (strongSelf.nodeModel==nil) {
                    [strongSelf.view insertSubview:strongSelf.noNodeView aboveSubview:strongSelf.toolView];
                }else{
                    [strongSelf.nodeModel addObserver:self forKeyPath:@"totalReply" options:NSKeyValueObservingOptionNew context:nil];
                    [strongSelf.nodeModel addObserver:self forKeyPath:@"totalScore" options:NSKeyValueObservingOptionNew context:nil];
                }
            } failureBlock:^(NSDictionary __unused *dictRet, NSError __unused *error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf.view insertSubview:strongSelf.noNodeView aboveSubview:strongSelf.toolView];
            }];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePostDeleteNotification:) name:Notification_Key_Post_Delete object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUserBlockNotification:) name:Notification_Key_User_Blocked object:nil];
    }
    return self;
}

- (id)initWithNodeModel:(TGNodeModel *)nodeModel
{
    self = [self init];
    if (self) {
        self.nodeModel = nodeModel;
        self.nodeId = nodeModel.nodeId;
        
        [self.nodeModel addObserver:self forKeyPath:@"totalReply" options:NSKeyValueObservingOptionNew context:nil];
        [self.nodeModel addObserver:self forKeyPath:@"totalScore" options:NSKeyValueObservingOptionNew context:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePostDeleteNotification:) name:Notification_Key_Post_Delete object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUserBlockNotification:) name:Notification_Key_User_Blocked object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    // Do any additional setup after loading the view.
}

- (void)dealloc
{
    if (self.nodeModel) {
        [self.nodeModel removeObserver:self forKeyPath:@"totalReply" context:nil];
        [self.nodeModel removeObserver:self forKeyPath:@"totalScore" context:nil];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:Notification_Key_Post_Delete object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:Notification_Key_User_Blocked object:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id) __unused object change:(NSDictionary *) __unused change context:(void *) __unused context
{
    if ([keyPath isEqualToString:@"totalReply"]) {
        if (self.nodeModel.totalReply > 0) {
            self.commentTitleLabel.text = [NSString stringWithFormat:@"%@ %ld",TGLocalized(@"Stream.Comments"),(long)self.nodeModel.totalReply];
        }else{
            self.commentTitleLabel.text = TGLocalized(@"Stream.Comments");
        }
        [self.commentTitleLabel sizeToFit];
        CGRect rect = self.pointTitleLabel.frame;
        rect.origin.x = self.commentTitleLabel.frame.origin.x+self.commentTitleLabel.frame.size.width+20;
        self.pointTitleLabel.frame = rect;
    }else if ([keyPath isEqualToString:@"totalScore"]){
        self.pointTitleLabel.text = [NSString stringWithFormat:@"%@ %ld",TGLocalized(@"Stream.Points"),(long)self.nodeModel.totalScore];
        [self.pointTitleLabel sizeToFit];
    }
}

- (void)loadView
{
    [super loadView];
    
    self.tableView.backgroundColor = UIColorRGB(0xefeff4);
    self.tableView.tableHeaderView = self.tableViewHeadView;
    CGRect frame = self.tableView.frame;
    frame.size.height -= 46;
    self.tableView.frame = frame;
    __weak typeof(self) weakSelf = self;
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf loadMore];
    }];
    
    [self.view addSubview:self.chatToolBar];
    self.chatToolBar.inputTextView.returnKeyType = UIReturnKeySend;
    self.chatToolBar.inputTextView.enablesReturnKeyAutomatically = NO;
    self.chatToolBar.userInteractionEnabled = self.nodeModel;

    [self.view addSubview:self.toolView];
    [self.toolView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
        make.height.equalTo(@46);
    }];
    
    self.currentPage = 1;
    self.timeStamp = @"";
    [self loadMore];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidLayoutSubviews
{
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsMake(0,0,0,0)];
    }
    
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsMake(0,0,0,0)];
    }
}

#pragma mark  - showImage
- (void)touchImageView:(UIImageView *)imageView WithPictureObject:(id)pictureObj
{
    NSMutableArray *photos = [NSMutableArray new];
    
    IDMPhoto *photo;
    
    if (self.nodeModel.sourceType == PostSourceTypeForward)
    {
        for (TGNodePhotoObject *obj in self.nodeModel.forward.photoMsgs) {
            photo = [IDMPhoto photoWithURL:[NSURL URLWithString:obj.originUrl]];
            [photos addObject:photo];
        }
    }else  if(self.nodeModel.sourceType == PostSourceTypePublish){
        for (TGNodePhotoObject *obj in self.nodeModel.post.images) {
            photo = [IDMPhoto photoWithURL:[NSURL URLWithString:obj.originUrl]];
            [photos addObject:photo];
        }
    }
    
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:photos animatedFromView:imageView];
    browser.delegate = self;
    browser.displayActionButton = YES;
    browser.displayArrowButton = NO;
    browser.displayCounterLabel = YES;
    browser.usePopAnimation = YES;
    browser.scaleImage = imageView.image;
    browser.view.tintColor = [UIColor whiteColor];
    [browser setInitialPageIndex:((TGNodePhotoObject *)pictureObj).pictureIndexInPost];
    
    [self presentViewController:browser animated:YES completion:nil];
}

#pragma mark - ASWatcher
- (void)actorMessageReceived:(NSString *)path messageType:(NSString *) __unused messageType message:(id)message
{
    if ([path hasPrefix:@"/tg/contacts/search"])
    {
        NSArray *users = [message objectForKey:@"users"];
        if (users.count) {
            for (TGUser *user in users) {
                if ([user.userName isEqualToString:self.currentUserWanted]) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        TGTelegraphUserInfoController *userInfoController = [[TGTelegraphUserInfoController alloc] initWithUid:user.uid];
                        [self.navigationController pushViewController:userInfoController animated:true];
                    });
                    break;
                }
            }
        }
    }
}

#pragma mark - method
- (void)enterUserDetail:(UITapGestureRecognizer *) __unused recognizer
{
    [self searchForeignWithUserName:self.nodeModel.author.userName];
    
//    if (self.nodeModel.isPublic != PostPublishTypeGroupBoard && self.nodeModel.sourceType == PostSourceTypeForward && !self.nodeModel.forward.comment.length)
//    {
//        //进入群组
//        if ((T8CONTEXT.username == nil) || [T8CONTEXT.username isEqualToString:@""])
//        {
//            TGUsernameController *usernameController = [[TGUsernameController alloc] init];
//            
//            TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[usernameController]];
//            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
//                navigationController.restrictLandscape = false;
//            else
//            {
//                navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
//                navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
//            }
//            
//            [self presentViewController:navigationController animated:true completion:nil];
//        }else{
//            TGReplyGroupViewController *replyGroupController = [[TGReplyGroupViewController alloc] initWithConversationId:-self.nodeModel.forward.groupId.longLongValue groupName:self.nodeModel.forward.groupName groupAvatarKey:self.nodeModel.forward.groupAvatarKey groupDescription:nil];
//            
//            TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[replyGroupController]];
//            
//            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
//            {
//                navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
//                navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
//            }
//            
//            [self presentViewController:navigationController animated:true completion:nil];
//        }
//    }else{
//        //进入用户
//        [self searchForeignWithUserName:self.nodeModel.author.userName];
//    }
}

- (void)enterGroupDetail
{
    if ((T8CONTEXT.username == nil) || [T8CONTEXT.username isEqualToString:@""])
    {
        TGUsernameController *usernameController = [[TGUsernameController alloc] init];
        
        TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[usernameController]];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            navigationController.restrictLandscape = false;
        else
        {
            navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
            navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        
        [self presentViewController:navigationController animated:true completion:nil];
    }else{
        TGReplyGroupViewController *replyGroupController = [[TGReplyGroupViewController alloc] initWithConversationId:-self.nodeModel.forward.groupId.longLongValue groupName:self.nodeModel.forward.groupName groupAvatarKey:self.nodeModel.forward.groupAvatarKey groupDescription:nil];
        
        TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[replyGroupController]];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            navigationController.presentationStyle = TGNavigationControllerPresentationStyleInFormSheet;
            navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        
        [self presentViewController:navigationController animated:true completion:nil];
    }
}

- (void)enterForwardByUserDetail
{
    [self searchForeignWithUserName:self.nodeModel.author.userName];
}

- (void)searchForeignWithUserName:(NSString *)username
{
    self.currentUserWanted = username;
    NSString *searchPath = [NSString stringWithFormat:@"/tg/contacts/search/(%ld)", (long)[username hash]];
    [ActionStageInstance() requestActor:searchPath options:[NSDictionary dictionaryWithObjectsAndKeys:username, @"query",[[NSNumber alloc] initWithBool:false], @"searchPhonebook", nil] watcher:self];
}

- (void)handleUserBlockNotification:(NSNotification *)notification
{
    NSMutableDictionary *dict = (NSMutableDictionary *)notification.object;
    NSString *t8id = [dict objectForKey:@"t8id"];
    NSString *tgid = [dict objectForKey:@"tgid"];
    if ([self.nodeModel.author.authorId isEqualToString:t8id] || [self.nodeModel.author.tgUserId isEqualToString:tgid]) {
        [self performSelector:@selector(popWithDelay) withObject:nil afterDelay:0.5];
    }
}

- (void)handlePostDeleteNotification:(NSNotification *)notification
{
    NSString *postID = notification.object;
    if ([postID isEqualToString:self.nodeModel.nodeId]) {
        [self performSelector:@selector(popWithDelay) withObject:nil afterDelay:0.5];
    }
}

- (void)popWithDelay
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)loadMore
{
    __weak typeof(self) weakSelf = self;
    [T8NodeHttpRequestService getNodeCommentListWithPostID:self.nodeId page:self.currentPage limit:NodeCommentPageLimit timestamp:self.timeStamp success:^(NSDictionary *dictRet) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.timeStamp = [dictRet stringForKey:@"timestamp" withDefault:@""];
        NSArray *dataArr = [dictRet arrayForKey:@"data" withDefault:[NSArray array]];
        for (NSDictionary *commentDict in dataArr) {
            TGNodeCommentModel *comment = [[TGNodeCommentModel alloc] initWithDict:commentDict];
            [strongSelf.dataArray addObject:comment];
        }
        [strongSelf.tableView reloadData];
        strongSelf.currentPage++;
        [strongSelf.tableView.infiniteScrollingView stopAnimating];
        if (dataArr.count < NodeCommentPageLimit) {
            [strongSelf.tableView setShowsInfiniteScrolling:NO];
        }
        if (strongSelf.dataArray.count == 0) {
            strongSelf.tableView.tableFooterView = strongSelf.noCommentsView;
        }else{
            strongSelf.tableView.tableFooterView = [[UIView alloc] init];
        }
    } failure:^(NSDictionary __unused *dictRet, NSError __unused *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.tableView.infiniteScrollingView stopAnimating];
        strongSelf.tableView.tableFooterView = strongSelf.noNetworkView;
    }];
}

- (void)enterReply
{
//    if (![T8LoginHelper checkLogin]) {
//        return;
//    }
    
    [self.chatToolBar.inputTextView becomeFirstResponder];
}

#pragma mark - DXMessageToolBarDelegate
- (void)didSendText:(NSString *)text
{
    NSString *comment = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (comment.length==0) {
        [T8HudHelper showHUDMessage:TGLocalized(@"Stream.CommentNotNil")];
        return;
    }
    NSString *streamId = @"";
    if (self.streamType == StreamTypeGroup) {
        streamId = @(self.groupId).stringValue;
    }else{
        streamId = @"0";
    }
    __weak typeof(self) weakSelf = self;
    [T8NodeHttpRequestService postNodeCommentWithPostID:self.nodeModel.nodeId content:comment streamId:streamId success:^(NSDictionary *dictRet) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.view endEditing:YES];
        strongSelf.nodeModel.totalReply++;
        [T8HudHelper showHUDMessage:TGLocalized(@"Stream.CommentSuccess")];
        NSString *replyID = [dictRet stringForKey:@"id" withDefault:@""];
        if (![replyID isEqualToString:@""]) {
            TGNodeCommentModel *commentModel = [TGNodeCommentModel getDefaultCommentModel];
            commentModel.content = text;
            commentModel.commentId = replyID;
            [strongSelf.dataArray insertObject:commentModel atIndex:0];
            [strongSelf.tableView reloadData];
            strongSelf.tableView.tableFooterView = [[UIView alloc] init];
            [strongSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    } failure:^(NSDictionary *dictRet, NSError __unused *error) {
        if (dictRet) {
            [T8HudHelper showHUDMessage:[dictRet stringForKey:@"message" withDefault:TGLocalized(@"Stream.CommentFail")]];
        }
    }];
}

#pragma mark - getter
- (UILabel *)forwardByLabel
{
    if (!_forwardByLabel) {
        _forwardByLabel = [[UILabel alloc] init];
        _forwardByLabel.text = TGLocalized(@"Stream.ForwardBy");
        _forwardByLabel.font = [UIFont systemFontOfSize:13];
        _forwardByLabel.textColor = UIColorRGB(0x4A4A4A);
    }
    return _forwardByLabel;
}

- (UIButton *)forwardByButton
{
    if (!_forwardByButton) {
        _forwardByButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _forwardByButton.titleLabel.font = [UIFont systemFontOfSize:13];
        _forwardByButton.tintColor = UIColorRGB(0x3991F5);
        _forwardByButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_forwardByButton setTitle:self.nodeModel.author.name forState:UIControlStateNormal];
        [_forwardByButton addTarget:self action:@selector(enterForwardByUserDetail) forControlEvents:UIControlEventTouchUpInside];
    }
    return _forwardByButton;
}

- (UIView *)noCommentsView
{
    if (!_noCommentsView) {
        _noCommentsView = [[UIView alloc] init];
        _noCommentsView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 325);
        _noCommentsView.backgroundColor = UIColorRGB(0xefeff4);
        UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"stream_nocomment"]];
        [_noCommentsView addSubview:logo];
        [logo mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(_noCommentsView);
            make.top.equalTo(_noCommentsView).offset(112);
        }];
        UILabel *info = [[UILabel alloc] init];
        info.text = TGLocalized(@"Stream.NoComments");
        info.textColor = UIColorRGB(0xb6c1cc);
        info.font = [UIFont fontWithName:@"Heiti SC-Light" size:16.0f];
        [_noCommentsView addSubview:info];
        [info mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(_noCommentsView);
            make.top.equalTo(logo.mas_bottom).offset(15);
        }];
    }
    return _noCommentsView;
}

- (UIView *)noNetworkView
{
    if (!_noNetworkView) {
        _noNetworkView = [[UIView alloc] init];
        _noNetworkView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 325);
        _noNetworkView.backgroundColor = UIColorRGB(0xefeff4);
        UIImageView *logo = [[UIImageView alloc] init];
        logo.image = [UIImage imageNamed:@"stream_wifi"];
        [_noNetworkView addSubview:logo];
        [logo mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(_noNetworkView);
            make.top.equalTo(_noNetworkView).offset(115);
        }];
        UILabel *info = [[UILabel alloc] init];
        info.text = TGLocalized(@"Common.CheckNetwork");
        info.textColor = UIColorRGB(0xb6c1cc);
        info.font = [UIFont fontWithName:@"Heiti SC-Light" size:16.0f];
        [_noNetworkView addSubview:info];
        [info mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(_noNetworkView);
            make.top.equalTo(logo.mas_bottom).offset(12);
        }];
    }
    return _noNetworkView;
}

- (UIView *)noNodeView
{
    if (!_noNodeView) {
        _noNodeView = [[UIView alloc] init];
        _noNodeView.frame = CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y, self.tableView.frame.size.width, self.tableView.frame.size.height+self.chatToolBar.frame.size.height);
        _noNodeView.backgroundColor = UIColorRGB(0xefeff4);
        UILabel *info = [[UILabel alloc] init];
        info.text = TGLocalized(@"Stream.NodeNotExist");
        info.textColor = UIColorRGB(0xb6c1cc);
        info.font = [UIFont fontWithName:@"Heiti SC-Light" size:16.0f];
        [_noNodeView addSubview:info];
        [info mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_noNodeView);
        }];
    }
    return _noNodeView;
}

- (UIView *)tableViewHeadView
{
    if (self.nodeModel==nil) {
        return nil;
    }
    if (!_tableViewHeadView) {
        _tableViewHeadView = [[UIView alloc] init];
        _tableViewHeadView.backgroundColor = [UIColor whiteColor];
        __block CGFloat headViewHeight = 0.0f;
        
        [_tableViewHeadView addSubview:self.headView];
        [self.headView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_tableViewHeadView);
            make.right.equalTo(_tableViewHeadView);
            make.width.equalTo(_tableViewHeadView);
            make.height.equalTo(@64);
        }];
        headViewHeight += 64.0f;
        
        if (self.nodeModel.sourceType == PostSourceTypePublish) {
            //直接发布的消息
            
            //文字
            if (self.nodeModel.post && self.nodeModel.post.text.length > 0) {
                self.postCommentLabel.frame = CGRectMake(15, 64+9, [UIScreen mainScreen].bounds.size.width-30, [self.nodeModel.post.text heightForSize:CGSizeMake([UIScreen mainScreen].bounds.size.width-30, 9999) font:self.postCommentLabel.font]);
                self.postCommentLabel.text = self.nodeModel.post.text;
                [_tableViewHeadView addSubview:self.postCommentLabel];
                headViewHeight += self.postCommentLabel.frame.size.height + 18;
            }
            
            //图片，是小图的形式
            if (self.nodeModel.post && self.nodeModel.post.images.count>0) {
                TGNodeImageView *imageView = [[TGNodeImageView alloc] initWithFrame:CGRectMake(15, headViewHeight, [UIScreen mainScreen].bounds.size.width-30, 0)];
                CGFloat height = [imageView setImagesWithArray:self.nodeModel.post.images];
                imageView.frame = CGRectMake(15, headViewHeight, [UIScreen mainScreen].bounds.size.width-30, height);
                [imageView setDelegate:self];
                [_tableViewHeadView addSubview:imageView];
                headViewHeight += height + 10;
            }
            
            //链接
            if (self.nodeModel.post && (self.nodeModel.post.urlTitle.length>0 || self.nodeModel.post.urlImage.length>0 || self.nodeModel.post.urlDesc.length>0)) {
                TGLinkShowViewForCell *linkView = [[TGLinkShowViewForCell alloc] initWithFrame:CGRectMake(15, headViewHeight, [UIScreen mainScreen].bounds.size.width-30, 100)];
                linkView.titleLabel.text = self.nodeModel.post.urlTitle;
                [linkView.imgView setImageWithURL:[NSURL URLWithString:self.nodeModel.post.urlImage] placeholderImage:[UIImage imageNamed:@"default_link_img"]];
                linkView.descriptionLabel.text = self.nodeModel.post.urlDesc;
                linkView.urlLabel.text = self.nodeModel.post.url;
                [linkView updateLinkUrl:self.nodeModel.post.url];
                [_tableViewHeadView addSubview:linkView];
                headViewHeight += 100 + 10;
            }
            
            //bottom line
            UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, headViewHeight, [UIScreen mainScreen].bounds.size.width, 25)];
            bottomLine.backgroundColor = UIColorRGB(0xefeff4);
            bottomLine.layer.borderColor = [UIColorRGB(0xdddddd) CGColor];
            bottomLine.layer.borderWidth = 0.5;
            [_tableViewHeadView addSubview:bottomLine];
            headViewHeight += 10 + bottomLine.frame.size.height;
        }else if (self.nodeModel.sourceType == PostSourceTypeForward){
            //转发的消息
            
            //文字，转发时带的评论
            if (self.nodeModel.forward && self.nodeModel.forward.comment.length>0) {
                self.postCommentLabel.frame = CGRectMake(15, 64+9, [UIScreen mainScreen].bounds.size.width-30, [self.nodeModel.forward.comment heightForSize:CGSizeMake([UIScreen mainScreen].bounds.size.width-30, 9999) font:self.postCommentLabel.font]);
                self.postCommentLabel.text = self.nodeModel.forward.comment;
                [_tableViewHeadView addSubview:self.postCommentLabel];
                headViewHeight += self.postCommentLabel.frame.size.height + 18;
            }
            
            //转发的消息
            UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, headViewHeight-0.5, [UIScreen mainScreen].bounds.size.width, 0.5)];
            topLine.backgroundColor = UIColorRGB(0xdddddd);
            [_tableViewHeadView addSubview:topLine];
            for (TGNodeForwardMessageModel *msg in self.nodeModel.forward.messages) {
                TGNodeForwardMsgView *msgView = [[TGNodeForwardMsgView alloc] initWithMessage:msg];
                msgView.frame = CGRectMake(0, headViewHeight, msgView.bounds.size.width, msgView.bounds.size.height);
                if ([msgView isKindOfClass:[TGNodeForwardPhotoMsgView class]]) {
                    [((TGNodeForwardPhotoMsgView *)msgView).imageView setDelegate:self];
                }
                __weak typeof(self) weakSelf = self;
                msgView.enterUser = ^(NSString *username){
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    [strongSelf searchForeignWithUserName:username];
                };
                [_tableViewHeadView addSubview:msgView];
                headViewHeight += msgView.frame.size.height;
            }
            //forward by
//            if (self.nodeModel.forward && self.nodeModel.forward.comment.length==0) {
//                UIView *forwardBgView = [[UIView alloc] init];
//                forwardBgView.frame = CGRectMake(0, headViewHeight, [UIScreen mainScreen].bounds.size.width, 30);
//                forwardBgView.backgroundColor = UIColorRGB(0xfafafa);
//                [_tableViewHeadView addSubview:forwardBgView];
//                
//                [_tableViewHeadView addSubview:self.forwardByLabel];
//                [_tableViewHeadView addSubview:self.forwardByButton];
//                
//                [self.forwardByLabel mas_makeConstraints:^(MASConstraintMaker *make) {
//                    make.left.equalTo(_tableViewHeadView).offset(15);
//                    make.top.equalTo(_tableViewHeadView).offset(headViewHeight);
//                }];
//                [self.forwardByButton mas_makeConstraints:^(MASConstraintMaker *make) {
//                    make.centerY.equalTo(self.forwardByLabel);
//                    make.left.equalTo(self.forwardByLabel.mas_right).offset(10);
//                    make.height.equalTo(@25);
//                }];
//                
//                headViewHeight += 30;
//            }
            //bottom line
            UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, headViewHeight, [UIScreen mainScreen].bounds.size.width, 25)];
            bottomLine.backgroundColor = UIColorRGB(0xefeff4);
            bottomLine.layer.borderColor = [UIColorRGB(0xdddddd) CGColor];
            bottomLine.layer.borderWidth = 0.5;
            [_tableViewHeadView addSubview:bottomLine];
            headViewHeight += 10 + bottomLine.frame.size.height;
        }
        
        //评论
        self.commentTitleLabel.frame = CGRectMake(15, headViewHeight, 0, 0);
        if (self.nodeModel.totalReply > 0) {
            self.commentTitleLabel.text = [NSString stringWithFormat:@"%@ %ld",TGLocalized(@"Stream.Comments"),(long)self.nodeModel.totalReply];
        }else{
            self.commentTitleLabel.text = TGLocalized(@"Stream.Comments");
        }
        [self.commentTitleLabel sizeToFit];
        [_tableViewHeadView addSubview:self.commentTitleLabel];
        headViewHeight += self.commentTitleLabel.frame.size.height + 8;
        
        //赞
        if (self.nodeModel.totalScore > 0) {
            self.pointTitleLabel.frame = CGRectMake(self.commentTitleLabel.frame.origin.x+self.commentTitleLabel.frame.size.width+20, self.commentTitleLabel.frame.origin.y, 0, 0);
            self.pointTitleLabel.text = [NSString stringWithFormat:@"%@ %ld",TGLocalized(@"Stream.Points"),(long)self.nodeModel.totalScore];
            [self.pointTitleLabel sizeToFit];
            [_tableViewHeadView addSubview:self.pointTitleLabel];
        }
        
        //bottom line
//        UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, headViewHeight-1, [UIScreen mainScreen].bounds.size.width, 0.5)];
//        bottomLine.backgroundColor = UIColorRGB(0xdddddd);
//        [_tableViewHeadView addSubview:bottomLine];
        
        _tableViewHeadView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, headViewHeight);
    }
    return _tableViewHeadView;
}

- (TGNodeHeadView *)headView
{
    if (!_headView) {
        _headView = [[TGNodeHeadView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 64.0f)];
        if ([self.nodeModel.author.avatar hasPrefix:@"http"]) {
            [_headView.avatarView setImageWithURL:[NSURL URLWithString:self.nodeModel.author.avatar] placeholderImage:[UIImage imageNamed:@"default_profile_img_s"]];
        }else{
            [self.headView.avatarView loadImage:self.nodeModel.author.avatar filter:@"circle:64x64" placeholder:[UIImage imageNamed:@"default_profile_img_s"]];
        }
        _headView.nameLabel.text = self.nodeModel.author.name;
        
//        if (self.nodeModel.sourceType == PostSourceTypePublish) {
//            if ([self.nodeModel.author.avatar hasPrefix:@"http"]) {
//                [_headView.avatarView setImageWithURL:[NSURL URLWithString:self.nodeModel.author.avatar] placeholderImage:[UIImage imageNamed:@"default_profile_img_s"]];
//            }else{
//                [self.headView.avatarView loadImage:self.nodeModel.author.avatar filter:@"circle:64x64" placeholder:[UIImage imageNamed:@"default_profile_img_s"]];
//            }
//            _headView.nameLabel.text = self.nodeModel.author.name;
//        }else if (self.nodeModel.sourceType == PostSourceTypeForward){
//            if (self.nodeModel.forward.comment.length)
//            {
//                if ([self.nodeModel.author.avatar hasPrefix:@"http"]) {
//                    [_headView.avatarView setImageWithURL:[NSURL URLWithString:self.nodeModel.author.avatar] placeholderImage:[UIImage imageNamed:@"default_profile_img_s"]];
//                }else{
//                    [self.headView.avatarView loadImage:self.nodeModel.author.avatar filter:@"circle:64x64" placeholder:[UIImage imageNamed:@"default_profile_img_s"]];
//                }
//                _headView.nameLabel.text = self.nodeModel.author.name;
//            }else{
//                if (self.nodeModel.forward.groupAvatarKey.length>0) {
//                    [self.headView.avatarView loadImage:self.nodeModel.forward.groupAvatarKey filter:@"circle:64x64" placeholder:[UIImage imageNamed:@"default_profile_img_s"]];
//                }else{
//                    [self.headView.avatarView setImageWithURL:[NSURL URLWithString:self.nodeModel.forward.groupAvatar] placeholderImage:[UIImage imageNamed:@"default_profile_img_s"]];
//                }
//                _headView.nameLabel.text = self.nodeModel.forward.groupName;
//            }
//        }
        
        _headView.timeLabel.text = [[NSDate getDateFromT8TimeStamp:self.nodeModel.createTime] timeIntervalDescription];
        if (self.nodeModel.sourceType == PostSourceTypeForward) {
            _headView.groupLabel.text = self.nodeModel.forward.groupName;
            [_headView.groupLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(enterGroupDetail)]];
        }
        [_headView.avatarView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(enterUserDetail:)]];
        [_headView.nameLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(enterUserDetail:)]];
    }
    return _headView;
}

- (TGNodeToolView *)toolView
{
    if (!_toolView) {
        _toolView = [[TGNodeToolView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 46)];
        _toolView.backgroundColor = [UIColor whiteColor];
        [_toolView.recommendBtn addTarget:self action:@selector(enterReply) forControlEvents:UIControlEventTouchUpInside];
        [_toolView setObject:self.nodeModel];
        //topLine
        UIImageView *topLine = [[UIImageView alloc] init];
        topLine.backgroundColor = UIColorRGB(0xdddddd);
        [_toolView addSubview:topLine];
        [topLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_toolView);
            make.left.equalTo(_toolView);
            make.right.equalTo(_toolView);
            make.height.equalTo(@0.5);
        }];
    }
    return _toolView;
}

- (DXMessageToolBar *)chatToolBar
{
    if (_chatToolBar == nil) {
        _chatToolBar = [[DXMessageToolBar alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - [DXMessageToolBar defaultHeight], self.view.frame.size.width, [DXMessageToolBar defaultHeight])];
        _chatToolBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
        _chatToolBar.delegate = (id)self;
    }
    
    return _chatToolBar;
}

- (TTTAttributedLabel *)postCommentLabel
{
    if (!_postCommentLabel) {
        _postCommentLabel = [[TTTAttributedLabel alloc] init];
        _postCommentLabel.font = [UIFont systemFontOfSize:16];
        _postCommentLabel.textColor = UIColorRGB(0x4a4a4a);
        _postCommentLabel.numberOfLines = 0;
        _postCommentLabel.delegate = self;
        _postCommentLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    }
    return _postCommentLabel;
}

- (UILabel *)commentTitleLabel
{
    if (!_commentTitleLabel) {
        _commentTitleLabel = [[UILabel alloc] init];
        _commentTitleLabel.font = [UIFont systemFontOfSize:14];
        _commentTitleLabel.textColor = UIColorRGB(0x4a4a4a);
    }
    return _commentTitleLabel;
}

- (UILabel *)pointTitleLabel
{
    if (!_pointTitleLabel) {
        _pointTitleLabel = [[UILabel alloc] init];
        _pointTitleLabel.font = [UIFont systemFontOfSize:14];
        _pointTitleLabel.textColor = UIColorRGB(0x4a4a4a);
    }
    return _pointTitleLabel;
}

#pragma mark - UITableViewDataSource & UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *) __unused tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *) __unused tableView numberOfRowsInSection:(NSInteger) __unused section
{
    return self.dataArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TGNodeCommentModel *comment = [self.dataArray objectAtIndex:indexPath.row];
    if (comment.cellHeight == 0) {
        comment.cellHeight = [TGNodeDetailCommentCell tableView:tableView rowHeightForObject:comment];
    }
    return comment.cellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    TGNodeDetailCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[TGNodeDetailCommentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    TGNodeCommentModel *comment = [self.dataArray objectAtIndex:indexPath.row];
    [cell setObject:comment];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    
}

-(void)tableView:(UITableView *) __unused tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *) __unused indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *) __unused scrollView
{
    [self.view endEditing:YES];
}

#pragma mark - TTTAttributedLabelDelegate
- (void)attributedLabel:(TTTAttributedLabel *) __unused label didSelectLinkWithURL:(NSURL *)url
{
//    [[UIApplication sharedApplication] openURL:url];
    [(TGApplication *)[UIApplication sharedApplication] openURL:url forceNative:true];
}

@end
