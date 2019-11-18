//
//  ResultSocket.m
//  QPlayAutoSDK
//
//  Created by travisli(李鞠佑) on 2018/11/5.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#import "ResultSocket.h"
#import "CocoaAsyncSocket.h"
#import "QMMacros.h"


@interface ResultSocket()<GCDAsyncUdpSocketDelegate>

@property (nonatomic,strong) GCDAsyncUdpSocket *udpSocket;

@end

@implementation ResultSocket

- (void)start
{
    if(self.udpSocket!=nil)
    {
        return;
    }
    self.udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSError *error = nil;
    if (![self.udpSocket bindToPort:LocalResultPort error:&error])
    {
        NSLog(@"ResultSocket Error binding: %@", error);
        return;
    }
    
    if (![self.udpSocket beginReceiving:&error])
    {
        NSLog(@"ResultSocket Error receiving: %@", error);
        return;
    }
    
}

- (void)stop
{
    if(self.udpSocket!=nil)
    {
        if (![self.udpSocket isClosed])
            [self.udpSocket close];
        self.udpSocket = nil;
    }
}

- (void)sendMsg:(NSString*)msg
{
    if(self.destIP.length==0 || self.destPort==0)
    {
        NSLog(@"ResultSocket host or port is invalid:%@ %d",self.destIP,self.destPort);
        return;
    }
    [self.udpSocket sendData:[msg dataUsingEncoding:NSUTF8StringEncoding] toHost:self.destIP port:self.destPort withTimeout:-1 tag:0];
    
}

#pragma GCDAsyncUdpSocketDelegate

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    NSLog(@"ResultSocket发送结果成功");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError * _Nullable)error
{
    NSLog(@"ResultSocket发送结果失败:%@",error);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(nullable id)filterContext
{
    NSString *msg = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"ResultSocket recv result: %@",msg);
    
    if (msg && [self.delegate respondsToSelector:@selector(onResultSocket:recvData:)])
    {
        [self.delegate onResultSocket:self recvData:data];
    }
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError  * _Nullable)error
{
     NSLog(@"ResultSocket close: %@",error);
}
@end

