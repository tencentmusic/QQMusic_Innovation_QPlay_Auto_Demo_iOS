//
//  CommandSocket.h
//  QPlayAutoSDK
//
//  Created by travisli(李鞠佑) on 2018/11/5.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CommandSocket;
@protocol CommandSocketDelegate <NSObject>

- (void)onCommandSocket:(CommandSocket*)socket recvData:(NSData*)data;

@end

@interface CommandSocket : NSObject

@property (nonatomic,weak) id<CommandSocketDelegate> delegate;
@property (nonatomic,strong) NSString *destIP;
@property (nonatomic,assign) int destPort;

- (instancetype)initWithDestinationIP:(NSString*)destIP;
- (void)start;
- (void)stop;
- (void)sendMsg:(NSString*)msg;

- (NSString*)connectedHost;

@end
NS_ASSUME_NONNULL_END
