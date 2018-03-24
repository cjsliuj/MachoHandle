//
//  MachoHandle.m
//  
//
//  Created by jerry on 2017/11/26.
//  Copyright © 2017年 test. All rights reserved.
//

#import "MachoHandle.h"

NS_ASSUME_NONNULL_BEGIN
void insert(NSString * filePath, NSData * toInsertData, long offset){
    NSFileHandle * fh = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
    [fh seekToFileOffset:offset];
    NSData * remainData = [fh readDataToEndOfFile];
    [fh truncateFileAtOffset:offset];
    [fh writeData:toInsertData];
    [fh writeData:remainData];
    [fh synchronizeFile];
    [fh closeFile];
}
void delete(NSString * filePath, long offset, long size){
    NSFileHandle * fh = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
    [fh seekToFileOffset:offset + size];
    NSData * remainData = [fh readDataToEndOfFile];
    [fh truncateFileAtOffset:offset];
    [fh writeData:remainData];
    [fh synchronizeFile];
    [fh closeFile];
}

void * loadBytes(NSFileHandle * file ,long offset, int size) {
    [file seekToFileOffset:offset];
    NSData * data = [file readDataOfLength:size];
    void *buf = calloc(1, size);
    [data getBytes:buf length:data.length];
    return buf;
}

@implementation MachoHandle
{
    NSFileHandle * _machoFileHandle;
    NSString * _machoPath;
}
//MARK: - ------ Public ------
- (instancetype) initWithMachoPath:(NSString *)machoPath{
    NSAssert([[NSFileManager defaultManager] fileExistsAtPath:machoPath],
             [@"file not exists at: " stringByAppendingString:machoPath]);
    self = [super init];
    if (self) {
        _machoFileHandle = [NSFileHandle fileHandleForUpdatingAtPath:machoPath];
        _machoPath = machoPath;
    }
    uint32_t magic = [self _readMagicWithOffset:0];
    NSAssert([MachoHandle _isValidMachoOfMagic:magic],
             [machoPath stringByAppendingString:@" is a illegal macho file"]);
    
    return self;
}
//MARK: - arch
- (NSArray<FatArch*> *) getFatArchs{
    uint32_t magic = [self _readMagicWithOffset:0];
    BOOL isFat = [MachoHandle _isFatOfMagic:magic];
    BOOL is64 = [MachoHandle _isMagic64:magic];
    BOOL shouldSwap = [MachoHandle _shouldSwapBytesOfMagic:magic];
    if (!isFat){
        return @[];
    }
    int fat_header_size = sizeof(struct fat_header);
    int fat_arch_size = sizeof(struct fat_arch);
    
    struct fat_header * fatHeader = loadBytes(_machoFileHandle, 0, fat_header_size);
    if (shouldSwap) {
        swap_fat_header(fatHeader, 0);
    }
    NSMutableArray * rs = @[].mutableCopy;
    int arch_offset = fat_header_size;
    for (int i = 0; i < fatHeader->nfat_arch; i++) {
        FatArch * fatArchObj = [[FatArch alloc]init];
        if(is64){
            struct fat_arch_64 *arch =  loadBytes(_machoFileHandle, arch_offset, fat_arch_size);
            if (shouldSwap) {
                swap_fat_arch_64(arch, 1, 0);
            }
            fatArchObj.fatArch64 = arch;
        }else{
            struct fat_arch *arch = loadBytes(_machoFileHandle, arch_offset, fat_arch_size);
            if (shouldSwap) {
                swap_fat_arch(arch, 1, 0);
            }
            fatArchObj.fatArch = arch;
        }
        fatArchObj.offset = arch_offset;
        [rs addObject:fatArchObj];
        arch_offset += fat_arch_size;
    }
    return rs;
}


//MARK: - machheader
- (MachHeader * ) getMachHeaderInFatArch:(nullable FatArch *)fatArch{
    long mach_header_offset = 0;
    if (fatArch != nil){
        if (fatArch.fatArch != nil ){
            mach_header_offset = fatArch.fatArch -> offset;
        }else if(fatArch.fatArch64 != nil){
            mach_header_offset = fatArch.fatArch64 -> offset;
        }else{
            NSAssert(false, @"fatArch is nil");
        }
    }
    MachHeader * machHeaderObj = [[MachHeader alloc]init];
    machHeaderObj.offset = mach_header_offset;
    
    uint32_t magic = [self _readMagicWithOffset:mach_header_offset];
    int is_64 = [MachoHandle _isMagic64:magic];
    int is_swap_mach = [MachoHandle _shouldSwapBytesOfMagic:magic];
    if (is_64) {
        int header_size = sizeof(struct mach_header_64);
        struct mach_header_64 * header = loadBytes(_machoFileHandle,mach_header_offset,header_size);
        if (is_swap_mach) {
            swap_mach_header_64(header, 0);
        }
        machHeaderObj.machHeader64 = header;
    } else {
        int header_size = sizeof(struct mach_header);
        struct mach_header * header = loadBytes(_machoFileHandle, mach_header_offset, header_size);
        if (is_swap_mach) {
            swap_mach_header(header, 0);
        }
        machHeaderObj.machHeader = header;
        
    }
    return machHeaderObj;
    
}
//MARK: - dylib link
- (void) addDylibLink:(NSString *)link{
    NSArray<FatArch *>* fatArchs = [self getFatArchs];
    if (fatArchs.count >0){
        for(FatArch * arch in fatArchs){
            [self _addLink:link inFatArch:arch];
        }
    }else{
        [self _addLink:link inFatArch:nil];
    }
}

