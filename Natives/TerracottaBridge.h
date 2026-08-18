#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TerracottaSessionState) {
    TerracottaSessionStateWaiting = 0,
    TerracottaSessionStateHostScanning,
    TerracottaSessionStateHostStarting,
    TerracottaSessionStateHostReady,
    TerracottaSessionStateGuestConnecting,
    TerracottaSessionStateGuestStarting,
    TerracottaSessionStateGuestReady,
    TerracottaSessionStateException,
    TerracottaSessionStateUnknown
};

FOUNDATION_EXPORT NSString * const TerracottaStateDidChangeNotification;

@interface TerracottaBridge : NSObject

+ (instancetype)sharedBridge;
- (BOOL)isAvailable;
- (void)start;
- (void)stop;
- (NSDictionary *)currentState;
- (TerracottaSessionState)sessionState;
- (BOOL)startHostScanningWithRoom:(NSString *)room player:(NSString *)player;
- (BOOL)startHostWithRoom:(NSString *)room port:(NSUInteger)port player:(NSString *)player;
- (BOOL)joinRoom:(NSString *)room player:(NSString *)player;
- (BOOL)isValidRoomCode:(NSString *)room;

@end

NS_ASSUME_NONNULL_END
