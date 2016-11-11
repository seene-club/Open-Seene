//
//  AuthenticationController.m
//  Open Seene
//
//  Created by Mathias Zettler on 13.09.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AuthenticationController.h"
#import "SBJson.h"
#import "FlickrAPI.h"
#import "AppDelegate.h"

@interface AuthenticationController () {
    FlickrAPI *flickrAPI;
}

@property (weak, nonatomic) IBOutlet UIButton *okButton;
@property (weak, nonatomic) IBOutlet UITextField *fkey1;
@property (weak, nonatomic) IBOutlet UITextField *fkey2;
@property (weak, nonatomic) IBOutlet UITextField *fkey3;


@end

@implementation AuthenticationController

- (void)viewDidLoad {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    // Call authorization view for "Open Seene" in WebView
    flickrAPI = [[FlickrAPI alloc] init];
    NSString *fullURL = [NSString stringWithFormat:@"https://www.flickr.com/auth-%@", flrAPIid];
    NSURL *url = [NSURL URLWithString:fullURL];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [_authView loadRequest:requestObj];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

-(void)doLogin {
    // Exchange MiniToken to FullToken via FlickrAPI
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSString *miniToken = [NSString stringWithFormat:@"%@-%@-%@", _fkey1.text, _fkey2.text, _fkey3.text];
    [flickrAPI exchangeMiniTokenToFullToken:miniToken];
    
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate updateOwnProfile];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)okPushed:(id)sender {
    [self doLogin];
}

@end
