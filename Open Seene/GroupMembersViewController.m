//
//  GroupMembersViewController.m
//  Open Seene
//
//  Created by Mathias Zettler on 11.10.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "SVProgressHUD.h"
#import "GroupMembersViewController.h"
#import "FlickrAPI.h"
#import "FlickrBuddy.h"
#import "FileHelper.h"

@interface GroupMembersViewController () {
    
    FlickrAPI *flickrAPI;
    FileHelper *fileHelper;
    BOOL scanComplete;
    NSMutableArray *memberList;
    NSMutableArray *followingList;
}

@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@end


@implementation GroupMembersViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.tableView setHidden:YES];
    scanComplete = NO;
    
    fileHelper = [[FileHelper alloc] initFileHelper];
    flickrAPI = [[FlickrAPI alloc] init];
    memberList = [[NSMutableArray alloc] init];
    followingList = [[NSMutableArray alloc] init];
    
    // Load Following List from Device
    followingList = [fileHelper loadFollowingListFromPhone];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [SVProgressHUD showWithStatus:@"contacting Flickr"];
    // 1. Load all members from the "Seene" group
    memberList = [flickrAPI getGroupContactList];
    
    // 2. Looking for "Public Seenes" Album for every single member
    [self performSelectorInBackground:@selector(scanForPublicSeenesInBackgroundProcess) withObject:nil];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

// Looking for album "public seenes" for every member of the "Seene" group (Background Thread)
- (void)scanForPublicSeenesInBackgroundProcess
{
    [self performSelectorOnMainThread:@selector(setScanProgress:) withObject:[NSNumber numberWithFloat:0.0] waitUntilDone:NO];
    int ndx;
    for (ndx = 0; ndx < memberList.count; ndx++) {
        FlickrBuddy *member = [memberList objectAtIndex:ndx];
        NSLog(@"Member: %@", member.username);
        NSMutableArray *albumList = [[NSMutableArray alloc] init];
        // Call API for Member's Albums (extracting "Public Seenes" only this time).
        albumList = [flickrAPI getAlbumList:member.nsid];
        int adx;
        for (adx = 0; adx < albumList.count; adx++) {
            FlickrAlbum *album = [albumList objectAtIndex:adx];
            if (album.settype == 1) member.public_set = album;
        }
        float progress = (float)ndx / (float)memberList.count;
        NSLog(@"progress: %f", progress);
        [self performSelectorOnMainThread:@selector(setScanProgress:) withObject:[NSNumber numberWithFloat:progress] waitUntilDone:NO];
    }
    [self performSelectorOnMainThread:@selector(setScanProgress:) withObject:[NSNumber numberWithFloat:1.0] waitUntilDone:NO];
}

// Update ProgressBar on (UI)MainThread
- (void)setScanProgress:(NSNumber *)number {
    [SVProgressHUD showProgress:number.floatValue status:@"Loading from Flickr"];
    if (number.floatValue == 1.0) {
        [SVProgressHUD dismiss];
        scanComplete = YES;
        [self.tableView reloadData];
        [self.tableView setHidden:NO];
        [self.tableView setBackgroundColor:[UIColor darkGrayColor]];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FlickrBuddy *selectedMember = [memberList objectAtIndex:indexPath.item];
    
    NSLog(@"member id: %@", selectedMember.nsid);
    NSLog(@"member username: %@", selectedMember.username);
    NSLog(@"icon info: %@ - %@", selectedMember.iconfarm, selectedMember.iconserver);
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [memberList count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"MemberEntryCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    FlickrBuddy *selectedMember = [memberList objectAtIndex:indexPath.row];
    
    // special cell properties
    cell.textLabel.font = [UIFont systemFontOfSize:12.0];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.textColor = [UIColor whiteColor];
    [cell setBackgroundColor:[UIColor darkGrayColor]];
    
    NSString *canFollowString = @"scanning...";
    if (scanComplete) {
        if (selectedMember.public_set == nil) {
            canFollowString = @"No Album \"Public Seenes\" found for this user.";
            
            UIImage *image = [UIImage imageNamed:@"fail.png"];
            
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            CGRect frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
            button.frame = frame;   // match the button's size with the image size
            button.tag = indexPath.row;
            [button setBackgroundImage:image forState:UIControlStateNormal];
            
            cell.accessoryView = button;
            
        } else {
            canFollowString = @"\"Public Seenes\" Album available!";
            
            BOOL checked =  false;
            selectedMember.following = 0;
            int ndx;
            // TODO: Speed up
            for (ndx = 0; ndx < followingList.count; ndx++) {
                FlickrBuddy *aPerson = [followingList objectAtIndex:ndx];
                if ([aPerson.nsid caseInsensitiveCompare:selectedMember.nsid] == NSOrderedSame) {
                    NSLog(@"DEBUG: NSID match! %@", selectedMember.nsid);
                    checked = true;
                    selectedMember.following = 1;
                }
            }
            
            UIImage *image = (checked) ? [UIImage imageNamed:@"checked.png"] : [UIImage imageNamed:@"unchecked.png"];
            
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            CGRect frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
            button.frame = frame;   // match the button's size with the image size
            button.tag = indexPath.row;
            [button setBackgroundImage:image forState:UIControlStateNormal];
            
            // set the button's target to this table view controller so we can interpret touch events and map that to a NSIndexSet
            [button addTarget:self action:@selector(checkButton_click:event:) forControlEvents:UIControlEventTouchUpInside];
            
            cell.accessoryView = button;
        }
    }
    
    // Label and Image of the cell
    cell.textLabel.text = [NSString stringWithFormat:@"@%@\n%@\n%@" , selectedMember.username, selectedMember.realname, canFollowString];
    [cell.imageView setImage:[fileHelper getCachedImageForNSID:selectedMember.nsid]];
    
    // Round images
    cell.imageView.layer.cornerRadius = cell.imageView.frame.size.width / 2;
    cell.imageView.clipsToBounds = YES;

    cell.textLabel.enabled = YES;
    
    return cell;
}

// click on "follow"
- (void)checkButton_click:(id)sender event:(id)event
{
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint: currentTouchPosition];
    if (indexPath != nil)
    {
        FlickrBuddy *selectedMember = [memberList objectAtIndex:indexPath.item];
        // perform follow or unfollow?
        if (selectedMember.following == 0) {
            [fileHelper createFollowingFile:selectedMember];
            [self tableView: self.tableView didSelectRowAtIndexPath: indexPath];
        } else {
            [fileHelper deleteFollowingFile:selectedMember];
        }

        UIImage *newImage;
        
        // change visible state
        BOOL checked =  (selectedMember.following==0) ? NO : YES;
        if (checked) {
            selectedMember.following = 0;
            newImage = [UIImage imageNamed:@"unchecked.png"];
        } else {
            selectedMember.following = 1;
            newImage = [UIImage imageNamed:@"checked.png"];
        }
        
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        UIButton *button = (UIButton *)cell.accessoryView;
        [button setBackgroundImage:newImage forState:UIControlStateNormal];
    }
    
    followingList = [fileHelper loadFollowingListFromPhone];
}


- (IBAction)closeButtonPushed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
