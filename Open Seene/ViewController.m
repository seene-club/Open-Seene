//
//  ViewController.m
//  Open Seene
//
//  Created by Mathias Zettler on 12.09.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//


#import <mach/mach.h>
#import "ViewController.h"
#import "NSString+MD5.h"
#import "UIImage+animatedGIF.h"
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
    int reportedIndex;
    Boolean timelineCreated;
    CGFloat screenWidth;
    CGFloat screenHeight;
    
}

@end

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    flickr_token = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrToken"];
    
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGSize screenSize = screenBound.size;
    screenWidth = screenSize.width;
    screenHeight = screenSize.height;
    NSLog(@"Screen: %f x %f", screenWidth, screenHeight);
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"loading_animation_3D_01" withExtension:@"gif"];
    _previewImage.image =  [UIImage animatedImageWithAnimatedGIFData:[NSData dataWithContentsOfURL:url]];
    
    [self viewerControlsHidden:YES];
    if (([flickr_token length] > 10) && (!timelineCreated)) [self createTimeline];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)viewerControlsHidden:(BOOL)hiddenstate {
    [_titleLabel setHidden:hiddenstate];
    [_usernameButton setHidden:hiddenstate];
    [_likeButton setHidden:hiddenstate];
    [_commentButton setHidden:hiddenstate];
    [_nextButton setHidden:hiddenstate];
    [_previousButton setHidden:hiddenstate];
    [_previewImage setHidden:hiddenstate];
    [_dateLabelButton setHidden:hiddenstate];
}

// when view appears, check if user has already authorized Flickr account for "Open Seene"
- (void)viewDidAppear:(BOOL)animated {
    flickr_token = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrToken"];
    
    if (([flickr_token length] == 0) || (!flickr_token) || ([flickr_token isEqualToString:@"(null)"])) {
        NSLog(@"Flickr: login invalid!!! Reauthorization necessary...");
        [self performSegueWithIdentifier: @"authSegue" sender: self];
    } else {
        if (!timelineCreated) [self createTimeline];
    }
}


- (void)createTimeline {
    // Building Timeline from FlickrBuddies
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

- (NSURLRequest *)getURLrequestForIndex:(int)timelineIndex {
    photo = [timelinePhotos objectAtIndex:timelineIndex];
    
    NSString *viewerURL = [NSString stringWithFormat:@"%@%@", htmlViewerBaseURL, photo.originalURL];
    NSLog(@"Loading Seene: %d %@ %@", timelineIndex, photo.ownerName, photo.originalURL);
    NSLog(@"thumbnail-URL: %@",photo.thumbnailURL);
    
    NSURL *url = [NSURL URLWithString:viewerURL];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    return requestObj;
}

- (NSString*)dateStringFromUnixTimestamp:(NSString*)uts {
    double unixTimeStamp = [uts doubleValue];
    NSTimeInterval unixTimeInterval = unixTimeStamp;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:unixTimeInterval];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    return [dateFormatter stringFromDate:date];
}

