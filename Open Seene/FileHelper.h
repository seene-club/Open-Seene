//
//  FileHelper.h
//  Open Seene
//
//  Created by Mathias Zettler on 18.10.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import "FlickrBuddy.h"
#import <UIKit/UIKit.h>

@interface FileHelper : NSObject

// Helper methods catalogue
- (NSMutableArray*)loadFollowingListFromPhone;          //read following list from device (AppDirectory/Documents/<NSID>/following/...)
- (void)checkAndCreateDir:(NSString*)dirPath;           //checks if a directory exists. If not it will be created.
- (void)cacheMemberOnDevice:(FlickrBuddy*)member;       //persists a member of "Seene" group in device cache
- (NSString*)getCachedUsernameForNSID:(NSString*)nsid;  //get username from cache
- (UIImage*)getCachedImageForNSID:(NSString*)nsid;      //get user's profile image from cache
- (void)createFollowingFile:(FlickrBuddy*)person;       //create "following" File for a person
- (void)deleteFollowingFile:(FlickrBuddy*)person;       //remove "following" File for a person
- (void)createInitialFollowingFiles;                    //create "following" Files for "Staff Picks" and "User Picks"


//Instance (-) custom constructor method
- (id)initFileHelper;

//Class (+) custom "convenient" constructor
+ (FileHelper*)fileHelper;

@end
