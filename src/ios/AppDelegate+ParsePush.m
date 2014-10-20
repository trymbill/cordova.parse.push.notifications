#import "AppDelegate+ParsePush.h"
#import <Parse/Parse.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Cordova/CDV.h>
#import <objc/runtime.h>

@implementation AppDelegate (ParsePush)

+ (void)load {
  Method original = class_getInstanceMethod(self, @selector(didFinishLaunchingWithOptions:));
  Method custom = class_getInstanceMethod(self, @selector(customDidFinishLaunchingWithOptions:));
  method_exchangeImplementations(original, custom);
}

- (BOOL)application:(UIApplication*)application customDidFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  // Fetch parse plist file and get app id and client key from it
  NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"parse" ofType:@"plist"]];
  NSString *app_id = [dictionary objectForKey:@"ParseAppID"];
  NSString *client_key = [dictionary objectForKey:@"ParseClientKey"];

  [Parse setApplicationId:app_id clientKey:client_key];

  [[PFInstallation currentInstallation] setObject:[PFUser currentUser] forKey:@"user"];
  [[PFInstallation currentInstallation] saveEventually];

  // Register for Push Notitications, if running iOS 8
  if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                    UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                             categories:nil];
    [application registerUserNotificationSettings:settings];
    [application registerForRemoteNotifications];
  } else {
    // Register for Push Notifications before iOS 8
    [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                     UIRemoteNotificationTypeAlert |
                                                     UIRemoteNotificationTypeSound)];
  }

  if (launchOptions != nil) {
    NSDictionary* notification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (notification != nil) {
      NSLog(@"Opened: %@", notification);
    }
  }

  return [self application:application customDidFinishLaunchingWithOptions:launchOptions];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  // Store the deviceToken in the current installation and save it to Parse.
  PFInstallation *currentInstallation = [PFInstallation currentInstallation];
  [currentInstallation setDeviceTokenFromData:deviceToken];
  [currentInstallation saveInBackground];
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
  if([application applicationState] == UIApplicationStateInactive) {
    NSLog(@"Received notification while inactive: %@", userInfo);
    [PFPush handlePush:userInfo];
  }
  else
  {
    NSLog(@"Received notifications while active: %@", userInfo);
  }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  NSLog(@"Active - Set Badge Number to Zero");
}

@end
