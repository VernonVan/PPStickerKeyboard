//
//  PPStickerPageView.m
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/15.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import "PPStickerPageView.h"
#import "PPSticker.h"

NSUInteger const PPStickerPageViewMaxEmojiCount = 20;
static NSUInteger const PPStickerPageViewLineCount = 3;
static NSUInteger const PPStickerPageViewButtonPerLine = 7;
static CGFloat const PPStickerPageViewEmojiButtonLength = 32.0;
static CGFloat const PPStickerPageViewEmojiButtonVerticalMargin = 16.0;

@interface PPStickerPageView ()
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) NSTimer *deleteEmojiTimer;
@property (nonatomic, strong) PPSticker *sticker;
@property (nonatomic, strong) NSArray<PPButton *> *emojiButtons;
@end

@implementation PPStickerPageView

@synthesize focused = _focused;
@synthesize reuseIdentifier = _reuseIdentifier;
@synthesize nonreusable = _nonreusable;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithFrame:frame]) {
        NSMutableArray *emojiButtons = [[NSMutableArray alloc] init];
        for (NSUInteger i = 0; i < PPStickerPageViewMaxEmojiCount; i++) {
            PPButton *button = [[PPButton alloc] init];
            button.tag = i;
            [button addTarget:self action:@selector(didClickEmojiButton:) forControlEvents:UIControlEventTouchUpInside];
            UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressEmoji:)];
            longPressRecognizer.minimumPressDuration = 0.2;
            [button addGestureRecognizer:longPressRecognizer];
            [emojiButtons addObject:button];
            [self addSubview:button];
        }
        self.emojiButtons = emojiButtons;
        [self addSubview:self.deleteButton];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame reuseIdentifier:nil];
}

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    return [self initWithFrame:CGRectZero reuseIdentifier:reuseIdentifier];
}

- (UIButton *)deleteButton
{
    if (!_deleteButton) {
        _deleteButton = [[UIButton alloc] init];
        [_deleteButton setImage:[UIImage imageNamed:@"delete-emoji"] forState:UIControlStateNormal];
        [_deleteButton addTarget:self action:@selector(didTouchDownDeleteButton:) forControlEvents:UIControlEventTouchDown];
        [_deleteButton addTarget:self action:@selector(didTouchUpInsideDeleteButton:) forControlEvents:UIControlEventTouchUpInside];
        [_deleteButton addTarget:self action:@selector(didTouchUpOutsideDeleteButton:) forControlEvents:UIControlEventTouchUpOutside];
    }
    return _deleteButton;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat screenWidth = CGRectGetWidth(self.bounds);
    CGFloat spaceBetweenButtons = (screenWidth - PPStickerPageViewButtonPerLine * PPStickerPageViewEmojiButtonLength) / (PPStickerPageViewButtonPerLine + 1);
    for (PPButton *button in self.emojiButtons) {
        NSUInteger index = button.tag;
        if (index > self.sticker.emojis.count) {
            break;
        }

        NSUInteger line = index / PPStickerPageViewButtonPerLine;
        NSUInteger row = index % PPStickerPageViewButtonPerLine;

        CGFloat minX = row * PPStickerPageViewEmojiButtonLength + (row + 1) * spaceBetweenButtons;
        CGFloat minY = line * (PPStickerPageViewEmojiButtonLength + PPStickerPageViewEmojiButtonVerticalMargin);
        button.frame = CGRectMake(minX, minY, PPStickerPageViewEmojiButtonLength, PPStickerPageViewEmojiButtonLength);
        button.touchInsets = UIEdgeInsetsMake(-PPStickerPageViewEmojiButtonVerticalMargin / 2, -spaceBetweenButtons / 2, -PPStickerPageViewEmojiButtonVerticalMargin / 2, -spaceBetweenButtons / 2);
    }

    CGFloat minDeleteX = screenWidth - spaceBetweenButtons - PPStickerPageViewEmojiButtonLength;
    CGFloat minDeleteY = (PPStickerPageViewLineCount - 1) * (PPStickerPageViewEmojiButtonLength + PPStickerPageViewEmojiButtonVerticalMargin);
    self.deleteButton.frame = CGRectMake(minDeleteX, minDeleteY, PPStickerPageViewEmojiButtonLength, PPStickerPageViewEmojiButtonLength);
}

- (void)configureWithSticker:(PPSticker *)sticker
{
    if (!sticker) {
        return;
    }
    self.sticker = sticker;

    NSArray<PPEmoji *> *emojis = [self emojisForSticker:sticker atPage:self.pageIndex];
    NSUInteger index = 0;
    for (PPEmoji *emoji in emojis) {
        if (index > PPStickerPageViewMaxEmojiCount) {
            break;
        }

        PPButton *button = self.emojiButtons[index];
        [button setImage:[self emojiImageWithName:emoji.imageName] forState:UIControlStateNormal];
        index += 1;
    }

    [self setNeedsLayout];
}

