//
//  DiscoverSocket.m
//  QPlayAutoSDK
//
//  Created by travisli(李鞠佑) on 2018/11/5.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#import "DiscoverSocket.h"
#import "CocoaAsyncSocket.h"
#import "QMNetworkHelper.h"
#import "QMMacros.h"
#import "QPlayAutoSDK.h"

@interface DiscoverSocket()<GCDAsyncUdpSocketDelegate>

@property (nonatomic,strong) GCDAsyncUdpSocket *discoverSocket;
@property (nonatomic,strong) NSTimer *discoverTimer;
@property (nonatomic,strong) NSString *broadcastIP;
@property (nonatomic,strong) NSString *localIP;

@end

@implementation DiscoverSocket


- (void)start
{
    if(self.discoverSocket!=nil)
    {
        return;
    }
    self.discoverSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSError *error = nil;
    
    if (![self.discoverSocket bindToPort:0 error:&error])
    {
        NSLog(@"Error binding: %@", error);
        return;
    }
    
    self.broadcastIP =[QMNetworkHelper getBroadcastAddress];
    self.localIP =[QMNetworkHelper getIPAddress:YES];
    
    if (![self.discoverSocket enableBroadcast:YES error:&error])
    {
        NSLog(@"Error enableBroadcast: %@", error);
        return;
    }
    if (![self.discoverSocket beginReceiving:&error])
    {
        NSLog(@"Error receiving: %@", error);
        return;
    }
    
    self.discoverTimer = [NSTimer scheduledTimerWithTimeInterval:5
                                                          target:self
                                                        selector:@selector(discover)
                                                        userInfo:self
                                                         repeats:YES];
}

- (void)stop
{
    [self.discoverTimer invalidate];
    self.discoverTimer = nil;
    if(self.discoverSocket!=nil)
    {
        if (![self.discoverSocket isClosed])
            [self.discoverSocket close];
        self.discoverSocket = nil;
    }
}

- (void)discover
{
    NSLog(@"discovering... %@",self.broadcastIP);
    NSString *msg = [NSString stringWithFormat:@"{\"Discover\":{\"DeviceIP\":\"%@\",\"DeviceID\":\"%@\",\"DataPort\":%d, \"CommandPort\":%d, \"ResultPort\":%d, \"DeviceType\":%d, \"ConnectType\":1, \"DeviceBrand\":\"%@\", \"DeviceName\":\"%@\"}}\r\n",self.localIP,self.appInfo.deviceId,LocalDataPort,LocalCommandPort,LocalResultPort,self.appInfo.deviceType,self.appInfo.brand,self.appInfo.name];
    [self.discoverSocket sendData:[msg dataUsingEncoding:NSUTF8StringEncoding] toHost:self.broadcastIP  port:RemoteCommandPort withTimeout:-1 tag:0];
}

#pragma GCDAsyncUdpSocketDelegate


- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    NSLog(@"discover:didSendDataWithTag:%ld",tag);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError * _Nullable)error
{
    NSLog(@"discover:didNotSendDataWithTag:%ld,error:%@",tag,error);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(nullable id)filterContext
{
    NSLog(@"discover:recv data:%lu",(unsigned long)address.length);
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError  * _Nullable)error
{
    NSLog(@"discover:close error:%@",error);
}

@end
