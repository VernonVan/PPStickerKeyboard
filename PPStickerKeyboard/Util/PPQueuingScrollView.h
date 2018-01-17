//
//  PPQueuingScrollView.h
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/15.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PPReusablePage.h"

@class PPQueuingScrollView;

@protocol PPQueuingScrollViewDelegate <UIScrollViewDelegate>

@required

- (UIView<PPReusablePage> *)queuingScrollView:(PPQueuingScrollView *)queuingScrollView viewBeforeView:(UIView *)view;
- (UIView<PPReusablePage> *)queuingScrollView:(PPQueuingScrollView *)queuingScrollView viewAfterView:(UIView *)view;

@optional

- (void)queuingScrollViewChangedFocusView:(PPQueuingScrollView *)queuingScrollView previousFocusView:(UIView *)previousFocusView;

@end

@interface PPQueuingScrollView : UIScrollView

@property (nonatomic, weak) id<PPQueuingScrollViewDelegate> delegate;

@property (nonatomic) CGFloat pagePadding;

@property (nonatomic, readonly) CGPoint targetContentOffset;

- (id)reusableViewWithIdentifer:(NSString *)identifier;

- (void)displayView:(UIView<PPReusablePage> *)view;

@property (nonatomic, readonly) UIView *focusView;

- (NSArray *)allViews;

- (void)scrollToNextPageAnimated:(BOOL)animated;

- (void)scrollToPreviousPageAnimated:(BOOL)animated;

- (void)locateTargetContentOffset;

- (BOOL)contentOffsetIsValid;

- (CGRect)contentBounds;

@end
