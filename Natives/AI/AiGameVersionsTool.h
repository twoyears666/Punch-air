//
//  AiGameVersionsTool.h
//  Amethyst
//
//  Air AI Agent 版本工具：
//    - list_game_versions（只读）：拉取真实 MC 版本列表（含 30 分钟缓存）。
//

#import <Foundation/Foundation.h>
#import "AiTool.h"

NS_ASSUME_NONNULL_BEGIN

/// list_game_versions 工具：查询远端可安装的 Minecraft 版本清单
@interface AiGameVersionsTool : NSObject <AiTool>

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *summary;
@property (nonatomic, readonly) AiToolPermission permission;

@end

NS_ASSUME_NONNULL_END