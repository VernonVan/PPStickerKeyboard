//
//  PPStickerTextView.h
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/17.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PPStickerDataManager.h"
@class PPStickerInputView;

typedef NS_ENUM (NSUInteger, PPKeyboardType) {
    PPKeyboardTypeNone = 0,
    PPKeyboardTypeSystem,
    PPKeyboardTypeSticker,
};

@protocol PPStickerInputViewDelegate <NSObject>

@optional

- (BOOL)stickerInputViewShouldBeginEditing:(PPStickerInputView *)inputView;

- (void)stickerInputViewDidEndEditing:(PPStickerInputView *)inputView;

- (void)stickerInputViewDidChange:(PPStickerInputView *)inputView;

- (void)stickerInputViewDidClickSendButton:(PPStickerInputView *)inputView;

@end

@interface PPStickerInputView : UIView

@property (nonatomic, weak) id<PPStickerInputViewDelegate> delegate;

@property (nonatomic, strong, readonly) NSString *plainText;

@property (nonatomic, assign, readonly) PPKeyboardType keyboardType;

- (CGFloat)heightThatFits;

- (void)clearText;

- (void)changeKeyboardTo:(PPKeyboardType)toType;

@end