- (void) removeLinkedDylib:(NSString *)link{
    NSArray<FatArch *>* fatArchs = [self getFatArchs];
    if (fatArchs.count >0){
        for(FatArch * arch in fatArchs){
            [self _removeLink:link inFatArch:arch];
        }
    }else{
        [self _removeLink:link inFatArch:nil];
    }
}

- (NSString *)getLinkNameForDylibCmd:(DylibCommand * )dylibCmd{
    int pathstringLen = dylibCmd.dylibCmd->cmdsize -  dylibCmd.dylibCmd->dylib.name.offset;
    char * paths = loadBytes(_machoFileHandle, dylibCmd.offset + dylibCmd.dylibCmd->dylib.name.offset, pathstringLen);
    return [[NSString alloc]initWithUTF8String:paths];
}

//MARK: - load command
- (NSArray<LoadCommand *> *) getAllLoadCommandsInFatArch:(nullable FatArch *)fatArch{
    MachHeader * machheader = [self getMachHeaderInFatArch:fatArch];
    return [self _getLoadCommandsAfterMachHeader:machheader];
}

- (NSArray<LoadCommand *> *) getLoadCommandsInFatArch:(nullable FatArch *)fatArch
                                      loadCommandType:(int)loadCommandType{
    NSArray<LoadCommand *> * lcmds = [self getAllLoadCommandsInFatArch:fatArch];
    NSMutableArray<LoadCommand *> * rs = @[].mutableCopy;
    for (LoadCommand * lcmd in lcmds){
        if (lcmd.loadCmd->cmd == loadCommandType){
            [rs addObject:lcmd];
        }
    }
    return rs;
}
- (NSArray<DylibCommand *> *) getDylibCommandInFatArch:(nullable FatArch *)fatArch{
    NSMutableArray<DylibCommand *> * rs = @[].mutableCopy;
    MachHeader * machheader = [self getMachHeaderInFatArch:fatArch ];
    long magic = [self _readMagicWithOffset:machheader.offset];
    BOOL shouldSwap = [MachoHandle _shouldSwapBytesOfMagic:magic];
    
    NSArray<LoadCommand *> *lcmds = [self getLoadCommandsInFatArch:fatArch loadCommandType:LC_LOAD_DYLIB];
    for (LoadCommand * cmd in lcmds){
        struct dylib_command * dylib = loadBytes(_machoFileHandle, cmd.offset, sizeof(struct dylib_command));
        if (shouldSwap) {
            swap_dylib_command(dylib, 0);
        }
        DylibCommand * dylibcmd = [[DylibCommand alloc]init];
        dylibcmd.offset = cmd.offset;
        dylibcmd.dylibCmd = dylib;
        [rs addObject:dylibcmd];
    }
    return rs;
}

