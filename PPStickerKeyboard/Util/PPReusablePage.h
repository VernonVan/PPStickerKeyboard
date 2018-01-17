//
//  PPReusablePage.h
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/15.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PPReusablePage <NSObject>

@property (nonatomic, strong) NSString *reuseIdentifier;

@property (nonatomic) BOOL nonreusable;

@property (nonatomic) BOOL focused;

- (void)prepareForReuse;

@optional

- (void)didBecomeFocusPage;
- (void)didResignFocusPage;

@end