#pragma mark - PPReusablePage

- (void)prepareForReuse
{
    self.sticker = nil;
    for (PPButton *button in self.emojiButtons) {
        [button setImage:nil forState:UIControlStateNormal];
        button.frame = CGRectZero;
    }
}

#pragma mark - private method

- (void)didClickEmojiButton:(UIButton *)button
{
    NSUInteger index = button.tag;
    NSArray<PPEmoji *> *emojis = [self emojisForSticker:self.sticker atPage:self.pageIndex];
    if (index >= emojis.count) {
        return;
    }

    PPEmoji *emoji = emojis[index];
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerPageView:didClickEmoji:)]) {
        [self.delegate stickerPageView:self didClickEmoji:emoji];
    }
}

- (void)didTouchDownDeleteButton:(UIButton *)button
{
    if (self.deleteEmojiTimer) {
        [self.deleteEmojiTimer invalidate];
        self.deleteEmojiTimer = nil;
    }

    self.deleteEmojiTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(delegateDeleteEmoji) userInfo:nil repeats:YES];
}

- (void)didTouchUpInsideDeleteButton:(UIButton *)button
{
    [self delegateDeleteEmoji];

    if (self.deleteEmojiTimer) {
        [self.deleteEmojiTimer invalidate];
        self.deleteEmojiTimer = nil;
    }
}

- (void)didTouchUpOutsideDeleteButton:(UIButton *)button
{
    if (self.deleteEmojiTimer) {
        [self.deleteEmojiTimer invalidate];
        self.deleteEmojiTimer = nil;
    }
}

- (void)delegateDeleteEmoji
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerPageViewDidClickDeleteButton:)]) {
        [self.delegate stickerPageViewDidClickDeleteButton:self];
    }
}

- (NSArray<PPEmoji *> *)emojisForSticker:(PPSticker *)sticker atPage:(NSUInteger)page
{
    if (!sticker || !sticker.emojis.count) {
        return nil;
    }

    NSUInteger totalPage = sticker.emojis.count / PPStickerPageViewMaxEmojiCount + 1;
    if (page >= totalPage) {
        return nil;
    }

    BOOL isLastPage = (page == totalPage - 1 ? YES : NO);
    NSUInteger beginIndex = page * PPStickerPageViewMaxEmojiCount;
    NSUInteger length = (isLastPage ? (sticker.emojis.count - page * PPStickerPageViewMaxEmojiCount) : PPStickerPageViewMaxEmojiCount);
    NSArray *emojis = [sticker.emojis subarrayWithRange:NSMakeRange(beginIndex, length)];
    return emojis;
}

- (UIImage *)emojiImageWithName:(NSString *)name
{
    if (!name.length) {
        return nil;
    }
    
    UIImage *image = [UIImage imageNamed:[@"Sticker.bundle" stringByAppendingPathComponent:name]];
    return image;
}

- (void)didLongPressEmoji:(UILongPressGestureRecognizer *)recognizer
{
    if (!self.emojiButtons || !self.emojiButtons.count) {
        return;
    }

    NSArray<PPEmoji *> *emojis = [self emojisForSticker:self.sticker atPage:self.pageIndex];
    if (!emojis || !emojis.count) {
        return;
    }

    PPEmoji *emoji = nil;
    UIButton *currentButton = nil;
    CGPoint point = [recognizer locationInView:self];
    for (NSUInteger i = 0, max = self.emojiButtons.count; i < max; i++) {
        if (CGRectContainsPoint(UIEdgeInsetsInsetRect(self.emojiButtons[i].frame, self.emojiButtons[i].touchInsets), point)) {
            if (i < emojis.count) {
                currentButton = self.emojiButtons[i];
                emoji = emojis[i];
            }
            break;
        }
    }

    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            [self showPreviewViewWithEmoji:emoji button:currentButton];
            break;
        case UIGestureRecognizerStateChanged:
            [self showPreviewViewWithEmoji:emoji button:currentButton];
            break;
        case UIGestureRecognizerStateEnded:
            [self hidePreviewViewForButton:currentButton];
            if (currentButton) {
                [self didClickEmojiButton:currentButton];
            }
            break;
        default:
            [self hidePreviewViewForButton:currentButton];
            break;
    }
}

- (void)showPreviewViewWithEmoji:(PPEmoji *)emoji button:(UIButton *)button
{
    if (!emoji) {
        [self hidePreviewViewForButton:button];
        return;
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerPageView:showEmojiPreviewViewWithEmoji:buttonFrame:)]) {
        [self.delegate stickerPageView:self showEmojiPreviewViewWithEmoji:emoji buttonFrame:button.frame];
    }
}

- (void)hidePreviewViewForButton:(UIButton *)button
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerPageViewHideEmojiPreviewView:)]) {
        [self.delegate stickerPageViewHideEmojiPreviewView:self];
    }
}

@end
