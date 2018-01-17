//
//  PPAttributedString.m
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/17.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import "PPAttributedString.h"
#import "PPTextBackedString.h"

@implementation NSAttributedString (PPAddition)

- (NSString *)pp_plainTextForRange:(NSRange)range
{
    if (range.location == NSNotFound || range.length == NSNotFound) {
        return nil;
    }
    NSMutableString *result = [NSMutableString string];
    if (range.length == 0) return result;
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
