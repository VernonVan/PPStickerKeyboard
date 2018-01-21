//
//  PPAttributedString.m
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/17.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import "NSAttributedString+PPAddition.h"

@implementation NSAttributedString (PPAddition)

- (NSRange)pp_rangeOfAll
{
    return NSMakeRange(0, self.length);
}

- (NSString *)pp_plainTextForRange:(NSRange)range
{
    if (range.location == NSNotFound || range.length == NSNotFound) {
        return nil;
    }

    NSMutableString *result = [[NSMutableString alloc] init];
    if (range.length == 0) {
        return result;
    }

    NSString *string = self.string;
    [self enumerateAttribute:PPTextBackedStringAttributeName inRange:range options:kNilOptions usingBlock:^(id value, NSRange range, BOOL *stop) {
        PPTextBackedString *backed = value;
        if (backed && backed.string) {
            [result appendString:backed.string];
        } else {
            [result appendString:[string substringWithRange:range]];
        }
    }];
    return result;
}

@end

@implementation NSMutableAttributedString (PPAddition)

- (void)pp_setTextBackedString:(PPTextBackedString *)textBackedString range:(NSRange)range
{
    if (textBackedString && ![NSNull isEqual:textBackedString]) {
        [self addAttribute:PPTextBackedStringAttributeName value:textBackedString range:range];
    } else {
        [self removeAttribute:PPTextBackedStringAttributeName range:range];
    }
}

@end
