//
//  PlaylistPopupView.m
//  OpenApiDemo
//
//  Created by macrzhou on 2025/6/25.
//

#import "PlaylistPopupView.h"
#import "Masonry.h"
#import "MainTableCell.h"
#import "QPlayAutoSDK.h"

@interface PlaylistPopupView()<UITableViewDataSource,UITableViewDelegate>
@property (nonatomic) UIView *backgroundView;
@property (nonatomic) UIView *contentView;
@property (nonatomic) UIVisualEffectView *effectView;
@property (nonatomic) UITableView *tableView;
@end

@implementation PlaylistPopupView

+ (instancetype)sharedInstance {
    static PlaylistPopupView *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PlaylistPopupView alloc] init];
    });
    return instance;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.backgroundView.backgroundColor = [UIColor lightGrayColor];
    [self addSubview:self.backgroundView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide)];
    [self.backgroundView addGestureRecognizer:tap];
    
    CGFloat height = [UIScreen mainScreen].bounds.size.height*0.65;
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, height)];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.contentView.layer.cornerRadius = 12;
    self.contentView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner; // 顶部圆角
    [self addSubview:self.contentView];
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.bounces = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = YES;
    self.tableView.rowHeight = 60;
    [self.tableView registerClass:[MainTableCell class] forCellReuseIdentifier:@"PlaylistTableCell"];
    self.tableView.frame = self.contentView.bounds;
    
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    self.effectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    
    self.effectView.frame = self.contentView.bounds;
    [self.contentView addSubview:self.effectView];
    [self.contentView addSubview:self.tableView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playingListDidChanged) name:QPlayAuto_PlayingListChanged object:nil];
}

- (void)show {
    UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
    self.frame = window.bounds;
    [window addSubview:self];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundView.alpha = 1;
        CGRect frame = self.contentView.frame;
        frame.origin.y = [UIScreen mainScreen].bounds.size.height - frame.size.height;
        self.contentView.frame = frame;
    }];
}

- (void)hide {
    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundView.alpha = 0;
        CGRect frame = self.contentView.frame;
        frame.origin.y = [UIScreen mainScreen].bounds.size.height;
        self.contentView.frame = frame;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

#pragma mark: - Notification
- (void)playingListDidChanged {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark: - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [QPlayAutoSDK playingList].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MainTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PlaylistTableCell" forIndexPath:indexPath];
    QPlayAutoListItem *song = [QPlayAutoSDK playingList][indexPath.row];
    [cell updateWithItem:song];
    return cell;
}

#pragma mark: - UITableViewDelegate
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [NSString stringWithFormat:@"共%ld首",[QPlayAutoSDK playingList].count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}


@end
