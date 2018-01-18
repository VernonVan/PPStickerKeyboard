//
//  ViewController.m
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/14.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import "ViewController.h"
#import "PPStickerTextView.h"

@interface ViewController () <PPStickerTextViewDelegate>

@property (nonatomic, strong) PPStickerTextView *stickerTextView;

@end

@implementation ViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:self.stickerTextView];
    CGFloat height = [self.stickerTextView heightThatFits];
    self.stickerTextView.frame = CGRectMake(0, CGRectGetHeight(self.view.bounds) - height, CGRectGetWidth(self.view.bounds), height);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    
}

- (PPStickerTextView *)stickerTextView
{
    if (!_stickerTextView) {
        _stickerTextView = [[PPStickerTextView alloc] init];
    }
    return _stickerTextView;
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    if (![self.stickerTextView isFirstResponder]) {
        return;
    }

    NSDictionary *userInfo = [notification userInfo];
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect stickerTextViewFrame = self.stickerTextView.frame;
    CGFloat textViewHeight = [self.stickerTextView heightThatFits];
    stickerTextViewFrame.origin.y = CGRectGetHeight(self.view.bounds) - CGRectGetHeight(keyboardFrame) - textViewHeight;

    [UIView animateWithDuration:duration animations:^{
        self.stickerTextView.frame = stickerTextViewFrame;
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect stickerTextViewFrame = self.stickerTextView.frame;
    CGFloat textViewHeight = [self.stickerTextView heightThatFits];
    stickerTextViewFrame.origin.y = CGRectGetHeight(self.view.bounds) - textViewHeight;

    [UIView animateWithDuration:duration animations:^{
        self.stickerTextView.frame = stickerTextViewFrame;
    }];
}

#pragma mark - PPStickerTextViewDelegate

@end
