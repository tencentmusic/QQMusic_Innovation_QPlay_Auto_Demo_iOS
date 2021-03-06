//
//  QPlayAutoManager.m
//  QPlayAutoManager
//
//  Created by travisli(李鞠佑) on 2018/11/5.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#import "QPlayAutoManager.h"
#import "DiscoverSocket.h"
#import "HeartbeatSocket.h"
#import "CommandSocket.h"
#import "DataSocket.h"
#import "ResultSocket.h"
#import "QPlayAutoEntity.h"
#import "QMMacros.h"
#import <UIKit/UIDevice.h>
#import "QMNetworkHelper.h"
#import "QQMusicUtils.h"


NSString *const kQPlayAutoItemRootID = @"-1";
NSString *const kQPlayAutoCmd_MobileDeviceInfos = @"MobileDeviceInfos";
NSString *const kQPlayAutoCmd_DeviceInfos = @"DeviceInfos";
NSString *const kQPlayAutoCmd_Items = @"Items";
NSString *const kQPlayAutoCmd_IsFavorite = @"IsFavorite";
NSString *const kQPlayAutoCmd_AddFavorite = @"AddFavorite";
NSString *const kQPlayAutoCmd_RemoveFavorite = @"RemoveFavorite";
NSString *const kQPlayAutoCmd_GetPlayMode = @"GetPlayMode";
NSString *const kQPlayAutoCmd_SetPlayMode = @"SetPlayMode";
NSString *const kQPlayAutoCmd_SetAssenceMode = @"SetAssenceMode";
NSString *const kQPlayAutoCmd_GetCurrentSong = @"GetCurrentSong";
NSString *const kQPlayAutoCmd_PICData = @"PICData";
NSString *const kQPlayAutoCmd_LyricData = @"LyricData";
NSString *const kQPlayAutoCmd_Search = @"Search";
NSString *const kQPlayAutoCmd_Disconnect = @"Disconnect";
NSString *const kQPlayAutoCmd_MediaInfo = @"MediaInfo";
NSString *const kQPlayAutoCmd_PCMData = @"PCMData";
NSString *const kQPlayAutoCmd_PlaySongIdList = @"PlaySongIdList";
NSString *const kQPlayAutoCmd_PlaySongMIdList = @"PlaySongMidList";
NSString *const kQPlayAutoCmd_PlayNext = @"PlayNext";
NSString *const kQPlayAutoCmd_PlayPrev = @"PlayPrev";
NSString *const kQPlayAutoCmd_PlayPause = @"PlayPause";
NSString *const kQPlayAutoCmd_PlayResume = @"PlayResume";
NSString *const kQPlayAutoCmd_PlaySeek = @"PlaySeek";
NSString *const kQPlayAutoCmd_Heartbeat = @"Heartbeat";
NSString *const kQPlayAutoCmd_CommInfos = @"CommInfos";
NSString *const kQPlayAutoCmd_Auth = @"Auth";


@interface QPlayAutoManager()<CommandSocketDelegate,DiscoverSocketDelegate,ResultSocketDelegate>


@property (nonatomic,strong) DiscoverSocket *discoverSocket;
@property (nonatomic,strong) HeartbeatSocket *heartbeatSocket;
@property (nonatomic,strong) CommandSocket *commandSocket;
@property (nonatomic,strong) DataSocket *dataSocket;
@property (nonatomic,strong) ResultSocket *resultSocket;
@property (nonatomic,strong) NSTimer *checkHeartbeatTimer;
@property (nonatomic,assign) NSTimeInterval lastHeartbeatTime;


@property (nonatomic,assign) int qmCommandPort;
@property (nonatomic,assign) int qmResultPort;
@property (nonatomic,strong) NSString *qmHost;

@property (nonatomic,assign) NSInteger requestNo;
@property (nonatomic, strong) NSMutableDictionary<NSString *,QPlayAutoRequestInfo *> *requestDic;

@property (nonatomic,strong) QPlayAutoListItem *rootItem;

@end


@implementation QPlayAutoManager

+ (instancetype)sharedInstance
{
    static QPlayAutoManager* g_dQPlayAutoManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_dQPlayAutoManager = [[QPlayAutoManager alloc] init];
    });
    return g_dQPlayAutoManager;
}

