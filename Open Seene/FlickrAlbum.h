//
//  FlickrAlbum.h
//  Open Seene
//
//  Created by Mathias Zettler on 23.09.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FlickrAlbum : NSObject {

    NSString *setid;
    NSString *primary_photo;
    NSString *secret;
    NSString *server;
    NSString *farm;
    NSString *photo_count;
    NSString *title;
    NSString *description;
    int settype;            // 1 = public, 2 = private, 3 = seene set
}

//non thread-safe getter and setter will be generated.
@property (nonatomic, copy) NSString *setid;
@property (nonatomic, copy) NSString *primary_photo;
@property (nonatomic, copy) NSString *secret;
@property (nonatomic, copy) NSString *server;
@property (nonatomic, copy) NSString *farm;
@property (nonatomic, copy) NSString *photo_count;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *description;
@property (nonatomic, assign) int settype;


/* Public methods */
//Instance (-) custom constructor method
- (id)initFlickrAlbumWithID:(NSString*)sid;

//Class (+) custom "convenient" constructor
+ (FlickrAlbum*)flickrAlbumWithID:(NSString*)sid;

@end

