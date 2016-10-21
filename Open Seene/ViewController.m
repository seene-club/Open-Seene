//
//  ViewController.m
//  Open Seene
//
//  Created by Mathias Zettler on 12.09.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "ViewController.h"
#import "NSString+MD5.h"
#import "SBJson.h"
#import "AppDelegate.h"
#import "FlickrAPI.h"
#import "FlickrBuddy.h"
#import "FlickrAlbum.h"
#import "FlickrPhoto.h"
#import "CommentsViewController.h"
#import "FileHelper.h"

@interface ViewController () {

    FlickrAPI *flickrAPI;
    FlickrPhoto *photo;
    FileHelper *fileHelper;
    WKWebViewConfiguration *wKWebConfig;
    WKWebView *webView;
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
    
    [self viewerControlsHidden:YES];
    [self createTimeline];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)viewerControlsHidden:(BOOL)hiddenstate {
    [_titleLabel setHidden:hiddenstate];
    [_usernameButton setHidden:hiddenstate];
    [_likeButton setHidden:hiddenstate];
    [_commentButton setHidden:hiddenstate];
    [_nextButton setHidden:hiddenstate];
    [_previousButton setHidden:hiddenstate];
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

- (void)createTimeline {
    // Building Timeline from FlickrBuddies
    //AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    //buddyList = appDelegate.buddyList;
    fileHelper = [[FileHelper alloc] initFileHelper];
    buddyList = [fileHelper loadFollowingListFromPhone];
    
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
        [self viewerControlsHidden:NO];
    } else {
        [fileHelper createInitialFollowingFiles];
        [self createTimeline];
    }
}


- (void)showSeene {
    //NSString *fullURL = @"https://seene-shelter.github.io/viewer/#/?url=https:%2F%2Fc7.staticflickr.com%2F9%2F8066%2F29189599710_5cff46eac9_o.jpg";
    photo = [timelinePhotos objectAtIndex:showIndex];
    
    NSString *viewerURL = [NSString stringWithFormat:@"https://seene-shelter.github.io/viewer/#/?url=%@", photo.originalURL];
    NSLog(@"Loading Seene: %d %@ %@", showIndex, photo.ownerName, photo.originalURL);

    NSURL *url = [NSURL URLWithString:viewerURL];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    
    if (webView==nil) {
        wKWebConfig = [[WKWebViewConfiguration alloc] init];
        webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 60, 414, 414) configuration:wKWebConfig];
        webView.navigationDelegate = self;
        [self.view addSubview:webView];
    }
    
    [webView loadRequest:requestObj];
    
    // Fill-in labels
    [_usernameButton setTitle:[NSString stringWithFormat:@"@%@",photo.ownerName] forState:UIControlStateNormal];
    [_titleLabel setText:photo.title];
    
    UIImage *likeButton;
    UIImage *commentButton = [UIImage imageNamed:@"comment.png"];
    
    // check if photo is already liked
    if ([[NSString stringWithFormat:@"%@",photo.isFavorite] isEqualToString:[NSString stringWithFormat:@"1"]]) {
        //[_likeButton setTitle:@"remove like" forState:UIControlStateNormal];
        likeButton = [UIImage imageNamed:@"heart.png"];
    } else {
        //[_likeButton setTitle:@"like" forState:UIControlStateNormal];
        likeButton = [UIImage imageNamed:@"heart_empty.png"];
    }
    
    [_likeButton setImage:[self burnTextIntoImage:photo.favoritesCount :likeButton] forState:UIControlStateNormal];
    [_commentButton setImage:[self burnTextIntoImage:photo.commentsCount :commentButton] forState:UIControlStateNormal];
    
    // dis-/enable previous / next buttons
    [_nextButton setEnabled:(showIndex + 1 < [timelinePhotos count])];
    [_nextButton setHidden:!(showIndex + 1 < [timelinePhotos count])];
    [_previousButton setEnabled:(showIndex + 0 > 0)];
    [_previousButton setHidden:!(showIndex + 0 > 0)];
    
}


- (UIImage *)burnTextIntoImage:(NSString *)text :(UIImage *)img {
    
    UIGraphicsBeginImageContext(img.size);
    
    CGRect rect = CGRectMake(0,0, img.size.width, img.size.height);
    [img drawInRect:rect];
    
    [[UIColor blackColor] set];           // set text color
    NSInteger fontSize = 14;
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{ NSFontAttributeName: font,
                                  NSParagraphStyleAttributeName: paragraphStyle,
                                  NSForegroundColorAttributeName: [UIColor blackColor]};

    CGSize size = [text sizeWithAttributes:attributes];
    //CGSize size = [text sizeWithFont:font];

    if (size.width < rect.size.width) {
        CGRect r = CGRectMake(rect.origin.x,
                              rect.origin.y + (rect.size.height - size.height)/2,
                              rect.size.width,
                              (rect.size.height - size.height)/2);
        [text drawInRect:r withFont:font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
        //[text drawInRect:r withAttributes:attributes];
    }

    
    UIImage *theImage=UIGraphicsGetImageFromCurrentImageContext();   // extract the image
    UIGraphicsEndImageContext();     // clean  up the context.
    return theImage;
}

- (IBAction)reloadPushed:(id)sender {
    [self createTimeline];
}

- (IBAction)previousPushed:(id)sender {
    showIndex--;
    [self showSeene];
}

- (IBAction)nextPushed:(id)sender {
    showIndex++;
    [self showSeene];
}

-(IBAction)likePushed:(id)sender {
    flickrAPI = [[FlickrAPI alloc] init];
    if ([[NSString stringWithFormat:@"%@",photo.isFavorite] isEqualToString:[NSString stringWithFormat:@"1"]]) {
        Boolean success = [flickrAPI removeLike:photo];
        if (success) {
            photo.isFavorite = @"0";
            photo.favoritesCount =  [NSString stringWithFormat:@"%d",[photo.favoritesCount intValue] - 1];
            [self showSeene];
        }
    } else {
        Boolean success = [flickrAPI likeSeene:photo];
        if (success) {
            photo.isFavorite = @"1";
            photo.favoritesCount =  [NSString stringWithFormat:@"%d",[photo.favoritesCount intValue] + 1];
            [self showSeene];
        }
    }
}

// parameters for the segue to the CommentsViewController
-(void) prepareForSegue:(UIStoryboardPopoverSegue *)segue sender:(id)sender
{
    NSLog(@"segue.destinationViewController: %@", segue.destinationViewController);
    if ([segue.destinationViewController isKindOfClass:[CommentsViewController class]]) {
        CommentsViewController *cvc = (CommentsViewController *) segue.destinationViewController;
        cvc.photo = photo;
    }
}

-(IBAction)commentButtonPushed:(id)sender {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self performSegueWithIdentifier: @"commentsSegue" sender: self];
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
   [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [webView loadHTMLString: @"" baseURL: nil];
    webView = nil;
    [self showSeene];
}

@end
