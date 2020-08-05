//
//  ViewController.m
//  QPlayAutoDemo
//
//  Created by travisli(李鞠佑) on 2018/11/5.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#import "ViewController.h"
#import "QPlayAutoSDK.h"

#define NormalPageSize  (30)
#define ID_GO_BACK @"GO_BACK"
#define ID_SEARCH @"SEARCH"

static NSString * const App_ID = @"";//QQ音乐申请的
static NSString * const App_PrivateKey = @"";//RSA私钥

@interface ViewController ()<QPlayAutoSDKDelegate,UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) QPlayAutoListItem *rootItem;
@property (nonatomic,strong) QPlayAutoListItem *currentItem;
@property (nonatomic,strong) QPlayAutoListItem *searchItem;
@property (nonatomic,strong) QPlayAutoListItem *currentSong;
@property (nonatomic,assign) QPlayAutoPlayState playState;
@property (nonatomic,strong) NSMutableArray<QPlayAutoListItem*> *pathStack;
@property (nonatomic,strong) NSMutableDictionary<NSString*,UIImage*> *imageCache;
@property (nonatomic,strong) NSTimer *progressTimer;
@property (nonatomic,assign) BOOL isConnected;
@property (nonatomic,assign) NSInteger currentProgress;
@property (nonatomic,assign) QPlayAutoPlayMode currentPlayMode;
@property (nonatomic,assign) BOOL isLove;

@property (nonatomic,strong) NSString *openId;
@property (nonatomic,strong) NSString *openToken;

@property (weak, nonatomic) IBOutlet UIButton *likeButtohn;
@property (nonatomic,strong) UISegmentedControl       *assenceSegmentedControl;



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    QPlayAutoAppInfo *appInfo = [[QPlayAutoAppInfo alloc] init];
    appInfo.deviceId = @"qplayauto123";
    appInfo.scheme = @"qplayautodemo://";
    appInfo.brand = @"QQMusic";
    appInfo.name = @"QPlayAutoDemo";
    appInfo.bundleId = @"com.tencent.QPlayAutoDemo";
    appInfo.appId = App_ID;
    appInfo.secretKey = App_PrivateKey;
    appInfo.deviceType = APP_DEVICE_TYPE;
    [QPlayAutoSDK registerApp:appInfo delegate:self];
    [self.tableview registerClass:[UITableViewCell class] forCellReuseIdentifier:@"qplayautocell"];
    self.tableview.delegate = self;
    self.tableview.dataSource = self;
    self.imageCache = [[NSMutableDictionary alloc]init];
    [self.btnConnect setTitleColor:[UIColor colorWithRed:50.f/255 green:188.f/255 blue:108.f/255 alpha:1] forState:UIControlStateNormal];
    [self.btnMore setTitleColor:self.btnConnect.currentTitleColor forState:UIControlStateNormal];
    [self setupUI];
}

- (void)setupUI {
    _assenceSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"整首",@"高潮"]];
    _assenceSegmentedControl.selectedSegmentIndex = 0;
    [_assenceSegmentedControl addTarget:self action:@selector(assenceSegmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
    _assenceSegmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_assenceSegmentedControl];
    
    NSLayoutConstraint *a = [NSLayoutConstraint constraintWithItem:_assenceSegmentedControl attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:-20];
    NSLayoutConstraint *b = [NSLayoutConstraint constraintWithItem:_assenceSegmentedControl attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_likeButtohn attribute:NSLayoutAttributeTop multiplier:1 constant:-15];
    [NSLayoutConstraint activateConstraints:@[a,b]];
}

- (void)assenceSegmentedControlChanged:(UISegmentedControl*)sender {
    if (sender.selectedSegmentIndex == 0) {
        [QPlayAutoSDK setAssenceMode:QPlayAutoAssenceMode_Full callback:^(BOOL success, NSDictionary *dict) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    UIAlertController *vc = [UIAlertController alertControllerWithTitle:nil message:@"设置 播放整首 成功" preferredStyle:UIAlertControllerStyleAlert];
                    [vc addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil]];                [self presentViewController:vc animated:YES completion:nil];
                }
                else {
                    UIAlertController *vc = [UIAlertController alertControllerWithTitle:nil message:@"设置 播放整首 失败" preferredStyle:UIAlertControllerStyleAlert];
                    [vc addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil]];                [self presentViewController:vc animated:YES completion:nil];
                }
                
            });
        }];
    }
    else {
        [QPlayAutoSDK setAssenceMode:QPlayAutoAssenceMode_Part callback:^(BOOL success, NSDictionary *dict) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    UIAlertController *vc = [UIAlertController alertControllerWithTitle:nil message:@"设置 播放高潮 成功" preferredStyle:UIAlertControllerStyleAlert];
                    [vc addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil]];                [self presentViewController:vc animated:YES completion:nil];
                }
                else {
                    UIAlertController *vc = [UIAlertController alertControllerWithTitle:nil message:@"设置 播放高潮 失败" preferredStyle:UIAlertControllerStyleAlert];
                    [vc addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil]];                [self presentViewController:vc animated:YES completion:nil];
                }
                
            });
        }];
    }
}