//MARK: - ------ Private ------
- (void) _addLink:(NSString *)link inFatArch:(nullable FatArch *)arch{
    uint32_t dylib_size = (uint32_t)[[link dataUsingEncoding:NSUTF8StringEncoding] length] + sizeof(struct dylib_command);
    dylib_size += sizeof(long) - (dylib_size % sizeof(long)); //按 long 类型长度对齐
    
    struct dylib_command dyld;
    dyld.cmd = LC_LOAD_DYLIB;
    dyld.cmdsize = dylib_size;
    dyld.dylib.compatibility_version = 0;
    dyld.dylib.current_version = 0;
    dyld.dylib.timestamp = 0;
    dyld.dylib.name.offset = sizeof(struct dylib_command);
    
    MachHeader * machHeader = [self getMachHeaderInFatArch:arch];
    long headerOffset = machHeader.offset;
    long headerSize = 0;
    long originNcmdSize = 0;
    //修改 mach header
    if(machHeader.machHeader){
        originNcmdSize = machHeader.machHeader->sizeofcmds;
        headerSize = sizeof(struct mach_header);
        machHeader.machHeader->ncmds += 1;
        machHeader.machHeader->sizeofcmds += dyld.cmdsize;
        [_machoFileHandle seekToFileOffset:machHeader.offset];
       
        [_machoFileHandle writeData: [NSData dataWithBytes:machHeader.machHeader length:sizeof(struct mach_header)]];
    }else{
        originNcmdSize = machHeader.machHeader64->sizeofcmds;
        headerSize = sizeof(struct mach_header_64);
        machHeader.machHeader64->ncmds += 1;
        machHeader.machHeader64->sizeofcmds += dyld.cmdsize;
        [_machoFileHandle seekToFileOffset:machHeader.offset];
        [_machoFileHandle writeData:[NSData dataWithBytes:machHeader.machHeader64 length:sizeof(struct mach_header_64)]];
    }
    [_machoFileHandle seekToFileOffset:(headerOffset + headerSize + originNcmdSize)];
    [_machoFileHandle writeData:[NSData dataWithBytes: &dyld length:sizeof(struct dylib_command)]];
    [_machoFileHandle writeData:[link dataUsingEncoding:NSUTF8StringEncoding]];
}
- (void) _removeLink:(NSString *)link inFatArch:(nullable FatArch *)arch{
    DylibCommand * toDelDc = nil;
    NSArray <DylibCommand *> * allDlCmds = [self getDylibCommandInFatArch:arch];
    for (DylibCommand * dc in allDlCmds){
        NSString * linkName = [self getLinkNameForDylibCmd:dc];
        if ([linkName rangeOfString:link].location != NSNotFound){
            toDelDc = dc;
            break;
        }
    }
    if (!toDelDc) {
        return;
    }
    MachHeader * machHeader = [self getMachHeaderInFatArch:arch];
    long headerOffset = machHeader.offset;
    long headerSize = 0;
    long originNcmdSize = 0;
    //change mach header
    if(machHeader.machHeader){
        originNcmdSize = machHeader.machHeader->sizeofcmds;
        headerSize = sizeof(struct mach_header);
        machHeader.machHeader->ncmds -= 1;
        machHeader.machHeader->sizeofcmds -= toDelDc.dylibCmd->cmdsize;
        [_machoFileHandle seekToFileOffset:machHeader.offset];
        [_machoFileHandle writeData: [NSData dataWithBytes:machHeader.machHeader length:sizeof(struct mach_header)]];
    }else{
        originNcmdSize = machHeader.machHeader64->sizeofcmds;
        headerSize = sizeof(struct mach_header_64);
        machHeader.machHeader64->ncmds -= 1;
        machHeader.machHeader64->sizeofcmds -= toDelDc.dylibCmd->cmdsize;
        [_machoFileHandle seekToFileOffset:machHeader.offset];
        [_machoFileHandle writeData: [NSData dataWithBytes:machHeader.machHeader64 length:sizeof(struct mach_header_64)]];
    }
    
    /*
     Through the insert and delete operation, as if using 0 replace dylib_command bytes.
     */
    int n = toDelDc.dylibCmd->cmdsize;
    uint8 *arr;
    arr = (uint8*)malloc(sizeof(uint8)*n);
    for (int i = 0; i < n; i++)
        arr[i] = 0;
    insert(_machoPath,[NSData dataWithBytes:arr length:n], headerOffset + headerSize + originNcmdSize);
    delete(_machoPath, toDelDc.offset, toDelDc.dylibCmd->cmdsize);
}


- (NSArray<LoadCommand *> *) _getLoadCommandsAfterMachHeader:(MachHeader *)machHeader{
    int ncmds = 0;
    long load_commands_offset = 0;
    
    if (machHeader.machHeader != nil){
        ncmds = machHeader.machHeader->ncmds;
        load_commands_offset = machHeader.offset + sizeof(struct mach_header);
    }else if (machHeader.machHeader64 != nil){
        ncmds = machHeader.machHeader64->ncmds;
        load_commands_offset = machHeader.offset + sizeof(struct mach_header_64);
    }else{
        NSAssert(false, @"nil machHeader");
    }
    uint32_t magic = [self _readMagicWithOffset:machHeader.offset];
    int shouldSwap = [MachoHandle _shouldSwapBytesOfMagic:magic];
    NSMutableArray * rs = @[].mutableCopy;
    for (int  i = 0; i < ncmds; i++) {
        struct load_command *cmd = loadBytes(_machoFileHandle, load_commands_offset, sizeof(struct load_command));
        if (shouldSwap) {
            swap_load_command(cmd, 0);
        }
        LoadCommand * lc = [[LoadCommand alloc]init];
        lc.offset = load_commands_offset;
        lc.loadCmd = cmd;
        
        [rs addObject:lc];
        
        load_commands_offset += cmd->cmdsize;
    }
    return rs;
}

//MARK: - magic
- (uint32_t) _readMagicWithOffset:(uint64_t)offset {
    uint32_t magic;
    uint32_t * t = loadBytes(_machoFileHandle, offset, sizeof(uint32_t));
    magic = *t;
    return magic;
}
+ (BOOL) _isFatOfMagic:(long)magic {
    return magic == FAT_MAGIC || magic == FAT_CIGAM;
}
+ (BOOL) _isMagic64:(long)magic {
    return magic == MH_MAGIC_64 || magic == MH_CIGAM_64;
}
+ (BOOL) _shouldSwapBytesOfMagic:(long)magic {
    return magic == MH_CIGAM || magic == MH_CIGAM_64 || magic == FAT_CIGAM;
}
+ (BOOL) _isValidMachoOfMagic:(long)magic{
    return magic == FAT_MAGIC || magic == FAT_CIGAM || magic == MH_MAGIC_64 || magic == MH_CIGAM_64;
}
- (void)dealloc{
    [_machoFileHandle closeFile];
}

@end
NS_ASSUME_NONNULL_END









