//
//  TGUpvoteMessageTableViewCell.m
//  Telegraph
//
//  Created by yewei on 15/3/18.
//
//

#import "TGUpvoteMessageTableViewCell.h"
#import "TGDateUtils.h"
#import "TGStringUtils.h"

#import "TGReusableLabel.h"
#import "TGLabel.h"
#import "TGLetteredAvatarView.h"
#import "TGImageUtils.h"

#import "TGMessage.h"
#import "TGUser.h"

#import "TGDateLabel.h"

#import "TGViewController.h"

#import "TGFont.h"
#import "TGTimerTarget.h"
#import "T8StickToTopManager.h"

static UIColor *normalTextColor = nil;
static UIColor *actionTextColor = nil;
static UIColor *mediaTextColor = nil;

@interface TGUpvoteMessageTextView : UIView

@property (nonatomic, strong) NSString *authorName;
@property (nonatomic) CGRect authorNameFrame;
@property (nonatomic, strong) UIFont *authorNameFont;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic) CGRect textFrame;
@property (nonatomic, strong) UIFont *textFont;

@end

@implementation TGUpvoteMessageTextView

- (void)drawRect:(CGRect)rect
{
    static CGColorRef authorNameColor = nil;
    static UIColor *nAuthorNameColor = nil;
    if (authorNameColor == nil)
    {
        nAuthorNameColor = [UIColor blackColor];
        authorNameColor = CGColorRetain([nAuthorNameColor CGColor]);
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect frame = self.frame;
    CGRect authorNameFrame = CGRectOffset(_authorNameFrame, -frame.origin.x, -frame.origin.y);
    CGRect textFrame = CGRectOffset(_textFrame, -frame.origin.x, -frame.origin.y);
    
    CGContextSetFillColorWithColor(context, authorNameColor);
    if (CGRectIntersectsRect(rect, authorNameFrame))
    {
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        style.lineBreakMode = NSLineBreakByTruncatingTail;
        style.alignment = NSTextAlignmentLeft;
        
        NSDictionary *attributes = @{
                                     NSParagraphStyleAttributeName: style,
                                     NSFontAttributeName: _authorNameFont,
                                     NSForegroundColorAttributeName:nAuthorNameColor
                                     };
        
        [_authorName drawWithRect:authorNameFrame options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
    }
    
    if (CGRectIntersectsRect(rect, textFrame))
    {
        CGContextSetFillColorWithColor(context, _textColor.CGColor);
        
        static NSDictionary *attributes = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^
                      {
                          NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
                          style.lineSpacing = 1 + TGRetinaPixel;
                          style.lineBreakMode = NSLineBreakByWordWrapping;
                          style.alignment = NSTextAlignmentLeft;
                          
                          attributes = @{
                                         NSParagraphStyleAttributeName: style,
                                         NSFontAttributeName: _textFont,
                                         NSForegroundColorAttributeName: _textColor
                                         };
                      });
        
        [_text drawWithRect:textFrame options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine attributes:attributes context:nil];
    }
}

@end

@interface TGUpvoteMessageTableViewCell ()

{
    CALayer *_separatorLayer;
    UIImageView *_avatarIconView;
}

@property (nonatomic, strong) UIView *wrapView;

@property (nonatomic, strong) TGUpvoteMessageTextView *textView;

@property (nonatomic, strong) TGLetteredAvatarView *avatarView;
@property (nonatomic, strong) UIImageView *authorAvatarStrokeView;

@property (nonatomic, strong) UILabel *pointsLabel;
@property (nonatomic, strong) TGDateLabel *dateLabel;

@property (nonatomic, strong) NSString *dateString;

@property (nonatomic) int validViews;
@property (nonatomic) CGSize validSize;

@property (nonatomic) bool editingIsActive;

@property (nonatomic, strong) UIColor *messageTextColor;

@end

@implementation TGUpvoteMessageTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier assetsSource:(id<TGDialogListCellAssetsSource>)assetsSource
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        if (iosMajorVersion() >= 7)
        {
            self.contentView.superview.clipsToBounds = false;
        }
        
        _separatorLayer = [[CALayer alloc] init];
        _separatorLayer.backgroundColor = TGSeparatorColor().CGColor;
        [self.layer addSublayer:_separatorLayer];
        
        _wrapView = [[UIView alloc] init];
        _wrapView.clipsToBounds = true;
        [self addSubview:_wrapView];
        
        UIView *selectedView = [[UIView alloc] init];
        selectedView.backgroundColor = TGSelectionColor();
        self.selectedBackgroundView = selectedView;
        
        _assetsSource = assetsSource;
        
        _textView = [[TGUpvoteMessageTextView alloc] initWithFrame:CGRectMake(58, 2, self.frame.size.width - 58, 46)];
        _textView.contentMode = UIViewContentModeLeft;
        _textView.authorNameFont = TGMediumSystemFontOfSize(16);
        _textView.textFont = TGSystemFontOfSize(15);
        _textView.opaque = true;
        _textView.backgroundColor = [UIColor whiteColor];
        
        [_wrapView addSubview:_textView];
        
        _dateString = [[NSMutableString alloc] initWithCapacity:16];
        
        CGFloat dateFontSize = 14.0f;
        CGFloat amWidth = 24.0f;
        if (TGIsPad())
        {
            dateFontSize = 15.0f;
            amWidth = 25.0f;
        }
        
        _pointsLabel = [[UILabel alloc] init];
        _pointsLabel.textColor = UIColorRGB(0x969699);
        _pointsLabel.backgroundColor = [UIColor clearColor];
        _pointsLabel.opaque = false;
        _pointsLabel.font = TGSystemFontOfSize(dateFontSize);
        [_wrapView addSubview:_pointsLabel];
        
        _dateLabel = [[TGDateLabel alloc] init];
        _dateLabel.amWidth = amWidth;
        _dateLabel.pmWidth = amWidth;
        _dateLabel.dstOffset = 0.0f;
        _dateLabel.dateFont = TGSystemFontOfSize(dateFontSize);
        _dateLabel.dateTextFont = TGSystemFontOfSize(dateFontSize);
        _dateLabel.dateLabelFont = TGSystemFontOfSize(dateFontSize);
        _dateLabel.textColor = UIColorRGB(0x969699);
        _dateLabel.backgroundColor = [UIColor clearColor];
        _dateLabel.opaque = false;
        
#if !TGTEST
        [_wrapView addSubview:_dateLabel];
#endif
        
        bool fadeTransition = cpuCoreCount() > 1;
        
        _avatarView = [[TGLetteredAvatarView alloc] initWithFrame:CGRectMake(10, 7 - TGRetinaPixel, 38 + TGRetinaPixel, 38 + TGRetinaPixel)];
        [_avatarView setSingleFontSize:20.0f doubleFontSize:13.0f useBoldFont:false];
        _avatarView.fadeTransition = fadeTransition;
        [_wrapView addSubview:_avatarView];
        
        _avatarIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BroadcastLargeAvatarIcon.png"]];
        _avatarIconView.frame = (CGRect){{23.0f, 23.0f}, _avatarIconView.frame.size};
        _avatarIconView.hidden = true;
        [_wrapView addSubview:_avatarIconView];
        
        _validSize = CGSizeZero;
    }
    return self;
}

