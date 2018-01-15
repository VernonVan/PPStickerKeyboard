//
//  PPSktickerKeyboard.m
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/14.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import "PPStickerKeyboard.h"
#import "PPSticker.h"
#import "PPEmojiPreviewView.h"
#import "PPSlideLineButton.h"
#import "PPUIColor.h"
#import "PPScreen.h"
#import "PPStickerPageView.h"

static CGFloat const PPStickerTopInset = 12.0;
static CGFloat const PPStickerScrollViewHeight = 132.0;
static CGFloat const PPKeyboardPageControlTopMargin = 10.0;
static CGFloat const PPKeyboardPageControlHeight = 7.0;
static CGFloat const PPKeyboardCoverButtonWidth = 50.0;
static CGFloat const PPKeyboardCoverButtonHeight = 44.0;
static CGFloat const PPPreviewViewWidth = 92.0;
static CGFloat const PPPreviewViewHeight = 137.0;

#define SEGMENT_HEIGHT ([UIScreen pp_isIPhoneX] ? 34.0 + 44.0 : 44.0)

@interface PPStickerKeyboard ()
@property (nonatomic, strong) NSArray<PPSticker *> *stickers;
@property (nonatomic, strong) UIScrollView *queuingScrollView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) NSArray<PPSlideLineButton *> *stickerCoverButtons;
@property (nonatomic, strong) PPSlideLineButton *sendButton;
@property (nonatomic, strong) UIScrollView *bottomScrollableSegment;
@property (nonatomic, strong) UIView *bottomBGView;
@property (nonatomic, strong) PPEmojiPreviewView *emojiPreviewView;
@end

@implementation PPStickerKeyboard {
    NSUInteger _currentStickerIndex;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _currentStickerIndex = 0;

        [self addSubview:self.queuingScrollView];
        [self addSubview:self.pageControl];
        [self addSubview:self.bottomBGView];
        [self addSubview:self.sendButton];
        [self addSubview:self.bottomScrollableSegment];

        [self initStickers];
        [self reloadScrollableSegment];
        [self changeStickerToIndex:0];
    }
    return self;
}

- (void)initStickers
{
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.queuingScrollView.frame = CGRectMake(0, PPStickerTopInset, CGRectGetWidth(self.bounds), PPStickerScrollViewHeight);
    self.pageControl.frame = CGRectMake(0, CGRectGetMaxY(self.queuingScrollView.frame) + PPKeyboardPageControlTopMargin, CGRectGetWidth(self.bounds), PPKeyboardPageControlHeight);

    NSUInteger buttonCount = self.stickerCoverButtons.count;
    [self reloadScrollableSegment];
    for (NSUInteger i = 0; i < buttonCount; i++) {
        PPSlideLineButton *button = self.stickerCoverButtons[i];
        button.frame = CGRectMake(i * PPKeyboardCoverButtonWidth, 0, PPKeyboardCoverButtonWidth, PPKeyboardCoverButtonHeight);

        if (_currentStickerIndex == i) {
            button.backgroundColor = [UIColor pp_colorWithRGBString:@"#EDEDED"];
        } else {
            button.backgroundColor = [UIColor whiteColor];
        }
    }
    self.bottomScrollableSegment.contentSize = CGSizeMake(buttonCount * PPKeyboardCoverButtonWidth, PPKeyboardCoverButtonHeight);
    self.bottomScrollableSegment.frame = CGRectMake(0, CGRectGetHeight(self.bounds) - SEGMENT_HEIGHT, CGRectGetWidth(self.bounds) - PPKeyboardCoverButtonWidth, SEGMENT_HEIGHT);

    self.sendButton.frame = CGRectMake(CGRectGetWidth(self.bounds) - PPKeyboardCoverButtonWidth, CGRectGetMinY(self.bottomScrollableSegment.frame), PPKeyboardCoverButtonWidth, PPKeyboardCoverButtonHeight);
    self.bottomBGView.frame = CGRectMake(0, CGRectGetMinY(self.bottomScrollableSegment.frame), CGRectGetWidth(self.frame), SEGMENT_HEIGHT);
}

#pragma mark - getter / setter

- (UIScrollView *)queuingScrollView
{
    if (!_queuingScrollView) {
        _queuingScrollView = [[UIScrollView alloc] init];
    }
    return _queuingScrollView;
}

- (UIPageControl *)pageControl
{
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.hidesForSinglePage = YES;
    }
    return _pageControl;
}

