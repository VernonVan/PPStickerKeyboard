//
//  PPStickerDataManager.h
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/17.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PPSticker;

@interface PPStickerDataManager : NSObject

+ (instancetype)sharedInstance;

/// 所有的表情包
@property (nonatomic, strong, readonly) NSArray<PPSticker *> *allStickers;

/* 匹配给定attributedString中的所有emoji，如果匹配到的emoji有本地图片的话会直接换成本地的图片
 *
 * @param attributedString 可能包含表情包的attributedString
 * @param font 表情图片的对齐字体大小
 */
- (void)replaceEmojiForAttributedString:(NSMutableAttributedString *)attributedString font:(UIFont *)font;

@end
