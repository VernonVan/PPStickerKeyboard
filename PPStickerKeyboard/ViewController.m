//
//  ViewController.m
//  PPStickerKeyboard
//
//  Created by Vernon on 2018/1/14.
//  Copyright © 2018年 Vernon. All rights reserved.
//

#import "ViewController.h"
#import "PPStickerInputView.h"
#import "PPUtil.h"

@interface ViewController () <UITableViewDataSource, PPStickerInputViewDelegate>
@property (nonatomic, strong) NSArray<NSString *> *messages;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) PPStickerInputView *inputView;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.inputView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    CGFloat height = [self.inputView heightThatFits];
    CGFloat minY = CGRectGetHeight(self.view.bounds) - height - PP_SAFEAREAINSETS(self.view).bottom;
    self.inputView.frame = CGRectMake(0, minY, CGRectGetWidth(self.view.bounds), height);

    self.tableView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetMinY(self.inputView.frame));
}

- (PPStickerInputView *)inputView
{
    if (!_inputView) {
        _inputView = [[PPStickerInputView alloc] init];
        _inputView.delegate = self;
    }
    return _inputView;
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.dataSource = self;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"MessageCell"];
    }
    return _tableView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MessageCell" forIndexPath:indexPath];
    NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:self.messages[indexPath.row] attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:16.0], NSForegroundColorAttributeName: [UIColor blackColor] }];
    [PPStickerDataManager.sharedInstance replaceEmojiForAttributedString:attributedMessage font:[UIFont systemFontOfSize:16.0]];
    cell.textLabel.attributedText = attributedMessage;
    return cell;
}

#pragma mark - PPStickerInputViewDelegate

- (void)stickerInputViewDidClickSendButton:(PPStickerInputView *)inputView
{
    NSString *plainText = inputView.plainText;
    if (!plainText.length) {
        return;
    }
    
    NSMutableArray *messages = [[NSMutableArray alloc] initWithArray:self.messages];
    [messages addObject:plainText];
    self.messages = messages;
    [inputView clearText];
    
    [self.tableView reloadData];
}

@end
