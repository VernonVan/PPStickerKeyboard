//
//  PPAttributedString.h
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/17.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPTextBackedString.h"

@interface NSAttributedString (PPAddition)

- (NSRange)pp_rangeOfAll;

- (nullable NSString *)pp_plainTextForRange:(NSRange)range;

@end

@interface NSMutableAttributedString (PPAddition)

- (void)pp_setTextBackedString:(nullable PPTextBackedString *)textBackedString range:(NSRange)range;

@end
