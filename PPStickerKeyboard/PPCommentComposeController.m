//
//  PPCommentComposeController.M
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/14.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import "ZKRCommentComposeController.h"
#import <ZUIKit/ZUIKit.h>
#import "ZCLDataManager+Profile.h"
#import "ZCLDataManager.h"
#import "ZCLLoginRequest.h"
#import "ZCLUser.h"
#import "ZKRAPIManager.h"
#import "ZKRAccountManager.h"
#import "ZKRAccountUser.h"
#import "ZKRAppSettingManager.h"
#import "ZKRArticle.h"
#import "ZKRArticlePostCommentArg.h"
#import "ZKRBaiduMobileAnalysis.h"
#import "ZKRBlockKit.h"
#import "ZKRCommentApiManager.h"
#import "ZKRCommentComposeBar.h"
#import "ZKRCommentReplyAction.h"
#import "ZKRInBlockComment.h"
#import "ZKRRootBlock.h"
#import "ZKRUtilities.h"
#import "ZWSKit.h"
#import "ZKRAuther.h"

#define COMMENT_CACHE_KEY      @"CommentCacheKey"

#define COMMENT_CACHE_TEXT_KEY @"comment_cache_text_key"

@interface ZKRCommentComposeController () <ZKRCommentComposeBarDelegate> {
    BOOL _keyboardDidShow;
    BOOL _sendingSuspended;   // 标识是否有需要发送的评论被中断，被中断则不需要清除数据。 用于需要登录时，不清除数据，避免登录回来后数据丢失。
}

@property (nonatomic) ZKRCommentComposeBar *composeView;

@property (nonatomic) ZKRInBlockComment *replyComment;

@property (nonatomic, weak) UIView *showInView;

@end

@implementation ZKRCommentComposeController

+ (NSMutableDictionary *)commentInputCache
{
    static NSMutableDictionary *inputCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        inputCache = [NSMutableDictionary dictionary];
    });
    return inputCache;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    _composeView.delegate = nil;
    [_composeView removeFromSuperview];

    _delegate = nil;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self observeKeyboardNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)receiveMemoryWarning:(NSNotification *)notification
{
    [[[self class] commentInputCache] removeAllObjects];
}

#pragma mark - ZKRCommentComposeBarDelegate

- (BOOL)commentComposeViewShouldBeginEditing:(ZKRCommentComposeBar *)composeBar
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(commentComposeShouldBeginEditing:)]) {
        return [self.delegate commentComposeShouldBeginEditing:self];
    } else {
        return YES;
    }
}

- (void)commentComposeViewDidEndEditing:(ZKRCommentComposeBar *)composeView
{
    [self saveInputCache];
    [self.composeView layoutSubviews];
    if (!_sendingSuspended) {
        [self cleanData];
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(commentComposeEndEditing:)]) {
        [self.delegate commentComposeEndEditing:self];
    }
    self.composeView.textView.text = @"";
    self.composeView.textView.placeholder = ZKRCommentComposeControllerPlaceholder;
}

- (BOOL)commentIsTooLong:(NSString *)comment
{
    NSUInteger maxLength = 500;
    NSUInteger maxNumberOfLines = 30;
    NSString *text = comment;

    if ([text zui_numberOfLines] > maxNumberOfLines) {
        return YES;
    }

    if ([text length] > maxLength) {
        return YES;
    }

    return NO;
}

