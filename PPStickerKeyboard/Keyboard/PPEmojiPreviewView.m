//
//  PPEmojiPreviewView.m
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/14.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import "PPEmojiPreviewView.h"
#import "PPEmoji.h"
#import "PPUtil.h"

static CGFloat PPEmojiPreviewImageTopPadding = 18.0;
static CGFloat PPEmojiPreviewImageLeftRightPadding = 22.0;
static CGFloat PPEmojiPreviewImageLength = 48.0;
static CGFloat PPEmojiPreviewImageBottomMargin = 2.0;
static CGFloat PPEmojiPreviewTextMaxWidth = 60.0;
static CGFloat PPEmojiPreviewTextHeight = 13.0;

@interface PPEmojiPreviewView ()
@property (nonatomic, strong) UIImageView *emojiImageView;
@property (nonatomic, strong) UILabel *descriptionLabel;
@end

@implementation PPEmojiPreviewView

- (instancetype)init
{
    if (self = [super init]) {
        self.image = [UIImage imageNamed:@"emoji-preview-bg"];
        [self addSubview:self.emojiImageView];
        [self addSubview:self.descriptionLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    if (!self.emoji) {
        return;
    }
    self.emojiImageView.image = [UIImage imageNamed:[@"Sticker.bundle" stringByAppendingPathComponent:self.emoji.imageName]];
    self.emojiImageView.frame = CGRectMake(PPEmojiPreviewImageLeftRightPadding, PPEmojiPreviewImageTopPadding, PPEmojiPreviewImageLength, PPEmojiPreviewImageLength);

    self.descriptionLabel.text = self.emoji.emojiDescription;
    CGSize labelSize = [self.descriptionLabel textRectForBounds:CGRectMake(0, 0, PPEmojiPreviewTextMaxWidth, PPEmojiPreviewTextHeight) limitedToNumberOfLines:1].size;
    self.descriptionLabel.frame = CGRectMake((CGRectGetWidth(self.bounds) - labelSize.width) / 2, CGRectGetMaxY(self.emojiImageView.frame) + PPEmojiPreviewImageBottomMargin, labelSize.width, labelSize.height);
}

- (void)setEmoji:(PPEmoji *)emoji
{
    if (_emoji != emoji) {
        _emoji = emoji;
        [self setNeedsLayout];
    }
}

- (UIImageView *)emojiImageView
{
    if (!_emojiImageView) {
        _emojiImageView = [[UIImageView alloc] init];
    }
    return _emojiImageView;
}

- (UILabel *)descriptionLabel
{
    if (!_descriptionLabel) {
        _descriptionLabel = [[UILabel alloc] init];
        _descriptionLabel.font = [UIFont systemFontOfSize:11.0];
        _descriptionLabel.textColor = [UIColor pp_colorWithRGBString:@"#4A4A4A"];
        _descriptionLabel.lineBreakMode = NSLineBreakByCharWrapping;
    }
    return _descriptionLabel;
}

@end
