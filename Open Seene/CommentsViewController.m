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

@interface CommentsViewController () {
    
    FlickrAPI *flickrAPI;
    NSMutableArray *comments;
}

@end


@implementation CommentsViewController

@synthesize photoID, thumbnailURL, photographerName, phototitle;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    flickrAPI = [[FlickrAPI alloc] init];
    
    
    NSURL *url = [NSURL URLWithString:thumbnailURL];
    NSData *data = [NSData dataWithContentsOfURL : url];
    
    [_photoThumbnail setImage:[UIImage imageWithData: data]];
    [_photographerLabel setText:photographerName];
    [_photoTitleLabel setText:phototitle];
    
    comments = [[NSMutableArray alloc] init];
    
    comments = [flickrAPI getComments:photoID];
    
    [self.tableView reloadData];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
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
    
    NSString *iconUrl = [NSString stringWithFormat:@"https://farm%@.staticflickr.com/%@/buddyicons/%@.jpg",
                         selectedComment.iconfarm, selectedComment.iconserver, selectedComment.authorNSID];
    
    NSURL *url = [NSURL URLWithString:iconUrl];
    NSData *data = [NSData dataWithContentsOfURL : url];

    
    // Label and Image of the cell
    cell.textLabel.text = selectedComment.commentText;
    [cell.imageView setImage:[UIImage imageWithData: data]];
    
    //cell.accessoryType = UITableViewCellAccessoryCheckmark;
    //cell.userInteractionEnabled = YES;
    cell.textLabel.enabled = YES;
    

    
    return cell;
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //[self.tableView reloadData];
}


@end
