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

@synthesize photo;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    flickrAPI = [[FlickrAPI alloc] init];
    
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

- (IBAction)postButtonPushed:(id)sender {
    
    if ([_commentTextField.text length] > 0) {
        
        if ([flickrAPI commentSeene:photo withText:_commentTextField.text]) {
            _commentTextField.text = @"";
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
    [cell setBackgroundColor:[UIColor darkGrayColor]];
    
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
