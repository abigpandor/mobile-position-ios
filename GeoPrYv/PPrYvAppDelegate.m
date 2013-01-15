//
//  PPrYvAppDelegate.m
//  AT PrYv
//
//  Created by Nicolas Manzini on 06.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import "PPrYvAppDelegate.h"
#import "PPrYvMapViewController.h"
#import "PPrYvLoginViewController.h"
#import "User+Extras.h"
#import "PPrYvCoreDataManager.h"
#import "PPrYvLocationManager.h"
#import "PPrYvPositionEventSender.h"
#import "PPrYvApiClient.h"
#import "PPrYvOpenUDID.h"
#import "Folder.h"

@interface PPrYvAppDelegate()
- (void)reportSyncError:(NSError *)error;
@end

@implementation PPrYvAppDelegate

@synthesize mapViewController = _mapViewController;

#pragma mark - Application Life Cycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"OpenUDID: %@", [PPrYvOpenUDID value]);

    // start core location manager
    [PPrYvLocationManager sharedInstance];

    // get the current user if any available
    User * user = [User currentUserInContext:[[PPrYvCoreDataManager sharedInstance] managedObjectContext]];

    self.mapViewController = [[PPrYvMapViewController alloc] initWithNibName:@"PPrYvMapViewController"
                                                                      bundle:nil];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.mapViewController;
    [self.window makeKeyAndVisible];
    
    if (user == nil) {
        
        // no user available - show the login form
        PPrYvLoginViewController * login = nil;
        
        login = [[PPrYvLoginViewController alloc] initWithNibName:@"PPrYvLoginViewController"
                                                           bundle:nil];

        [self.window.rootViewController presentViewController:login animated:YES completion:nil];
    }
    else {
        
        // a user exists. Thus maybe some events are waiting to be uploaded

        // start or restart the api Client with the new user upon successful start it would try to synchronize
        PPrYvApiClient *apiClient = [PPrYvApiClient sharedClient];
        [apiClient startClientWithUserId:user.userId
                              oAuthToken:user.userToken
                               channelId:kPrYvApplicationChannel successHandler:^(NSTimeInterval serverTime)
        {

            [PPrYvPositionEventSender sendAllPendingEventsToPrYvApi];
        }                   errorHandler:^(NSError *error)
        {
            [self reportSyncError:error];
        }];

    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[PPrYvLocationManager sharedInstance] applicationDidEnterBackground:application];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[PPrYvApiClient sharedClient] synchronizeTimeWithSuccessHandler:^(NSTimeInterval serverTime) {
        [PPrYvPositionEventSender sendAllPendingEventsToPrYvApi];
    } errorHandler:^(NSError *error) {
        [self reportSyncError:error];
    }];

    [[PPrYvLocationManager sharedInstance] applicationWillEnterForeground:application];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[PPrYvCoreDataManager sharedInstance] saveContext];
}

#pragma mark - private

- (void)reportSyncError:(NSError *)error
{
    [[[UIAlertView alloc] initWithTitle:nil
                                message:NSLocalizedString(@"alertCantSynchronize", )
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"cancelButton", )
                      otherButtonTitles:nil] show];
}

@end