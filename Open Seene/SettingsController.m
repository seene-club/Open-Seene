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

@end

@implementation SettingsController

- (void)viewDidLoad {
    flickrAPI = [[FlickrAPI alloc] init];
    
    [self.tabBarItem setImage:[[UIImage imageNamed:@"Profile.png"]
                               imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    
    flickr_token = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrToken"];
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
}

- (IBAction)logoutPushed:(id)sender {
    [flickrAPI resetLoginUserDefaults];
}

@end