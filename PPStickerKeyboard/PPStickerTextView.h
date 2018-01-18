//
//  PPStickerTextView.h
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/17.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PPStickerTextView;

typedef NS_ENUM (NSUInteger, PPKeyboardType) {
    PPKeyboardTypeNone = 0,
    PPKeyboardTypeSystem,
    PPKeyboardTypeSticker,
};

@protocol PPStickerTextViewDelegate <NSObject>

@optional

- (void)stickerTextViewDidEndEditing:(PPStickerTextView *)composeBar;

- (void)stickerTextViewDidPressReturnKey:(PPStickerTextView *)composeBar;

- (void)stickerTextViewDidChange:(PPStickerTextView *)composeBar;

- (void)stickerTextViewDidClickSendButton:(PPStickerTextView *)composeBar;

@end

@interface PPStickerTextView : UIView

@property (nonatomic, weak) id<PPStickerTextViewDelegate> delegate;

@property (nonatomic, strong, readonly) NSString *plainText;

@property (nonatomic, assign, readonly) PPKeyboardType keyboardType;

- (CGFloat)heightThatFits;

- (void)clearText;

- (void)changeKeyboardTo:(PPKeyboardType)toType;

@end
