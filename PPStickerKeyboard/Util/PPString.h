//
//  PPString.h
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/19.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSString (PPAddition)

- (CGSize)pp_sizeWithFont:(UIFont *)font;

- (CGSize)pp_sizeWithFont:(UIFont *)font constrainedToSize:(CGSize)size lineBreakMode:(NSLineBreakMode)lineBreakMode;

@end
