#import "AppDelegate+ParsePush.h"
#import <Parse/Parse.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Cordova/CDV.h>
#import <objc/runtime.h>

@implementation AppDelegate (ParsePush)

+ (void)load {
  method_exchangeImplementations(class_getInstanceMethod(self, @selector(application:didFinishLaunchingWithOptions:)), class_getInstanceMethod(self, @selector(application:customDidFinishLaunchingWithOptions:)));
}

- (BOOL)application:(UIApplication*)application customDidFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
    // Get app info
    NSBundle *bundle = [NSBundle mainBundle];
    NSDictionary *info = [bundle infoDictionary];

    NSString *app_id = [[info objectForKey:@"ParseAppID"] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    NSString *client_key = [[info objectForKey:@"ParseClientKey"] stringByReplacingOccurrencesOfString:@"\"" withString:@""];

    [Parse setApplicationId:app_id clientKey:client_key];

    [PFUser enableAutomaticUser];
    
    PFACL *defaultACL = [PFACL ACL];
    [defaultACL setPublicReadAccess:YES];
    
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
    
    if (application.applicationState != UIApplicationStateBackground) {
        BOOL preBackgroundPush = ![application respondsToSelector:@selector(backgroundRefreshStatus)];
        BOOL oldPushHandlerOnly = ![self respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)];
        BOOL noPushPayload = ![launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (preBackgroundPush || oldPushHandlerOnly || noPushPayload) {
            [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
            
            NSDictionary* notification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
            if (notification != nil) {
                NSLog(@"Opened: %@", notification);
            }
        }
    }
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                        UIUserNotificationTypeBadge |
                                                        UIUserNotificationTypeSound);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                                 categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    } else
#endif
    {
        [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                         UIRemoteNotificationTypeAlert |
                                                         UIRemoteNotificationTypeSound)];
    }

    return [self application:application customDidFinishLaunchingWithOptions:launchOptions];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    [PFPush storeDeviceToken:newDeviceToken];
    [PFPush subscribeToChannelInBackground:@"" target:self selector:@selector(subscribeFinished:error:)];
}


- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (error.code == 3010) {
        NSLog(@"Push notifications are not supported in the iOS Simulator.");
    } else {
        // show some alert or otherwise handle the failure to register.
        NSLog(@"application:didFailToRegisterForRemoteNotificationsWithError: %@", error);
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
    
    if (application.applicationState == UIApplicationStateInactive) {
        [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        [currentInstallation saveInBackground];
    }
}

#pragma mark - ()

- (void)subscribeFinished:(NSNumber *)result error:(NSError *)error {
    if ([result boolValue]) {
        NSLog(@"ParsePush successfully subscribed to push notifications on the broadcast channel.");
    } else {
        NSLog(@"ParsePush failed to subscribe to push notifications on the broadcast channel.");
    }
}

@end