- (void)commentComposeViewDidPressReturnKey:(ZKRCommentComposeBar *)composeView
{
    NSString *commentString = composeView.plainText;

    NSString *trimmedString = [commentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedString.length == 0) {
        [ZKRUtilities showStatusBarMsg:@"不能发送空白内容" success:NO];
        return;
    }

    if ([self commentIsTooLong:commentString]) {
        [ZKRUtilities showStatusBarMsg:ZKRCommentComposeControllerCommentLengthError success:NO];
        return;
    }

    if (self.shouldShowLoginTips && ![[ZKRAccountManager sharedManager] userLogined]) {
        _sendingSuspended = YES;
        [[ZKRBaiduMobileAnalysis sharedAnalyst] logEventWithEventId:ZKRBaiduMobileAnalysisReplyCommentLoginRemind eventLabel:@"评论提醒数"];
        [ZCLLoginRequest sentRequestWithMethod:nil reason:ZCLLoginReasonReplyComment completion:^(BOOL finished, NSError *error) {
            if (finished && !error) {
                if ([[ZKRAccountManager sharedManager] userLogined]) {
                    [[ZKRBaiduMobileAnalysis sharedAnalyst] logEventWithEventId:ZKRBaiduMobileAnalysisReplyCommentToLoginSuccess eventLabel:@"评论登录数"];
                    [self sendCommentWithContent:commentString];
                }
            }
            _sendingSuspended = NO;
            [self cleanData];
        }];
        return;
    }

    [self sendCommentWithContent:commentString];
}

- (void)sendCommentWithContent:(NSString *)content
{
    ZKRArticlePostCommentArg *commentActionArg = [[ZKRArticlePostCommentArg alloc] init];
    commentActionArg.articlePk = [_delegate commentComposePk];
    commentActionArg.requestUrl = [self.apiManager commentApiURLForApiKey:ZKRAPICommentReplyUrl];
    commentActionArg.blockPk = self.blockManager.block.pk;
    NSString *contentString = [NSString stringWithFormat:@"%@", content];

    if (self.replyComment) {
        commentActionArg.content = [NSString stringWithFormat:@"回复@%@:%@", self.replyComment.autherName, content];
        commentActionArg.replyComment = self.replyComment;
    } else {
        commentActionArg.content = contentString;
    }

    [self.apiManager sendComment:commentActionArg completion:^(NSError *error, NSString *commentPK) {
        if (!error && commentPK) {
            [[ZKRBaiduMobileAnalysis sharedAnalyst] logEventWithEventId:ZKRBaiduMobileAnalysisCommentReplyClick eventLabel:ZKRBaiduMobileAnalysisCommentReplyClick];
            commentActionArg.commentPk = commentPK;
            commentActionArg.content = contentString;
            [self callShouldSendCommentDelegate:commentActionArg];
            NSString *key = nil;
            if ([commentActionArg.replyComment.pk zui_isValid]) {
                key = commentActionArg.replyComment.pk;
            } else if ([commentActionArg.articlePk zui_isValid]) {
                key = commentActionArg.articlePk;
            }
            if ([key zui_isValid]) {
                [[[self class] commentInputCache] removeObjectForKey:key];
            }
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(commentCompose:didSendWithError:)]) {
            [self.delegate commentCompose:self didSendWithError:error];
        }
    }];

    [self composeViewEndEditing];
    [self cleanData];
}

- (void)cleanData
{
    self.replyAction = nil;
    self.replyComment = nil;
    self.blockManager = nil;
}

- (void)commentComposeViewDidChange:(ZKRCommentComposeBar *)composeView
{
}

- (void)commentComposeViewDidClickSendButton:(ZKRCommentComposeBar *)composeBar
{
    [self commentComposeViewDidPressReturnKey:composeBar];
}

#pragma mark - Keyboard
- (void)observeKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notif
{
    if (![self.composeView.textView isFirstResponder]) {
        return;
    }

    NSDictionary *info = [notif userInfo];
    CGRect keyboardFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect correctFrame = self.composeView.frame;
    correctFrame.origin.y = CGRectGetMaxY(self.showInView.bounds) - correctFrame.size.height - keyboardFrame.size.height;

    if (_keyboardDidShow) {
        [UIView performWithoutAnimation:^{
            self.composeView.frame = correctFrame;
        }];
    } else {
        self.composeView.frame = correctFrame;
    }

    _keyboardDidShow = YES;
}

