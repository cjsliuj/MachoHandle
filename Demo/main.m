//
//  main.m
//  Demo
//
//  Created by 刘杰 on 2018/12/3.
//  Copyright © 2018年 com.sz.jerry. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@import MachoHandle;

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
    NSString * binaryPath = @"/Users/jerry/Desktop/518娱乐-121416/Payload/GloryProject-mobile.app/GloryProject-mobile";
    assert([NSFileManager.defaultManager fileExistsAtPath:binaryPath]);
    MachoHandle * machoHandler = [[MachoHandle alloc]initWithMachoPath:binaryPath];
    NSLog(@"original");
    //print shared libraries used (like command 'otool -L')
    listLinkedDylibs(machoHandler);
    //add a dylib link
    addDylibLink(machoHandler, @"@executable_path/aaaa");
    addDylibLink(machoHandler, @"@executable_path/bbbb");
    //remove dylib link
    removeDylibLink(machoHandler, @"@executable_path/aaaa");
    NSLog(@"after edit");
    listLinkedDylibs(machoHandler);
    return 0;
}


