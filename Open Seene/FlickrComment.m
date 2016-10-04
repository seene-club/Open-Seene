//
//  FlickrComment.m
//  Open Seene
//
//  Created by Mathias Zettler on 04.10.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import "FlickrComment.h"

@implementation FlickrComment
@synthesize commentid, authorNSID, author_is_deleted, authorname, iconfarm, iconserver, dateCreate, commentText;

/* Instance (-) custom constructor method */
- (id)initFlickrCommentWithID:(NSString *)cid {
    
    self = [super init]; //call to default super constructor
    
    if (self) { //check that that construction did not return a nil object.
        commentid =  [cid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];;
    }
    
    return self;
}

/* Class (+) custom "convenient" constructor */
+ (FlickrComment*)flickrCommentWithID:(NSString*)cid {
    return [[self alloc] initFlickrCommentWithID:cid];
}

@end
