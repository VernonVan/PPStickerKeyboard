//
//  PPStickerTextView.m
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/17.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import "PPStickerTextView.h"
#import "PPStickerKeyboard.h"
#import "PPStickerDataManager.h"
#import "PPUtil.h"

static CGFloat const PPStickerTextViewHeight = 44.0;
static CGFloat const PPStickerTextViewLeftRightPadding = 20.0;

static CGFloat const PPStickerTextViewTextViewTopMargin = 6.0;
static CGFloat const PPStickerTextViewTextViewUnfocusLeftRightPadding = 5.0;
static CGFloat const PPStickerTextViewTextViewLeftRightPadding = 16.0;
static CGFloat const PPStickerTextViewTextViewBottomMargin = 10.0;
static NSUInteger const PPStickerTextViewMaxLineCount = 6;
static NSUInteger const PPStickerTextViewMinLineCount = 3;
static CGFloat const PPStickerTextViewLineSpacing = 5.0;
static CGFloat const PPStickerTextViewFontSize = 16.0;

static CGFloat const PPStickerTextViewEmojiToggleLength = 48.0;
static CGFloat const PPStickerTextViewToggleButtonLength = 24.0;

#define STICKER_KEYBOARD_HEIGHT ([UIScreen pp_isIPhoneX] ? 34.0 + 212.0 : 212.0)

@interface PPStickerTextView () <UITextViewDelegate, PPStickerKeyboardDelegate> {
    BOOL _keepsPreMode;
}

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIView *separatedLine;
@property (nonatomic, strong) UIButton *emojiToggleButton;
@property (nonatomic, strong) PPStickerKeyboard *stickerKeyboard;
@property (nonatomic, strong) UIView *bottomBGView;     // 消除语音键盘的空隙

@property (nonatomic, assign, readwrite) PPKeyboardType keyboardType;

@end

@implementation PPStickerTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentMode = UIViewContentModeRedraw;
        self.exclusiveTouch = YES;
        self.backgroundColor = [UIColor whiteColor];
        self.textView.backgroundColor = [UIColor grayColor];

        _stickerKeyboard.delegate = self;
        _keyboardType = PPKeyboardTypeSystem;
        _keepsPreMode = YES;

        [self addSubview:self.textView];
        [self addSubview:self.separatedLine];
        [self addSubview:self.emojiToggleButton];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    [[UIColor pp_colorWithRGBString:@"#D2D2D2"] setStroke];

    CGContextSaveGState(context);
    CGContextSetLineWidth(context, PPOnePixelToPoint());
    CGContextMoveToPoint(context, 0, PPOnePixelToPoint() / 2);
    CGContextAddLineToPoint(context, CGRectGetMaxX(self.bounds), PPOnePixelToPoint() / 2);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.textView.frame = [self frameTextView];
    if (!self.textView.isFirstResponder) {
        self.separatedLine.frame = CGRectZero;
        self.emojiToggleButton.frame = CGRectZero;
    } else {
        self.separatedLine.frame = [self frameSeparatedLine];
        self.emojiToggleButton.frame = [self frameEmojiToggleButton];
    }

    [self refreshTextUI];
}

- (CGFloat)heightThatFits
{    
    if (_keepsPreMode) {
        return PPStickerTextViewHeight;
    } else {
        CGFloat textViewHeight = [self.textView.layoutManager usedRectForTextContainer:self.textView.textContainer].size.height;
        CGFloat minHeight = [self heightWithLine:PPStickerTextViewMinLineCount];
        CGFloat maxHeight = [self heightWithLine:PPStickerTextViewMaxLineCount];
        CGFloat calculateHeight = MIN(maxHeight, MAX(minHeight, textViewHeight));
        CGFloat height = PPStickerTextViewTextViewTopMargin + calculateHeight + PPStickerTextViewTextViewBottomMargin + PPStickerTextViewEmojiToggleLength;
        return height;
    }
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return CGSizeMake(size.width, [self heightThatFits]);
}

