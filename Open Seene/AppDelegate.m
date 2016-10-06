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

@interface AppDelegate () {
    
    FlickrAPI *flickrAPI;
    NSString *flickr_token;
    NSString *flickr_nsid;
    NSString *flickr_username;
    NSString *flickr_fullname;
}

@end

@implementation AppDelegate
@synthesize buddyList;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // If we have a already a token in the UserDefaults, we'll try to retrieve the user's profile data.
    flickrAPI = [[FlickrAPI alloc] init];
    
    flickr_token = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrToken"];
    
    NSLog(@"AppDelegate: UserDefaults 'FlickrToken': %@", flickr_token);
    
    if ((flickr_token) || ([flickr_token length] > 10)) {
        
        if ([flickrAPI testFlickrLogin]) {
        
            flickr_nsid = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrNSID"];
            flickr_username = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrUsername"];
            flickr_fullname = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrFullname"];
            NSLog(@"AppDelegate: UserDefaults 'FlickrNSID': %@", flickr_nsid);
            NSLog(@"AppDelegate: UserDefaults 'FlickrUsername': %@", flickr_username);
            NSLog(@"AppDelegate: UserDefaults 'FlickrFullname': %@", flickr_fullname);
        
            // Update Profile and Buddy-List
        [   self updateProfileContacts];
        }
    }

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
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

- (void)updateProfileContacts {
    
    // Call API for User's profile icon & store the URL to UserDefaults
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[NSUserDefaults standardUserDefaults] setValue:[flickrAPI getProfileIconURL:flickr_nsid] forKey:@"FlickrProfileIconURL"];
    
    // Call API for User's ContactList (buddies)
    buddyList = [[NSMutableArray alloc] init];
    buddyList = [flickrAPI getContactList];
    
    int ndx;
    for (ndx = 0; ndx < buddyList.count; ndx++) {
        FlickrBuddy *buddy = [buddyList objectAtIndex:ndx];
        NSLog(@"Buddy: %@", buddy.username);
        NSMutableArray *albumList = [[NSMutableArray alloc] init];
        // Call API for Buddies Albums (extracting "Public Seenes" only this time).
        albumList = [flickrAPI getAlbumList:buddy.nsid];
        int adx;
        for (adx = 0; adx < albumList.count; adx++) {
            FlickrAlbum *album = [albumList objectAtIndex:adx];
            if (album.settype == 1) buddy.public_set = album;
        }
    }
}

@end
