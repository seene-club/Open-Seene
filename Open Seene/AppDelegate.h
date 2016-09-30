//
//  AppDelegate.h
//  Open Seene
//
//  Created by Mathias Zettler on 12.09.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    NSMutableArray *buddyList;
}

- (void)updateProfileContacts;

@property (nonatomic, retain) NSMutableArray *buddyList;
@property (strong, nonatomic) UIWindow *window;


@end

