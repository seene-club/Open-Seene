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

@synthesize photoID;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    flickrAPI = [[FlickrAPI alloc] init];
    comments = [[NSMutableArray alloc] init];
    
    comments = [flickrAPI getComments:photoID];
    
    [self.tableView reloadData];
    
   
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
    

    
    // Bild und Beschriftung der Zelle
    cell.textLabel.text = selectedComment.commentText;
    //[cell.imageView setImage:[self getMIMETypeImage:selectedNode]];
    
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    cell.userInteractionEnabled = YES;
    cell.textLabel.enabled = YES;
    

    
    return cell;
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //[self.tableView reloadData];
}


@end
