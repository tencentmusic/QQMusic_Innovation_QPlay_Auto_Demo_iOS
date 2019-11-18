//
//  CommandSocket.m
//  QPlayAutoSDK
//
//  Created by travisli(李鞠佑) on 2018/11/5.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#import "CommandSocket.h"
#import "CocoaAsyncSocket.h"
#import "QMMacros.h"


@interface CommandSocket()<GCDAsyncUdpSocketDelegate>

@property (nonatomic,strong) GCDAsyncUdpSocket *udpSocket;
@property (nonatomic,strong) NSData *destAddress;
@property (nonatomic,strong) NSTimer *timer;

@end

@implementation CommandSocket

- (instancetype)initWithDestinationIP:(NSString*)destIP
{
    if (self = [super init])
    {
        self.destIP = destIP;
    }
    return self;
}

- (void)start
{
    if(self.udpSocket!=nil)
    {
        return;
    }
    
    self.udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError *error = nil;
    
    if (![self.udpSocket bindToPort:LocalCommandPort error:&error])
    {
        NSLog(@"cmdsocket Error binding: %@", error);
        return;
    }
    
    if (![self.udpSocket beginReceiving:&error])
    {
        NSLog(@"cmdsocket Error receiving: %@", error);
        return;
    }
    
    NSLog(@"cmdsocket bind on:%d",LocalCommandPort);
    
}

- (void)stop
{
    [self.timer invalidate];
    self.timer = nil;
    self.timer = nil;
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
        NSLog(@"cmdsocket host or port is invalid:%@ %d",self.destIP,self.destPort);
        return;
    }
    NSLog(@"向QQ音乐发送：%@",msg);
    [self.udpSocket sendData:[msg dataUsingEncoding:NSUTF8StringEncoding] toHost:self.destIP port:self.destPort withTimeout:-1 tag:0];
}

- (NSString*)connectedHost
{
    return [self.udpSocket connectedHost];
}

#pragma GCDAsyncUdpSocketDelegate

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address
{
    NSLog(@"cmdsocket didConnectToAddress：%@",address);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError * _Nullable)error
{
    NSLog(@"cmdsocket connect error：%@",error);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    NSLog(@"cmdsocket发送数据成功 %ld",tag);}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError * _Nullable)error
{
    NSLog(@"cmdsocket发送数据错误：%@",error);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(nullable id)filterContext
{
    if(self.destAddress==nil && address!=nil )
    {
        NSString *host=nil;
        uint16_t port = 0;
        if([GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address])
        {
            self.destAddress = address;
            self.destIP = host;
            NSLog(@"cmdsocket recv from addr:%@ %hu",host,port);
        }
    }
    
//    NSString *msg = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"cmdsocket didReceiveData: %@",msg);
    
    if ([self.delegate respondsToSelector:@selector(onCommandSocket:recvData:)])
    {
        [self.delegate onCommandSocket:self recvData:data];
    }
    
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError  * _Nullable)error
{
    NSLog(@"cmdsocket:close：%@",error);
}

@end
