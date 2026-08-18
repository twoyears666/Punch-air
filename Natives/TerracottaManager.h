#import <Foundation/Foundation.h>
#import "TerracottaBridge.h"

NS_ASSUME_NONNULL_BEGIN

@interface TerracottaManager : NSObject
+ (instancetype)sharedManager;
@property(nonatomic, readonly) BOOL available;
@property(nonatomic, readonly) NSDictionary *state;
- (void)start;
- (void)stop;
- (BOOL)hostWithRoom:(NSString *)room player:(NSString *)player;
- (BOOL)hostWithRoom:(NSString *)room port:(NSUInteger)port player:(NSString *)player;
- (BOOL)joinRoom:(NSString *)room player:(NSString *)player;
@end

NS_ASSUME_NONNULL_END
