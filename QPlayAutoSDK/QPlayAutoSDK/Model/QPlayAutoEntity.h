//
//  Header.h
//  QQMusic
//
//  Created by lijuyou on 15-2-5.
//
//

#import <Foundation/Foundation.h>
#import "QPlayAutoDefine.h"

#define QPLAYAUTO_VERSION @"1.2"

//QPlayAuto命令
#define QPLAYAUTO_CMD_DISCOVER @"Discover"              //发现命令,只用于 Wifi 通讯模式下发现设备
#define QPLAYAUTO_CMD_COMMINFOS @"CommInfos"            //车机通信信息:由移动设备发出
#define QPLAYAUTO_CMD_MOBILEINFO @"MobileDeviceInfos"   //查询移动设备信息:由车机发出
#define QPLAYAUTO_CMD_DEVICEINFO @"DeviceInfos"         //查询车机信息:由移动设备发出
#define QPLAYAUTO_CMD_ITEMS @"Items"                    //查询歌单根/子目录:由车机发出
#define QPLAYAUTO_CMD_PCITURE @"PICData"                //查询歌曲图片:由车机发出
#define QPLAYAUTO_CMD_MEDIAINFO @"MediaInfo"            //查询歌曲播放信息命令: 由车机发出
#define QPLAYAUTO_CMD_PCM @"PCMData"                    //读取歌曲 PCM 数据播放:由车机发出
#define QPLAYAUTO_CMD_STOP_DATA @"StopSendData"         //发送停止二进制数据传输命令:由移动设备/车机发出
#define QPLAYAUTO_CMD_PLAY_PRE @"DevicePlayPre"         //上一首命令:由移动设备发送
#define QPLAYAUTO_CMD_PLAY_NEXT @"DevicePlayNext"       //下一首命令:由移动设备发送
#define QPLAYAUTO_CMD_PLAY @"DevicePlayPlay"            //播放命令:由移动设备发送
#define QPLAYAUTO_CMD_PAUSE @"DevicePlayPause"          //播放命令:由移动设备发送
#define QPLAYAUTO_CMD_STOP_PLAY @"DevicePlayStop"       //播放命令:由移动设备发送
#define QPLAYAUTO_CMD_PLAY_STATE @"PlayState"           //查询车机播放状态命令:由移动设备发送
#define QPLAYAUTO_CMD_DISCONNECT @"Disconnect"          //断开连接命令:由移动设备/车机发送
#define QPLAYAUTO_CMD_HEARTBEAT @"Heartbeat"            //心跳包
#define QPLAYAUTO_CMD_REGISTER_PALYSTATE @"RegisterPlayState"       //注册播放消息回发命令:由移动设备发送
#define QPLAYAUTO_CMD_UNREGISTER_PALYSTATE @"UnRegisterPlayState"   //注销播播放消息回发命令:由移动设备发送
#define QPLAYAUTO_CMD_GETLYRIC @"LyricData"             //获取歌词:由车机发出
#define QPLAYAUTO_CMD_SEARCH @"Search"                  //搜索
#define QPLAYAUTO_CMD_NETWORK_STATE @"NetworkState"     //读取网络状态

#define QPLAYAUTO_LIST_ROOT @"-1"
#define QPLAYAUTO_LIST_LOCAL @"LOCAL_MUSIC"
#define QPLAYAUTO_LIST_FAV @"MY_FOLDER"
#define QPLAYAUTO_LIST_RANK @"RANK"
#define QPLAYAUTO_LIST_SQUARE @"ONLINE_FOLDER"
#define QPLAYAUTO_LIST_RADIO @"ONLINE_RADIO"
#define QPLAYAUTO_LIST_CATEGORY @"ASSORTMENT"
#define QPLAYAUTO_LIST_RECENTPLAY @"RECENT_PLAY"
#define QPLAYAUTO_LIST_SEPARATOR @"___" //分隔符

#define QPLAYAUTO_KEY_CMD @"cmd"
#define QPLAYAUTO_KEY_CALLBACKURL @"callbackurl"
#define QPLAYAUTO_KEY_DEVICE_NAME @"devicename"
#define QPLAYAUTO_KEY_DEVICE_ID @"deviceid"
#define QPLAYAUTO_KEY_DEVICE_BRAND @"devicebrand"


#define QPLAYAUTO_PCM_BUFFER 0x100000 //默认PCMbuffer为 1M

#define QPLAYAUTO_REQUEST_MIN_INTERVAL 0.5f //车机请求的最小时间间隔(秒)，时间太接近的重复请求可以忽略



/**
 QPlay播放信息
 */
@interface QPlayAutoPlayInfo : NSObject

@property (nonatomic,strong) NSString *songID;
@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSString *artist;
@property (nonatomic,strong) NSString *album;
@property (nonatomic,assign) NSInteger duration;
@property (nonatomic,assign) NSInteger playState;
@property (nonatomic,assign) BOOL isFav;

- (instancetype)initWithDictionary:(NSDictionary*)dict;
@end

//QPlayAuto请求
@interface QPlayAutoRequestInfo : NSObject

@property (nonatomic,assign) NSInteger requestNo;
@property (nonatomic, copy) QPlayAutoRequestFinishBlock finishBlock;
@property (nonatomic,strong,readonly) NSString *key;
- (instancetype)initWithRequestNO:(NSInteger)requestNo finishBlock:(QPlayAutoRequestFinishBlock)finishBlock;

@end


/**
 音频信息
 */
@interface QPlayAutoMediaInfo : NSObject

@property (nonatomic,strong) NSString *songID;
@property (nonatomic,assign) NSInteger pcmDataLength;
@property (nonatomic,assign) NSInteger rate;
@property (nonatomic,assign) NSInteger bit;
@property (nonatomic,assign) NSInteger channel;

- (instancetype)initWithDictionary:(NSDictionary*)dict;
@end
