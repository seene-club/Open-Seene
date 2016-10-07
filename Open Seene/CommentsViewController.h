//
//  CommentsViewController.h
//  Open Seene
//
//  Created by Mathias Zettler on 04.10.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlickrPhoto.h"

@interface CommentsViewController : UIViewController  <UITableViewDelegate, UITableViewDataSource> {
    
    FlickrPhoto *photo;

}

@property (nonatomic, retain) FlickrPhoto *photo;

//InterfaceBuilder outlets
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *postButton;
@property (weak, nonatomic) IBOutlet UIImageView *photoThumbnail;
@property (weak, nonatomic) IBOutlet UILabel *photographerLabel;
@property (weak, nonatomic) IBOutlet UILabel *photoTitleLabel;
@property (weak, nonatomic) IBOutlet UITextField *commentTextField;

@end
