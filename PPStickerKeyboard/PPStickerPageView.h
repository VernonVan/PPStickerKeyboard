//
//  PPStickerPageView.h
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/15.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PPStickerPageView;
@class PPSticker;
@class PPEmoji;

@protocol PPStickerPageViewDelegate <NSObject>

- (void)stickerPageView:(PPStickerPageView *)stickerPageView didClickEmoji:(PPEmoji *)emoji;
- (void)stickerPageViewDidClickDeleteButton:(PPStickerPageView *)stickerPageView;
- (void)stickerPageView:(PPStickerPageView *)stickerKeyboard showEmojiPreviewViewWithEmoji:(PPEmoji *)emoji buttonFrame:(CGRect)buttonFrame;
- (void)stickerPageViewHideEmojiPreviewView:(PPStickerPageView *)stickerKeyboard;

@end

@interface PPStickerPageView : UIView

@end