- (void)dealloc
{
    [_avatarView cancelLoading];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    bool wasSelected = self.selected;
    
    [super setSelected:selected animated:animated];
    
    if ((selected && !wasSelected))
    {
        [self adjustOrdering];
    }
    
    if ((selected && !wasSelected) || (!selected && wasSelected))
    {
        UIView *selectedView = self.selectedBackgroundView;
        if (selectedView != nil && (self.selected || self.highlighted))
        {
            CGFloat separatorHeight = TGIsRetina() ? 0.5f : 1.0f;
            selectedView.frame = CGRectMake(0, -separatorHeight, selectedView.frame.size.width, self.frame.size.height + separatorHeight);
        }
        
        if (TGIsPad())
        {
            bool hidden = (self.selected || self.highlighted);
            if (_separatorLayer.hidden != hidden)
            {
                [CATransaction begin];
                [CATransaction setDisableActions:true];
                _separatorLayer.hidden = hidden;
                [CATransaction commit];
            }
        }
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    bool wasHighlighted = self.highlighted;
    
    [super setHighlighted:highlighted animated:animated];
    
    if ((highlighted && !wasHighlighted))
    {
        [self adjustOrdering];
    }
    
    if ((highlighted && !wasHighlighted) || (!highlighted && wasHighlighted))
    {
        UIView *selectedView = self.selectedBackgroundView;
        if (selectedView != nil && (self.selected || self.highlighted))
        {
            CGFloat separatorHeight = TGIsRetina() ? 0.5f : 1.0f;
            selectedView.frame = CGRectMake(0, -separatorHeight, selectedView.frame.size.width, self.frame.size.height + separatorHeight);
        }
        
        if (TGIsPad())
        {
            bool hidden = (self.selected || self.highlighted);
            if (_separatorLayer.hidden != hidden)
            {
                [CATransaction begin];
                [CATransaction setDisableActions:true];
                _separatorLayer.hidden = hidden;
                [CATransaction commit];
            }
        }
    }
}

- (void)adjustOrdering
{
    UIView *selectedView = self.selectedBackgroundView;
    if (selectedView != nil)
    {
        CGFloat separatorHeight = TGIsRetina() ? 0.5f : 1.0f;
        selectedView.frame = CGRectMake(0, -separatorHeight, selectedView.frame.size.width, self.frame.size.height + separatorHeight);
    }
    
    if ([self.superview isKindOfClass:[UITableView class]])
    {
        Class UITableViewCellClass = [UITableViewCell class];
        Class UISearchBarClass = [UISearchBar class];
        int maxCellIndex = 0;
        int index = -1;
        int selfIndex = 0;
        for (UIView *view in self.superview.subviews)
        {
            index++;
            if ([view isKindOfClass:UITableViewCellClass] || [view isKindOfClass:UISearchBarClass])
            {
                maxCellIndex = index;
                
                if (view == self)
                    selfIndex = index;
            }
        }
        
        if (selfIndex < maxCellIndex)
        {
            [self.superview insertSubview:self atIndex:maxCellIndex];
        }
    }
}

- (void)collectCachedPhotos:(NSMutableDictionary *)dict
{
    [_avatarView tryFillCache:dict];
}
- (void)resetView:(bool)keepState
{
    if (self.selectionStyle != UITableViewCellSelectionStyleBlue)
        self.selectionStyle = UITableViewCellSelectionStyleBlue;
    
    _dateString = _date == 0 ? nil : [TGDateUtils stringForMessageListDate:(int)_date];
    
    _textView.authorName = _authorName;
    
    if (normalTextColor == nil)
    {
        normalTextColor = UIColorRGB(0x8e8e93);
        actionTextColor = UIColorRGB(0x8e8e93);
        mediaTextColor = UIColorRGB(0x8e8e93);
    }
    
    bool attachmentFound = false;
    
    if (_messageAttachments != nil && _messageAttachments.count != 0)
    {
        for (TGMediaAttachment *attachment in _messageAttachments)
        {
            if (attachment.type == TGActionMediaAttachmentType)
            {
                TGActionMediaAttachment *actionAttachment = (TGActionMediaAttachment *)attachment;
                switch (actionAttachment.actionType)
                {
                    case TGMessageActionChatEditTitle:
                    {
                        TGUser *user = [_users objectForKey:@"author"];
                        _messageText = [[NSString alloc] initWithFormat:TGLocalized(@"Notification.RenamedChat"), user.displayName];
                        _messageTextColor = actionTextColor;
                        attachmentFound = true;
                        
                        break;
                    }
                    case TGMessageActionChatEditPhoto:
                    {
                        TGUser *user = [_users objectForKey:@"author"];
                        if ([(TGImageMediaAttachment *)[actionAttachment.actionData objectForKey:@"photo"] imageInfo] == nil)
                            _messageText = [[NSString alloc] initWithFormat:TGLocalized(@"Notification.RemovedGroupPhoto"), user.displayName];
                        else
                            _messageText = [[NSString alloc] initWithFormat:TGLocalized(@"Notification.ChangedGroupPhoto"), user.displayName];
                        _messageTextColor = actionTextColor;
                        attachmentFound = true;
                        
                        break;
                    }
                    case TGMessageActionUserChangedPhoto:
                    {
                        TGUser *user = [_users objectForKey:@"author"];
                        if ([(TGImageMediaAttachment *)[actionAttachment.actionData objectForKey:@"photo"] imageInfo] == nil)
                            _messageText = [[NSString alloc] initWithFormat:TGLocalized(@"Notification.RemovedUserPhoto"), user.displayFirstName];
                        else
                            _messageText = [[NSString alloc] initWithFormat:TGLocalized(@"Notification.ChangedUserPhoto"), user.displayFirstName];
                        _messageTextColor = actionTextColor;
                        attachmentFound = true;
                        
                        break;
                    }
                    case TGMessageActionChatAddMember:
                    {
                        NSNumber *nUid = [actionAttachment.actionData objectForKey:@"uid"];
                        if (nUid != nil)
                        {
                            TGUser *authorUser = [_users objectForKey:@"author"];
                            TGUser *subjectUser = [_users objectForKey:nUid];
                            if (authorUser.uid == subjectUser.uid)
                                _messageText = [[NSString alloc] initWithFormat:TGLocalized(@"Notification.JoinedChat"), authorUser.displayName];
                            else
                                _messageText = [[NSString alloc] initWithFormat:TGLocalized(@"Notification.Invited"), authorUser.displayName, subjectUser.displayName];
                            _messageTextColor = actionTextColor;
                            attachmentFound = true;
                        }
                        
                        break;
                    }
                    case TGMessageActionChatDeleteMember:
                    {
                        NSNumber *nUid = [actionAttachment.actionData objectForKey:@"uid"];
                        if (nUid != nil)
                        {
                            TGUser *authorUser = [_users objectForKey:@"author"];
                            TGUser *subjectUser = [_users objectForKey:nUid];
                            if (authorUser.uid == subjectUser.uid)
                                _messageText = [[NSString alloc] initWithFormat:TGLocalized(@"Notification.LeftChat"), authorUser.displayName];
                            else
                                _messageText = [[NSString alloc] initWithFormat:TGLocalized(@"Notification.Kicked"), authorUser.displayName, subjectUser.displayName];
                            _messageTextColor = actionTextColor;
                            attachmentFound = true;
                        }
                        
                        break;
                    }
                    case TGMessageActionCreateChat:
                    {
                        TGUser *user = [_users objectForKey:@"author"];
                        _messageText = [[NSString alloc] initWithFormat:TGLocalized(@"Notification.CreatedChat"), user.displayName];
                        _messageTextColor = actionTextColor;
                        attachmentFound = true;
                        
                        break;
                    }
                    case TGMessageActionCreateBroadcastList:
                    {
                        _messageText = TGLocalized(@"Notification.CreatedBroadcastList");
                        _messageTextColor = actionTextColor;
                        attachmentFound = true;
                        
                        break;
                    }
                    case TGMessageActionContactRequest:
                    {
                        _messageText = [[NSString alloc] initWithFormat:@"%@ sent contact request", _authorName];
                        _messageTextColor = actionTextColor;
                        attachmentFound = true;
                        
                        break;
                    }
                    case TGMessageActionAcceptContactRequest:
                    {
                        _messageText = [[NSString alloc] initWithFormat:@"%@ accepted contact request", _authorName];
                        _messageTextColor = actionTextColor;
                        attachmentFound = true;
                        
                        break;
                    }
                    case TGMessageActionContactRegistered:
                    {
                        _messageText = [[NSString alloc] initWithFormat:TGLocalized(@"Notification.Joined"), _authorName];
                        _messageTextColor = actionTextColor;
                        attachmentFound = true;
                        
                        break;
                    }
                    case TGMessageActionEncryptedChatRequest:
                    {
                        _messageText = TGLocalized(@"Notification.EncryptedChatRequested");
                        _messageTextColor = actionTextColor;
                        attachmentFound = true;
                        
                        break;
                    }
                    case TGMessageActionEncryptedChatAccept:
                    {
                        _messageText = TGLocalized(@"Notification.EncryptedChatAccepted");
                        _messageTextColor = actionTextColor;
                        attachmentFound = true;
                        
                        break;
                    }
                    case TGMessageActionEncryptedChatDecline:
                    {
                        _messageText = TGLocalized(@"Notification.EncryptedChatRejected");
                        _messageTextColor = actionTextColor;
                        attachmentFound = true;
                        
                        break;
                    }
                    case TGMessageActionEncryptedChatMessageLifetime:
                    {
                        _messageTextColor = actionTextColor;
                        attachmentFound = true;
                        
                        break;
                    }
                    case TGMessageActionEncryptedChatScreenshot:
                    case TGMessageActionEncryptedChatMessageScreenshot:
                    {
                        break;
                    }
                    default:
                        break;
                }
            }
            else if (attachment.type == TGImageMediaAttachmentType)
            {
                _messageText = TGLocalized(@"Message.Photo");
                _messageTextColor = mediaTextColor;
                attachmentFound = true;
                break;
            }
            else if (attachment.type == TGVideoMediaAttachmentType)
            {
                _messageText = TGLocalized(@"Message.Video");
                _messageTextColor = mediaTextColor;
                attachmentFound = true;
                break;
            }
            else if (attachment.type == TGLocationMediaAttachmentType)
            {
                _messageText = TGLocalized(@"Message.Location");
                _messageTextColor = mediaTextColor;
                attachmentFound = true;
                break;
            }
            else if (attachment.type == TGContactMediaAttachmentType)
            {
                _messageText = TGLocalized(@"Message.Contact");
                _messageTextColor = mediaTextColor;
                attachmentFound = true;
                break;
            }
            else if (attachment.type == TGDocumentMediaAttachmentType)
            {
                TGDocumentMediaAttachment *documentAttachment = (TGDocumentMediaAttachment *)attachment;
                
                bool isAnimated = false;
                CGSize imageSize = CGSizeZero;
                bool isSticker = false;
                for (id attribute in documentAttachment.attributes)
                {
                    if ([attribute isKindOfClass:[TGDocumentAttributeAnimated class]])
                    {
                        isAnimated = true;
                    }
                    else if ([attribute isKindOfClass:[TGDocumentAttributeImageSize class]])
                    {
                        imageSize = ((TGDocumentAttributeImageSize *)attribute).size;
                    }
                    else if ([attribute isKindOfClass:[TGDocumentAttributeSticker class]])
                    {
                        isSticker = true;
                    }
                }
                
                if (isSticker)
                {
                    _messageText = TGLocalized(@"Message.Sticker");
                }
                else
                {
                    NSString *fileName = ((TGDocumentMediaAttachment *)attachment).fileName;
                    if (fileName.length != 0)
                        _messageText = fileName;
                    else
                        _messageText = TGLocalized(@"Message.File");
                    
                    _messageTextColor = mediaTextColor;
                    attachmentFound = true;
                }
                break;
            }
            else if (attachment.type == TGAudioMediaAttachmentType)
            {
                _messageText = TGLocalized(@"Message.Audio");
                _messageTextColor = mediaTextColor;
                attachmentFound = true;
                break;
            }
        }
    }
    
    if (!attachmentFound)
    {
        _messageTextColor = normalTextColor;
    }
    
    if (_messageText.length == 0)
    {
        _messageTextColor = actionTextColor;
    }
    
    _textView.text = _messageText;
    _textView.textColor = _messageTextColor;
    
    _avatarView.hidden = false;
    
    static UIImage *placeholder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      //!placeholder
                      UIGraphicsBeginImageContextWithOptions(CGSizeMake(62.0f, 62.0f), false, 0.0f);
                      CGContextRef context = UIGraphicsGetCurrentContext();
                      
                      CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
                      CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, 62.0f, 62.0f));
                      CGContextSetStrokeColorWithColor(context, UIColorRGB(0xd9d9d9).CGColor);
                      CGContextSetLineWidth(context, 1.0f);
                      CGContextStrokeEllipseInRect(context, CGRectMake(0.5f, 0.5f, 61.0f, 61.0f));
                      
                      placeholder = UIGraphicsGetImageFromCurrentImageContext();
                      UIGraphicsEndImageContext();
                  });
    
    if (_avatarUrl.length != 0)
    {
        _avatarView.fadeTransitionDuration = keepState ? 0.3 : 0.14;
        
        if (![_avatarView.currentUrl isEqualToString:_avatarUrl])
        {
            if (keepState)
            {
                [_avatarView loadImage:_avatarUrl filter:@"circle:38x38" placeholder:(_avatarView.currentImage != nil ? _avatarView.currentImage : placeholder) forceFade:true];
            }
            else
            {
                [_avatarView loadImage:_avatarUrl filter:@"circle:38x38" placeholder:placeholder forceFade:false];
            }
        }
    }
    else
    {
        _avatarView.fadeTransitionDuration = 0.14;
        
        [_avatarView loadGroupPlaceholderWithSize:CGSizeMake(38.0f, 38.0f) conversationId:_conversationId title:_authorName placeholder:placeholder];
    }
    
    _dateLabel.dateText = _dateString;
    
    _pointsLabel.text = _pointText;
    
    _validSize = CGSizeZero;
    
    [_textView setNeedsDisplay];
    
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
#undef TG_TIMESTAMP_DEFINE
#undef TG_TIMESTAMP_MEASURE
    
