//
//  Helper.h
//  Open Seene
//
//  Created by Mathias Zettler on 18.10.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import "FlickrBuddy.h"

@interface FileHelper : NSObject

// Helper methods catalogue
- (NSMutableArray*)loadFollowingListFromPhone;      //read following list from device (AppDirectory/Documents/<NSID>/following/...)
- (void)checkAndCreateDir:(NSString*)dirPath;       //checks if a directory exists. If not it will be created.
- (void)createFollowingFile:(FlickrBuddy*)person;   //create "following" File for a person
- (void)deleteFollowingFile:(FlickrBuddy*)person;   //remove "following" File for a person


//Instance (-) custom constructor method
- (id)initFileHelper;

//Class (+) custom "convenient" constructor
+ (FileHelper*)fileHelper;

@end