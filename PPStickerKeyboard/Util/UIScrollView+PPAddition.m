//
//  PPScrollView.m
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/19.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import "UIScrollView+PPAddition.h"

@implementation UIScrollView (PPAddition)

- (CGPoint)pp_maximumContentOffset
{
    CGRect bounds             = self.bounds;
    CGSize contentSize        = self.contentSize;
    UIEdgeInsets contentInset = self.contentInset;
    
    CGFloat x = MAX(-contentInset.left, contentSize.width + contentInset.right - bounds.size.width);
    CGFloat y = MAX(-contentInset.top, contentSize.height + contentInset.bottom - bounds.size.height);
    
    return CGPointMake(x, y);
}

@end
