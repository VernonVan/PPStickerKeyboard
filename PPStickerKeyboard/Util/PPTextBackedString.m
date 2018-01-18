//
//  PPTextBackedString.m
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/17.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import "PPTextBackedString.h"

NSString *const PPTextBackedStringAttributeName = @"PPTextBackedString";

@implementation PPTextBackedString

+ (instancetype)stringWithString:(NSString *)string
{
    PPTextBackedString *one = [[self alloc] init];
    one.string = string;
    return one;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.string forKey:@"string"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _string = [aDecoder decodeObjectForKey:@"string"];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    typeof(self) one = [[self.class alloc] init];
    one.string = self.string;
    return one;
}

@end
