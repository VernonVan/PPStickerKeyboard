//
//  PPSlideLineButton.m
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/14.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import "PPSlideLineButton.h"
#import "UIScreen+PPAddition.h"

static CGFloat const PPSlideLineHeight = 22.0;

@interface PPSlideLineButton ()
@property (nonatomic, strong) NSArray<UIView *> *lineViews;
@end

@implementation PPSlideLineButton

- (instancetype)init
{
    if (self = [super init]) {
        self.linePosition = PPSlideLineButtonPositionNone;
        self.lineColor = [UIColor blackColor];
    }
    return self;
}

- (void)setLineColor:(UIColor *)lineColor
{
    if (_lineColor != lineColor) {
        _lineColor = lineColor;
        [self setNeedsLayout];
    }
}

- (void)setLinePosition:(PPSlideLineButtonPosition)linePosition
{
    if (_linePosition != linePosition) {
        _linePosition = linePosition;
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    for (UIView *lineView in self.lineViews) {
        [lineView removeFromSuperview];
    }
    self.lineViews = nil;

    UIView *leftLine = [[UIView alloc] initWithFrame:CGRectMake(0, (CGRectGetHeight(self.bounds) - PPSlideLineHeight) / 2, PPOnePixelToPoint(), PPSlideLineHeight)];
    leftLine.backgroundColor = self.lineColor;
    UIView *rightLine = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.bounds) - PPOnePixelToPoint(), (CGRectGetHeight(self.bounds) - PPSlideLineHeight) / 2, PPOnePixelToPoint(), PPSlideLineHeight)];
    rightLine.backgroundColor = self.lineColor;

    NSMutableArray *lineViews = [[NSMutableArray alloc] init];
    switch (self.linePosition) {
        case PPSlideLineButtonPositionNone:
            break;
        case PPSlideLineButtonPositionLeft:
            [lineViews addObject:leftLine];
            [self addSubview:leftLine];
            break;
        case PPSlideLineButtonPositionRight:
            [lineViews addObject:rightLine];
            [self addSubview:rightLine];
            break;
        case PPSlideLineButtonPositionBoth:
            [lineViews addObject:leftLine];
            [lineViews addObject:rightLine];
            [self addSubview:leftLine];
            [self addSubview:rightLine];
            break;
        default:
            break;
    }
    self.lineViews = lineViews;
}

@end
