//
//  FlickrAPI.h
//  Open Seene
//
//  Created by Mathias Zettler on 22.09.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import "FlickrBuddy.h"
#import "FlickrPhoto.h"
#import "FlickrAPI_keys.h"

@interface FlickrAPI : NSObject

// API methods catalogue
-(NSMutableArray*)getComments:(NSString*)photoid;            //flickr.photos.comments.getList
-(Boolean)likeSeene:(FlickrPhoto*)photo;                     //flickr.favorites.add
-(Boolean)removeLike:(FlickrPhoto*)photo;                    //flickr.favorites.remove
-(NSMutableArray*)getPublicSeenesList:(FlickrBuddy*)buddy;   //flickr.photosets.getPhotos
-(NSMutableArray*)getAlbumList:(NSString*)flickr_nsid;       //flickr.photosets.getList
-(NSMutableArray*)getContactList;                            //flickr.contacts.getList
-(NSString*)getProfileIconURL:(NSString*)flickr_nsid;        //flickr.people.getInfo
-(void)exchangeMiniTokenToFullToken:(NSString*)miniToken;    //flickr.auth.getFullToken

@end


