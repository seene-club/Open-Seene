//
//  Helper.m
//  Open Seene
//
//  Created by Mathias Zettler on 18.10.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileHelper.h"
#import "FlickrAlbum.h"
#import "FlickrBuddy.h"

@interface FileHelper () {
    
    NSString *personalDir;
    NSString *followingDir;
    NSFileManager *fileManager;
}
@end

@implementation FileHelper

/* Instance (-) custom constructor method */
- (id)initFileHelper {
    
    self = [super init]; //call to default super constructor
    
    if (self) { //check that that construction did not return a nil object.
        fileManager = [NSFileManager new];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        [self checkAndCreateDir:documentsDirectory];
        NSString *flickr_nsid = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrNSID"];
        personalDir = [documentsDirectory stringByAppendingPathComponent:flickr_nsid];
        followingDir = [personalDir stringByAppendingPathComponent:@"following"];
        [self checkAndCreateDir:personalDir];
        [self checkAndCreateDir:followingDir];
    }
    
    return self;
}

/* Class (+) custom "convenient" constructor */
+ (FileHelper*)fileHelper {
    return [[self alloc] initFileHelper];
}

// Read following list from device (AppDirectory/Documents/<NSID>/following/...)
- (NSMutableArray*)loadFollowingListFromPhone {
    NSMutableArray *personList;
    NSString *item;
    NSError *error;
    
    personList = [[NSMutableArray alloc] init];
    
    NSLog(@"DEBUG: following DIR: %@", followingDir);
    
    int ndx = 0;
    NSArray *directoryContent = [fileManager contentsOfDirectoryAtPath:followingDir error:NULL];
    for (item in directoryContent){
        
        NSString *followingFile = [followingDir stringByAppendingPathComponent:item];
        NSString *followingFileData = [NSString stringWithContentsOfFile:followingFile encoding:NSUTF8StringEncoding error:&error];
        
        ndx++;
        NSLog(@"DEBUG: following file: %i. %@ - content: %@", ndx, item, followingFileData);
        
        FlickrBuddy *aPerson = [FlickrBuddy flickrBuddyWithID:(NSString *) item];
        aPerson.username = [[followingFileData componentsSeparatedByString:@"{#}"] objectAtIndex:1];
        aPerson.realname = [[followingFileData componentsSeparatedByString:@"{#}"] objectAtIndex:2];
        
        FlickrAlbum *thePublicAlbum = [FlickrAlbum flickrAlbumWithID:(NSString *)[[followingFileData componentsSeparatedByString:@"{#}"] objectAtIndex:0]];
        thePublicAlbum.settype = 1;
        aPerson.public_set = thePublicAlbum;
        
        [personList addObject:aPerson];
        
    }
    
    return personList;
}

//create "following" File for a person
- (void)createFollowingFile:(FlickrBuddy*)person {
    FlickrAlbum *publicset = person.public_set;
    if (publicset) {
        NSString *followingFileName = person.nsid;
        NSString *followingFile = [followingDir stringByAppendingPathComponent:followingFileName];
        NSString *persistenceString = [NSString stringWithFormat:@"%@{#}%@{#}%@",publicset.setid, person.username, person.realname];
        NSLog(@"writing file: %@ with content: %@ (Public Seenes Album ID)", followingFile, persistenceString);
        [[persistenceString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:followingFile atomically:YES];
    }
}

- (void)createInitialFollowingFiles {
        // Add Album "public seenes" of the "Staff Picks" Flickr Account to following list
        [[@"72157671955461494{#}Seene: Staff Picks{#}Staff Picks Seene" dataUsingEncoding:NSUTF8StringEncoding]
            writeToFile:[followingDir stringByAppendingPathComponent:@"146378156@N07"] atomically:YES];
   
        // Add Album "public seenes" of the "User Picks" Flickr Account to following list
        [[@"72157675498674745{#}Seene: User Picks{#}User Picks Seene" dataUsingEncoding:NSUTF8StringEncoding]
            writeToFile:[followingDir stringByAppendingPathComponent:@"143161055@N06"] atomically:YES];
}

//remove "following" File for a person
- (void)deleteFollowingFile:(FlickrBuddy*)person {
    NSString *followingFileName = person.nsid;
    NSString *fileToDelete = [followingDir stringByAppendingPathComponent:followingFileName];
    NSError *err;
    [fileManager removeItemAtPath:fileToDelete error:&err];

}

//checks if a directory exists. If not it will be created.
- (void)checkAndCreateDir:(NSString*)dirPath {
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath])
    {
        NSLog(@"Creating Directory: %@",dirPath);
        if (![[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:NO attributes:nil error:&error])
        {
            NSLog(@"Create directory error: %@", error);
        }
    }
}

@end