//
//  ViewController.m
//  Open Seene
//
//  Created by Mathias Zettler on 12.09.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import "ViewController.h"
#import "NSString+MD5.h"
#import "SBJson.h"
#import "AppDelegate.h"
#import "FlickrAPI.h"
#import "FlickrBuddy.h"
#import "FlickrAlbum.h"
#import "FlickrPhoto.h"

@interface ViewController () {

    FlickrAPI *flickrAPI;
    NSString *flickr_token;
    NSString *flickr_nsid;
    NSString *flickr_username;
    NSString *flickr_fullname;
    NSMutableArray *buddyList;
    NSMutableArray *timelinePhotos;
    int showIndex;
    Boolean timelineCreated;
    
}

@end

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self createTimeline];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


- (void)createTimeline {
    // Building Timeline from FlickrBuddies
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    buddyList = appDelegate.buddyList;
    
    flickrAPI = [[FlickrAPI alloc] init];
    timelinePhotos = [[NSMutableArray alloc] init];
    
    int ndx;
    for (ndx = 0; ndx < buddyList.count; ndx++) {
        FlickrBuddy *buddy = [buddyList objectAtIndex:ndx];
        if (buddy.public_set) {
            NSLog(@"%@ (%@) has Public Seenes set: %@", buddy.username, buddy.nsid, buddy.public_set.setid);
            NSMutableArray *buddyPhotos = [[NSMutableArray alloc] init];
            buddyPhotos = [flickrAPI getPublicSeenesList:buddy];
            [timelinePhotos addObjectsFromArray:buddyPhotos];
        }
    }
    
    // Sorting Timeline
    NSSortDescriptor *dateUploadDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateupload" ascending:NO];
    NSArray *sortDescriptors = @[dateUploadDescriptor];
    
    timelinePhotos = (NSMutableArray *)[timelinePhotos sortedArrayUsingDescriptors:sortDescriptors];
    
    if ([timelinePhotos count] > 0 ) {
        timelineCreated = TRUE;
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        showIndex = 0;
        [self showSeene];
        
    }
}


- (void)showSeene {
    //NSString *fullURL = @"https://seene-shelter.github.io/viewer/#/?url=https:%2F%2Fc7.staticflickr.com%2F9%2F8066%2F29189599710_5cff46eac9_o.jpg";
    FlickrPhoto *photo = [timelinePhotos objectAtIndex:showIndex];
    
    NSString *viewerURL = [NSString stringWithFormat:@"https://seene-shelter.github.io/viewer/#/?url=%@", photo.originalURL];
    NSLog(@"Loading Seene: %d %@ %@", showIndex, photo.ownerName, photo.originalURL);
    NSURL *url = [NSURL URLWithString:viewerURL];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [_SeeneViewer loadRequest:requestObj];
    
    
    [_usernameButton setTitle:[NSString stringWithFormat:@"@%@",photo.ownerName] forState:UIControlStateNormal];
    [_titleLabel setText:photo.title];
    [_likesCountLabel setText:[NSString stringWithFormat:@"%@ likes",photo.favoritesCount]];
    [_commentsCountButton setTitle:[NSString stringWithFormat:@"%@ comments",photo.commentsCount] forState:UIControlStateNormal];
    
    
    [_nextButton setEnabled:(showIndex + 1 < [timelinePhotos count])];
    [_nextButton setHidden:!(showIndex + 1 < [timelinePhotos count])];
    [_previousButton setEnabled:(showIndex + 0 > 0)];
    [_previousButton setHidden:!(showIndex + 0 > 0)];
    
}

- (IBAction)previousPushed:(id)sender {
    showIndex--;
    [self showSeene];
}

- (IBAction)nextPushed:(id)sender {
    showIndex++;
    [self showSeene];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}


// when view appears, check if user has already authorized Flickr account for "Open Seene"
- (void)viewDidAppear:(BOOL)animated {
    
    flickr_token = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrToken"];
    NSLog(@"UserDefaults 'FlickrToken': %@", flickr_token);
    
    if (([flickr_token length] == 0) || (!flickr_token) || ([flickr_token isEqualToString:@"(null)"])) {
        [self performSegueWithIdentifier: @"authSegue" sender: self];
    }
    
    if (!timelineCreated) [self createTimeline];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end