//
//  FlickrBuddy.m
//  Open Seene
//
//  Created by Mathias Zettler on 23.09.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import "FlickrBuddy.h"

@implementation FlickrBuddy
@synthesize nsid, username, realname, location, pathalias, iconfarm, iconserver, public_set, private_set;


/* Instance (-) custom constructor method */
- (id)initFlickrBuddyWithID:(NSString *)uid {
    
    self = [super init]; //call to default super constructor
    
    if (self) { //check that that construction did not return a nil object.
        nsid =  [uid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];;
    }
    
    return self;
}

/* Class (+) custom "convenient" constructor */
+ (FlickrBuddy*)flickrBuddyWithID:(NSString*)uid {
    return [[self alloc] initFlickrBuddyWithID:uid];
}

@end

