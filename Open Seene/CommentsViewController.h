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
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) NSString* photoID;

@end