- (void)sizeToFit
{
    CGSize size = [self sizeThatFits:self.bounds.size];
    self.frame = CGRectMake(CGRectGetMinX(self.frame), CGRectGetMaxY(self.frame) - size.height, size.width, size.height);
}

#pragma mark - public method

- (void)clearText
{
    self.textView.text = nil;
    [self sizeToFit];
}

- (NSString *)plainText
{
    return [self.textView.attributedText pp_plainTextForRange:NSMakeRange(0, self.textView.attributedText.length)];
}

- (void)changeKeyboardTo:(PPKeyboardType)toType
{
    if (self.keyboardType == toType) {
        return;
    }

    switch (toType) {
        case PPKeyboardTypeNone:
            [self.emojiToggleButton setImage:[UIImage imageNamed:@"toggle_emoji"] forState:UIControlStateNormal];
            self.textView.inputView = nil;
            break;
        case PPKeyboardTypeSystem:
            [self.emojiToggleButton setImage:[UIImage imageNamed:@"toggle_emoji"] forState:UIControlStateNormal];
            self.textView.inputView = nil;
            [self.textView reloadInputViews];
            break;
        case PPKeyboardTypeSticker:
            [self.emojiToggleButton setImage:[UIImage imageNamed:@"toggle_keyboard"] forState:UIControlStateNormal];
            self.textView.inputView = self.stickerKeyboard;
            [self.textView reloadInputViews];
            break;
        default:
            break;
    }

    self.keyboardType = toType;
}

#pragma mark - getter / setter

- (UITextView *)textView
{
    if (!_textView) {
        _textView = [[UITextView alloc] initWithFrame:self.bounds];
        _textView.delegate = self;
        _textView.backgroundColor = [UIColor clearColor];
        _textView.font = [UIFont systemFontOfSize:PPStickerTextViewFontSize];
        _textView.scrollsToTop = NO;
        _textView.returnKeyType = UIReturnKeySend;
        _textView.enablesReturnKeyAutomatically = YES;
        if (@available(iOS 11.0, *)) {
            _textView.textDragInteraction.enabled = NO;
        }
    }
    return _textView;
}

- (UIView *)separatedLine
{
    if (!_separatedLine) {
        _separatedLine = [[UIView alloc]init];
        _separatedLine.backgroundColor = [UIColor pp_colorWithRGBString:@"#DEDEDE"];
    }
    return _separatedLine;
}

- (UIButton *)emojiToggleButton
{
    if (!_emojiToggleButton) {
        _emojiToggleButton = [[UIButton alloc] init];
        [_emojiToggleButton setImage:[UIImage imageNamed:@"toggle_emoji"] forState:UIControlStateNormal];
        [_emojiToggleButton addTarget:self action:@selector(toggleKeyboardDidClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _emojiToggleButton;
}

- (PPStickerKeyboard *)stickerKeyboard
{
    if (!_stickerKeyboard) {
        _stickerKeyboard = [[PPStickerKeyboard alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), STICKER_KEYBOARD_HEIGHT)];
    }
    return _stickerKeyboard;
}

- (UIView *)bottomBGView
{
    if (!_bottomBGView) {
        _bottomBGView = [[UIView alloc] init];
        _bottomBGView.backgroundColor = [UIColor whiteColor];
    }
    return _bottomBGView;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    self.bottomBGView.frame = CGRectMake(0, CGRectGetMaxY(frame), CGRectGetWidth(self.bounds), UIScreen.mainScreen.bounds.size.height - CGRectGetMaxY(frame));
}

- (void)setFrame:(CGRect)frame animated:(BOOL)animated
{
    if (CGRectEqualToRect(frame, self.frame)) {
        return;
    }

    void (^ changesAnimations)(void) = ^{
        [self setFrame:frame];
        [self setNeedsLayout];
    };

    if (changesAnimations) {
        if (animated) {
            [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:changesAnimations completion:nil];
        } else {
            changesAnimations();
        }
    }
}

#pragma mark - private method

- (void)refreshTextUI
{
    if (!self.textView.text.length) {
        return;
    }

    UITextRange *markedTextRange = [self.textView markedTextRange];
    UITextPosition *position = [self.textView positionFromPosition:markedTextRange.start offset:0];
    if (position) {
        return;     // 正处于输入拼音还未点确定的中间状态
    }

    NSRange selectedRange = self.textView.selectedRange;

    NSMutableAttributedString *attributedComment = [[NSMutableAttributedString alloc] initWithString:self.plainText attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:PPStickerTextViewFontSize], NSForegroundColorAttributeName: [UIColor pp_colorWithRGBString:@"#3B3B3B"] }];

    // 匹配表情
    [PPStickerDataManager.sharedInstance replaceEmojiForAttributedString:attributedComment font:[UIFont systemFontOfSize:PPStickerTextViewFontSize]];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = PPStickerTextViewLineSpacing;
    [attributedComment addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:attributedComment.pp_rangeOfAll];

    NSUInteger offset = self.textView.attributedText.length - attributedComment.length;
    self.textView.attributedText = attributedComment;
    self.textView.selectedRange = NSMakeRange(selectedRange.location - offset, 0);
}

