//
//  FlickrAlbum.m
//  Open Seene
//
//  Created by Mathias Zettler on 23.09.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import "FlickrAlbum.h"

@implementation FlickrAlbum
@synthesize setid, primary_photo, secret, server, farm, photo_count, title, description, settype;


/* Instance (-) custom constructor method */
- (id)initFlickrAlbumWithID:(NSString *)sid {
    
    self = [super init]; //call to default super constructor
    
    if (self) { //check that that construction did not return a nil object.
        setid =  [sid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];;
    }
    
    return self;
}

/* Class (+) custom "convenient" constructor */
+ (FlickrAlbum*)flickrAlbumWithID:(NSString*)sid {
    return [[self alloc] initFlickrAlbumWithID:sid];
}

@end