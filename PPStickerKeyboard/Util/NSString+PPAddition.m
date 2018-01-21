//
//  PPString.m
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/19.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import "NSString+PPAddition.h"

@implementation NSString (PPAddition)

- (CGSize)pp_sizeWithFont:(UIFont *)font
{
    return [self pp_sizeWithFont:font constrainedToSize:CGSizeMake(CGFLOAT_MAX, 1) lineBreakMode:NSLineBreakByWordWrapping];
}

- (CGSize)pp_sizeWithFont:(UIFont *)font constrainedToSize:(CGSize)size lineBreakMode:(NSLineBreakMode)lineBreakMode
{
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];

    if (font) {
        attributes[NSFontAttributeName] = font;
    }

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = lineBreakMode;
    attributes[NSParagraphStyleAttributeName] = paragraphStyle;

    return [self boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil].size;
}

@end