- (void)keyboardWillHide:(NSNotification *)notif
{
    CGRect correctFrame = self.composeView.frame;
    correctFrame.origin.y = MAX(CGRectGetMaxY(self.showInView.bounds), MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height));

    if (!_keyboardDidShow) {
        [UIView performWithoutAnimation:^{
            self.composeView.frame = correctFrame;
        }];
    } else {
        self.composeView.frame = correctFrame;
    }

    _keyboardDidShow = NO;
}

- (CGRect)frameOfComposeView
{
    CGRect rect = CGRectZero;
    rect.size.width = CGRectGetWidth(self.showInView.bounds);
    rect.size.height = [self.composeView heightThatFit];
    rect.origin.y = CGRectGetMaxY(self.showInView.bounds) - rect.size.height;
    return rect;
}

- (void)setThemeMode:(ZUIThemeMode)themeMode
{
    if (_themeMode != themeMode) {
        _themeMode = themeMode;
        self.composeView.zui_themeMode = themeMode;
    }
}

- (ZKRCommentComposeBar *)composeView
{
    if (!_composeView) {
        _composeView = [[ZKRCommentComposeBar alloc] init];
        _composeView.zui_themeMode = self.themeMode;
        _composeView.delegate = self;
        _composeView.textView.placeholder = ZKRCommentComposeControllerPlaceholder;
        _composeView.showMaskDidEditing = YES;
        __weak id weakSelf = self;
        [_composeView setClosedButtonDidClickAction:^{
            [weakSelf composeViewCloseButtonClicked];
        }];
    }

    return _composeView;
}

- (BOOL)isComposeViewEditing
{
    return [self.composeView isEditing];
}

- (void)composeViewBeginEditing
{
    if (![self.composeView isFirstResponder]) {
        [self.composeView changeKeyboardTo:ZKRKeyboardTypeSystem];
        [self.composeView becomeFirstResponder];
    }
}

- (void)composeViewEndEditing
{
    if ([self.composeView isFirstResponder]) {
        [self.composeView resignFirstResponder];
    }
}

- (void)composeViewCloseButtonClicked
{
    if (![self.composeView isEditing]) {
    } else {
        [self composeViewEndEditing];
    }
}

- (void)showCommentComposeInView:(UIView *)showView withReplyComment:(ZKRInBlockComment *)commentModel
{
    if (!showView) {
        return;
    }

    if (_keyboardDidShow) {
        return;
    }

    if (commentModel) {
        self.replyComment = commentModel;
        [self.composeView refreshReplyName:commentModel.autherName];
        self.composeView.textView.placeholder = @"";
    } else {
        [self.composeView refreshReplyName:@""];
    }

    [self loadInputCache];

    self.showInView = showView;
    CGRect frame = [self frameOfComposeView];
    frame.origin.y = [UIScreen mainScreen].bounds.size.height;
    self.composeView.frame = frame;

    [showView addSubview:self.composeView];

    [self composeViewBeginEditing];
}

- (void)closeCommentCompose
{
    [self composeViewEndEditing];
}

