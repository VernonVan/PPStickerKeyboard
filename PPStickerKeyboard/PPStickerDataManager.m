//
//  PPStickerDataManager.m
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/17.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import "PPStickerDataManager.h"
#import "PPSticker.h"

@implementation PPStickerMatchingResult
@end

@interface PPStickerDataManager ()
@property (nonatomic, strong, readwrite) NSArray<PPSticker *> *allStickers;
@end

@implementation PPStickerDataManager

+ (instancetype)sharedInstance
{
    static PPStickerDataManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PPStickerDataManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self initStickers];
    }
    return self;
}

- (void)initStickers
{
    NSString *path = [NSBundle.mainBundle pathForResource:@"InnerStickersInfo" ofType:@"plist"];
    if (!path) {
        return;
    }

    NSArray *array = [[NSArray alloc] initWithContentsOfFile:path];
    NSMutableArray<PPSticker *> *stickers = [[NSMutableArray alloc] init];
    for (NSDictionary *stickerDict in array) {
        PPSticker *sticker = [[PPSticker alloc] init];
        sticker.coverImageName = stickerDict[@"cover_pic"];
        NSArray *emojiArr = stickerDict[@"emoticons"];
        NSMutableArray<PPEmoji *> *emojis = [[NSMutableArray alloc] init];
        for (NSDictionary *emojiDict in emojiArr) {
            PPEmoji *emoji = [[PPEmoji alloc] init];
            emoji.imageName = emojiDict[@"image"];
            emoji.emojiDescription = emojiDict[@"desc"];
            [emojis addObject:emoji];
        }
        sticker.emojis = emojis;
        [stickers addObject:sticker];
    }
    self.allStickers = stickers;
}

#pragma mark - public method

- (NSArray<PPStickerMatchingResult *> *)matchingEmojiForString:(NSString *)string
{
    if (!string.length) {
        return nil;
    }

    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\[.+?\\]" options:0 error:NULL];
    NSArray<NSTextCheckingResult *> *results = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    if (results && results.count) {
        NSMutableArray *emojiMatchingResults = [[NSMutableArray alloc] init];
        for (NSTextCheckingResult *result in results) {
            NSString *emojiSubString = [string substringWithRange:result.range];
            NSString *showingDescription = [emojiSubString substringFromIndex:1];       // 去掉[
            showingDescription = [showingDescription substringWithRange:NSMakeRange(0, showingDescription.length - 1)];    // 去掉]
            PPEmoji *emoji = [self emojiWithEmojiDescription:showingDescription];
            if (emoji) {
                PPStickerMatchingResult *emojiMatchingResult = [[PPStickerMatchingResult alloc] init];
                emojiMatchingResult.range = result.range;
                emojiMatchingResult.showingDescription = emojiSubString;
                emojiMatchingResult.emojiImage = [UIImage imageNamed:showingDescription];
                [emojiMatchingResults addObject:emojiMatchingResult];
            }
        }
        return emojiMatchingResults;
    }
    return nil;
}

- (void)replaceEmojiForAttributedString:(NSMutableAttributedString *)attributedString
{
    if (!attributedString || !attributedString.length) {
        return;
    }

    NSArray<PPStickerMatchingResult *> *matchingResults = [self matchingEmojiForString:attributedString.string isShowEmoji:isShowEmoji];
    NSDictionary<NSString *, id> *attributes = attributedString.yy_attributes;
    UIFont *font = emojiBaseFont ? emojiBaseFont : attributedString.yy_font;
    NSUInteger offset = 0;
    if (matchingResults && matchingResults.count) {
        for (PPStickerMatchingResult *result in matchingResults) {
            if (isShowEmoji && result.emojiImage) {
                CGFloat fontHeight = font.lineHeight;
                NSMutableAttributedString *emojiAttributedString = [NSMutableAttributedString yy_attachmentStringWithContent:result.emojiImage contentMode:UIViewContentModeScaleAspectFit attachmentSize:CGSizeMake(fontHeight, fontHeight) alignToFont:font alignment:YYTextVerticalAlignmentCenter];
                [emojiAttributedString yy_setTextBackedString:[YYTextBackedString stringWithString:result.backedDescription] range:NSMakeRange(0, emojiAttributedString.length)];
                if (!emojiAttributedString) {
                    continue;
                }
                NSRange actualRange = NSMakeRange(result.range.location - offset, result.backedDescription.length);
                [attributedString replaceCharactersInRange:actualRange withAttributedString:emojiAttributedString];
                offset += result.backedDescription.length - emojiAttributedString.length;
            } else {
                NSMutableAttributedString *attributedDescription = [[NSMutableAttributedString alloc] initWithString:result.showingDescription attributes:attributes];
                if (isShowEmoji) {
                    [attributedDescription yy_setTextBackedString:[YYTextBackedString stringWithString:result.backedDescription] range:NSMakeRange(0, attributedDescription.length)];
                }
                if (!attributedDescription) {
                    continue;
                }
                NSRange actualRange = NSMakeRange(result.range.location - offset, result.backedDescription.length);
                [attributedString replaceCharactersInRange:actualRange withAttributedString:attributedDescription];
                offset += result.backedDescription.length - result.showingDescription.length;
            }
        }
    }
}

#pragma mark - private method

- (PPEmoji *)emojiWithEmojiDescription:(NSString *)emojiDescription
{
    for (PPSticker *sticker in self.allStickers) {
        for (PPEmoji *emoji in sticker.emojis) {
            if ([emoji.emojiDescription isEqualToString:emojiDescription]) {
                return emoji;
            }
        }
    }
    return nil;
}

@end
