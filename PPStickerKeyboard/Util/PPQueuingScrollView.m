//
//  PPQueuingScrollView.m
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/15.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import "PPQueuingScrollView.h"

typedef NS_ENUM (NSInteger, PPQueuingScrollViewLocation) {
    PPQueuingScrollViewLocationUnknown = -1,
    PPQueuingScrollViewLocationSingle,
    PPQueuingScrollViewLocationHead,
    PPQueuingScrollViewLocationIntermediate,
    PPQueuingScrollViewLocationTrail,
};

#define PAGE_NUMBER 3

@interface PPQueuingScrollView () {
}

@property (nonatomic) NSMutableDictionary *reusableViewSets;
@property (nonatomic) UIView<PPReusablePage> *leftView;
@property (nonatomic) UIView<PPReusablePage> *centerView;
@property (nonatomic) UIView<PPReusablePage> *rightView;
@property (nonatomic) UIView *focusView;
@property (nonatomic) PPQueuingScrollViewLocation location;
@property (nonatomic) CGPoint targetContentOffset;

@end

@implementation PPQueuingScrollView

@dynamic delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.pagingEnabled = YES;
        self.contentSize = CGSizeMake(frame.size.width * PAGE_NUMBER, frame.size.height);
        self.pagePadding = 15.f;
        self.location = PPQueuingScrollViewLocationUnknown;
    }
    return self;
}

- (NSMutableDictionary *)reusableViewSets
{
    if (!_reusableViewSets) {
        _reusableViewSets = [[NSMutableDictionary alloc] init];
    }

    return _reusableViewSets;
}

