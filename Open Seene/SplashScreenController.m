//
//  SplashScreenController.m
//  Open Seene
//
//  Created by Mathias Zettler on 02.12.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SplashScreenController.h"
#import "UIImage+animatedGIF.h"
#import "SBJson.h"
#import "FlickrAPI.h"
#import "FlickrBuddy.h"
#import "FlickrAlbum.h"
#import "FileHelper.h"
#import "StoryboardFinder.h"
#import "AppDelegate.h"
#import "ViewController.h"

@interface SplashScreenController ()
@property (weak, nonatomic) IBOutlet UIImageView *splashImage;
@end

@implementation SplashScreenController {
    FlickrAPI *flickrAPI;
    FileHelper *fileHelper;
    NSString *flickr_token;
    NSString *flickr_nsid;
    NSString *flickr_username;
    NSString *flickr_fullname;
    NSMutableArray *buddyList;
    NSMutableArray *timelinePhotos;
    StoryboardFinder *sbFinder;
    NSString *sbName;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"splash_animation" withExtension:@"gif"];
    _splashImage.image =  [UIImage animatedImageWithAnimatedGIFData:[NSData dataWithContentsOfURL:url]];
}

// TODO Timeline nach ViewController bringen!
- (void)viewDidAppear:(BOOL)animated {
    //NSTimer *timedThread = [NSTimer scheduledTimerWithTimeInterval:3.1 target:self selector:@selector(triggerEntryPointView) userInfo:nil repeats:NO];

    flickrAPI = [[FlickrAPI alloc] init];
    fileHelper = [[FileHelper alloc] initFileHelper];
    
    flickr_token = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrToken"];
    
    NSLog(@"SplashScreenController: UserDefaults 'FlickrToken': %@", flickr_token);
    
    // If we have a already a token in the UserDefaults, we'll try to retrieve the user's profile data.
    if ((flickr_token) && ([flickr_token length] > 10)) {
        
        if ([flickrAPI testFlickrLogin]) {
            
            flickr_nsid = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrNSID"];
            flickr_username = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrUsername"];
            flickr_fullname = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrFullname"];
            NSLog(@"SplashScreenController: UserDefaults 'FlickrNSID': %@", flickr_nsid);
            NSLog(@"SplashScreenController: UserDefaults 'FlickrUsername': %@", flickr_username);
            NSLog(@"SplashScreenController: UserDefaults 'FlickrFullname': %@", flickr_fullname);
            [[NSUserDefaults standardUserDefaults] setValue:[flickrAPI getProfileIconURL:flickr_nsid] forKey:@"FlickrProfileIconURL"];
            //ViewController *viewController = [[ViewController alloc] init];
            //[viewController createTimeline];
        } else {
            [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"FlickrToken"];
            NSLog(@"DEBUG: test login to Flickr failed!");
        }
    } else {
        [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"FlickrToken"];
        NSLog(@"DEBUG: ticket not valid!");
    }

    
}

- (void)triggerEntryPointView {
    
    sbFinder = [[StoryboardFinder alloc] initStoryboardFinder];
    [sbFinder storyboardNameToUserDefaults];
    sbName = [[NSUserDefaults standardUserDefaults] stringForKey:@"StoryboardName"];
    NSLog(@"SplashScreenController: Storyboard for device: %@", sbName);
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName: sbName bundle:[NSBundle mainBundle]];
    UIViewController *myController = [storyboard instantiateViewControllerWithIdentifier:@"entryPoint"];
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate.window makeKeyAndVisible];
    [appDelegate.window.window.rootViewController presentViewController:myController animated:YES completion:NULL];
    
}

@end
