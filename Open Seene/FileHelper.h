//
//  FileHelper.h
//  Open Seene
//
//  Created by Mathias Zettler on 18.10.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import "FlickrBuddy.h"
#import "FlickrComment.h"
#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface FileHelper : NSObject

// Helper methods catalogue
- (NSMutableArray*)loadFollowingListFromPhone;                          //read following list from device (AppDirectory/Documents/<NSID>/following/...)
- (void)checkAndCreateDir:(NSString*)dirPath;                           //checks if a directory exists. If not it will be created.
- (NSString*)cacheUploadImage:(ALAssetRepresentation*)representation;   //persists a jpg with depthmap in users upload cache
- (Boolean)moveUploadedImage:(NSString*)imagePath;                      //move successfully uploaded Seene to this directory
- (Boolean)alreadyUploadedCheck:(NSString*)fileName;                    //checks if a Photo is already in the uploaded Seenes directory
- (void)cacheMemberOnDevice:(FlickrBuddy*)member;                       //persists a member of "Seene" group in device cache
- (void)cacheMemberFromComment:(FlickrComment*)comment;                 //persists a commentator of a Seene in device cache. Maybe not a Seenester!
- (NSString*)getCachedUsernameForNSID:(NSString*)nsid;                  //get username from cache
- (UIImage*)getCachedImageForNSID:(NSString*)nsid;                      //get user's profile image from cache
- (void)createFollowingFile:(FlickrBuddy*)person;                       //create "following" File for a person
- (void)deleteFollowingFile:(FlickrBuddy*)person;                       //remove "following" File for a person
- (void)createInitialFollowingFiles;                                    //create "following" Files for "Staff Picks" and "User Picks"


//Instance (-) custom constructor method
- (id)initFileHelper;

//Class (+) custom "convenient" constructor
+ (FileHelper*)fileHelper;

@end
