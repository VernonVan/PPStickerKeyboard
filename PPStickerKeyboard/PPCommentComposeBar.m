//
//  PPCommentComposeBar.m
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/17.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import "PPCommentComposeBar.h"
#import "PPStickerKeyboard.h"
#import "PPScreen.h"
#import "PPUIColor.h"

static CGFloat const PPCommentBarDefaultMinHeight = 44.0;
static CGFloat const PPCommentBarDefaultMaxHeight = 70.0;
static CGFloat const PPCommentBarLeftRightPadding = 20.0;

static CGFloat const PPCommentBarTextViewTopMargin = 6.0;
static CGFloat const PPCommentBarTextViewLeftRightPadding = 16.0;
static CGFloat const PPCommentBarTextViewBottomMargin = 12.0;
static NSUInteger const PPCommentBarCommentMaxLineCount = 6;
static NSUInteger const PPCommentBarCommentMinLineCount = 3;
static CGFloat const PPCommentBarCommentLineSpacing = 5.0;
static CGFloat const PPCommentBarCommentFontSize = 16.0;

static CGFloat const PPCommentBarSeperateLineTopMargin = 12.0;

static CGFloat const PPCommentBarEmojiToggleLeftPadding = 8.0;
static CGFloat const PPCommentBarEmojiToggleLength = 48.0;

static CGFloat const PPCommentBarCountHeight = 17.0;
static CGFloat const PPCommentBarCountFontSize = 14.0;

#define STICKER_KEYBOARD_HEIGHT ([UIScreen pp_isIPhoneX] ? 34.0 + 212.0 : 212.0)

@interface PPCommentComposeBar () <UITextViewDelegate, PPStickerKeyboardDelegate> {
    CGFloat _leftRightPadding;
    CGFloat _textViewContentSizeHeight;
}

@property (nonatomic, strong) UIView *separatedLine;
@property (nonatomic, strong) UIButton *emojiToggleButton;
@property (nonatomic, strong) PPStickerKeyboard *stickerKeyboard;
@property (nonatomic, strong) UIView *bottomBGView;     // 语音键盘的空隙

@property (nonatomic, assign, readwrite) PPKeyboardType keyboardType;

@end

@implementation PPCommentComposeBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.minHeight = PPCommentBarDefaultMinHeight;
        self.maxHeight = PPCommentBarDefaultMaxHeight;

        self.contentMode = UIViewContentModeRedraw;
        [self addSubview:self.textView];
        [self addSubview:self.separatedLine];
        [self addSubview:self.emojiToggleButton];
        self.stickerKeyboard.delegate = self;
        self.exclusiveTouch = YES;

        _keyboardType = PPKeyboardTypeSystem;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.textView.frame = [self frameTextView];
    self.separatedLine.frame = [self frameSeparatedLine];
    self.emojiToggleButton.frame = [self frameEmojiToggleButton];

    [self refreshTextUI];
}

- (CGFloat)heightThatFit
{
    [self.textView setNeedsLayout];
    CGFloat textViewHeight = fabs(self.textView.contentInset.top) + [self.textView.layoutManager usedRectForTextContainer:self.textView.textContainer].size.height + fabs(self.textView.contentInset.bottom);
    CGFloat textViewContentSizeHeight = self.textView.textContainerInset.top + textViewHeight + self.textView.textContainerInset.bottom;
    _textViewContentSizeHeight = textViewContentSizeHeight;

    CGFloat minHeight = self.textView.textContainerInset.top + [self heightWithLine:PPCommentBarCommentMinLineCount] + self.textView.textContainerInset.bottom;
    CGFloat maxHeight = self.textView.textContainerInset.top + [self heightWithLine:PPCommentBarCommentMaxLineCount] + self.textView.textContainerInset.bottom;
    CGFloat calculateHeight = MIN(maxHeight, MAX(minHeight, textViewContentSizeHeight));
    CGFloat height = calculateHeight + PPCommentBarEmojiToggleLength + PPCommentBarTextViewBottomMargin;

    return height;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return CGSizeMake(size.width, [self heightThatFit]);
}