- (void)start:(QPlayAutoAppInfo*)appInfo
{
    self.appInfo = appInfo;
    if (self.appInfo.deviceType!=APP_DEVICE_TYPE)
    {
        //App方式的不再用发广播，直接使用scheme拉起来连接
        self.discoverSocket = [[DiscoverSocket alloc] init];
        self.discoverSocket.appInfo = appInfo;
        [self.discoverSocket start];
        self.discoverSocket.delegate = self;
    }
    
    self.commandSocket = [[CommandSocket alloc] init];
    [self.commandSocket start];
    self.commandSocket.delegate = self;
    
    self.dataSocket = [[DataSocket alloc] init];
    [self.dataSocket start];
    self.requestDic = [[NSMutableDictionary alloc]init];
    
    self.isConnected = NO;
    self.isStarted = YES;
}

- (void)stop
{
    if(self.isConnected)
    {
        [self stopCheckHeartbeatTimer];
        [self requestDisconnect];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self innerStop];
        });
    }
    else
    {
       [self innerStop];
    }
}

- (void)innerStop
{
    self.isConnected = NO;
    self.isStarted = NO;
    self.requestDic = nil;
    [self.discoverSocket stop];
    self.discoverSocket = nil;
    
    [self.commandSocket stop];
    self.commandSocket = nil;
    
    [self.dataSocket stop];
    self.dataSocket = nil;
    
    [self.heartbeatSocket stop];
    self.heartbeatSocket = nil;
    
    [self.resultSocket stop];
    self.resultSocket = nil;
}

#pragma mark Handler

- (void)onConnectSuccess
{
    NSLog(@"连接成功 %@ %d %d",self.qmHost,self.qmResultPort,self.qmCommandPort);
    self.isConnected = YES;
    if (self.discoverSocket)
    {
        [self.discoverSocket stop];//重启或断开连接后再开启
        self.discoverSocket = nil;
    }
    self.heartbeatSocket = [[HeartbeatSocket alloc]init];
    self.heartbeatSocket.destIP = self.qmHost;
    self.heartbeatSocket.destPort = self.qmCommandPort;
    [self.heartbeatSocket start];
    
    self.resultSocket = [[ResultSocket alloc]init];
    self.resultSocket.delegate = self;
    self.resultSocket.destIP = self.qmHost;
    self.resultSocket.destPort = self.qmResultPort;
    [self.resultSocket start];
    
    self.rootItem = [[QPlayAutoListItem alloc]init];
    self.rootItem.ID = kQPlayAutoItemRootID;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyConnectSuccess object:nil];
    
    self.lastHeartbeatTime = [NSDate timeIntervalSinceReferenceDate];
    [self startCheckHeartbeatTimer];
}

- (void)onDisconnect
{
    self.isConnected = NO;
    [self stopCheckHeartbeatTimer];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyDisconnect object:nil];
}

#pragma mark Commands

//查询移动设备信息
- (void)requestMobileDeviceInfos:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\"}\r\n",(long)req.requestNo,kQPlayAutoCmd_MobileDeviceInfos];
    [self.commandSocket sendMsg:msg];
}


//查询歌单目录
- (NSInteger)requestItems:(NSString*)parentID
                pageIndex:(NSUInteger)pageIndex
                 pageSize:(NSUInteger)pageSize
                    appId:(nullable NSString*)appId         //访问用户歌单需要
                   openId:(nullable NSString*)openId        //访问用户歌单需要
                openToken:(nullable NSString*)openToken     //访问用户歌单需要
                calllback:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\",\"Arguments\":{\"ParentID\":\"%@\", \"PageIndex\":%tu, \"PagePerCount\":%tu,\"AppID\":\"%@\",\"OpenID\":\"%@\",\"OpenToken\":\"%@\"}}\r\n",(long)req.requestNo, kQPlayAutoCmd_Items,parentID,pageIndex,pageSize,appId,openId,openToken];
    [self.commandSocket sendMsg:msg];
    return req.requestNo;
}

- (NSInteger)requestQueryFavoriteState:(NSString*)songId calllback:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\",\"Arguments\":{\"SongID\":\"%@\"}}\r\n",(long)req.requestNo,kQPlayAutoCmd_IsFavorite,songId];
    [self.commandSocket sendMsg:msg];
    return req.requestNo;
}

