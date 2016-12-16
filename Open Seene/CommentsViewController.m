//
//  CommentsViewController.m
//  Open Seene
//
//  Created by Mathias Zettler on 04.10.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommentsViewController.h"
#import "FlickrAPI.h"
#import "FlickrComment.h"
#import "FileHelper.h"

@interface CommentsViewController () {
    
    FlickrAPI *flickrAPI;
    FileHelper *fileHelper;
    NSMutableArray *comments;
}

@end

//TODO
//Use FileHelper to read usernames from cache.
//Format Comments.


@implementation CommentsViewController

@synthesize photo;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    flickrAPI = [[FlickrAPI alloc] init];
    fileHelper = [[FileHelper alloc] initFileHelper];
    
    NSURL *url = [NSURL URLWithString:photo.thumbnailURL];
    NSData *data = [NSData dataWithContentsOfURL : url];
    
    [_photoThumbnail setImage:[UIImage imageWithData: data]];
    [_photographerLabel setText:[NSString stringWithFormat:@"@%@",photo.ownerName]];
    [_photoTitleLabel setText:photo.title];
    
    comments = [[NSMutableArray alloc] init];
    comments = [flickrAPI getComments:photo.photoid];
    [self.tableView reloadData];
    [self.tableView setBackgroundColor:[UIColor darkGrayColor]];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (NSString*)replaceMentions:(NSString*)cmnt {
    
    int ndx;
    for (ndx = 0; ndx < comments.count; ndx++) {
        FlickrComment *comment = [comments objectAtIndex:ndx];
        
        cmnt = [cmnt stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"@{%@}", comment.authorname]
                                                    withString:[NSString stringWithFormat:@"[https://www.flickr.com/photos/%@/]", comment.authorNSID]];
    }
    
    return cmnt;
    
}

- (IBAction)postButtonPushed:(id)sender {
    
    if ([_commentTextView.text length] > 0) {
        
        _commentTextView.text = [self replaceMentions:_commentTextView.text];
        
        if ([flickrAPI commentSeene:photo withText:_commentTextView.text]) {
            _commentTextView.text = @"";
            comments = [flickrAPI getComments:photo.photoid];
            [self.tableView reloadData];
        } else {
            NSString *errMsg = [NSString stringWithFormat:@"%@\nError Code: %@\n%@",flickrAPI.getLastFailOrigin,flickrAPI.getLastFailID,flickrAPI.getLastFailText];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Posting comment failed!"
                                                            message:errMsg
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            [flickrAPI lastFailClear];
        }
    }
}

- (IBAction)closeButtonPushed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    FlickrComment *selectedComment = [comments objectAtIndex:indexPath.item];
    
    NSLog(@"comment id: %@", selectedComment.commentid);
    NSLog(@"comment text: %@", selectedComment.commentText);
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [comments count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"CommentEntryCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    FlickrComment *selectedComment = [comments objectAtIndex:indexPath.row];
    
    cell.textLabel.font = [UIFont systemFontOfSize:12.0];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.textColor = [UIColor whiteColor];
    [cell setBackgroundColor:[UIColor darkGrayColor]];
    
    // Label and Image of the cell
    cell.textLabel.text = [self commentFormatter:selectedComment.commentText];
    UIImage *cachedImage = [fileHelper getCachedImageForNSID:selectedComment.authorNSID];
    if (cachedImage == nil) { // retrieving image for non-cached people
        [fileHelper cacheMemberFromComment:selectedComment];
        cachedImage = [fileHelper getCachedImageForNSID:selectedComment.authorNSID];
    }
    [cell.imageView setImage:cachedImage];
    
    // Round images
    cell.imageView.layer.cornerRadius = cell.imageView.frame.size.width / 2;
    cell.imageView.clipsToBounds = YES;
    
    //cell.accessoryType = UITableViewCellAccessoryCheckmark;
    //cell.userInteractionEnabled = YES;
    cell.textLabel.enabled = YES;

    
    return cell;
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    //automatic reload since iOS 7!
    //[self.tableView reloadData];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewRowAction *editAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"reply" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        FlickrComment *selectedComment = [comments objectAtIndex:indexPath.row];
        
        NSLog(@"reply for: %@", selectedComment.authorname);
        _commentTextView.text = [NSString stringWithFormat:@"%@ @{%@}", _commentTextView.text, selectedComment.authorname];
        tableView.editing = NO;

    }];
    editAction.backgroundColor = [UIColor lightGrayColor];
    
    
    return @[editAction];
}

