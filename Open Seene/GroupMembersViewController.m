//
//  GroupMembersViewController.m
//  Open Seene
//
//  Created by Mathias Zettler on 11.10.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GroupMembersViewController.h"
#import "FlickrAPI.h"
#import "FlickrBuddy.h"

@interface GroupMembersViewController () {
    
    FlickrAPI *flickrAPI;
    BOOL scanComplete;
    NSString *personalDir;
    NSString *followingDir;
    NSFileManager *fileManager;
    NSMutableArray *memberList;
    NSMutableArray *followingList;
}

@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@end


@implementation GroupMembersViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    scanComplete = NO;
    fileManager = [NSFileManager new];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    [self checkAndCreateDir:documentsDirectory];
    NSString *flickr_nsid = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrNSID"];
    personalDir = [documentsDirectory stringByAppendingPathComponent:flickr_nsid];
    followingDir = [personalDir stringByAppendingPathComponent:@"following"];
    [self checkAndCreateDir:personalDir];
    [self checkAndCreateDir:followingDir];
    
    flickrAPI = [[FlickrAPI alloc] init];
    
    // Call API for FlickrGroup "Seene" Members
    memberList = [[NSMutableArray alloc] init];
    memberList = [flickrAPI getGroupContactList];
    followingList = [self loadFollowingListFromPhone];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


// Read following list from device (AppDirectory/Documents/<NSID>/following/...)
- (NSMutableArray*)loadFollowingListFromPhone {
    NSMutableArray *personList;
    NSString *item;
    NSError *error;
    
    personList = [[NSMutableArray alloc] init];
    
       NSArray *directoryContent = [fileManager contentsOfDirectoryAtPath:followingDir error:NULL];
    for (item in directoryContent){
     
        NSString *followingFile = [followingDir stringByAppendingPathComponent:item];
        NSString *followingFileData = [NSString stringWithContentsOfFile:followingFile encoding:NSUTF8StringEncoding error:&error];
        
        NSLog(@"file: %@ - content: %@", item, followingFileData);
        
        FlickrBuddy *aPerson = [FlickrBuddy flickrBuddyWithID:(NSString *) item];
        FlickrAlbum *thePublicAlbum = [FlickrAlbum flickrAlbumWithID:(NSString *)followingFileData];
        thePublicAlbum.settype = 1;
        aPerson.public_set = thePublicAlbum;
        
        [personList addObject:aPerson];
   
    }
    
    return personList;
}

- (void)viewDidAppear:(BOOL)animated {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
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
    }
    
    scanComplete = YES;
    [self.tableView reloadData];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;


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
    
    
    NSString *iconUrl = [NSString stringWithFormat:@"https://farm%@.staticflickr.com/%@/buddyicons/%@.jpg",
                                 selectedMember.iconfarm, selectedMember.iconserver, selectedMember.nsid];
    
    
    NSURL *url;
    if ([iconUrl rangeOfString:@"farm0."].location == NSNotFound) {
       url = [NSURL URLWithString:iconUrl];
    } else {
       url = [NSURL URLWithString:@"https://www.flickr.com/images/buddyicon.gif"];
    }
    
    NSData *data = [NSData dataWithContentsOfURL : url];
    
    NSString *canFollowString = @"scanning...";
    if (scanComplete) {
        if (selectedMember.public_set == nil) {
            canFollowString = @"No Album \"Public Seenes\" found for this user.";
        } else {
            canFollowString = @"\"Public Seenes\" Album available!";
            
            BOOL checked =  false;
            selectedMember.following = 0;
            int ndx;
            for (ndx = 0; ndx < followingList.count; ndx++) {
                FlickrBuddy *aPerson = [followingList objectAtIndex:ndx];
                if ([aPerson.nsid caseInsensitiveCompare:selectedMember.nsid] == NSOrderedSame) {
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
    [cell.imageView setImage:[UIImage imageWithData: data]];
    
    //cell.accessoryType = UITableViewCellAccessoryCheckmark;
    //cell.userInteractionEnabled = YES;
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
        FlickrBuddy *followingMember = [memberList objectAtIndex:indexPath.item];
        // perform follow or unfollow?
        if (followingMember.following == 0) {
            [self writeFollowingFile:followingMember];
            [self tableView: self.tableView didSelectRowAtIndexPath: indexPath];
        } else {
            NSString *followingFileName = followingMember.nsid;
            NSString *fileToDelete = [followingDir stringByAppendingPathComponent:followingFileName];
            NSError *err;
            [fileManager removeItemAtPath:fileToDelete error:&err];
        }
        UIImage *newImage;
        
        // change visible state
        BOOL checked =  (followingMember.following==0) ? NO : YES;
        if (checked) {
            followingMember.following=0;
            newImage = [UIImage imageNamed:@"unchecked.png"];
        } else {
            followingMember.following=1;
            newImage = [UIImage imageNamed:@"checked.png"];
        }
        
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        UIButton *button = (UIButton *)cell.accessoryView;
        [button setBackgroundImage:newImage forState:UIControlStateNormal];
    }
}

//create "following" File
- (void)writeFollowingFile:(FlickrBuddy*)person {
    FlickrAlbum *publicset = person.public_set;
    if (publicset) {
        NSString *followingFileName = person.nsid;
        NSString *followingFile = [followingDir stringByAppendingPathComponent:followingFileName];
        NSLog(@"writing file: %@ with content: %@ (Public Seenes Album ID)", followingFile, publicset.setid);
        [[publicset.setid dataUsingEncoding:NSUTF8StringEncoding] writeToFile:followingFile atomically:YES];
    }
}

- (IBAction)closeButtonPushed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)checkAndCreateDir:(NSString*)dirPath {
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath])
    {
        NSLog(@"Creating Directory: %@",dirPath);
        if (![[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:NO attributes:nil error:&error])
        {
            NSLog(@"Create directory error: %@", error);
        }
    }
}



@end