- (IBAction)onClickStart:(id)sender {
    if([QPlayAutoSDK isStarted])
    {
        [QPlayAutoSDK stop];
        self.currentItem = nil;
        self.currentSong = nil;
        [self.tableview reloadData];
        [self.btnConnect setTitle:@"开始连接" forState:UIControlStateNormal];
        self.isConnected = NO;
    }
    else
    {
        [QPlayAutoSDK activeQQMusicApp];
        [QPlayAutoSDK start];
        [self.btnConnect setTitle:@"停止连接" forState:UIControlStateNormal];
        self.isConnected = NO;
    }
    
}

- (IBAction)onClickPlayPause:(id)sender {
    if(self.isConnected==NO)
        return;
    if(self.playState == QPlayAutoPlayState_Playing)
    {
        [QPlayAutoSDK playerPlayPause];
    }
    else
    {
        [QPlayAutoSDK playerResume:^(BOOL success, NSDictionary *dict) {
            if (!success)
            {
                [self showErrorCodeAlert:[NSString stringWithFormat:@"%@",dict]];
            }
        }];
    }
}

- (IBAction)onClickPlayPrev:(id)sender {
    if(self.isConnected==NO)
        return;
    [QPlayAutoSDK playerPlayPrev:^(BOOL success, NSDictionary *dict) {
        if (!success)
        {
            [self showErrorCodeAlert:[NSString stringWithFormat:@"%@",dict]];
        }
    }];
}

- (IBAction)onClickPlayNext:(id)sender {
    if(self.isConnected==NO)
        return;
    [QPlayAutoSDK playerPlayNext:^(BOOL success, NSDictionary *dict) {
        if (!success)
        {
            [self showErrorCodeAlert:[NSString stringWithFormat:@"%@",dict]];
        }
    }];
}

- (IBAction)onClickPlayMode:(id)sender {
    if(self.isConnected==NO)
        return;
    QPlayAutoPlayMode newMode;
    switch (self.currentPlayMode) {
        case QPlayAutoPlayMode_SequenceCircle:
            newMode = QPlayAutoPlayMode_RandomCircle;
            break;
        case QPlayAutoPlayMode_RandomCircle:
            newMode = QPlayAutoPlayMode_SingleCircle;
            break;
        default:
            newMode = QPlayAutoPlayMode_SequenceCircle;
            break;
    }
    [QPlayAutoSDK setPlayMode:newMode callback:^(BOOL success, NSDictionary *dict) {
        NSLog(@"setPlayMode compled:%d",(int)success);
        if(success)
        {
            self.currentPlayMode = newMode;
            [self updatePlayModeUI];
        }
    }];
}

- (IBAction)onClickLove:(id)sender {
    if(self.isConnected==NO || self.currentSong==nil)
        return;
    [QPlayAutoSDK setFavoriteState:!self.isLove songId:self.currentSong.ID callback:^(BOOL success, NSDictionary *dict) {
        NSLog(@"setFavoriteState compled:%d",(int)success);
        if(success)
        {
            self.isLove = !self.isLove;
            [self updateFavUI:self.isLove];
        }
    }];
}

- (IBAction)onSliderSeek:(id)sender {
    if(self.isConnected==NO || self.currentSong==nil)
        return;
    float newPos = self.progressSlider.value;
    [QPlayAutoSDK playerSeek:(NSInteger)newPos];
}

