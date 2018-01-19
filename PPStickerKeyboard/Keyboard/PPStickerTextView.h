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

/**
 *  用于垂直居中，目前实现方法会改变scrollView的contentInset
 */
@property (nonatomic) BOOL verticalCenter;

@end