- (void)sizeToFit
{
    CGSize size = [self sizeThatFits:self.bounds.size];
    CGRect orgFrame = self.frame;
    CGRect newFrame = CGRectMake(orgFrame.origin.x, CGRectGetMaxY(orgFrame) - size.height, size.width, size.height);
    self.frame = newFrame;
}

#pragma mark - public method

- (BOOL)isEditing
{
    return [self.textView isFirstResponder];
}

- (void)clearText
{
    self.textView.text = nil;
    self.textView.contentSize = CGSizeZero;
    [self sizeToFit];
}

#pragma mark - getter / setter

- (UITextView *)textView
{
    if (!_textView) {
        _textView = [[UITextView alloc] initWithFrame:self.bounds];
        _textView.delegate = self;
        _textView.backgroundColor = [UIColor clearColor];
        _textView.font = [UIFont systemFontOfSize:PPCommentBarCommentFontSize];
        _textView.scrollsToTop = NO;
        _textView.returnKeyType = UIReturnKeySend;
        _textView.enablesReturnKeyAutomatically = YES;
        if (@available(iOS 11.0, *)) {
            _textView.textDragInteraction.enabled = NO;
        }
    }
    return _textView;
}

- (NSString *)plainText
{
//    return [self.textView.attributedText yy_plainTextForRange:NSMakeRange(0, self.textView.attributedText.length)];
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
        [_emojiToggleButton addTarget:self action:@selector(stickerKeyboardDidClicked:) forControlEvents:UIControlEventTouchUpInside];
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
            [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:changesAnimations completion:^(BOOL finished) {
            }];
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
        return;
    }

    NSString *plainText = self.plainText;
    NSRange selectedRange = self.textView.selectedRange;

    NSMutableAttributedString *attributedComment = [[NSMutableAttributedString alloc] initWithString:plainText attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:PPCommentBarCommentFontSize], NSForegroundColorAttributeName: [UIColor pp_colorWithRGBString:@"#3B3B3B"] }];

    // 匹配表情
    NSArray<PPStickerMatchingResult *> *matches = [self replaceEmojiForAttributedString:attributedComment];

    // 超出字数置灰
    if (plainText.length > PPCommentMaxWordCount) {
        if (self.isShowEmoji) {
            NSUInteger cutLength = 0;
            for (PPStickerMatchingResult *result in matches) {
                if (result.range.location >= PPCommentMaxWordCount) {
                    break;
                }
                if (result.emojiImage) {
                    cutLength += result.range.length - 1;
                }
            }
            NSUInteger loc = PPCommentMaxWordCount - cutLength;
            if (loc < attributedComment.length) {
                NSRange grayTextRange = NSMakeRange(loc, attributedComment.length - loc);
                [attributedComment addAttributes:@{ NSForegroundColorAttributeName: contentBeyondColor } range:grayTextRange];
            }
        } else {
            NSRange grayTextRange = NSMakeRange(PPCommentMaxWordCount, attributedComment.length - PPCommentMaxWordCount);
            [attributedComment setAttributes:@{ NSForegroundColorAttributeName: contentBeyondColor, NSFontAttributeName: [self contentFont] } range:grayTextRange];
        }
    }

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = PPCommentBarCommentLineSpacing;
    [attributedComment addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:attributedComment.yy_rangeOfAll];

    NSUInteger offset = self.textView.attributedText.length - attributedComment.length;
    self.textView.attributedText = attributedComment;
    self.textView.selectedRange = NSMakeRange(selectedRange.location - offset, 0);
}