- (IBAction)onClickMore:(id)sender {
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* reloadDataAction = [UIAlertAction actionWithTitle:@"重新获取数据"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction* action)
                                   
                                   {
                                       if(self.isConnected==NO)
                                           return;
                                       [self resetContent];
                                       [self requestContent:self.rootItem pageIndex:0 pageSize:NormalPageSize];
                                       [alertView dismissViewControllerAnimated: YES completion: nil];
                                   }];
    UIAlertAction* mvAction = [UIAlertAction actionWithTitle:@"同步播放信息"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction* action)
                               
                               {
                                   [self syncPlayInfo];
                                   [alertView dismissViewControllerAnimated: YES completion: nil];
                               }];
    UIAlertAction* midSongAction = [UIAlertAction actionWithTitle:@"Mid播放歌曲"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction* action)
                               
                               {
                                   [self playWithMid];
                                   [alertView dismissViewControllerAnimated: YES completion: nil];
                               }];
    UIAlertAction* requsetQQAction = [UIAlertAction actionWithTitle:@"查询QQ音乐信息"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction* action)
                               
                               {
                                   [self requestQQMusicInfo];
                                   [alertView dismissViewControllerAnimated: YES completion: nil];
                               }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction* action)
                                   
                                   {
                                       [alertView dismissViewControllerAnimated: YES completion: nil];
                                   }];
    
    
    [alertView addAction:reloadDataAction];
    [alertView addAction:mvAction];
    [alertView addAction:cancelAction];
    [alertView addAction:midSongAction];
    [alertView addAction:requsetQQAction];
    [self presentViewController:alertView animated:NO completion:nil];
}

#pragma mark Private Method

- (void)requestQQMusicInfo{
    [QPlayAutoSDK requestMobileDeviceInfos:^(BOOL success, NSDictionary *dict) {
        [self showErrorCodeAlert:[NSString stringWithFormat:@"%@",dict]];
    }];
}

- (void)startProgressTimer
{
    [self stopProgressTimer];
    self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(onUpdateProgress) userInfo:nil repeats:YES];
}

- (void)stopProgressTimer
{
    if (self.progressTimer)
    {
        [self.progressTimer invalidate];
        self.progressTimer = nil;
    }
}

- (void)resetContent
{
    self.rootItem = [[QPlayAutoListItem alloc]init];
    self.rootItem.ID = kQPlayAutoItemRootID;
    self.rootItem.items = [[NSMutableArray alloc]init];
    
    self.searchItem = [[QPlayAutoListItem alloc]init];
    self.searchItem.Name = @"搜索";
    self.searchItem.ID = ID_SEARCH;
    [self.rootItem.items addObject:self.searchItem];
    
    self.currentItem = self.rootItem;
    self.pathStack = [[NSMutableArray alloc] init];
}

- (void)playWithMid
{
    //通过Mid播放陈亦迅两首歌
    [QPlayAutoSDK playSongMidAtIndex:@[@"0026ato22llymc",@"001fZLRw0Z0yRV"] playIndex:0 callback:^(BOOL success, NSDictionary *dict) {
        if (!success)
        {
            [self showErrorCodeAlert:[NSString stringWithFormat:@"%@",dict]];
        }
    }];
}

#pragma mark Update UI


- (void)updatePlayState:(QPlayAutoPlayState)playState song:(QPlayAutoListItem*)song position:(NSInteger)progress
{
    if (song.Type!=QPlayAutoListItemType_Song)
        return;
    self.playState = playState;
    self.currentProgress  = progress;
    self.progressSlider.value = self.currentProgress;
    switch (playState) {
        case QPlayAutoPlayState_Stop:
            [self.btnPlayPause setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
            [self stopProgressTimer];
            break;
        case QPlayAutoPlayState_Pause:
            [self.btnPlayPause setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
            [self stopProgressTimer];
            break;
        case QPlayAutoPlayState_Playing:
            [self.btnPlayPause setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
            [self startProgressTimer];
            break;
    }
    
    if (![self.currentSong.ID isEqualToString:song.ID])
    {
        self.currentSong = song;
        [self updateCurrentSongUI];
    }
}

- (void)updateCurrentSongUI
{
    if(self.isConnected==NO || self.currentSong==nil)
        return;
    self.progressSlider.maximumValue = (float)self.currentSong.Duration;
    self.songTitleLabel.text = self.currentSong.Name;
    self.singerLabel.text = [NSString stringWithFormat:@"%@-%@",self.currentSong.Album,self.currentSong.Artist];
    //专辑图
    if(self.currentSong.CoverUri.length>0)
    {
        UIImage *image = [self.imageCache objectForKey:self.currentSong.CoverUri];
        if(image)
        {
            [self.albumImgView setImage:image];
        }
        else
        {
            NSURL *url = [NSURL URLWithString:self.currentSong.CoverUri];
            if(url)
            {
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    NSData *data = [NSData dataWithContentsOfURL:url];
                    UIImage *image = [UIImage imageWithData:data];
                    if(image)
                    {
                        [self.imageCache setObject:image forKey:self.currentSong.CoverUri];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            [self.albumImgView setImage:image];
                        });
                    }
                });
            }
        }
    }
    
    self.isLove = NO;
    [self updateFavUI:self.isLove];
    [self syncFavState];
}

