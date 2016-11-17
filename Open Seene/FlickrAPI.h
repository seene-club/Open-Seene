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

static NSString *htmlViewerBaseURL = @"https://seene-shelter.github.io/viewer/#/?url=";

@interface FlickrAPI : NSObject

// API methods catalogue (original Flickr method name in the comment)
-(NSString*)uploadSeene:(NSString*)filePath withTitle:(NSString*)title withDescription:(NSString*)description isPublic:(NSString*)publicUp; //POST-Request:https://up.flickr.com/services/upload/
-(NSString*)getOriginalPhotoURL:(NSString*)photoid;                                             //flickr.photos.getSizes 
-(Boolean)updatePhotoDescription:(NSString*)photoid withDescription:(NSString*)description;     //flickr.photos.setMeta
-(Boolean)testFlickrLogin;                                                                      //flickr.test.login
-(Boolean)commentSeene:(FlickrPhoto*)photo withText:(NSString*)comment_text;                    //flickr.photos.comments.addComment
-(NSMutableArray*)getComments:(NSString*)photoid;                                               //flickr.photos.comments.getList
-(Boolean)likeSeene:(FlickrPhoto*)photo;                                                        //flickr.favorites.add
-(Boolean)removeLike:(FlickrPhoto*)photo;                                                       //flickr.favorites.remove
-(NSMutableArray*)getPublicSeenesList:(FlickrBuddy*)buddy;                                      //flickr.photosets.getPhotos
-(NSMutableArray*)getAlbumList:(NSString*)flickr_nsid;                                          //flickr.photosets.getList
-(NSMutableArray*)getGroupContactList;                                                          //flickr.groups.members.getList - members of the "Seene" group.
-(NSMutableArray*)getContactList;                                                               //flickr.contacts.getList
-(NSString*)getProfileIconURL:(NSString*)flickr_nsid;                                           //flickr.people.getInfo
-(void)exchangeMiniTokenToFullToken:(NSString*)miniToken;                                       //flickr.auth.getFullToken
-(void)resetLoginUserDefaults;                                                                  //No API call, just reset login related UserDefaults.
-(NSString*) getLastFailOrigin;                                                                 //No API call
-(NSString*) getLastFailID;                                                                     //No API call
-(NSString*) getLastFailText;                                                                   //No API call
-(void) lastFailClear;                                                                          //No API call

@end


