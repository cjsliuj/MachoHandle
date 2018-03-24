//
//  main.m
//  Demo
//
//  Created by jerry on 2018/3/24.
//  Copyright © 2018年 com.sz.jerry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MachoHandle.h"

void listLinkedDylibs(MachoHandle * machoHandler){
    NSArray * archs = [machoHandler getFatArchs];
    if (archs.count > 0) {
        for (FatArch * arch in archs){
            NSLog(@"--------- %@", [arch getCpuTypeName]);
            NSArray * dylibcmds = [machoHandler getDylibCommandInFatArch:arch];
            for(DylibCommand * dylcmd in dylibcmds){
                NSString * cmd = [machoHandler getLinkNameForDylibCmd:dylcmd];
                NSLog(@"%@",cmd);
            }
        }
    }else{
        NSArray * dylibcmds = [machoHandler getDylibCommandInFatArch:nil];
        for(DylibCommand * dylcmd in dylibcmds){
            NSString * cmd = [machoHandler getLinkNameForDylibCmd:dylcmd];
            NSLog(@"%@",cmd);
        }
    }
    
}
void addDylibLink(MachoHandle * machoHandler, NSString * link){
    [machoHandler addDylibLink:link];
}

void removeDylibLink(MachoHandle * machoHandler, NSString * link){
    [machoHandler removeLinkedDylib:link];
}

int main(int argc, const char * argv[]) {
    NSString * binaryPath = @"/Users/jerry/Desktop/TTT";//set a mach-o file path
    MachoHandle * machoHandler = [[MachoHandle alloc]initWithMachoPath:binaryPath];
    NSLog(@"原始的");
    listLinkedDylibs(machoHandler);
    addDylibLink(machoHandler, @"@executable_path/aaaa");
    addDylibLink(machoHandler, @"@executable_path/bbbb");
    removeDylibLink(machoHandler, @"@executable_path/aaaa");
    NSLog(@"编辑后的");
    listLinkedDylibs(machoHandler);
    return 0;
}



