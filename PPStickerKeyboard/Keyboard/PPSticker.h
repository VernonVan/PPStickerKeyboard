//
//  PPSticker.h
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/14.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPEmoji.h"

@interface PPSticker : NSObject

@property (nonatomic, strong) NSString *coverImageName;
@property (nonatomic, strong) NSArray<PPEmoji *> *emojis;

@end
