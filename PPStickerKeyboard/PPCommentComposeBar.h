//
//  PPCommentComposeBar.h
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/17.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PPCommentComposeBar;

typedef NS_ENUM (NSUInteger, PPKeyboardType) {
    PPKeyboardTypeNone = 0,
    PPKeyboardTypeSystem,
    PPKeyboardTypeSticker,
};

@protocol PPCommentComposeBarDelegate <NSObject>

@optional

- (BOOL)commentComposeViewShouldBeginEditing:(PPCommentComposeBar *)composeBar;

- (void)commentComposeViewDidEndEditing:(PPCommentComposeBar *)composeBar;

- (void)commentComposeViewDidPressReturnKey:(PPCommentComposeBar *)composeBar;

- (void)commentComposeViewDidChange:(PPCommentComposeBar *)composeBar;

- (void)commentComposeViewDidClickSendButton:(PPCommentComposeBar *)composeBar;

@end

@interface PPCommentComposeBar : UIView 

@property (nonatomic, weak) id<PPCommentComposeBarDelegate> delegate;

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong, readonly) NSString *plainText;

@property (nonatomic) CGFloat minHeight;
@property (nonatomic) CGFloat maxHeight;

@property (nonatomic, assign, readonly) PPKeyboardType keyboardType;

- (BOOL)isEditing;

- (CGFloat)heightThatFit;

- (void)clearText;

- (void)changeKeyboardTo:(PPKeyboardType)toType;

@end
