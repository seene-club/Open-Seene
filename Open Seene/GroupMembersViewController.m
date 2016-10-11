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
    NSMutableArray *memberList;
}

@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@end


@implementation GroupMembersViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    flickrAPI = [[FlickrAPI alloc] init];
    
    // Call API for FlickrGroup "Seene" Members
    memberList = [[NSMutableArray alloc] init];
    memberList = [flickrAPI getGroupContactList];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
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
    }
    
    FlickrBuddy *selectedMember = [memberList objectAtIndex:indexPath.row];
    
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
    
    
    // Label and Image of the cell
    cell.textLabel.text = selectedMember.username;
    [cell.imageView setImage:[UIImage imageWithData: data]];
    
    //cell.accessoryType = UITableViewCellAccessoryCheckmark;
    //cell.userInteractionEnabled = YES;
    cell.textLabel.enabled = YES;
    
    
    return cell;
}

- (IBAction)closeButtonPushed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}



@end
