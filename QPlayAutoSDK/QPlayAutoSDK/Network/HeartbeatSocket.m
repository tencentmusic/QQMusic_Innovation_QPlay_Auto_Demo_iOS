//
//  HeartbeatSocket.m
//  QPlayAutoSDK
//
//  Created by travisli(李鞠佑) on 2018/11/5.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#import "HeartbeatSocket.h"
#import "CocoaAsyncSocket.h"
#import "QMMacros.h"

@interface HeartbeatSocket()<GCDAsyncUdpSocketDelegate>

@property (nonatomic,strong) GCDAsyncUdpSocket *udpSocket;
@property (nonatomic,strong) NSTimer *timer;

@end

@implementation HeartbeatSocket

- (void)start
{
    if(self.udpSocket!=nil)
    {
        return;
    }
    self.udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSError *error = nil;
    
    if (![self.udpSocket bindToPort:0 error:&error])
    {
        NSLog(@"Error binding: %@", error);
        return;
    }
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:3
                                                  target:self
                                                selector:@selector(sendHeartbeat)
                                                userInfo:self
                                                 repeats:YES];
}

- (void)stop
{
    [self.timer invalidate];
    self.timer = nil;
    if(self.udpSocket!=nil)
    {
        if (![self.udpSocket isClosed])
            [self.udpSocket close];
        self.udpSocket = nil;
    }
    
}

- (void)sendHeartbeat
{
    if(self.destIP.length==0 || self.destPort==0)
    {
        NSLog(@"heartbeat host or port is invalid:%@ %d",self.destIP,self.destPort);
        return;
    }
    NSString *msg = @"{\"RequestID\":123,\"Request\":\"Heartbeat\"}\r\n";
    [self.udpSocket sendData:[msg dataUsingEncoding:NSUTF8StringEncoding] toHost:self.destIP port:self.destPort withTimeout:-1 tag:0];
}

#pragma GCDAsyncUdpSocketDelegate

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError * _Nullable)error
{
    NSLog(@"heartbeat failed:%@",error);
}

@end
