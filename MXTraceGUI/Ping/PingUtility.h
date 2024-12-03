//
//  PingUtility.h
//  MXTraceGUI
//
//  Created by Max Xu on 2024/11/29.
//

#import <Foundation/Foundation.h>
#import "PingResult.h"

typedef void (^PingResultHandler)(PingResult *result);

@interface PingUtility : NSObject

@property (nonatomic, copy) NSString *host;                   // 目标主机
@property (nonatomic, copy) PingResultHandler resultHandler;  // Ping 结果回调

- (instancetype)initWithHost:(NSString *)host resultHandler:(PingResultHandler)handler;
- (void)startPing;

@end
