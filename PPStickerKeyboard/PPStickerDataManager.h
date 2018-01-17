//
//  PPStickerDataManager.h
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/17.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PPSticker;

@interface PPStickerMatchingResult : NSObject
@property (nonatomic, assign) NSRange range;                    // 匹配到的表情包文本的range
@property (nonatomic, strong) UIImage *emojiImage;              // 如果能在本地找到emoji的图片，则此值不为空
@property (nonatomic, strong) NSString *showingDescription;     // 显示在界面上的文本(形如：[哈哈])，不为空
@end

@interface PPStickerDataManager : NSObject

+ (instancetype)sharedInstance;

/// 所有的表情包
@property (nonatomic, strong, readonly) NSArray<PPSticker *> *allStickers;

/* 匹配给定string中的所有emoji
 *
 * @param string 被匹配的字符串
 *
 * @return 匹配结果
 */
- (NSArray<PPStickerMatchingResult *> *)matchingEmojiForString:(NSString *)string;

/* 匹配给定attributedString中的所有emoji，如果匹配到的emoji有本地图片的话会直接换成本地的图片；如果没有本地图片的话会把内部编码改成明文能显示的描述(如：[\e1_1:哈哈] -> [哈哈])，并会尝试下载该表情
 *
 * @param attributedString 可能包含表情包的attributedString
 */
- (void)replaceEmojiForAttributedString:(NSMutableAttributedString *)attributedString;

@end
