//
//  PPScreen.m
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/15.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import "UIScreen+PPAddition.h"

CGFloat PPOnePixelToPoint(void)
{
    static CGFloat onePixelWidth = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        onePixelWidth = 1.f / [UIScreen mainScreen].scale;
    });

    return onePixelWidth;
}

CGRect PPRectInsetEdges(CGRect rect, UIEdgeInsets edgeInsets)
{
    rect.origin.x += edgeInsets.left;
    rect.size.width -= edgeInsets.left + edgeInsets.right;
    
    rect.origin.y += edgeInsets.top;
    rect.size.height -= edgeInsets.top + edgeInsets.bottom;
    
    if (rect.size.width < 0) {
        rect.size.width = 0;
    }
    
    if (rect.size.height < 0) {
        rect.size.height = 0;
    }
    
    return rect;
}

@implementation UIScreen (PPAddition)

- (ZUIScreenPhysicalSize)zui_physicalSize
{
    CGSize size = self.bounds.size;

    if (size.width > size.height) {
        CGFloat temp = size.height;
        size.height = size.width;
        size.width = temp;
    }

    if (CGSizeEqualToSize(size, CGSizeMake(375, 667))) {
        return ZUIScreenPhysicalSize_4_7_inch;
    }

    if (CGSizeEqualToSize(size, CGSizeMake(414, 736))) {
        return ZUIScreenPhysicalSize_5_5_inch;
    }

    if (CGSizeEqualToSize(size, CGSizeMake(375, 812))) {
        return ZUIScreenPhysicalSize_5_8_inch;
    }

    if (CGSizeEqualToSize(size, CGSizeMake(320, 480))) {
        return ZUIScreenPhysicalSize_3_5_inch;
    }

    if (CGSizeEqualToSize(size, CGSizeMake(320, 568))) {
        return ZUIScreenPhysicalSize_4_0_inch;
    }

    return ZUIScreenPhysicalSizeUnknown; // 无法识别的屏幕尺寸
}

+ (BOOL)pp_isIPhoneX
{
    static BOOL isIPhoneX;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isIPhoneX = ([[UIScreen mainScreen] zui_physicalSize] == ZUIScreenPhysicalSize_5_8_inch);
    });
    return isIPhoneX;
}

@end
