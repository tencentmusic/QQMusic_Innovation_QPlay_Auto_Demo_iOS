//
//  HeartbeatSocket.h
//  QPlayAutoSDK
//
//  Created by travisli(李鞠佑) on 2018/11/5.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HeartbeatSocket : NSObject

@property (nonatomic,strong) NSString *destIP;
@property (nonatomic,assign) int destPort;

- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