- (void)updateFavUI:(BOOL)isFav
{
    NSString *imgName = isFav ? @"loved" : @"love";
    [self.btnLove setImage:[UIImage imageNamed:imgName] forState:UIControlStateNormal];
}

- (void)updatePlayModeUI
{
    switch (self.currentPlayMode) {
        case QPlayAutoPlayMode_SingleCircle:
            [self.btnPlayMode setImage:[UIImage imageNamed:@"repeatone_normal"] forState:UIControlStateNormal];
            break;
        case QPlayAutoPlayMode_RandomCircle:
            [self.btnPlayMode setImage:[UIImage imageNamed:@"random_normal"] forState:UIControlStateNormal];
            break;
        default:
            [self.btnPlayMode setImage:[UIImage imageNamed:@"repeat_normal"] forState:UIControlStateNormal];
            break;
    }
}


- (void)onUpdateProgress
{
    if(self.isConnected==NO)
    {
        [self stopProgressTimer];
        return;
    }
    if (self.currentSong==nil || self.playState!=QPlayAutoPlayState_Playing || self.currentSong.Duration<=0)
        return;
    self.currentProgress ++ ;
    //    NSLog(@"更新进度:%d/%d",(int)self.currentProgress,(int)self.currentSong.Duration);
    if(self.currentProgress>self.currentSong.Duration)
        self.currentProgress = self.currentSong.Duration;
    else if(self.currentProgress<0)
        self.currentProgress = 0;
    self.progressSlider.value = self.currentProgress;
}


- (void)setLog:(NSString*)log
{
    NSString *logText = [NSString stringWithFormat:@"log：%@",log];
    if(NSThread.isMainThread)
    {
        [self.logLabel setText:logText];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.logLabel setText:logText];
        });
    }
}

#pragma mark SDK交互


- (void)onConnected
{
    [self setLog:@"连接成功"];
    self.isConnected = YES;
    [self resetContent];
    
    [self syncPlayInfo];
    [self syncPlayMode];
//    [self requestContent:self.rootItem pageIndex:0 pageSize:NormalPageSize];
    [self requestOpenIDAuth];
}

- (void)onDisconnect
{
    [self setLog:@"连接断开"];
    self.isConnected = NO;
    [self stopProgressTimer];
    [self.btnConnect setTitle:@"开始连接" forState:UIControlStateNormal];
}

- (void)syncPlayInfo
{
    if(self.isConnected==NO)
        return;
    [QPlayAutoSDK getCurrentPlayInfo:^(BOOL success, NSDictionary *dataDict) {
        QPlayAutoPlayState playState = [[dataDict objectForKey:kQPlayAutoArgument_State] unsignedIntegerValue];
        NSInteger position = [[dataDict objectForKey:kQPlayAutoArgument_Position]integerValue];
        NSDictionary *songDict = [dataDict objectForKey:kQPlayAutoArgument_Song];
        QPlayAutoListItem *song =[[QPlayAutoListItem alloc] initWithDictionary:songDict];
        [self updatePlayState:playState song:song position:position];
    }];
}

- (void)syncFavState
{
    if(self.isConnected==NO || self.currentSong==nil)
        return;
    //收藏状态
    [QPlayAutoSDK queryFavoriteState:self.currentSong.ID calllback:^(BOOL success, NSDictionary *dict) {
        if(success)
        {
            NSString *songId = [dict objectForKey:kQPlayAutoArgument_SongID];
            if([songId isEqualToString:self.currentSong.ID])
            {
                BOOL isFav = [[dict objectForKey:kQPlayAutoArgument_IsFav] boolValue];
                self.isLove = isFav;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateFavUI:isFav];
                });
            }
        }
        else
        {
            [self setLog:@"queryFavoriteState 失败"];
        }
    }];
}

- (void)syncPlayMode
{
    //同步播放模式设置
    [QPlayAutoSDK getPlayMode:^(BOOL success, NSDictionary *dict) {
        if(success)
        {
            QPlayAutoPlayMode playMode = [[dict objectForKey:kQPlayAutoArgument_PlayMode] integerValue];
            self.currentPlayMode = playMode;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updatePlayModeUI];
            });
        }
        else
        {
            [self setLog:@"getPlayMode 失败"];
        }
    }];
}

