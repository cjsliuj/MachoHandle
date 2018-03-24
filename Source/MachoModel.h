//
//  MachoModel.h
//
//
//  Created by jerry on 2017/12/1.
//  Copyright © 2017年 test. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <mach-o/loader.h>
#include <mach-o/swap.h>
#include <mach-o/fat.h>

@interface FatArch : NSObject
@property (nonatomic,assign) long offset;
@property (nonatomic,assign) struct fat_arch * fatArch;
@property (nonatomic,assign) struct fat_arch_64 * fatArch64;
- (NSString *)getCpuTypeName;
@end

@interface MachHeader : NSObject
@property (nonatomic,assign) long offset;
@property (nonatomic,assign) struct mach_header * machHeader;
@property (nonatomic,assign) struct mach_header_64 * machHeader64;
@end

@interface DylibCommand : NSObject
@property (nonatomic,assign) long offset;
@property (nonatomic,assign) struct dylib_command * dylibCmd;
@end

@interface LoadCommand : NSObject
@property (nonatomic,assign) long offset;
@property (nonatomic,assign) struct load_command * loadCmd;
@end


