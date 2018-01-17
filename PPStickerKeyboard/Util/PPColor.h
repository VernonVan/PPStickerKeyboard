//
//  PPColor.h
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/15.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (PPAdditions)

+ (UIColor *)pp_colorWithRGBString:(NSString *)string;

+ (UIColor *)pp_colorWithRGBString:(NSString *)string alpha:(CGFloat)alpha;

@end