- (NSInteger)requestSetFavoriteState:(BOOL)isFav songId:(NSString*)songId callback:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    NSString *cmd = isFav ? kQPlayAutoCmd_AddFavorite : kQPlayAutoCmd_RemoveFavorite;
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\",\"Arguments\":{\"SongID\":\"%@\"}}\r\n",(long)req.requestNo,cmd,songId];
    [self.commandSocket sendMsg:msg];
    return req.requestNo;
}

- (NSInteger)requestGetPlayMode:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\"}\r\n",(long)req.requestNo,kQPlayAutoCmd_GetPlayMode];
    [self.commandSocket sendMsg:msg];
    return req.requestNo;
}

- (NSInteger)requestSetPlayMode:(QPlayAutoPlayMode)playMode callback:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\",\"Arguments\":{\"IntegerValue\":%d}}\r\n",(long)req.requestNo,kQPlayAutoCmd_SetPlayMode,(int)playMode];
    [self.commandSocket sendMsg:msg];
    return req.requestNo;
}

- (NSInteger)requestSetAssenceMode:(QPlayAutoAssenceMode)assenceMode callback:(QPlayAutoRequestFinishBlock)block {
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\",\"Arguments\":{\"IntegerValue\":%d}}\r\n",(long)req.requestNo,kQPlayAutoCmd_SetAssenceMode,(int)assenceMode];
    [self.commandSocket sendMsg:msg];
    return req.requestNo;
}

- (NSInteger)requestGetCurrentSong:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\"}\r\n",(long)req.requestNo,kQPlayAutoCmd_GetCurrentSong];
    [self.commandSocket sendMsg:msg];
    return req.requestNo;
}

//查询歌曲图片
- (void)requestAlbumImage:(NSString*)songId pageIndex:(NSUInteger)pageIndex
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:nil];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\",\"Arguments\":{\"SongID\":\"%@\", \"PackageIndex\":%tu}}\r\n",(long)req.requestNo,kQPlayAutoCmd_PICData,songId,pageIndex];
    [self.commandSocket sendMsg:msg];
}

//查询歌词
- (void)requestLyric:(NSString*)songId lyricType:(NSInteger)lyricType
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:nil];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\",\"Arguments\":{\"SongID\":\"%@\",\"PackageIndex\":,\"LyricType\":%zd}}\r\n",(long)req.requestNo,kQPlayAutoCmd_LyricData,songId,lyricType];
    [self.commandSocket sendMsg:msg];
}

//在线搜索歌曲
- (void)requestSearch:(NSString*)keyword pageIndex:(NSUInteger)pageIndex callback:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\",\"Arguments\":{\"Key\":\"%@\",\"PageFlag\":%zd}}\r\n",(long)req.requestNo,kQPlayAutoCmd_Search,keyword,pageIndex];
    [self.commandSocket sendMsg:msg];
}

//断开连接请求
- (void)requestDisconnect
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:nil];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{ \"RequestID\":%ld,\"Request\":\"%@\"}\r\n",(long)req.requestNo,kQPlayAutoCmd_Disconnect];
    [self.commandSocket sendMsg:msg];
}

//查询歌曲播放信息
- (void)requestMediaInfo:(NSString*)songId
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:nil];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{ \"RequestID\":%ld,\"Request\":\"%@\",\"Arguments\":{\"SongID\":\"%@\"}}\r\n",(long)req.requestNo,kQPlayAutoCmd_MediaInfo,songId];
    [self.commandSocket sendMsg:msg];
}

//查询歌曲播放信息
- (void)requestPcmData:(NSString*)songId packageIndex:(NSUInteger)packageIndex
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:nil];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\", \"Arguments\":{\"SongID\":\"%@\",\"PackageIndex\":%zd}}\r\n",(long)req.requestNo,kQPlayAutoCmd_PCMData,songId,packageIndex];
    [self.commandSocket sendMsg:msg];
}

- (void)requestPlaySongList:(NSArray<NSString*>*)songIdList playIndex:(NSInteger)playIndex callback:(QPlayAutoRequestFinishBlock)block
{
    if (songIdList.count==0)
        return;
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    
    NSString *songIdJson = [QQMusicUtils strWithJsonObject:songIdList];
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\", \"Arguments\":{\"SongIDLists\":%@,\"Index\":%zd}}\r\n",(long)req.requestNo,kQPlayAutoCmd_PlaySongIdList,songIdJson,playIndex];
    [self.commandSocket sendMsg:msg];
}

