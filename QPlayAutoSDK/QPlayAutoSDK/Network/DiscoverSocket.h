//
//  DiscoverSocket.h
//  QPlayAutoSDK
//
//  Created by travisli(李鞠佑) on 2018/11/5.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class DiscoverSocket;
@class QPlayAutoAppInfo;
@protocol DiscoverSocketDelegate <NSObject>

- (void)onDiscoversocket:(DiscoverSocket*)socket;

@end

@interface DiscoverSocket : NSObject

@property (nonatomic,weak) id<DiscoverSocketDelegate> delegate;
@property (nonatomic, strong) QPlayAutoAppInfo *appInfo;

- (void)start;
- (void)stop;
@end

NS_ASSUME_NONNULL_END
