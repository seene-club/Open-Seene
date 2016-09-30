//
//  FlickrPhoto.h
//  Open Seene
//
//  Created by Mathias Zettler on 27.09.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FlickrPhoto : NSObject {
    
    NSString *photoid;
    NSString *secret;
    NSString *server;
    NSString *farm;
    NSString *title;
    NSString *dateupload;
    NSString *ownerName;
    NSString *ownerNSID;
    NSString *originalURL;
    NSString *favoritesCount;
    NSString *commentsCount;
    NSString *isFavorite;
}

//non thread-safe getter and setter will be generated.
@property (nonatomic, copy) NSString *photoid;
@property (nonatomic, copy) NSString *secret;
@property (nonatomic, copy) NSString *server;
@property (nonatomic, copy) NSString *farm;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *dateupload;
@property (nonatomic, copy) NSString *ownerName;
@property (nonatomic, copy) NSString *ownerNSID;
@property (nonatomic, copy) NSString *originalURL;
@property (nonatomic, copy) NSString *favoritesCount;
@property (nonatomic, copy) NSString *commentsCount;
@property (nonatomic, copy) NSString *isFavorite;


/* Public methods */
//Instance (-) custom constructor method
- (id)initFlickrPhotoWithID:(NSString*)sid;

//Class (+) custom "convenient" constructor
+ (FlickrPhoto*)flickrPhotoWithID:(NSString*)sid;

@end
