//
//  PPStickerTextView.m
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/19.
//  Copyright © 2018年 ZAKER. All rights reserved.
//

#import "PPStickerTextView.h"
#import "PPStickerDataManager.h"
#import "PPUtil.h"

@interface PPStickerTextView ()
@property (nonatomic, strong) UILabel *placeholderLabel;
@end

@implementation PPStickerTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pp_textDidChange:) name:UITextViewTextDidChangeNotification object:self];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:self];
}

- (void)setFont:(UIFont *)font
{
    [super setFont:font];

    self.placeholderLabel.font = font;
}

- (void)setText:(NSString *)text
{
    [super setText:text];
    [self showPlaceholderIfNeeded];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    [super setAttributedText:attributedText];
    [self showPlaceholderIfNeeded];
}

- (UILabel *)placeholderLabel
{
    if (!_placeholderLabel) {
        _placeholderLabel = [[UILabel alloc] init];
        _placeholderLabel.backgroundColor = [UIColor clearColor];
        _placeholderLabel.font = self.font;
        _placeholderLabel.hidden = YES;

        [self addSubview:_placeholderLabel];
    }

    return _placeholderLabel;
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor
{
    self.placeholderLabel.textColor = placeholderColor;
}

- (UIColor *)placeholderColor
{
    return self.placeholderLabel.textColor;
}

- (void)setPlaceholder:(NSString *)placeholder
{
    self.placeholderLabel.text = placeholder;
    [self setNeedsLayout];
}

- (NSString *)placeholder
{
    return self.placeholderLabel.text;
}

- (void)showPlaceholderIfNeeded
{
    if ([self shouldShowPlaceholder]) {
        [self showPlaceholder];
    } else {
        [self hidePlaceholder];
    }
}

- (BOOL)shouldShowPlaceholder
{
    if ([self.text length] == 0 && [self.placeholder length] > 0) {
        return YES;
    }

    return NO;
}

- (void)showPlaceholder
{
    self.placeholderLabel.hidden = NO;
}

- (void)hidePlaceholder
{
    self.placeholderLabel.hidden = YES;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self showPlaceholderIfNeeded];
    self.placeholderLabel.frame = [self placeholderFrame];
    [self sendSubviewToBack:self.placeholderLabel];

    if (_verticalCenter) {
        [self verticalCenterContent];
    }
}

- (CGRect)placeholderFrame
{
    UIEdgeInsets insets = [self retainedContentInsets];
    CGRect bounds = PPRectInsetEdges(self.bounds, insets);
    CGSize placeholderSize = [self.placeholder pp_sizeWithFont:self.placeholderLabel.font constrainedToSize:CGSizeMake(bounds.size.width, CGFLOAT_MAX) lineBreakMode:NSLineBreakByCharWrapping];

    CGRect caretRect = [self caretRectForPosition:self.beginningOfDocument];

    CGFloat topMarge = (self.bounds.size.height - placeholderSize.height) / 2;
    if (topMarge < 0) {
        topMarge = 0;
    }

    CGRect frame;
    frame.size = placeholderSize;
    frame.origin.x = caretRect.origin.x;
    frame.origin.y = _verticalCenter ? topMarge : caretRect.origin.y;       // 因caretRect的origin.y有几像素偏差，故而在居中模式下不使用
    return frame;
}

- (UIEdgeInsets)retainedContentInsets
{
    return UIEdgeInsetsMake(8, 4, 8, 4);
}

- (void)pp_textDidChange:(NSNotification *)notif
{
    [self showPlaceholderIfNeeded];

    CGRect line = [self caretRectForPosition:self.selectedTextRange.start];
    CGRect bounds = self.bounds;
    CGPoint currentOffset = self.contentOffset;
    UIEdgeInsets currentInsets = self.contentInset;
    CGFloat overflow = line.origin.y + line.size.height - (currentOffset.y + bounds.size.height - currentInsets.bottom - currentInsets.top);

    if (overflow > 0) {
        CGPoint toOffset = [self pp_maximumContentOffset];
        [self setContentOffset:toOffset animated:YES];
    }
}

- (void)verticalCenterContent
{
    NSTextContainer *container = self.textContainer;
    NSLayoutManager *layoutManager = container.layoutManager;

    CGRect textRect = [layoutManager usedRectForTextContainer:container];

    UIEdgeInsets inset = self.textContainerInset;
    inset.top = self.bounds.size.height >= textRect.size.height ? (self.bounds.size.height - textRect.size.height) / 2 : inset.top;

    self.textContainerInset = inset;
}

#pragma mark - override

- (void)cut:(id)sender
{
    NSString *string = [self.attributedText pp_plainTextForRange:self.selectedRange];
    if (string.length) {
        [UIPasteboard generalPasteboard].string = string;

        NSRange selectedRange = self.selectedRange;
        NSMutableAttributedString *attributeContent = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
        [attributeContent replaceCharactersInRange:self.selectedRange withString:@""];
        self.attributedText = attributeContent;
        self.selectedRange = NSMakeRange(selectedRange.location, 0);

        if (self.delegate && [self.delegate respondsToSelector:@selector(textViewDidChange:)]) {
            [self.delegate textViewDidChange:self];
        }
    }
}

- (void)copy:(id)sender
{
    NSString *string = [self.attributedText pp_plainTextForRange:self.selectedRange];
    if (string.length) {
        [UIPasteboard generalPasteboard].string = string;
    }
}

- (void)paste:(id)sender
{
    NSString *string = UIPasteboard.generalPasteboard.string;
    if (string.length) {
        NSMutableAttributedString *attributedPasteString = [[NSMutableAttributedString alloc] initWithString:string];
        [PPStickerDataManager.sharedInstance replaceEmojiForAttributedString:attributedPasteString font:self.font];
        NSRange selectedRange = self.selectedRange;

        NSMutableAttributedString *attributeContent = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
        [attributeContent replaceCharactersInRange:self.selectedRange withAttributedString:attributedPasteString];
        self.attributedText = attributeContent;
        self.selectedRange = NSMakeRange(selectedRange.location + attributedPasteString.length, 0);

        if (self.delegate && [self.delegate respondsToSelector:@selector(textViewDidChange:)]) {
            [self.delegate textViewDidChange:self];
        }
    }
}

@end
