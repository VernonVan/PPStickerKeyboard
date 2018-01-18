//
//  PPStickerPageView.h
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/15.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PPUtil.h"
@class PPStickerPageView;
@class PPSticker;
@class PPEmoji;

extern NSUInteger const PPStickerPageViewMaxEmojiCount;

@protocol PPStickerPageViewDelegate <NSObject>

- (void)stickerPageView:(PPStickerPageView *)stickerPageView didClickEmoji:(PPEmoji *)emoji;
- (void)stickerPageViewDidClickDeleteButton:(PPStickerPageView *)stickerPageView;
- (void)stickerPageView:(PPStickerPageView *)stickerKeyboard showEmojiPreviewViewWithEmoji:(PPEmoji *)emoji buttonFrame:(CGRect)buttonFrame;
- (void)stickerPageViewHideEmojiPreviewView:(PPStickerPageView *)stickerKeyboard;

@end

@interface PPStickerPageView : UIView <PPReusablePage>

@property (nonatomic, weak) id<PPStickerPageViewDelegate> delegate;
@property (nonatomic, assign) NSUInteger pageIndex;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

- (void)configureWithSticker:(PPSticker *)sticker;

@end