- (void)requestPlaySongMidList:(NSArray<NSString*>*)songMIdList playIndex:(NSInteger)playIndex callback:(QPlayAutoRequestFinishBlock)block
{
    if (songMIdList.count==0)
        return;
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    
    NSString *songIdJson = [QQMusicUtils strWithJsonObject:songMIdList];
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\", \"Arguments\":{\"SongIDLists\":%@,\"Index\":%zd}}\r\n",(long)req.requestNo,kQPlayAutoCmd_PlaySongMIdList,songIdJson,playIndex];
    [self.commandSocket sendMsg:msg];
}

- (void)reqeustPlayNext:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{ \"RequestID\":%ld,\"Request\":\"%@\"}\r\n",(long)req.requestNo,kQPlayAutoCmd_PlayNext];
    [self.commandSocket sendMsg:msg];
}

- (void)reqeustPlayPrev:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{ \"RequestID\":%ld,\"Request\":\"%@\"}\r\n",(long)req.requestNo,kQPlayAutoCmd_PlayPrev];
    [self.commandSocket sendMsg:msg];
}

- (void)reqeustPlayPause
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:nil];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{ \"RequestID\":%ld,\"Request\":\"%@\"}\r\n",(long)req.requestNo,kQPlayAutoCmd_PlayPause];
    [self.commandSocket sendMsg:msg];
}

- (void)reqeustPlayResume:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{ \"RequestID\":%ld,\"Request\":\"%@\"}\r\n",(long)req.requestNo,kQPlayAutoCmd_PlayResume];
    [self.commandSocket sendMsg:msg];
}

- (void)requestSeek:(NSInteger)position
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:nil];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\", \"Arguments\":{\"IntegerValue\":%d}}\r\n",(long)req.requestNo,kQPlayAutoCmd_PlaySeek,(int)position];
    [self.commandSocket sendMsg:msg];
}

- (NSInteger)requestOpenIDAuthWithAppId:(NSString*)appId
                            packageName:(NSString*)packageName
                          encryptString:(NSString*)encryptString
                               callback:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\", \"Arguments\":{\"AppID\":\"%@\",\"PackageName\":\"%@\",\"EncryptString\":\"%@\"}}\r\n",(long)req.requestNo,kQPlayAutoCmd_Auth,appId,packageName,encryptString];
    [self.commandSocket sendMsg:msg];
    return req.requestNo;
}

- (NSInteger)requestSearch:(NSString*)keyword firstPage:(BOOL)firstPage callback:(QPlayAutoRequestFinishBlock)block
{
    QPlayAutoRequestInfo *req = [[QPlayAutoRequestInfo alloc]initWithRequestNO:[self getRequestId] finishBlock:block];
    [self.requestDic setObject:req forKey:req.key];
    NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"Request\":\"%@\", \"Arguments\":{\"Key\":\"%@\",\"PageFlag\":%d}}\r\n",(long)req.requestNo,kQPlayAutoCmd_Search,keyword,firstPage?0:1];
    [self.commandSocket sendMsg:msg];
    return req.requestNo;
}

#pragma mark Helpers

//获取请求ID
- (NSInteger)getRequestId
{
    @synchronized(self.requestDic)
    {
        self.requestNo += 1;
        return self.requestNo;
    }
}

- (void)startCheckHeartbeatTimer
{
    [self stopCheckHeartbeatTimer];
    self.checkHeartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(onCheckHeartbeat) userInfo:nil repeats:YES];
}

- (void)stopCheckHeartbeatTimer
{
    if (self.checkHeartbeatTimer)
    {
        [self.checkHeartbeatTimer invalidate];
        self.checkHeartbeatTimer = nil;
    }
}

- (void)onCheckHeartbeat
{
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval heartbeatTime = (now-self.lastHeartbeatTime);
    if (heartbeatTime>11)
    {
        NSLog(@"已经%.1f秒没有收到心跳包了，连接断开",heartbeatTime);
        [self onDisconnect];
    }
}

#pragma mark CommandSocketDelegate

