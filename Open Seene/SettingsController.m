//
//  SettingsController.m
//  Open Seene
//
//  Created by Mathias Zettler on 15.09.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SettingsController.h"
#import "FlickrAPI.h"
#import "GroupMembersViewController.h"

@interface SettingsController () {
    
    FlickrAPI *flickrAPI;
    NSString *flickr_token;
    NSString *flickr_nsid;
    NSString *flickr_username;
    NSString *flickr_fullname;
    NSString *flickr_profileIconURL;
}


@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (weak, nonatomic) IBOutlet UIImageView *imgProfile;
@property (weak, nonatomic) IBOutlet UILabel *lblUsername;
@property (weak, nonatomic) IBOutlet UILabel *lblFullname;
@property (weak, nonatomic) IBOutlet UIButton *membersButton;

@end

@implementation SettingsController

- (void)viewDidLoad {
    flickrAPI = [[FlickrAPI alloc] init];
    
    flickr_token = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrToken"];
    
    [_membersButton setEnabled:NO];
    [_logoutButton setTitle:@"Log in" forState:UIControlStateNormal];
}

- (void)viewDidAppear:(BOOL)animated {
    
    if ([self tokenExists]) {
        flickr_nsid = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrNSID"];
        flickr_username = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrUsername"];
        flickr_fullname = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrFullname"];
        flickr_profileIconURL = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrProfileIconURL"];
        
        [_lblUsername setText:flickr_username];
        [_lblFullname setText:flickr_fullname];
        
        NSURL *url = [NSURL URLWithString:flickr_profileIconURL];
        
        NSData *data = [NSData dataWithContentsOfURL : url];
        
        UIImage *image = [UIImage imageWithData: data];
        [_imgProfile setImage:image];
        
        self.imgProfile.layer.cornerRadius = self.imgProfile.frame.size.width / 2;
        self.imgProfile.clipsToBounds = YES;
        self.imgProfile.layer.borderWidth = 3.0f;
        self.imgProfile.layer.borderColor = [UIColor whiteColor].CGColor;
        
        [_membersButton setEnabled:YES];
        [_logoutButton setTitle:@"Log out" forState:UIControlStateNormal];
    }
}


- (IBAction)membersBUttonPushed:(id)sender {
    
    if ([self tokenExists]) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:[[NSUserDefaults standardUserDefaults] stringForKey:@"StoryboardName"] bundle:nil];

        UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"SeeneGroupMembersView"];

        viewController.modalPresentationStyle = UIModalPresentationFormSheet;
        viewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentViewController:viewController animated:YES completion:nil];
     }
}

- (IBAction)logoutPushed:(id)sender {
    if ([self tokenExists]) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Log out?"
                              message:@"Do you really want to disconnect Open Seene from your Flickr account?"
                              delegate:self cancelButtonTitle:@"Cancel"
                              otherButtonTitles:@"Yes", nil];
        [alert show];
    } else {
        [self performSegueWithIdentifier: @"authSegue" sender: self];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    // Yes button response
    if (buttonIndex == 1) {
        [self logOffHandling];
    }
}

- (void)logOffHandling {
    [_membersButton setEnabled:NO];
    [flickrAPI resetLoginUserDefaults];
    
    [_imgProfile setImage:[UIImage imageNamed:@"user.png"]];
    [_lblUsername setText:@"Flickr User"];
    [_lblFullname setText:@"not logged in"];
    
    [_logoutButton setTitle:@"Log in" forState:UIControlStateNormal];
}

- (Boolean)tokenExists {
    flickr_token = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrToken"];
    if ((flickr_token) && ([flickr_token length] > 10)) return YES;
    return NO;
}

@end
