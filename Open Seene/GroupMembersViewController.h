//
//  GroupMembersViewController.h
//  Open Seene
//
//  Created by Mathias Zettler on 11.10.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface GroupMembersViewController : UIViewController  <UITableViewDelegate, UITableViewDataSource> 

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