- (void)requestContent:(QPlayAutoListItem*)parentItem pageIndex:(NSUInteger)pageIndex pageSize:(NSUInteger)pageSize
{
    if(self.isConnected==NO)
        return;
    [self setLog:[NSString stringWithFormat:@"requestContent:%@ %@",parentItem.Name,parentItem.ID]];
    [QPlayAutoSDK getDataItems:parentItem.ID
                     pageIndex:pageIndex
                      pageSize:pageSize
                        openId:self.openId
                     openToken:self.openToken
                     calllback:^(BOOL success, NSDictionary *dict) {
                         
                         NSInteger errorCode = [[dict objectForKey:@"Error"] integerValue];
                         if (errorCode!=0)
                         {
                             [self setLog:[NSString stringWithFormat:@"获取数据失败,error:%zd",errorCode]];
                             return;
                         }
                         
                         NSInteger count = [[dict objectForKey:kQPlayAutoArgument_Count] integerValue];
                         //NSInteger pageIndex = [[dict objectForKey:kQPlayAutoArgument_PageIndex] integerValue];
                         NSString *parentID = [dict objectForKey:kQPlayAutoArgument_ParentID];
                         
                         [self setLog:[NSString stringWithFormat:@"requestContent completed:%@ %@ count:%ld",parentItem.Name,parentItem.ID,(long)count]];
                         QPlayAutoListItem *currentItem = [parentItem findItemWithID:parentID];
                         NSAssert(currentItem, @"what's wrong");
                         
                         
                         
                         if (currentItem.items == nil)
                         {
                             currentItem.items = [[NSMutableArray alloc]init];
                         }
                         
                         currentItem.totalCount = count;
                         NSArray *itemList = [dict objectForKey:kQPlayAutoArgument_Lists];
                         if (itemList.count>0)
                         {
                             for(NSDictionary *itemDict in itemList)
                             {
                                 if ([itemDict isKindOfClass:[NSDictionary class]] ==NO )
                                 {
                                     continue;
                                 }
                                 QPlayAutoListItem *item = [[QPlayAutoListItem alloc] initWithDictionary:itemDict];
                                 item.parentItem = currentItem;
                                 [currentItem.items addObject:item];
                             }
                         }
                         
                         if (self.currentItem.ID == parentItem.ID)
                         {
                             [self.tableview reloadData];
                         }
                     }];
}

- (void)requestOpenIDAuth
{
    if(self.isConnected==NO)
        return;
    [QPlayAutoSDK getOpenIdAuth:^(BOOL success, NSDictionary *dict) {
        if (success)
        {
            self.openId = [dict objectForKey:@"openId"];
            self.openToken = [dict objectForKey:@"openToken"];
            [self setLog:@"OpenId授权成功"];
        }
        else
        {
            [self setLog:@"OpenId授权失败"];
        }
        [self requestContent:self.rootItem pageIndex:0 pageSize:NormalPageSize];
    }];
}