- (NSArray<PPStickerMatchingResult *> *)replaceEmojiForAttributedString:(NSMutableAttributedString *)attributedString
{
    if (!attributedString || ![attributedString.string zui_isValid]) {
        return nil;
    }

    NSArray<PPStickerMatchingResult *> *matchingResults = [PPStickerDataManager.sharedInstance matchingEmojiForString:attributedString.string isShowEmoji:self.isShowEmoji];
    UIFont *emojiBaseFont = [self emojiBaseFont];
    NSDictionary<NSString *, id> *attributes = attributedString.yy_attributes;
    NSUInteger offset = 0;
    if (matchingResults && matchingResults.count) {
        for (PPStickerMatchingResult *result in matchingResults) {
            if (self.isShowEmoji && result.emojiImage) {
                CGFloat emojiHeight = emojiBaseFont.lineHeight;
                NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
                attachment.image = result.emojiImage;
                attachment.bounds = CGRectMake(0, emojiBaseFont.descender, emojiHeight, emojiHeight);
                NSMutableAttributedString *emojiAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
                [emojiAttributedString yy_setTextBackedString:[YYTextBackedString stringWithString:result.backedDescription] range:NSMakeRange(0, emojiAttributedString.length)];
                if (!emojiAttributedString) {
                    continue;
                }
                NSRange actualRange = NSMakeRange(result.range.location - offset, result.backedDescription.length);
                [attributedString replaceCharactersInRange:actualRange withAttributedString:emojiAttributedString];
                offset += result.backedDescription.length - emojiAttributedString.length;
            } else {
                NSMutableAttributedString *attributedDescription = [[NSMutableAttributedString alloc] initWithString:result.showingDescription attributes:attributes];
                if (self.isShowEmoji) {
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
    return matchingResults;
}

- (void)stickerKeyboardDidClicked:(id)sender
{
    [self changeKeyboardTo:(self.keyboardType == PPKeyboardTypeSystem ? PPKeyboardTypeSticker : PPKeyboardTypeSystem)];
}

- (CGFloat)heightWithLine:(NSInteger)lineNumber
{
    NSString *onelineStr = [[NSString alloc] init];
    CGRect onelineRect = [onelineStr boundingRectWithSize:CGSizeMake(self.textView.frame.size.width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName: [self contentFont] } context:nil];
    CGFloat heigth = lineNumber * onelineRect.size.height + (lineNumber - 1) * PPCommentBarCommentLineSpacing;
    return heigth;
}

- (CGRect)frameTextView
{
    CGRect textFrame = CGRectZero;

    CGFloat textFrame_x = _leftRightPadding;
    CGFloat textFrame_y = PPCommentBarTextViewTopMargin;
    CGFloat textFrame_Width = self.bounds.size.width - (2 * _leftRightPadding);

    if (_showCloseButton) {
        textFrame_x += PPCommentBarCloseWidth + PPCommentBarTextViewToCloseMargin;
        textFrame_Width -= PPCommentBarCloseWidth + PPCommentBarTextViewToCloseMargin;
    }

    if ([self.replyLabel.text zui_isValid]) {
        textFrame_y += PPCommentBarReplyTopPadding + PPCommentBarReplyHeight;
    }

    CGFloat textFrame_Height = 0;
    if (self.keepsPreModeTextViewWillEdited) {
        textFrame_Height = ((self.bounds.size.height - PPCommentBarTextViewTopMargin * 2) <= 0) ? self.bounds.size.height : self.bounds.size.height - PPCommentBarTextViewTopMargin * 2;
        textFrame = CGRectMake(textFrame_x, PPCommentBarTextViewTopMargin, textFrame_Width, textFrame_Height);
    } else {
        textFrame_Height = self.bounds.size.height - PPCommentBarTextViewTopMargin - PPCommentBarTextViewBottomMargin - PPCommentBarEmojiToggleLength;
        if ([self.replyLabel.text zui_isValid]) {
            textFrame_Height -= PPCommentBarReplyTopPadding + PPCommentBarReplyHeight;
        }
        if (textFrame_Height < 0) {
            textFrame_Height = self.bounds.size.height;
        }
        textFrame = CGRectMake(textFrame_x, textFrame_y, textFrame_Width, textFrame_Height);
    }

    return textFrame;
}

- (CGRect)frameSeparatedLine
{
    return CGRectMake(0, CGRectGetMaxY([self frameTextView]) + PPCommentBarSeperateLineTopMargin, self.bounds.size.width, ZUIOnePixelToPoint());
}

- (CGRect)frameEmojiToggleButton
{
    return CGRectMake(PPCommentBarEmojiToggleLeftPadding, CGRectGetMaxY([self frameSeparatedLine]), PPCommentBarEmojiToggleLength, PPCommentBarEmojiToggleLength);
}

- (void)delegateDidChange
{
    if ([self.delegate respondsToSelector:@selector(commentComposeViewDidChange:)]) {
        [self.delegate commentComposeViewDidChange:self];
    }
}

#pragma mark - UITextView

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([@"\n" isEqualToString:text]) {
        [self delegateDidPressReturnKey];
        return NO;
    }

    return YES;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    [[UIMenuController sharedMenuController] setTargetRect:CGRectZero inView:self.textView];
    [[UIMenuController sharedMenuController] setMenuVisible:NO animated:NO];

    if (self.keepsPreMode) {
        self.keepsPreModeTextViewWillEdited = YES;
    } else {
        self.keepsPreModeTextViewWillEdited = NO;
    }
    if ([self.delegate respondsToSelector:@selector(commentComposeViewShouldBeginEditing:)]) {
        return [self.delegate commentComposeViewShouldBeginEditing:self];
    } else {
        return YES;
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    self.keepsPreModeTextViewWillEdited = YES;
    self.replyLabel.text = @"";
    self.countLabel.text = PPCommentBarCountDefaultText;
    if ([self.delegate respondsToSelector:@selector(commentComposeViewDidEndEditing:)]) {
        [self.delegate commentComposeViewDidEndEditing:self];
    }
}

- (void)delegateDidPressReturnKey
{
    if ([self.delegate respondsToSelector:@selector(commentComposeViewDidPressReturnKey:)]) {
        [self.delegate commentComposeViewDidPressReturnKey:self];
    }
}

- (void)textViewDidChange:(UITextView *)textView
{
    [self refreshTextUI];

    CGSize size = [self sizeThatFits:self.bounds.size];
    CGRect orgFrame = self.frame;
    CGRect newFrame = CGRectMake(orgFrame.origin.x, CGRectGetMaxY(orgFrame) - size.height, size.width, size.height);
    [self setFrame:newFrame animated:YES];

    if (!_keepsPreMode) {
        self.textView.frame = [self frameTextView];
    }

    [self.textView scrollRangeToVisible:self.textView.selectedRange];

    [self delegateDidChange];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (_clickBackgroundClose) {
        if ([self.textView isFirstResponder]) {
            return YES;
        }
    }

    return [super pointInside:point withEvent:event];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_clickBackgroundClose) {
        UITouch *touch = [touches anyObject];
        CGPoint touchPoint = [touch locationInView:self];
        if (!CGRectContainsPoint(self.bounds, touchPoint)) {
            if ([self isFirstResponder]) {
                [self resignFirstResponder];
                [self initKeyboard];
            }
        } else {
            [super touchesBegan:touches withEvent:event];
        }
    } else {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)initKeyboard
{
    [self.emojiToggleButton setImage:[UIImage imageNamed:@"toggle_emoji"] forState:UIControlStateNormal];
    self.textView.inputView = nil;
    self.keyboardType = PPKeyboardTypeSystem;
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
    [self changeKeyboardTo:PPKeyboardTypeNone];
    self.keepsPreModeTextViewWillEdited = YES;
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

- (void)stickerKeyboard:(PPStickerKeyboard *)stickerKeyboard didClickEmoji:(PPEmoji *)emoji emojiImage:(UIImage *)emojiImage
{
    if (!emoji || !emojiImage) {
        return;
    }

    NSRange selectedRange = self.textView.selectedRange;
    NSString *emojiString = [NSString stringWithFormat:@"[/%@:%@]", emoji.code, emoji.emojiDescription];
    NSMutableAttributedString *emojiAttributedString = [[NSMutableAttributedString alloc] initWithString:emojiString];
    [emojiAttributedString yy_setTextBackedString:[YYTextBackedString stringWithString:emojiString] range:emojiAttributedString.yy_rangeOfAll];

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
    if (self.delegate && [self.delegate respondsToSelector:@selector(commentComposeViewDidClickSendButton:)]) {
        [self.delegate commentComposeViewDidClickSendButton:self];
    }
}

@end
