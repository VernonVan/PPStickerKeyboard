//
//  PPTextBackedString.h
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/17.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const PPTextBackedStringAttributeName;

@interface PPTextBackedString : NSObject <NSCoding, NSCopying>

@property (nullable, nonatomic, copy) NSString *string;

+ (instancetype)stringWithString:(nullable NSString *)string;

@end
