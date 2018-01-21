//
//  PPStickerTextView.h
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/19.
//  Copyright © 2018年 ZAKER. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PPStickerTextView : UITextView

@property (nonatomic, strong) NSString *placeholder;

@property (nonatomic, strong) UIColor *placeholderColor;

@property (nonatomic) BOOL verticalCenter;

@end
