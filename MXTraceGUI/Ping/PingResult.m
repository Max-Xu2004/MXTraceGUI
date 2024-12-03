//
//  PingResult.m
//  MXTraceGUI
//
//  Created by Max Xu on 2024/11/29.
//

#import "PingResult.h"

@implementation PingResult

- (NSString *)description {
    NSMutableString *record = [[NSMutableString alloc] initWithCapacity:20];
    
    if (self.ipAddress == nil) {
        [record appendFormat:@" \t"];
    } else {
        [record appendFormat:@"%@\t", self.ipAddress];
    }
    
    for (id number in self.recvDurations) {
        if ([number isKindOfClass:[NSNull class]]) {
            [record appendFormat:@"*\t"];
        } else {
            [record appendFormat:@"%.2f ms\t", [(NSNumber *)number floatValue] * 1000];
        }
    }
    
    return record;
}

@end
