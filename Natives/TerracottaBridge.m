#import "TerracottaBridge.h"
#import "terracotta.h"

NSString * const TerracottaStateDidChangeNotification = @"TerracottaStateDidChangeNotification";

@interface TerracottaBridge ()
@property(nonatomic, strong) dispatch_source_t stateTimer;
@property(nonatomic, copy) NSDictionary *lastState;
@property(nonatomic, assign) BOOL initialized;
@end

@implementation TerracottaBridge

+ (instancetype)sharedBridge {
    static TerracottaBridge *bridge;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bridge = [[self alloc] init];
    });
    return bridge;
}

- (BOOL)isAvailable {
    return terracotta_ios_available();
}

- (void)start {
    if (![self isAvailable]) return;

    // libterracotta 要求每个进程只初始化一次。结束会话只回到 waiting，
    // 再次打开页面不能重复调用 terracotta_ios_start。
    if (!self.initialized) {
        const char *home = getenv("POJAV_HOME");
        if (!home || home[0] == '\0') {
            NSLog(@"[Terracotta] POJAV_HOME is unavailable");
            return;
        }

        int result = terracotta_ios_start(home, -1);
        NSLog(@"[Terracotta] initialized: %d", result);
        if (result != 0) return;
        self.initialized = YES;
    }

    if (self.stateTimer) {
        [self pollState];
        return;
    }

    self.lastState = @{};
    dispatch_queue_t queue = dispatch_get_main_queue();
    self.stateTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(self.stateTimer,
                              dispatch_time(DISPATCH_TIME_NOW, 0),
                              NSEC_PER_SEC / 2,
                              NSEC_PER_SEC / 10);
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(self.stateTimer, ^{
        [weakSelf pollState];
    });
    dispatch_resume(self.stateTimer);
    [self pollState];
}

- (void)stop {
    if ([self isAvailable] && self.initialized) {
        terracotta_ios_set_waiting();
        [self pollState];
    }
}

- (void)dealloc {
    if (self.stateTimer) {
        dispatch_source_cancel(self.stateTimer);
        self.stateTimer = nil;
    }
}

- (NSDictionary *)currentState {
    if (![self isAvailable] || !self.initialized) return @{};
    char *json = terracotta_ios_get_state();
    if (!json) return @{};
    NSData *data = [NSData dataWithBytes:json length:strlen(json)];
    terracotta_ios_free_string(json);
    if (!data) return @{};
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return [object isKindOfClass:NSDictionary.class] ? object : @{};
}

- (TerracottaSessionState)sessionState {
    NSString *state = self.currentState[@"state"];
    if ([state isEqualToString:@"waiting"]) return TerracottaSessionStateWaiting;
    if ([state isEqualToString:@"host-scanning"]) return TerracottaSessionStateHostScanning;
    if ([state isEqualToString:@"host-starting"]) return TerracottaSessionStateHostStarting;
    if ([state isEqualToString:@"host-ok"]) return TerracottaSessionStateHostReady;
    if ([state isEqualToString:@"guest-connecting"]) return TerracottaSessionStateGuestConnecting;
    if ([state isEqualToString:@"guest-starting"]) return TerracottaSessionStateGuestStarting;
    if ([state isEqualToString:@"guest-ok"]) return TerracottaSessionStateGuestReady;
    if ([state isEqualToString:@"exception"]) return TerracottaSessionStateException;
    return TerracottaSessionStateUnknown;
}

- (BOOL)startHostScanningWithRoom:(NSString *)room player:(NSString *)player {
    if (![self isAvailable] || room.length == 0 || player.length == 0) return NO;
    terracotta_ios_set_scanning(room.UTF8String, player.UTF8String);
    return YES;
}

- (BOOL)startHostWithRoom:(NSString *)room port:(NSUInteger)port player:(NSString *)player {
    if (![self isAvailable] || room.length == 0 || player.length == 0 ||
        port == 0 || port > UINT16_MAX) return NO;
    return terracotta_ios_start_host_with_port(room.UTF8String, (uint16_t)port, player.UTF8String) != 0;
}

- (BOOL)joinRoom:(NSString *)room player:(NSString *)player {
    if (![self isAvailable] || room.length == 0 || player.length == 0 ||
        ![self isValidRoomCode:room]) return NO;
    return terracotta_ios_set_guesting(room.UTF8String, player.UTF8String) != 0;
}

- (BOOL)isValidRoomCode:(NSString *)room {
    return [self isAvailable] && room.length > 0 &&
           terracotta_ios_verify_room_code(room.UTF8String) == 3;
}

- (void)pollState {
    NSDictionary *state = self.currentState;
    if ([state isEqualToDictionary:self.lastState]) return;
    self.lastState = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:TerracottaStateDidChangeNotification
                                                        object:self
                                                      userInfo:state];
}

@end
