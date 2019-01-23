//
//  AppDelegate.m
//  iOSDemo
//
//  Created by jerry on 2019/1/23.
//  Copyright © 2019 com.sz.jerry. All rights reserved.
//

#import "AppDelegate.h"
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

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSString * machoPath = [[NSBundle mainBundle]executablePath];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    NSString * machopath22 = [docDir stringByAppendingString:@"/eeee"];
    [[NSFileManager defaultManager] copyItemAtPath:machoPath toPath:machopath22 error:nil];
    MachoHandle * handle = [[MachoHandle alloc]initWithMachoPath:machopath22];
    listLinkedDylibs(handle);
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
