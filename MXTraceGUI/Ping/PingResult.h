//
//  PingResult.h
//  MXTraceGUI
//
//  Created by Max Xu on 2024/11/29.
//

#import <Foundation/Foundation.h>

@interface PingResult : NSObject

@property (nonatomic, strong) NSString *ipAddress;  // 目标 IP 地址
@property (nonatomic, strong) NSArray<NSNumber *> *recvDurations;  // 延迟时间

- (NSString *)description;

@end
