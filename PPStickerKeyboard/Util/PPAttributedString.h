//
//  PPAttributedString.h
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/17.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (PPAddition)

- (nullable NSString *)pp_plainTextForRange:(NSRange)range;

@end
