//
//  PingUtility.m
//  MXTraceGUI
//
//  Created by Max Xu on 2024/11/29.
//

#import "PingUtility.h"
#import <sys/socket.h>
#import <arpa/inet.h>
#import <unistd.h>
#import <netdb.h>
#include <netinet/ip_icmp.h>
#import "TracerouteCommon.h"

@interface PingUtility ()

@property (nonatomic, assign) int send_sock;           // 套接字

@property (nonatomic) struct sockaddr_in destination;         // 目标地址

@property (nonatomic, strong) NSString *ipAddress;            // IP地址

@property (nonatomic, assign) struct sockaddr *remoteAddr;

@property (nonatomic, assign) BOOL isIPv6;

@end

@implementation PingUtility

- (instancetype)initWithHost:(NSString *)host resultHandler:(PingResultHandler)handler {
    self = [super init];
    if (self) {
        self.host = host;
        self.resultHandler = handler;
    }
    return self;
}

- (void)startPing {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self setupSocket];
        [self sendPing];
    });
}

- (void)setupSocket {
    NSArray *addresses = [TracerouteCommon resolveHost:self.host];
    if (addresses.count == 0) {
        NSLog(@"DNS解析失败");
        return;
    }
    self.ipAddress = [addresses firstObject];
    // 域名有多个地址时只取第一个
    if (addresses.count > 0) {
        NSLog(@"%@ has multiple addresses, using %@", self.host, self.ipAddress);
    }
    
    self.isIPv6 = [self.ipAddress rangeOfString:@":"].location != NSNotFound;
    
    // 目标主机地址
    self.remoteAddr = [TracerouteCommon makeSockaddrWithAddress:_ipAddress
                                                                       port:20000
                                                                     isIPv6:self.isIPv6];
    
    if (self.remoteAddr == NULL) {
        return;
    }
    
    // 创建套接字
    self.send_sock = socket(self.remoteAddr->sa_family,
                                   SOCK_DGRAM,
                                   self.isIPv6 ? IPPROTO_ICMPV6 : IPPROTO_ICMP);
    if (self.send_sock < 0) {
        NSLog(@"创建socket失败");
        return;
    }
    
    // 超时时间3秒
    struct timeval timeout;
    timeout.tv_sec = 3;
    timeout.tv_usec = 0;
    setsockopt(self.send_sock, SOL_SOCKET, SO_RCVTIMEO, (char *)&timeout, sizeof(timeout));
}

- (void)sendPing {
    BOOL succeed = NO;
    succeed = [self sendAndRecv:self.send_sock addr:self.remoteAddr];
    // 关闭socket
    close(self.send_sock);
}

- (BOOL)sendAndRecv:(int)sendSock
               addr:(struct sockaddr *)addr {
    char buff[200];
    BOOL finished = NO;
    BOOL isIPv6 = [_ipAddress rangeOfString:@":"].location != NSNotFound;
    socklen_t addrLen = isIPv6 ? sizeof(struct sockaddr_in6) : sizeof(struct sockaddr_in);
    
    // 构建icmp报文
    uint16_t identifier = (uint16_t)30;
    NSData *packetData = [TracerouteCommon makeICMPPacketWithID:identifier
                                                       sequence:30
                                                       isICMPv6:isIPv6];
    
    BOOL receiveReply = NO;
    NSMutableArray *durations = [[NSMutableArray alloc] init];
    
    // 连续发送3个ICMP报文，记录往返时长
    for (int try = 0; try < 3; try ++) {
        NSDate* startTime = [NSDate date];
        // 发送icmp报文
        ssize_t sent = sendto(sendSock,
                              packetData.bytes,
                              packetData.length,
                              0,
                              addr,
                              addrLen);
        if (sent < 0) {
            NSLog(@"发送失败: %s", strerror(errno));
            [durations addObject:[NSNull null]];
            continue;
        }
        
        // 接收icmp数据
        struct sockaddr remoteAddr;
        ssize_t resultLen = recvfrom(sendSock, buff, sizeof(buff), 0, (struct sockaddr*)&remoteAddr, &addrLen);
        if (resultLen < 0) {
            // fail
            [durations addObject:[NSNull null]];
            continue;
        } else {
            receiveReply = YES;
            NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:startTime];
            
            // 解析IP地址
            NSString* remoteAddress = nil;
            if (!isIPv6) {
                char ip[INET_ADDRSTRLEN] = {0};
                inet_ntop(AF_INET, &((struct sockaddr_in *)&remoteAddr)->sin_addr.s_addr, ip, sizeof(ip));
                remoteAddress = [NSString stringWithUTF8String:ip];
            } else {
                char ip[INET6_ADDRSTRLEN] = {0};
                inet_ntop(AF_INET6, &((struct sockaddr_in6 *)&remoteAddr)->sin6_addr, ip, INET6_ADDRSTRLEN);
                remoteAddress = [NSString stringWithUTF8String:ip];
            }
            
            // 结果判断
            [durations addObject:@(duration)];
            NSLog(@"%@", remoteAddress);
//            finished = YES;
        }
    }
    if (self.resultHandler) {
        PingResult * result = [[PingResult alloc] init];
        result.ipAddress = self.ipAddress;
        result.recvDurations = durations;
        self.resultHandler(result);
    }
    return finished;
}

- (void)notifyResult:(NSString *)result latency:(NSTimeInterval)latency {
    if (self.resultHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.resultHandler(result);
        });
    }
}

@end