- (void)onCommandSocket:(CommandSocket*)socket recvData:(NSData*)data
{
    NSError *error = nil;
    NSDictionary *cmdDict =  [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    NSString *cmd = [cmdDict objectForKey:@"Request"];
    NSInteger reqId = [[cmdDict objectForKey:@"RequestID"] integerValue];
    
    if ([cmd isEqualToString:kQPlayAutoCmd_Heartbeat])
    {
        //心跳
        self.lastHeartbeatTime = [NSDate timeIntervalSinceReferenceDate];
        return;
    }
    
    NSLog(@"Recv command:%@",cmdDict);
    
    if ([cmd isEqualToString:kQPlayAutoCmd_CommInfos])
    {
        //QQ音乐的连接信息
        NSDictionary *argsDict = [cmdDict objectForKey:@"Arguments"];
        self.qmCommandPort = [[argsDict objectForKey:@"CommandPort"] intValue];
        self.qmResultPort = [[argsDict objectForKey:@"ResultPort"] intValue];
        self.qmHost = self.commandSocket.destIP;
        self.commandSocket.destPort = self.qmCommandPort;
        [self onConnectSuccess];
        
    }
    else if ([cmd isEqualToString:kQPlayAutoCmd_DeviceInfos])
    {
        //获取设备信息
        NSString *osVer = [[UIDevice currentDevice] systemVersion];
        NSDictionary *appInfoDic = [[NSBundle mainBundle] infoDictionary];
        NSString *appVersion = [appInfoDic objectForKey:@"CFBundleShortVersionString"];
        NSString *msg = [NSString stringWithFormat:@"{\"RequestID\":%ld,\"DeviceInfos\":{\"Brand\":\"%@\",\"Models\":\"%@\",\"OS\":\"%@\",\" OSVer\":\"%@\",\"AppVer\":\"%@\",\"PCMBuf\":%d, \"PICBuf\":%d, \"LRCBuf\": %d, \"Network\":1, \"Ver\":\"1.2\"}}\r\n",(long)reqId,DeviceBrand,DeviceModel,DeviceOS,osVer,appVersion,PCMBufSize,PicBufSize,LrcBufSize];
        [self.resultSocket sendMsg:msg];
        
    }
    else
    {
        NSLog(@"未处理的命令:%@",cmd);
    }
}

#pragma mark ResultSocketDelegate

- (void)onResultSocket:(ResultSocket*)socket recvData:(NSData*)data
{
    NSError *error = nil;
    NSDictionary *resultDict =  [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    
    NSString *eventName = [resultDict objectForKey:@"Event"];
    if (eventName.length>0)
    {
        NSLog(@"收到事件：%@",eventName);
        //事件处理
        NSDictionary *dataDict = [resultDict objectForKey:@"Data"];
        
        if ([eventName isEqualToString:@"PlayState"])
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyPlayInfo object:nil userInfo:dataDict];
        }
        else if ([eventName isEqualToString:@"SongFavoriteState"])
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifySongFavariteStateChange object:nil userInfo:dataDict];
        }
        else if ([eventName isEqualToString:@"PlayMode"])
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyPlayModeChange object:nil userInfo:dataDict];
        }
        else if ([eventName isEqualToString:@"QPlay_TimeOff"])
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyPlayPausedByTimeOff object:nil userInfo:dataDict];
        }
        return;
    }
    
    
    id key  =  [[resultDict allKeys] firstObject];
    if ([key isKindOfClass:[NSString class]] == NO)
    {
        return;
    }
    
    NSString *strKey = key;
    NSDictionary *contentDict = [resultDict objectForKey:key];
    NSObject *err = [contentDict objectForKey:@"Error"];

    NSString *reqIdStr = [NSString stringWithFormat:@"%ld",(long)[[resultDict objectForKey:@"RequestID"] integerValue]];
    
   
    QPlayAutoRequestInfo * req = [self.requestDic objectForKey:reqIdStr];
    if(req)
    {
        if (req.finishBlock)
        {
            BOOL success = (err== nil) || ([self changeWithValue:err] == 0);
            req.finishBlock(success, contentDict);
        }
        else
        {
            NSLog(@"请求：%@ 回调为空",strKey);
        }
    }
    else
    {
        NSLog(@"注意了！！！没有找到对应的请求");
    }
    
}

- (int)changeWithValue:(id)value
{
   if([value isKindOfClass:[NSNumber class]])
   {
      int intValue = [value intValue];
      return intValue;
   }
   else
   {
       return 1;
   }
}

- (void)onDiscoversocket:(nonnull DiscoverSocket *)socket {
    
}
@end
