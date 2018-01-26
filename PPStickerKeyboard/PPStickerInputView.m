//
//  PPStickerTextView.m
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/17.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import "PPStickerInputView.h"
#import "PPStickerKeyboard.h"
#import "PPStickerTextView.h"
#import "PPUtil.h"

static CGFloat const PPStickerTextViewHeight = 44.0;

static CGFloat const PPStickerTextViewTextViewTopMargin = 10.0;
static CGFloat const PPStickerTextViewTextViewUnfocusLeftRightPadding = 5.0;
static CGFloat const PPStickerTextViewTextViewLeftRightPadding = 16.0;
static CGFloat const PPStickerTextViewTextViewBottomMargin = 10.0;
static NSUInteger const PPStickerTextViewMaxLineCount = 6;
static NSUInteger const PPStickerTextViewMinLineCount = 3;
static CGFloat const PPStickerTextViewLineSpacing = 5.0;
static CGFloat const PPStickerTextViewFontSize = 16.0;

static CGFloat const PPStickerTextViewEmojiToggleLength = 48.0;
static CGFloat const PPStickerTextViewToggleButtonLength = 24.0;

@interface PPStickerInputView () <UITextViewDelegate, PPStickerKeyboardDelegate>

@property (nonatomic, strong) PPStickerTextView *textView;
@property (nonatomic, strong) UIView *separatedLine;
@property (nonatomic, strong) PPButton *emojiToggleButton;
@property (nonatomic, strong) PPStickerKeyboard *stickerKeyboard;
@property (nonatomic, strong) UIView *bottomBGView;     // 消除语音键盘的空隙

@property (nonatomic, assign, readwrite) PPKeyboardType keyboardType;
@property (nonatomic, assign) BOOL keepsPreModeTextViewWillEdited;

@end

@implementation PPStickerInputView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentMode = UIViewContentModeRedraw;
        self.exclusiveTouch = YES;
        self.backgroundColor = [UIColor whiteColor];

        _keyboardType = PPKeyboardTypeSystem;
        _keepsPreModeTextViewWillEdited = YES;

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
    if (!self.keepsPreModeTextViewWillEdited) {
        self.separatedLine.frame = [self frameSeparatedLine];
        self.emojiToggleButton.frame = [self frameEmojiToggleButton];
    } else {
        self.separatedLine.frame = CGRectZero;
        self.emojiToggleButton.frame = CGRectZero;
    }

    [self refreshTextUI];
}

- (CGFloat)heightThatFits
{
    if (self.keepsPreModeTextViewWillEdited) {
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
    self.textView.font = [UIFont systemFontOfSize:PPStickerTextViewFontSize];
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
            self.textView.inputView = nil;                          // 切换到系统键盘
            [self.textView reloadInputViews];                       // 调用reloadInputViews方法会立刻进行键盘的切换
            break;
        case PPKeyboardTypeSticker:            
            [self.emojiToggleButton setImage:[UIImage imageNamed:@"toggle_keyboard"] forState:UIControlStateNormal];
            self.textView.inputView = self.stickerKeyboard;         // 切换到自定义的表情键盘
            [self.textView reloadInputViews];
            break;
        default:
            break;
    }

    self.keyboardType = toType;
}

#pragma mark - getter / setter