- (void)showSeene {
     NSURLRequest *requestObj = [self getURLrequestForIndex:showIndex];
    
    if (webView==nil) {
        wKWebConfig = [[WKWebViewConfiguration alloc] init];
        wKWebConfig.selectionGranularity = WKSelectionGranularityCharacter;
        webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 60, screenWidth, screenWidth) configuration:wKWebConfig];
        webView.navigationDelegate = self;
        [webView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:NULL];
        [webView setHidden:YES];
        [self.view addSubview:webView];
        [webView loadRequest:requestObj];
    }
    
    // remove all existing subviews tagged 4711 (blurred)
    for (UIView *subview in [self.view subviews]) {
        if (subview.tag == 4711) {
            [subview removeFromSuperview];
        }
    }
    
    //TODO: cache thumbnails on device (cached data can also be used for upcoming timeline in thumbnail view)
    UIImage *bgimg = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:photo.thumbnailURL]]];
    self.view.layer.contents = (id)bgimg.CGImage;
    
    // create a new blurred subview
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurEffectView.frame = self.view.bounds;
    blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    blurEffectView.tag = 4711;
    
    [self.view addSubview:blurEffectView];
    [self.view sendSubviewToBack:blurEffectView];
    
    // Fill-in labels
    [_usernameButton setTitle:[NSString stringWithFormat:@"@%@",photo.ownerName] forState:UIControlStateNormal];
    
    [_dateLabelButton setTitle:[self dateStringFromUnixTimestamp:photo.dateupload] forState:UIControlStateNormal];
    [_titleLabel setText:photo.title];
    
    UIImage *likeButton;
    UIImage *commentButton = [UIImage imageNamed:@"Comment-256px.png"];
    
    // check if photo is already liked
    if ([[NSString stringWithFormat:@"%@",photo.isFavorite] isEqualToString:[NSString stringWithFormat:@"1"]]) {
        //[_likeButton setTitle:@"remove like" forState:UIControlStateNormal];
        likeButton = [UIImage imageNamed:@"Like-Fill-256px.png"];
    } else {
        //[_likeButton setTitle:@"like" forState:UIControlStateNormal];
        likeButton = [UIImage imageNamed:@"Like-256px.png"];
    }
    
    [_likeButton setImage:[self burnTextIntoImage:photo.favoritesCount :likeButton] forState:UIControlStateNormal];
    [_commentButton setImage:[self burnTextIntoImage:photo.commentsCount :commentButton] forState:UIControlStateNormal];
    
    // dis-/enable previous / next buttons
    [_nextButton setEnabled:(showIndex + 1 < [timelinePhotos count])];
    [_nextButton setHidden:!(showIndex + 1 < [timelinePhotos count])];
    [_previousButton setEnabled:(showIndex + 0 > 0)];
    [_previousButton setHidden:!(showIndex + 0 > 0)];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"loading"] && object == webView) {
        if(webView.loading) {
            NSLog(@"DEBUG: WkWebView IS loading...");
        } else {
            NSLog(@"DEBUG: WkWebView NOT loading");
            NSTimer *timedThread = [NSTimer scheduledTimerWithTimeInterval:2.5 target:self selector:@selector(showWkWebView) userInfo:nil repeats:NO];
            
        }
    }
}

- (void)showWkWebView {
    [webView setHidden:NO];
}


- (UIImage *)burnTextIntoImage:(NSString *)text :(UIImage *)img {
    
    UIGraphicsBeginImageContext(img.size);
    
    CGRect rect = CGRectMake(0,0, img.size.width, img.size.height);
    [img drawInRect:rect];
    
    [[UIColor blackColor] set];           // set text color
    NSInteger fontSize = 110;
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
    [self destroyWkWebView];
    [self createTimeline];
}

- (IBAction)previousPushed:(id)sender {
    [self destroyWkWebView];
    showIndex--;
    [self showSeene];
}

- (IBAction)nextPushed:(id)sender {
    [self destroyWkWebView];
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

-(IBAction)cameraButtonPushed:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"seene://camera"]];
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
   [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self report_memory:@"Memory Usage"];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)destroyWkWebView {
    NSLog(@"DEBUG: destroyWkWebView triggered!!!");
    [webView setHidden:YES];
    [webView stopLoading];
    [webView removeObserver:self forKeyPath:@"loading"];
    [webView loadHTMLString: @"" baseURL: nil];
    
    NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
    NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
        
    }];
    [webView removeFromSuperview];
    webView = nil;
}


- (void)didReceiveMemoryWarning {
    NSLog(@"Open Seene did receive memory warning!!!");
    [self report_memory:@"memory warning!!!"];
    [self destroyWkWebView];
    
    if (reportedIndex != showIndex) {
       reportedIndex = showIndex;
       UIAlertView *alert = [[UIAlertView alloc]
                             initWithTitle:@"Could not load Seene!"
                             message:@"Open Seene did receive a memory warning and WkWebView stopped loading this Seene! Do you want to try to releod the Seene?"
                             delegate:self cancelButtonTitle:@"Cancel"
                             otherButtonTitles:@"Yes", nil];
       [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    // Yes button response
    if (buttonIndex == 1) {
        reportedIndex = -1;
        [self showSeene];
    }
}

-(void)report_memory:(NSString*)origin {
    static unsigned last_resident_size=0;
    static unsigned greatest = 0;
    static unsigned last_greatest = 0;
    
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    if( kerr == KERN_SUCCESS ) {
        int diff = (int)info.resident_size - (int)last_resident_size;
        unsigned latest = info.resident_size;
        if( latest > greatest   )   greatest = latest;  // track greatest mem usage
        int greatest_diff = greatest - last_greatest;
        int latest_greatest_diff = latest - greatest;
        NSLog(@"%@: %10u (%10d) : %10d :   greatest: %10u (%d)", origin, info.resident_size, diff, latest_greatest_diff, greatest, greatest_diff);
    } else {
        NSLog(@"Error with task_info(): %s", mach_error_string(kerr));
    }
    last_resident_size = info.resident_size;
    last_greatest = greatest;
}

@end
