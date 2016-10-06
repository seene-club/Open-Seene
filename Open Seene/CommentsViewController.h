//
//  CommentsViewController.h
//  Open Seene
//
//  Created by Mathias Zettler on 04.10.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CommentsViewController : UIViewController  <UITableViewDelegate, UITableViewDataSource> {
    NSString* photoID;
    NSString* thumbnailURL;
    NSString* photographerName;
    NSString* phototitle;
}

@property (nonatomic, retain) NSString* photoID;
@property (nonatomic, retain) NSString* thumbnailURL;
@property (nonatomic, retain) NSString* photographerName;
@property (nonatomic, retain) NSString* phototitle;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *postButton;
@property (weak, nonatomic) IBOutlet UIImageView *photoThumbnail;
@property (weak, nonatomic) IBOutlet UILabel *photographerLabel;
@property (weak, nonatomic) IBOutlet UILabel *photoTitleLabel;

@end
