//
//  MachoHandle.h
//  
//
//  Created by jerry on 2017/11/26.
//  Copyright © 2017年 test. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MachoModel.h"
NS_ASSUME_NONNULL_BEGIN
@interface MachoHandle : NSObject
- (instancetype) initWithMachoPath:(NSString *)machoPath;
//MARK: - arch
///如果binary是个thin版本则该方法会返回一个空数组。
- (NSArray<FatArch*> *) getFatArchs;

//MARK: - machheader
///如果binary是个thin版本，则fatArch传nil。
- (MachHeader * ) getMachHeaderInFatArch:(nullable FatArch *)fatArch;

//MARK: - dylib link
- (void) removeLinkedDylib:(NSString *)link;

- (void) addDylibLink:(NSString *)link;

- (NSString *)getLinkNameForDylibCmd:(DylibCommand * )dylibCmd;

//MARK: - load command
///如果binary是个thin版本，则fatArch传nil。
- (NSArray<LoadCommand *> *) getAllLoadCommandsInFatArch:(nullable FatArch *)fatArch;

/**
 loadCommandType 参考：mach-o/loader.h
 如果binary是个thin版本，则fatArch传nil。
 */
- (NSArray<LoadCommand *> *) getLoadCommandsInFatArch:(nullable FatArch *)fatArch
                                      loadCommandType:(int)loadCommandType;

///如果binary是个thin版本，则fatArch传nil。
- (NSArray<DylibCommand *> *) getDylibCommandInFatArch:(nullable FatArch *)fatArch;

@end
NS_ASSUME_NONNULL_END