- (void)toggleKeyboardDidClick:(id)sender
{
    [self changeKeyboardTo:(self.keyboardType == PPKeyboardTypeSystem ? PPKeyboardTypeSticker : PPKeyboardTypeSystem)];
}

- (CGFloat)heightWithLine:(NSInteger)lineNumber
{
    NSString *onelineStr = [[NSString alloc] init];
    CGRect onelineRect = [onelineStr boundingRectWithSize:CGSizeMake(self.textView.frame.size.width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:PPStickerTextViewFontSize] } context:nil];
    CGFloat heigth = lineNumber * onelineRect.size.height + (lineNumber - 1) * PPStickerTextViewLineSpacing;
    return heigth;
}

- (CGRect)frameTextView
{
    CGFloat minX = (self.textView.isFirstResponder ? PPStickerTextViewTextViewLeftRightPadding : PPStickerTextViewTextViewUnfocusLeftRightPadding);
    CGFloat width = self.bounds.size.width - (2 * minX);

    CGFloat height = 0;
    if (!self.textView.isFirstResponder) {
        height = CGRectGetHeight(self.bounds) - 2 * PPStickerTextViewTextViewTopMargin;
    } else {
       height = CGRectGetHeight(self.bounds) - PPStickerTextViewTextViewTopMargin - PPStickerTextViewTextViewBottomMargin - PPStickerTextViewEmojiToggleLength;
    }
    if (height < 0) {
        height = self.bounds.size.height;
    }

    return CGRectMake(minX, PPStickerTextViewTextViewTopMargin, width, height);
}

- (CGRect)frameSeparatedLine
{
    return CGRectMake(0, CGRectGetHeight(self.bounds) - PPStickerTextViewEmojiToggleLength, self.bounds.size.width, PPOnePixelToPoint());
}

- (CGRect)frameEmojiToggleButton
{
    return CGRectMake(PPStickerTextViewLeftRightPadding, CGRectGetHeight(self.bounds) - (PPStickerTextViewEmojiToggleLength + PPStickerTextViewToggleButtonLength) / 2, PPStickerTextViewToggleButtonLength, PPStickerTextViewToggleButtonLength);
}

#pragma mark - UITextView

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    _keepsPreMode = NO;
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([@"\n" isEqualToString:text]) {
        [self delegateDidPressReturnKey];
        return NO;
    }

    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    _keepsPreMode = YES;
    if ([self.delegate respondsToSelector:@selector(stickerTextViewDidEndEditing:)]) {
        [self.delegate stickerTextViewDidEndEditing:self];
    }
}

- (void)delegateDidPressReturnKey
{
    if ([self.delegate respondsToSelector:@selector(stickerTextViewDidPressReturnKey:)]) {
        [self.delegate stickerTextViewDidPressReturnKey:self];
    }
}

