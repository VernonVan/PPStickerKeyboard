//
//  PPScreen.h
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/15.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM (NSInteger, ZUIScreenPhysicalSize) {
    ZUIScreenPhysicalSizeUnknown   = -1,
    ZUIScreenPhysicalSize_3_5_inch = 0, // iPhone 4, 或者是在 iPad 上运行 iPhone App
    ZUIScreenPhysicalSize_4_0_inch = 1, // iPhone 5, 或者是 iPhone 6 使用放大模式
    ZUIScreenPhysicalSize_4_7_inch = 2, // iPhone 6, 或者是 iPhone 6 Plus 使用放大模式
    ZUIScreenPhysicalSize_5_5_inch = 3, // iPhone 6 Plus
    ZUIScreenPhysicalSize_5_8_inch = 4, // iPhone X
};

#define PP_SAFEAREAINSETS(view) ({ UIEdgeInsets i; if (@available(iOS 11.0, *)) { i = view.safeAreaInsets; } else { i = UIEdgeInsetsZero; } i; })

CGFloat PPOnePixelToPoint(void);

CGRect PPRectInsetEdges(CGRect rect, UIEdgeInsets edgeInsets);

@interface UIScreen (PPAddition)

+ (BOOL)pp_isIPhoneX;

@end