- (void)callShouldSendCommentDelegate:(ZKRArticlePostCommentArg *)arg
{
    ZKRAccountManager *accountManager = [ZKRAccountManager sharedManager];
    ZKRAccountUser *currentUserAccount = [accountManager userModelForUser:[accountManager currentUser]];

    ZKRInBlockComment *comment = [[ZKRInBlockComment alloc] init];
    comment.pk = arg.commentPk;
    comment.autherName = @"我";
    comment.content = arg.content;
    comment.likeNum = 0;
    comment.replyComment = arg.replyComment;
    comment.isLocalReply = YES;
    comment.mainSectionComment = arg.replyComment.mainSectionComment;

    if (arg.replyComment.auther) {
        comment.replyAuther = arg.replyComment.auther;
        comment.replyAuther.name = arg.replyComment.autherName;
    } else if ([arg.replyComment.autherName zui_isValid]) {
        ZKRAuther *beReplyAuthor = [[ZKRAuther alloc] init];
        beReplyAuthor.name = arg.replyComment.autherName;
        beReplyAuthor.userFlags = arg.replyComment.userFlags;
        beReplyAuthor.isOfficial = arg.replyComment.isOffical;
        comment.replyAuther = beReplyAuthor;
    }

    if ([accountManager userLogined]) {
        ZCLUser *user = nil;
        NSString *currentUID = [accountManager currentUser];
        if ([ZCLDataManager getUserInfo:&user UID:currentUID]) {
            ZKRAuther *auther = [[ZKRAuther alloc] init];
            auther.name = user.name;
            auther.userFlags = user.userFlags;
            auther.isOfficial = user.isOfficial;

            comment.userFlags = user.userFlags;
            comment.isOffical = user.isOfficial;
            comment.auther = auther;
        }
    }

    NSDate *now = [NSDate date];
    comment.displayTime = [now zui_smartDescriptionWithMaxRelativePastDays:7];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    comment.date = [dateFormatter stringFromDate:now];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    comment.time = [dateFormatter stringFromDate:now];

    if (currentUserAccount && [currentUserAccount.userID zui_isValid]) {
        comment.autherPk = currentUserAccount.userID;
        comment.auther.uid = currentUserAccount.userID;
    }
    if (currentUserAccount && [currentUserAccount.iconUrl zui_isValid]) {
        comment.autherIcon = currentUserAccount.iconUrl;
        comment.auther.icon = currentUserAccount.iconUrl;
    }
    if (currentUserAccount && [currentUserAccount.userName zui_isValid]) {
        comment.autherName = currentUserAccount.userName;
        comment.auther.name = currentUserAccount.userName;
    } else {
        NSString *geographicStr = [[NSUserDefaults standardUserDefaults] objectForKey:ZKRPreferenceGeographicInformation];
        if ([geographicStr zui_isValid]) {
            comment.autherName = [NSString stringWithFormat:@"%@用户", geographicStr];
        }
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(commentCompose:shouldSendComment:)]) {
        [self.delegate commentCompose:self shouldSendComment:comment];
    }
}

- (void)loadInputCache
{
    NSDictionary *commentCache = nil;
    NSString *pk = [_delegate commentComposePk];
    if ([self.replyComment.pk zui_isValid]) {
        commentCache = [[[self class] commentInputCache] objectForKey:self.replyComment.pk];
    } else if ([pk zui_isValid]) {
        commentCache = [[[self class] commentInputCache] objectForKey:pk];
    }

    if (commentCache && [commentCache isKindOfClass:[NSDictionary class]]) {
        NSString *inputCacheString = [commentCache objectForKey:COMMENT_CACHE_TEXT_KEY];
        if ([inputCacheString zui_isValid]) {
            self.composeView.textView.text = inputCacheString;
            [self.composeView layoutSubviews];
        }
    }
}

- (void)saveInputCache
{
    NSString *commentInputCacheKey = nil;
    NSString *pk = [_delegate commentComposePk];
    if ([self.replyComment.pk zui_isValid]) {
        commentInputCacheKey = self.replyComment.pk;
    } else if ([pk zui_isValid]) {
        commentInputCacheKey = pk;
    }

    if (![commentInputCacheKey zui_isValid]) {
        return;
    }

    BOOL hasText = self.composeView.textView.text && [self.composeView.textView.text zui_isValid];
    if (hasText) {
        NSMutableDictionary *commentCache = [[NSMutableDictionary alloc] init];
        [commentCache setObject:self.composeView.plainText forKey:COMMENT_CACHE_TEXT_KEY];
        [[[self class] commentInputCache] setObject:commentCache forKey:commentInputCacheKey];
    } else {
        [[[self class] commentInputCache] removeObjectForKey:commentInputCacheKey];
    }
}

@end
