//
//  FlickrPhoto.m
//  Open Seene
//
//  Created by Mathias Zettler on 27.09.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import "FlickrPhoto.h"

@implementation FlickrPhoto
@synthesize photoid, secret, server, farm, title, dateupload, ownerName, ownerNSID, originalURL,thumbnailURL, favoritesCount, commentsCount, isFavorite;


/* Instance (-) custom constructor method */
- (id)initFlickrPhotoWithID:(NSString *)pid {
    
    self = [super init]; //call to default super constructor
    
    if (self) { //check that that construction did not return a nil object.
        photoid =  [pid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];;
    }
    
    return self;
}

/* Class (+) custom "convenient" constructor */
+ (FlickrPhoto*)flickrPhotoWithID:(NSString*)pid {
    return [[self alloc] initFlickrPhotoWithID:pid];
}

@end