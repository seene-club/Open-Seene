//
//  AppDelegate.m
//  Open Seene
//
//  Created by Mathias Zettler on 12.09.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import "AppDelegate.h"
#import "SBJson.h"
#import "FlickrAPI.h"
#import "FlickrBuddy.h"
#import "FlickrAlbum.h"
#import "FileHelper.h"
#import "StoryboardFinder.h"

@interface AppDelegate () {
    
    FlickrAPI *flickrAPI;
    FileHelper *fileHelper;
    NSString *flickr_token;
    NSString *flickr_nsid;
    NSString *flickr_username;
    NSString *flickr_fullname;
    StoryboardFinder *sbFinder;
    NSString *sbName;
    
}

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    sbFinder = [[StoryboardFinder alloc] initStoryboardFinder];
    [sbFinder storyboardNameToUserDefaults];
    sbName = [[NSUserDefaults standardUserDefaults] stringForKey:@"StoryboardName"];
    
    NSLog(@"Storyboard for device: %@", sbName);
    
    // Experimenting with Cache Sizes to get rid of the memory leak of UIWebView...
    int cacheSizeMemory = 4*1024*1024; // 4MB
    int cacheSizeDisk = 32*1024*1024; // 32MB
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:cacheSizeMemory diskCapacity:cacheSizeDisk diskPath:@"nsurlcache"];
    [NSURLCache setSharedURLCache:sharedCache];
    
    flickrAPI = [[FlickrAPI alloc] init];
    fileHelper = [[FileHelper alloc] initFileHelper];
    
    flickr_token = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrToken"];
    
    NSLog(@"AppDelegate: UserDefaults 'FlickrToken': %@", flickr_token);
    
    // If we have a already a token in the UserDefaults, we'll try to retrieve the user's profile data.
    if ((flickr_token) && ([flickr_token length] > 10)) {
        
        if ([flickrAPI testFlickrLogin]) {
        
            flickr_nsid = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrNSID"];
            flickr_username = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrUsername"];
            flickr_fullname = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrFullname"];
            NSLog(@"AppDelegate: UserDefaults 'FlickrNSID': %@", flickr_nsid);
            NSLog(@"AppDelegate: UserDefaults 'FlickrUsername': %@", flickr_username);
            NSLog(@"AppDelegate: UserDefaults 'FlickrFullname': %@", flickr_fullname);
        
            // Update Profile Pic
            [self updateOwnProfile];
        } else {
            [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"FlickrToken"];
        }
    } else {
        [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"FlickrToken"];
    }

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    // Chance the Storyboard for the root Controller!
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName: sbName bundle:[NSBundle mainBundle]];
    UIViewController *myController = [storyboard instantiateViewControllerWithIdentifier:@"entryPoint"];
    [self.window makeKeyAndVisible];
    [self.window.rootViewController presentViewController:myController animated:YES completion:NULL];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

// Call API for User's profile icon & store the URL to UserDefaults
- (void)updateOwnProfile {
    flickr_token = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrToken"];
    if ((flickr_token) && ([flickr_token length] > 10)) {
        flickr_nsid = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrNSID"];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [[NSUserDefaults standardUserDefaults] setValue:[flickrAPI getProfileIconURL:flickr_nsid] forKey:@"FlickrProfileIconURL"];
    }
}

@end