- (NSString*)commentFormatter:(NSString*)cmnt {
    
    NSString *fcmnt = [cmnt stringByReplacingOccurrencesOfString:@"&quot;" withString: @"\""];
    // to be continued ...
    
    // replace all occurrences of [https://www.flickr.com/photos/<NSID>] by @username
    fcmnt = [self commentUsernameGrabber:fcmnt];
    fcmnt = [self commentFormatURLs:fcmnt];
    
    NSLog(@"Formatted Comment: %@", fcmnt);
                       
    return fcmnt;
}

- (NSString*)commentFormatURLs:(NSString*)cmnt {
    NSLog(@"DEBUG: commentFormatURLs - INPUT: %@",cmnt);
    NSString *pattern = @"(?i)<a([^>]+)>(.+?)</a>";
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:pattern
                                  options:NSRegularExpressionCaseInsensitive error:&error];
    if(error != nil){
        NSLog(@"Error with RegExp: %@",error);
    } else{
        NSString *replaced = [regex stringByReplacingMatchesInString:cmnt
                                                             options:0
                                                               range:NSMakeRange(0, [cmnt length])
                                                        withTemplate:[NSString stringWithFormat:@"%@", @"http://$2"]];
        
        NSLog(@"Replaced URL OUTPUT: %@",replaced);
        return replaced;
    }
    
    return cmnt;
}

// what we can do in future release: https://github.com/TTTAttributedLabel/TTTAttributedLabel
- (NSString*)commentUsernameGrabber:(NSString*)cmnt {
    NSLog(@"DEBUG: commentUsernameGrabber - INPUT: %@", cmnt);
    
    NSString *fcmnt;
    
    // Looking for [...] and extract a substring
    NSRange r1 = [cmnt rangeOfString:@"["];
    NSRange r2 = [cmnt rangeOfString:@"]"];
    
    if ((r1.location == NSNotFound) || (r2.location == NSNotFound)) return cmnt;
    
    NSRange rSub = NSMakeRange(r1.location + r1.length, r2.location - r1.location - r1.length);
    NSString *sub = [cmnt substringWithRange:rSub];
    
    // some mentions come along with http:// some with https://
    sub  = [sub  stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
    cmnt = [cmnt stringByReplacingOccurrencesOfString:@"[http://" withString:@"[https://"];
    NSLog(@"mention - sub: %@", sub);
    
    // Looking for the NSID in substring ("https://www.flickr.com/photos/<NSID>")
    NSString *cmprUser = @"https://www.flickr.com/photos/";
    
    if ([sub length] > [cmprUser length]) {
        NSRange range = [sub rangeOfString:cmprUser];
        if (range.location != NSNotFound) {
            // Extracting NSID
            NSRange rUserNSID = NSMakeRange(range.location + range.length, [sub length] - range.location - range.length);
            NSString *nsid = [sub substringWithRange:rUserNSID];
            NSLog(@"NSID: %@", nsid);
            // grab username from Cache and remove trailing "/" (somethimes there, sometimes not)
            NSString *username = [NSString stringWithFormat:@"@%@",[fileHelper getCachedUsernameForNSID:[nsid stringByReplacingOccurrencesOfString:@"/" withString:@"" ]]];
            NSLog(@"Username: %@", username);
            
            NSString *userRep = [NSString stringWithFormat:@"[%@%@]",cmprUser, nsid];
            // call "commentFormatter" recursively to replace other occurences
            NSLog(@"DEBUG: commentUsernameGrabber - recursive call!!!");
            fcmnt = [self commentUsernameGrabber:[cmnt stringByReplacingOccurrencesOfString:userRep withString:username]];
        }
    }

    NSLog(@"DEBUG: commentUsernameGrabber - formatted OUTPUT: %@", fcmnt);
    if (fcmnt == nil) return @"";
    return fcmnt;
}


@end
