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
/**
 If the structures of binary's format is 'thin', this method will return a empty array.
 */
- (NSArray<FatArch*> *) getFatArchs;

//MARK: - machheader
/**
 If the structures of binary's format is 'thin', you should set nil to the fatArch parameter.
 */
- (MachHeader * ) getMachHeaderInFatArch:(nullable FatArch *)fatArch;

//MARK: - dylib link
- (void) removeLinkedDylib:(NSString *)link;

- (void) addDylibLink:(NSString *)link;

- (NSString *)getLinkNameForDylibCmd:(DylibCommand * )dylibCmd;

//MARK: - load command
/**
 If the structures of binary's format is 'thin', you should set nil to the fatArch parameter.
 */
- (NSArray<LoadCommand *> *) getAllLoadCommandsInFatArch:(nullable FatArch *)fatArch;

/**
If the structures of binary's format is 'thin', you should set nil to the fatArch parameter.
loadCommandType Reference: mach-o/loader.h
*/
- (NSArray<LoadCommand *> *) getLoadCommandsInFatArch:(nullable FatArch *)fatArch
                                      loadCommandType:(int)loadCommandType;

/**
 If the structures of binary's format is 'thin', you should set nil to the fatArch parameter.
 */
- (NSArray<DylibCommand *> *) getDylibCommandInFatArch:(nullable FatArch *)fatArch;

@end
NS_ASSUME_NONNULL_END