- (PPSlideLineButton *)sendButton
{
    if (!_sendButton) {
        _sendButton = [[PPSlideLineButton alloc] init];
        [_sendButton setTitle:@"发送" forState:UIControlStateNormal];
        _sendButton.linePosition = PPSlideLineButtonPositionLeft;
        [_sendButton addTarget:self action:@selector(sendAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sendButton;
}

- (UIScrollView *)bottomScrollableSegment
{
    if (!_bottomScrollableSegment) {
        _bottomScrollableSegment = [[UIScrollView alloc] init];
        _bottomScrollableSegment.showsHorizontalScrollIndicator = NO;
        _bottomScrollableSegment.showsVerticalScrollIndicator = NO;
    }
    return _bottomScrollableSegment;
}

- (UIView *)bottomBGView
{
    if (!_bottomBGView) {
        _bottomBGView = [[UIView alloc] init];
    }
    return _bottomBGView;
}

- (PPEmojiPreviewView *)emojiPreviewView
{
    if (!_emojiPreviewView) {
        _emojiPreviewView = [[PPEmojiPreviewView alloc] init];
    }
    return _emojiPreviewView;
}

#pragma mark - private method

- (PPSticker *)stickerAtIndex:(NSUInteger)index
{
    if (self.stickers && index < self.stickers.count) {
        return self.stickers[index];
    }
    return nil;
}

- (void)reloadScrollableSegment
{
    for (UIButton *button in self.stickerCoverButtons) {
        [button removeFromSuperview];
    }
    self.stickerCoverButtons = nil;

    if (!self.stickers || !self.stickers.count) {
        return;
    }

    NSMutableArray *stickerCoverButtons = [[NSMutableArray alloc] init];
    for (NSUInteger index = 0, max = self.stickers.count; index < max; index++) {
        PPSlideLineButton *button = [[PPSlideLineButton alloc] init];
        button.tag = index++;
        button.imageView.contentMode = UIViewContentModeScaleAspectFit;
        button.linePosition = PPSlideLineButtonPositionRight;
        button.lineColor = [UIColor pp_colorWithRGBString:@"#D1D1D1"];
        button.backgroundColor = (_currentStickerIndex == index ? [UIColor pp_colorWithRGBString:@"#EDEDED"] : [UIColor whiteColor]);
        [button addTarget:self action:@selector(changeSticker:) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomScrollableSegment addSubview:button];
        [stickerCoverButtons addObject:button];
    }
    self.stickerCoverButtons = stickerCoverButtons;
}

- (void)changeStickerToIndex:(NSUInteger)toIndex
{
    if (toIndex >= self.stickerCoverButtons.count) {
        return;
    }

    _currentStickerIndex = toIndex;
    [self reloadScrollableSegment];
}

#pragma mark - target / action

- (void)changeSticker:(UIButton *)button
{
    [self changeStickerToIndex:button.tag];
}

- (void)sendAction:(PPSlideLineButton *)button
{
}

#pragma mark - PPStickerPageViewDelegate

- (void)stickerPageView:(PPStickerPageView *)stickerPageView didClickEmoji:(PPEmoji *)emoji
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerKeyboard:didClickEmoji:)]) {
        [self.delegate stickerKeyboard:self didClickEmoji:emoji];
    }
}

- (void)stickerPageViewDidClickDeleteButton:(PPStickerPageView *)stickerPageView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerKeyboardDidClickDeleteButton:)]) {
        [self.delegate stickerKeyboardDidClickDeleteButton:self];
    }
}

- (void)stickerPageView:(PPStickerPageView *)stickerKeyboard showEmojiPreviewViewWithEmoji:(PPEmoji *)emoji buttonFrame:(CGRect)buttonFrame
{
    if (!emoji) {
        return;
    }

    UIImage *emojiImage = [UIImage imageNamed:emoji.imageName];
    if (!emojiImage) {
        return;
    }

    self.emojiPreviewView.emoji = emoji;

    CGRect buttonFrameAtKeybord = CGRectMake(buttonFrame.origin.x, PPStickerTopInset + buttonFrame.origin.y, buttonFrame.size.width, buttonFrame.size.height);
    self.emojiPreviewView.frame = CGRectMake(CGRectGetMidX(buttonFrameAtKeybord) - PPPreviewViewWidth / 2, UIScreen.mainScreen.bounds.size.height - CGRectGetHeight(self.bounds) + CGRectGetMaxY(buttonFrameAtKeybord) - PPPreviewViewHeight, PPPreviewViewWidth, PPPreviewViewHeight);

    UIWindow *window = [UIApplication sharedApplication].windows.lastObject;
    if (window) {
        [window addSubview:self.emojiPreviewView];
    }
}

@end