- (PPStickerTextView *)textView
{
    if (!_textView) {
        _textView = [[PPStickerTextView alloc] initWithFrame:self.bounds];
        _textView.delegate = self;
        _textView.backgroundColor = [UIColor clearColor];
        _textView.font = [UIFont systemFontOfSize:PPStickerTextViewFontSize];
        _textView.scrollsToTop = NO;
        _textView.returnKeyType = UIReturnKeySend;
        _textView.enablesReturnKeyAutomatically = YES;
        _textView.placeholder = @"我是表情键盘";
        _textView.placeholderColor = [UIColor pp_colorWithRGBString:@"#B4B4B4"];
        _textView.textContainerInset = UIEdgeInsetsZero;
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

- (PPButton *)emojiToggleButton
{
    if (!_emojiToggleButton) {
        _emojiToggleButton = [[PPButton alloc] init];
        [_emojiToggleButton setImage:[UIImage imageNamed:@"toggle_emoji"] forState:UIControlStateNormal];
        _emojiToggleButton.touchInsets = UIEdgeInsetsMake(-12, -20, -12, -20);
        [_emojiToggleButton addTarget:self action:@selector(toggleKeyboardDidClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _emojiToggleButton;
}

- (PPStickerKeyboard *)stickerKeyboard
{
    if (!_stickerKeyboard) {
        _stickerKeyboard = [[PPStickerKeyboard alloc] init];
        _stickerKeyboard.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), [self.stickerKeyboard heightThatFits]);
        _stickerKeyboard.delegate = self;
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

- (void)setKeepsPreModeTextViewWillEdited:(BOOL)keepsPreModeTextViewWillEdited
{
    _keepsPreModeTextViewWillEdited = keepsPreModeTextViewWillEdited;
    if (!keepsPreModeTextViewWillEdited) {
        self.separatedLine.hidden = NO;
        self.separatedLine.frame = [self frameSeparatedLine];
    } else {
        self.separatedLine.hidden = YES;
        self.separatedLine.frame = CGRectZero;
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
    if (self.keepsPreModeTextViewWillEdited) {
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
    return CGRectMake(PPStickerTextViewTextViewLeftRightPadding, CGRectGetHeight(self.bounds) - (PPStickerTextViewEmojiToggleLength + PPStickerTextViewToggleButtonLength) / 2, PPStickerTextViewToggleButtonLength, PPStickerTextViewToggleButtonLength);
}

#pragma mark - UITextView

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    self.keepsPreModeTextViewWillEdited = NO;
    [self.inputView changeKeyboardTo:PPKeyboardTypeSystem];

    if ([self.delegate respondsToSelector:@selector(stickerInputViewShouldBeginEditing:)]) {
        return [self.delegate stickerInputViewShouldBeginEditing:self];
    } else {
        return YES;
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([@"\n" isEqualToString:text]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(stickerInputViewDidClickSendButton:)]) {
            [self.delegate stickerInputViewDidClickSendButton:self];
        }
        return NO;
    }

    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    self.keepsPreModeTextViewWillEdited = YES;

    if ([self.delegate respondsToSelector:@selector(stickerInputViewDidEndEditing:)]) {
        [self.delegate stickerInputViewDidEndEditing:self];
    }
}

- (void)textViewDidChange:(UITextView *)textView
{
    [self refreshTextUI];

    CGSize size = [self sizeThatFits:self.bounds.size];
    CGRect newFrame = CGRectMake(CGRectGetMinX(self.frame), CGRectGetMaxY(self.frame) - size.height, size.width, size.height);
    [self setFrame:newFrame animated:YES];
    
    if (!self.keepsPreModeTextViewWillEdited) {
        self.textView.frame = [self frameTextView];
    }
    [self.textView scrollRangeToVisible:self.textView.selectedRange];
    

    if ([self.delegate respondsToSelector:@selector(stickerInputViewDidChange:)]) {
        [self.delegate stickerInputViewDidChange:self];
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

- (BOOL)resignFirstResponder
{
    [super resignFirstResponder];
    self.keepsPreModeTextViewWillEdited = YES;
    [self changeKeyboardTo:PPKeyboardTypeNone];
    [self setNeedsLayout];
    return [self.textView resignFirstResponder];
}

#pragma mark - Keyboard

- (void)keyboardWillShow:(NSNotification *)notification
{
    if (!self.superview) {
        return;
    }
    
    [self.superview insertSubview:self.bottomBGView belowSubview:self];
    
    NSDictionary *userInfo = [notification userInfo];
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect inputViewFrame = self.frame;
    CGFloat textViewHeight = [self heightThatFits];
    inputViewFrame.origin.y = CGRectGetHeight(self.superview.bounds) - CGRectGetHeight(keyboardFrame) - textViewHeight;
    inputViewFrame.size.height = textViewHeight;
    
    [UIView animateWithDuration:duration animations:^{
        self.frame = inputViewFrame;
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    if (!self.superview) {
        return;
    }
    
    [self.bottomBGView removeFromSuperview];
    
    NSDictionary *userInfo = [notification userInfo];
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect inputViewFrame = self.frame;
    CGFloat textViewHeight = [self heightThatFits];
    inputViewFrame.origin.y = CGRectGetHeight(self.superview.bounds) - textViewHeight - PP_SAFEAREAINSETS(self.superview).bottom;
    inputViewFrame.size.height = textViewHeight;
    
    [UIView animateWithDuration:duration animations:^{
        self.frame = inputViewFrame;
    }];
}

#pragma mark - PPStickerKeyboardDelegate

- (void)stickerKeyboard:(PPStickerKeyboard *)stickerKeyboard didClickEmoji:(PPEmoji *)emoji
{
    if (!emoji) {
        return;
    }

    UIImage *emojiImage = [UIImage imageNamed:[@"Sticker.bundle" stringByAppendingPathComponent:emoji.imageName]];
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
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerInputViewDidClickSendButton:)]) {
        [self.delegate stickerInputViewDidClickSendButton:self];
    }
}

@end
