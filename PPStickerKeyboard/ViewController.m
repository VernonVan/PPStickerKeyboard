//
//  ViewController.m
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/14.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import "ViewController.h"
#import "PPStickerInputView.h"

@interface ViewController () <PPStickerInputViewDelegate>

@property (nonatomic, strong) PPStickerInputView *inputView;

@end

@implementation ViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:self.inputView];
    CGFloat height = [self.inputView heightThatFits];
    self.inputView.frame = CGRectMake(0, CGRectGetHeight(self.view.bounds) - height, CGRectGetWidth(self.view.bounds), height);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
}

- (PPStickerInputView *)inputView
{
    if (!_inputView) {
        _inputView = [[PPStickerInputView alloc] init];
        _inputView.delegate = self;
    }
    return _inputView;
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    if (![self.inputView isFirstResponder]) {
        return;
    }

    NSDictionary *userInfo = [notification userInfo];
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect inputViewFrame = self.inputView.frame;
    CGFloat textViewHeight = [self.inputView heightThatFits];
    inputViewFrame.origin.y = CGRectGetHeight(self.view.bounds) - CGRectGetHeight(keyboardFrame) - textViewHeight;
    inputViewFrame.size.height = textViewHeight;

    [UIView animateWithDuration:duration animations:^{
        self.inputView.frame = inputViewFrame;
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect inputViewFrame = self.inputView.frame;
    CGFloat textViewHeight = [self.inputView heightThatFits];
    inputViewFrame.origin.y = CGRectGetHeight(self.view.bounds) - textViewHeight;
    inputViewFrame.size.height = textViewHeight;

    [UIView animateWithDuration:duration animations:^{
        self.inputView.frame = inputViewFrame;
    }];
}

#pragma mark - PPinputViewDelegate

@end
