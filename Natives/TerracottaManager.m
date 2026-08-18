#import "TerracottaManager.h"

@implementation TerracottaManager

+ (instancetype)sharedManager {
    static TerracottaManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (TerracottaBridge *)bridge {
    return TerracottaBridge.sharedBridge;
}

- (BOOL)available {
    return self.bridge.isAvailable;
}

- (NSDictionary *)state {
    return self.bridge.currentState;
}

- (void)start {
    [self.bridge start];
}

- (void)stop {
    [self.bridge stop];
}

- (BOOL)hostWithRoom:(NSString *)room player:(NSString *)player {
    return [self.bridge startHostScanningWithRoom:room player:player];
}

- (BOOL)hostWithRoom:(NSString *)room port:(NSUInteger)port player:(NSString *)player {
    return [self.bridge startHostWithRoom:room port:port player:player];
}

- (BOOL)joinRoom:(NSString *)room player:(NSString *)player {
    return [self.bridge joinRoom:room player:player];
}

@end
