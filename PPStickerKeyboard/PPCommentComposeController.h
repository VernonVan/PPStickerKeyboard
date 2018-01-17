//
//  PPCommentComposeController.h
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/14.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import <ZUIKit/ZUIKit.h>

@class ZKRBlockManager;
@class ZKRCommentApiManager;
@class ZKRCommentComposeBar;
@class ZKRCommentComposeController;
@class ZKRCommentReplyAction;
@class ZKRInBlockComment;

@protocol ZKRCommentComposeControllerDelegate <NSObject>

@required

- (void)commentCompose:(ZKRCommentComposeController *)composeController didSendWithError:(NSError *)error;

- (void)commentComposeEndEditing:(ZKRCommentComposeController *)composeController;

- (BOOL)commentComposeShouldBeginEditing:(ZKRCommentComposeController *)composeController;

/** 返回 article.pk / activity.pk ... */
- (NSString *)commentComposePk;

@optional

- (void)commentCompose:(ZKRCommentComposeController *)composeController shouldSendComment:(ZKRInBlockComment *)comment;

@end

@interface ZKRCommentComposeController : NSObject

@property (nonatomic) ZKRCommentReplyAction *replyAction;
@property (nonatomic) ZKRBlockManager *blockManager;
@property (nonatomic) ZKRCommentApiManager *apiManager;     // 必须赋值
@property (nonatomic) ZUIThemeMode themeMode;
@property (nonatomic, weak) id<ZKRCommentComposeControllerDelegate> delegate;
@property (nonatomic) BOOL shouldShowLoginTips;

- (ZKRCommentComposeBar *)composeView;

- (BOOL)isComposeViewEditing;

- (void)showCommentComposeInView:(UIView *)showView withReplyComment:(ZKRInBlockComment *)commentModel;

- (void)closeCommentCompose;

@end
