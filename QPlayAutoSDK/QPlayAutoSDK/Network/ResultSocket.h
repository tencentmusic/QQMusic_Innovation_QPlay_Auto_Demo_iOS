//
//  ResultSocket.h
//  QPlayAutoSDK
//
//  Created by travisli(李鞠佑) on 2018/11/5.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ResultSocket;
@protocol ResultSocketDelegate <NSObject>

- (void)onResultSocket:(ResultSocket*)socket recvData:(NSData*)data;

@end

@interface ResultSocket : NSObject

@property (nonatomic,weak) id<ResultSocketDelegate> delegate;
@property (nonatomic,strong) NSString *destIP;
@property (nonatomic,assign) int destPort;

- (void)start;
- (void)stop;
- (void)sendMsg:(NSString*)msg;
@end


NS_ASSUME_NONNULL_END