#define TG_TIMESTAMP_DEFINE(x)
#define TG_TIMESTAMP_MEASURE(x)
    
    TG_TIMESTAMP_DEFINE(cellLayout);
    
    TG_TIMESTAMP_MEASURE(cellLayout);
    
    [super layoutSubviews];
    
    TG_TIMESTAMP_MEASURE(cellLayout);
    
    CGFloat separatorHeight = TGIsRetina() ? 0.5f : 1.0f;
    
    CGSize rawSize = self.frame.size;
    
    UIView *selectedView = self.selectedBackgroundView;
    if (selectedView != nil)
        selectedView.frame = CGRectMake(0, -separatorHeight, selectedView.frame.size.width, rawSize.height + separatorHeight);
    
    TG_TIMESTAMP_MEASURE(cellLayout);
    
    self.backgroundView.frame = CGRectMake(0.0f, 0.0f, rawSize.width, rawSize.height);
    
    static CGSize screenSize;
    static CGFloat widescreenWidth;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      screenSize = TGScreenSize();
                      widescreenWidth = MAX(screenSize.width, screenSize.height);
                  });
    
    CGFloat contentOffset = self.contentView.frame.origin.x;
    
    CGSize size = rawSize;
    if (!TGIsPad())
    {
        if (rawSize.width >= widescreenWidth - FLT_EPSILON)
            size.width = screenSize.height - contentOffset;
        else
            size.width = screenSize.width - contentOffset;
    }
    else
        size.width = rawSize.width - contentOffset;
    
    TG_TIMESTAMP_MEASURE(cellLayout);
    
    _separatorLayer.frame = CGRectMake(58.0f, size.height - separatorHeight, rawSize.width - 58.0f, separatorHeight);
    
    _wrapView.frame = CGRectMake(contentOffset, 0.0f, size.width, size.height);
    
    if (!CGSizeEqualToSize(_validSize, size))
    {
        if (_textView != nil)
        {
            if (!CGSizeEqualToSize(_textView.frame.size, CGRectMake(58.0f, 6, size.width - 58.0f, 62).size))
            {
                _textView.frame = CGRectMake(58.0f, 6, size.width - 58.0f, 62);
                [_textView setNeedsDisplay];
            }
        }
        
        int rightPadding = 0.0f;
        
        CGSize dateTextSize = [_dateLabel measureTextSize];
        
        CGFloat dateWidth = _date == 0 ? 0 : (int)(dateTextSize.width);
        CGRect dateFrame = CGRectMake(size.width - dateWidth - 11.0f + (contentOffset > FLT_EPSILON ? 4.0f : 0.0f), 10.0f + TGRetinaPixel - (TGIsPad() ? 1.0f : 0.0f), 75, 20);
        _dateLabel.frame = dateFrame;
        
        CGSize pointSize =  [_pointsLabel sizeThatFits:CGSizeMake(200, 20)];
        _pointsLabel.frame = CGRectMake(dateFrame.origin.x - pointSize.width - 10, dateFrame.origin.y, pointSize.width, 18);
        
        CGFloat titleLabelWidth = (int)(dateFrame.origin.x - 4 - 58.0f - 18);
        CGFloat groupChatIconWidth = 0.0f;
        
        if (false && _isGroupChat)
        {
            groupChatIconWidth = 22;
            titleLabelWidth -= groupChatIconWidth;
        }
        
        titleLabelWidth = MIN(titleLabelWidth, [_authorName sizeWithFont:_textView.authorNameFont].width);
        
        TG_TIMESTAMP_MEASURE(cellLayout);
        
        CGRect titleRect = CGRectMake(58.0f + groupChatIconWidth, 8.0f, titleLabelWidth, 20);
        
        CGRect messageRect = CGRectMake(58.0f, 30.0f - TGRetinaPixel, size.width - 58.0f - 7.0f - rightPadding, 40);
        
        if (_authorName != nil)
        {
            _textView.authorNameFrame = CGRectMake(58.0f, 29.0f + TGRetinaPixel, size.width - 58.0f - 4.0f - rightPadding, 20);
        }
        
        TG_TIMESTAMP_MEASURE(cellLayout);
        
        titleRect.size.width = titleLabelWidth;
        
        if (_authorName != nil && [_messageText sizeWithFont:_textView.textFont constrainedToSize:messageRect.size].height < 20)
            messageRect.origin.y += 9;
        
        _textView.authorNameFrame = titleRect;
        _textView.textFrame = messageRect;
        
        _validSize = size;
        
        TG_TIMESTAMP_MEASURE(cellLayout);
    }
}

#pragma mark -

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
}

- (void)resetLocalization
{
    _dateLabel.dateText = @"";
}

@end
