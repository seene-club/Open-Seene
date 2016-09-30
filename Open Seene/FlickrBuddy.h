//
//  FlickrBuddy.h
//  Open Seene
//
//  Created by Mathias Zettler on 23.09.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlickrAlbum.h"

@interface FlickrBuddy : NSObject {
    NSString *nsid;
    NSString *username;
    NSString *realname;
    NSString *location;
    NSString *pathalias;
    NSString *iconfarm;
    NSString *iconserver;
    FlickrAlbum *public_set;
    FlickrAlbum *private_set;
}

//non thread-safe getter and setter will be generated.
@property (nonatomic, copy) NSString *nsid;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *realname;
@property (nonatomic, copy) NSString *location;
@property (nonatomic, copy) NSString *pathalias;
@property (nonatomic, copy) NSString *iconfarm;
@property (nonatomic, copy) NSString *iconserver;
@property (nonatomic, retain) FlickrAlbum *public_set;
@property (nonatomic, retain) FlickrAlbum *private_set;


/* Public methods */
//Instance (-) custom constructor method
- (id)initFlickrBuddyWithID:(NSString*)uid;

//Class (+) custom "convenient" constructor
+ (FlickrBuddy*)flickrBuddyWithID:(NSString*)uid;

@end
