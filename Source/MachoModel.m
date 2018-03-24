//
//  MachoModel.m
//  
//
//  Created by jerry on 2017/12/1.
//  Copyright © 2017年 test. All rights reserved.
//

#import "MachoModel.h"
@implementation FatArch : NSObject
- (instancetype)init
{
    self = [super init];
    if (self) {
        _offset = 0;
        _fatArch = nil;
        _fatArch64 = nil;
    }
    return self;
}
- (NSString *)getCpuTypeName{
    cpu_type_t cpuType = 0;
    if(self.fatArch){
        cpuType = self.fatArch->cputype;
    }else{
        cpuType = self.fatArch64->cputype;
    }
    return [FatArch _nameOfCpuType:cpuType];
}
+ (NSString *) _nameOfCpuType:(cpu_type_t)cpuType{
    
    static NSDictionary * cpuType2Name = nil;
    if (cpuType2Name == nil){
        cpuType2Name = @{
                         @(CPU_TYPE_I386) : @"I386",
                         @(CPU_TYPE_X86) : @"X86",
                         @(CPU_TYPE_X86_64) : @"X86_64",
                         @(CPU_TYPE_ARM) : @"arm",
                         @(CPU_TYPE_ARM64) : @"arm64"
                         };
    }
    return cpuType2Name[@(cpuType)] == nil ? [NSString stringWithFormat:@"%d",cpuType] : cpuType2Name[@(cpuType)];
}

@end

@implementation MachHeader : NSObject
- (instancetype)init
{
    self = [super init];
    if (self) {
        _offset = 0;
        _machHeader = nil;
        _machHeader64 = nil;
    }
    return self;
}
@end

@implementation LoadCommand : NSObject
- (instancetype)init
{
    self = [super init];
    if (self) {
        _offset = 0;
        _loadCmd = nil;
    }
    return self;
}
@end

@implementation DylibCommand : NSObject
- (instancetype)init
{
    self = [super init];
    if (self) {
        _offset = 0;
        _dylibCmd = nil;
    }
    return self;
}
@end