- (void)textViewDidChange:(UITextView *)textView
{
    [self refreshTextUI];

    CGSize size = [self sizeThatFits:self.bounds.size];
    CGRect newFrame = CGRectMake(CGRectGetMinX(self.frame), CGRectGetMaxY(self.frame) - size.height, size.width, size.height);
    [self setFrame:newFrame animated:YES];

    [self.textView scrollRangeToVisible:self.textView.selectedRange];

    if ([self.delegate respondsToSelector:@selector(stickerTextViewDidChange:)]) {
        [self.delegate stickerTextViewDidChange:self];
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if ([self.textView isFirstResponder]) {
        return YES;
    }
    return [super pointInside:point withEvent:event];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    if (!CGRectContainsPoint(self.bounds, touchPoint)) {
        if ([self isFirstResponder]) {
            [self.emojiToggleButton setImage:[UIImage imageNamed:@"toggle_emoji"] forState:UIControlStateNormal];
            self.textView.inputView = nil;
            self.keyboardType = PPKeyboardTypeSystem;

            [self resignFirstResponder];
        }
    } else {
        [super touchesBegan:touches withEvent:event];
    }
}

- (BOOL)isFirstResponder
{
    return [self.textView isFirstResponder];
}

- (BOOL)becomeFirstResponder
{
    return [self.textView becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
    [super resignFirstResponder];
    _keepsPreMode = YES;
    [self changeKeyboardTo:PPKeyboardTypeNone];
    [self setNeedsLayout];
    return [self.textView resignFirstResponder];
}

- (BOOL)canResignFirstResponder
{
    return [self.textView canResignFirstResponder];
}

- (BOOL)canBecomeFirstResponder
{
    return [self.textView canBecomeFirstResponder];
}

#pragma mark - Keyboard

- (void)keyboardWillShow:(NSNotification *)notif
{
    [self.superview insertSubview:self.bottomBGView belowSubview:self];
}

- (void)keyboardWillHide:(NSNotification *)notif
{
    [self.bottomBGView removeFromSuperview];
}

#pragma mark - PPStickerKeyboardDelegate

- (void)stickerKeyboard:(PPStickerKeyboard *)stickerKeyboard didClickEmoji:(PPEmoji *)emoji
{
    if (!emoji) {
        return;
    }

    UIImage *emojiImage = [UIImage imageNamed:emoji.imageName];
    if (!emojiImage) {
        return;
    }

    NSRange selectedRange = self.textView.selectedRange;
    NSString *emojiString = [NSString stringWithFormat:@"[%@]", emoji.emojiDescription];
    NSMutableAttributedString *emojiAttributedString = [[NSMutableAttributedString alloc] initWithString:emojiString];
    [emojiAttributedString pp_setTextBackedString:[PPTextBackedString stringWithString:emojiString] range:emojiAttributedString.pp_rangeOfAll];

    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithAttributedString:self.textView.attributedText];
    [attributedText replaceCharactersInRange:selectedRange withAttributedString:emojiAttributedString];
    self.textView.attributedText = attributedText;
    self.textView.selectedRange = NSMakeRange(selectedRange.location + emojiAttributedString.length, 0);

    [self textViewDidChange:self.textView];
}

- (void)stickerKeyboardDidClickDeleteButton:(PPStickerKeyboard *)stickerKeyboard
{
    NSRange selectedRange = self.textView.selectedRange;
    if (selectedRange.location == 0 && selectedRange.length == 0) {
        return;
    }

    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithAttributedString:self.textView.attributedText];
    if (selectedRange.length > 0) {
        [attributedText deleteCharactersInRange:selectedRange];
        self.textView.attributedText = attributedText;
        self.textView.selectedRange = NSMakeRange(selectedRange.location, 0);
    } else {
        [attributedText deleteCharactersInRange:NSMakeRange(selectedRange.location - 1, 1)];
        self.textView.attributedText = attributedText;
        self.textView.selectedRange = NSMakeRange(selectedRange.location - 1, 0);
    }

    [self textViewDidChange:self.textView];
}

- (void)stickerKeyboardDidClickSendButton:(PPStickerKeyboard *)stickerKeyboard
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerTextViewDidClickSendButton:)]) {
        [self.delegate stickerTextViewDidClickSendButton:self];
    }
}

@end