- (void)setFocusView:(UIView *)newFocusView
{
    if (_focusView != newFocusView) {
        UIView *previousFocusView = _focusView;

        ((UIView<PPReusablePage> *)previousFocusView).focused = NO;
        if ([previousFocusView respondsToSelector:@selector(didResignFocusPage)]) {
            [((UIView < PPReusablePage > *)previousFocusView) didResignFocusPage];
        }

        ((UIView<PPReusablePage> *)newFocusView).focused = YES;
        if ([newFocusView respondsToSelector:@selector(didBecomeFocusPage)]) {
            [((UIView < PPReusablePage > *)newFocusView) didBecomeFocusPage];
        }

        _focusView = newFocusView;

        if ([self.delegate respondsToSelector:@selector(queuingScrollViewChangedFocusView:previousFocusView:)]) {
            [self.delegate queuingScrollViewChangedFocusView:self previousFocusView:previousFocusView];
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect bounds = self.bounds;

    self.contentSize = CGSizeMake(bounds.size.width * PAGE_NUMBER, bounds.size.height);

    [self updateForBounds:bounds];

    self.focusView = [self calculateFocusView];
}

- (CGRect)centerViewFrameForBounds:(CGRect)bounds;
{
    CGFloat pagePadding = self.pagePadding;
    CGFloat pageWidth   = bounds.size.width - pagePadding * 2;
    return CGRectMake(bounds.size.width + pagePadding, 0, pageWidth, bounds.size.height);
}

- (CGRect)leftViewFrameForBounds:(CGRect)bounds centerFrame:(CGRect)centerFrame
{
    return CGRectOffset(centerFrame, -bounds.size.width, 0);
}

- (CGRect)rightViewFrameForBounds:(CGRect)bounds centerFrame:(CGRect)centerFrame
{
    return CGRectOffset(centerFrame, bounds.size.width, 0);
}

- (void)updateInsets:(CGRect)bounds offsetTranlation:(CGFloat)offsetTranlation initialize:(BOOL)initialize
{
    if (!self.leftView && self.rightView) {
        self.contentInset = UIEdgeInsetsMake(0, -bounds.size.width, 0, bounds.size.width * 10);
        self.location = PPQueuingScrollViewLocationHead;
    } else if (!self.rightView && self.leftView) {
        self.contentInset = UIEdgeInsetsMake(0, bounds.size.width * 10, 0, -bounds.size.width);
        self.location = PPQueuingScrollViewLocationTrail;
    } else if (!self.leftView && !self.rightView) {
        self.contentInset = UIEdgeInsetsMake(0, -bounds.size.width, 0, -bounds.size.width);
        self.location = PPQueuingScrollViewLocationSingle;
    } else if (self.leftView && self.rightView) {
        self.contentInset = UIEdgeInsetsMake(0, bounds.size.width * 10, 0, bounds.size.width * 10);
        self.location = PPQueuingScrollViewLocationIntermediate;
    }

    if (initialize) {
        self.contentOffset = CGPointMake(bounds.size.width, 0);
    } else {
        self.contentOffset = CGPointMake(bounds.origin.x + offsetTranlation, 0);
    }
}

- (void)updateForBounds:(CGRect)bounds
{
    if (!self.centerView) {
        return;
    }

    UIView<PPReusablePage> *oldCenterView = self.centerView;
    UIView<PPReusablePage> *oldleftView   = self.leftView;
    UIView<PPReusablePage> *oldRightView  = self.rightView;

    CGRect centerViewFrame   = [self centerViewFrameForBounds:bounds];
    CGRect leftViewFrame     = [self leftViewFrameForBounds:bounds centerFrame:centerViewFrame];
    CGRect rightViewFrame    = [self rightViewFrameForBounds:bounds centerFrame:centerViewFrame];
    CGFloat offsetTranlation = 0;
    CGFloat initialize = NO;
    BOOL shouldUpdateInsets  = NO;

    if (self.location == PPQueuingScrollViewLocationUnknown) {
        UIView<PPReusablePage> *viewBeforeCenterView = [self viewBeforeCenterView];
        [self addSubview:viewBeforeCenterView];
        UIView<PPReusablePage> *viewAfterCenterView  = [self viewAfterCenterView];
        [self addSubview:viewAfterCenterView];

        self.leftView  = viewBeforeCenterView;
        self.rightView = viewAfterCenterView;
        initialize = YES;
        shouldUpdateInsets = YES;
    } else {
        if (bounds.origin.x >= bounds.size.width * 2) { // 向右看
            [self recycleView:oldleftView];
            //TODO: 待去掉该判断并重构ZKRDailyHotHeadLineView实现
            if (oldleftView != oldRightView) {
                [oldleftView removeFromSuperview];
            }

            self.centerView = oldRightView;
            self.leftView   = oldCenterView;
            self.rightView  = [self viewAfterCenterView];
            [self addSubview:self.rightView];

            offsetTranlation   = -bounds.size.width;
            shouldUpdateInsets = YES;
        } else if (bounds.origin.x <= 0) { // 向左看
            [self recycleView:oldRightView];
            //TODO: 待去掉该判断并重构ZKRDailyHotHeadLineView实现
            if (oldleftView != oldRightView) {
                [oldRightView removeFromSuperview];
            }

            self.centerView = oldleftView;
            self.rightView  = oldCenterView;
            self.leftView   = [self viewBeforeCenterView];
            [self addSubview:self.leftView];

            offsetTranlation   = bounds.size.width;
            shouldUpdateInsets = YES;
        }
    }

    self.leftView.frame   = leftViewFrame;
    self.centerView.frame = centerViewFrame;
    self.rightView.frame  = rightViewFrame;

    if (shouldUpdateInsets) {
        [self updateInsets:bounds offsetTranlation:offsetTranlation initialize:initialize];
    }
}

- (UIView<PPReusablePage> *)viewBeforeCenterView
{
    if (self.delegate) {
        return [self.delegate queuingScrollView:self viewBeforeView:self.centerView];
    }
    return nil;
}

- (UIView<PPReusablePage> *)viewAfterCenterView
{
    if (self.delegate) {
        return [self.delegate queuingScrollView:self viewAfterView:self.centerView];
    }
    return nil;
}

- (id)reusableViewWithIdentifer:(NSString *)identifier
{
    NSMutableSet *reusableViewSet = self.reusableViewSets[identifier];
    if (!reusableViewSet) {
        return nil;
    }

    id<PPReusablePage> result = [reusableViewSet anyObject];
    if (result) {
        [reusableViewSet removeObject:result];
        [result prepareForReuse];
    }

    return result;
}

- (void)displayView:(UIView<PPReusablePage> *)view
{
    [self recycleView:self.leftView];
    [self.leftView removeFromSuperview];
    self.leftView = nil;

    [self recycleView:self.rightView];
    [self.rightView removeFromSuperview];
    self.rightView = nil;

    self.location = PPQueuingScrollViewLocationUnknown;

    [self recycleView:self.centerView];
    [self.centerView removeFromSuperview];
    [self addSubview:view];
    self.centerView = view;
    self.focusView = view;

    CGRect bounds = self.bounds;
    self.contentOffset = CGPointMake(bounds.size.width, bounds.size.height);

    [self setNeedsLayout];
}

- (UIView *)calculateFocusView
{
    CGRect bounds  = self.bounds;
    UIView *result = nil;

    if (bounds.origin.x < bounds.size.width * 0.5) {
        result = self.leftView;
    } else if (bounds.origin.x > bounds.size.width * 1.5) {
        result = self.rightView;
    } else {
        result = self.centerView;
    }

    if (!result) {
        result = self.centerView;
    }

    return result;
}

- (NSArray *)allViews
{
    NSMutableArray *views = [[NSMutableArray alloc] init];

    if (self.leftView) {
        [views addObject:self.leftView];
    }

    if (self.centerView) {
        [views addObject:self.centerView];
    }

    if (self.rightView) {
        [views addObject:self.rightView];
    }

    return views;
}

- (void)recycleView:(UIView<PPReusablePage> *)view
{
    if (view.reuseIdentifier && !view.nonreusable) {
        NSMutableSet *reusableViewSet = self.reusableViewSets[view.reuseIdentifier];
        if (!reusableViewSet) {
            reusableViewSet = [[NSMutableSet alloc] init];
            self.reusableViewSets[view.reuseIdentifier] = reusableViewSet;
        }
        [reusableViewSet addObject:view];
    }
}

- (void)scrollToNextPageAnimated:(BOOL)animated
{
    if (![self contentOffsetIsValid]) {
        return;
    }
    CGPoint offset = self.contentOffset;
    offset.x += self.bounds.size.width;
    self.targetContentOffset = offset;
    [self setContentOffset:offset animated:animated];
}

- (void)scrollToPreviousPageAnimated:(BOOL)animated
{
    if (![self contentOffsetIsValid]) {
        return;
    }
    CGPoint offset = self.contentOffset;
    offset.x -= self.bounds.size.width;
    self.targetContentOffset = offset;
    [self setContentOffset:offset animated:animated];
}

- (BOOL)contentOffsetIsValid
{
    for (int i = 0; i < PAGE_NUMBER; i++) {
        //判断图片所在位置是否正确(因为在timer动画过程中可能会出现contentoffset不正确的情况)
        if (self.contentOffset.x == CGRectGetWidth(self.bounds) * i) {
            return YES;
        }
    }
    return NO;
}

- (void)locateTargetContentOffset
{
    [self setContentOffset:self.targetContentOffset];
}

- (CGRect)contentBounds
{
    CGFloat pageWidth = CGRectGetWidth(self.bounds) - _pagePadding * 2;
    return CGRectMake(0, 0, pageWidth, CGRectGetHeight(self.bounds));
}

@end