- (void)requestSearch
{
    if(self.isConnected==NO)
        return;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"搜索" message:@"请输入关键词" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"关键词";
        textField.text = @"周杰伦";
    }];
    UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"确定"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction* action)
                                    
                                    {
                                        [self presentViewController:alertController animated:YES completion:^{
                                            UITextField *textField = alertController.textFields.firstObject;
                                            if (textField.text.length>0){
                                                [QPlayAutoSDK search:textField.text firstPage:YES calback:^(BOOL success, NSDictionary *dict) {
                                                    NSInteger errorCode = [[dict objectForKey:@"Error"] integerValue];
                                                    if (errorCode!=0)
                                                    {
                                                        [self setLog:[NSString stringWithFormat:@"搜索失败,error:%zd",errorCode]];
                                                        return;
                                                    }
                                                    NSArray *itemList = [dict objectForKey:kQPlayAutoArgument_Lists];
                                                    if (itemList.count>0)
                                                    {
                                                        for(NSDictionary *itemDict in itemList)
                                                        {
                                                            if ([itemDict isKindOfClass:[NSDictionary class]] ==NO )
                                                            {
                                                                continue;
                                                            }
                                                            QPlayAutoListItem *item = [[QPlayAutoListItem alloc] initWithDictionary:itemDict];
                                                            item.parentItem = self.searchItem;
                                                            [self.searchItem.items addObject:item];
                                                        }
                                                    }
                                                    [self.tableview reloadData];
                                                }];
                                            }
                                        }];
                                        [alertController dismissViewControllerAnimated: YES completion: nil];
                                    }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction* action)
                                   
                                   {
                                       [alertController dismissViewControllerAnimated: YES completion: nil];
                                   }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark tableview

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.currentItem.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = @"qplayautocell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell==nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    if (self.currentItem.items.count <= indexPath.row)
    {
        return cell;
    }
    
    QPlayAutoListItem *listItem = [self.currentItem.items objectAtIndex:indexPath.row];
    if (listItem.Type == QPlayAutoListItemType_Song)
    {
        cell.imageView.image = [UIImage imageNamed:@"song"];
    }
    else if (listItem.Type == QPlayAutoListItemType_Radio)
    {
        cell.imageView.image = [UIImage imageNamed:@"radio"];
    }
    else
    {
        cell.imageView.image = [UIImage imageNamed:@"playlist"];
    }
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.text = listItem.Name;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.currentItem.items.count <= indexPath.row)
        return;
    QPlayAutoListItem *listItem = [self.currentItem.items objectAtIndex:indexPath.row];
    
    if ([listItem.ID isEqualToString:ID_GO_BACK])
    {
        if (self.pathStack.lastObject==nil)
        {
            self.currentItem = self.rootItem;
        }
        else
        {
            self.currentItem = self.pathStack.lastObject;
            [self.pathStack removeLastObject];
        }
        [self.tableview reloadData];
        return;
    }
    else if ([listItem.ID isEqualToString:ID_SEARCH])
    {
        self.currentItem = self.searchItem;
        self.currentItem.items = [[NSMutableArray alloc]init];
        QPlayAutoListItem *item = [self getGoBackItem];
        [self.currentItem.items addObject:item];
         [self.tableview reloadData];
        [self requestSearch];
        return;
    }
    
    if (listItem.Type !=QPlayAutoListItemType_Song)
    {
        [self.pathStack addObject:self.currentItem];
        self.currentItem = listItem;
        self.currentItem.items = [[NSMutableArray alloc]init];
        if ([self.currentItem.ID isEqualToString:self.rootItem.ID]==NO)
        {
            QPlayAutoListItem *item = [self getGoBackItem];
            [self.currentItem.items addObject:item];
        }
        [self.tableview reloadData];
        
        [self requestContent:self.currentItem pageIndex:0 pageSize:NormalPageSize];
    }
    else
    {
        self.currentSong = listItem;
        
        NSArray<QPlayAutoListItem*> *songlist = [self.currentItem.items subarrayWithRange:NSMakeRange(1, self.currentItem.items.count-1)];//第一行是『..返回上一级』
        NSUInteger playIndex = [songlist indexOfObject:listItem];
        if(playIndex==NSNotFound)
        {
            playIndex = 0;
        }
        [QPlayAutoSDK playAtIndex:songlist playIndex:playIndex callback:^(BOOL success, NSDictionary *dict) {
            if (!success)
            {
                [self showErrorCodeAlert:[NSString stringWithFormat:@"%@",dict]];
            }
        }];
        [self updateCurrentSongUI];
    }
}

- (QPlayAutoListItem*)getGoBackItem
{
    QPlayAutoListItem *item = [[QPlayAutoListItem alloc] init];
    item.ID = ID_GO_BACK;
    item.Name = @"..返回上一级";
    return item;
}


#pragma mark QPlayAutoConnectStateDelegate

- (void)onQPlayAutoConnectStateChanged:(QPlayAutoConnectState)newState
{
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (newState) {
            case QPlayAutoConnectState_Disconnect:
                [self onDisconnect];
                break;
            case QPlayAutoConnectState_Connected:
                [self onConnected];
                break;
            default:
                break;
        }
    }) ;
}

- (void)onQPlayAutoPlayStateChanged:(QPlayAutoPlayState)playState song:(QPlayAutoListItem*)song position:(NSInteger)position
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updatePlayState:playState song:song position:position];
    }) ;
    
}

- (void)onSongFavoriteStateChange:(NSString*)songID isFavorite:(BOOL)isFavorite
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.currentSong.ID isEqualToString:songID])
        {
            [self updateFavUI:isFavorite];
        }
    }) ;
}

- (void)onPlayModeChange:(QPlayAutoPlayMode)playMode
{
    self.currentPlayMode = playMode;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updatePlayModeUI];
    });
}

-(void)onPlayPausedByTimeoff
{
    [self showErrorCodeAlert:@"糟糕 定时关闭了"];
}

- (void)showErrorCodeAlert:(NSString *)content
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:content preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
