//
//  FlickrAPI.m
//  Open Seene
//
//  Created by Mathias Zettler on 22.09.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlickrAPI.h"
#import "FlickrBuddy.h"
#import "FlickrAlbum.h"
#import "FlickrPhoto.h"
#import "SBJson.h"
#import "NSString+MD5.h"

@implementation FlickrAPI

//flickr.favorites.add
-(void)likeSeene:(FlickrPhoto*)photo {
    
    NSString *flrMethod = @"flickr.favorites.add";
    //TODO
}

//flickr.photosets.getPhotos
-(NSMutableArray*)getPublicSeenesList:(FlickrBuddy*)buddy {
    
    NSString *flrMethod = @"flickr.photosets.getPhotos";
    NSString *flrExtras = @"date_upload,url_o,count_comments,count_faves,isfavorite";               // ! some of them are not documented on official Flickr API !
    
    NSString *flickr_token = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrToken"];
    
    NSString *flickr_nsid = buddy.nsid;
    NSString *publicset_id = buddy.public_set.setid;
    
    NSString *flrSigStr = [NSString stringWithFormat:@"%@api_key%@auth_token%@extras%@format%smethod%@nojsoncallback%sphotoset_id%@privacy_filter%suser_id%@", flrSecret, flrAPIKey, flickr_token, flrExtras, "json", flrMethod, "1", publicset_id, "1", flickr_nsid];
    NSLog(@"FlickrAPI Signature String: %@", flrSigStr);
    NSLog(@"FlickrAPI Signature MD5: %@", flrSigStr.MD5);
    
    NSString *urlString = [NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=%@&user_id=%@&photoset_id=%@&privacy_filter=1&extras=%@&api_key=%@&auth_token=%@&api_sig=%@&format=json&nojsoncallback=1", flrMethod, flickr_nsid, publicset_id, flrExtras, flrAPIKey, flickr_token, flrSigStr.MD5 ];
    NSLog(@"FlickrAPI %@ URL: %@", flrMethod, urlString);
    NSURL *url = [NSURL URLWithString:urlString];
    
    // 2. Get URLResponse string & parse JSON to Foundation objects.
    
    NSString *connectionResponse = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    
    SBJsonParser *jsonParser = [SBJsonParser new];
    id jsonResponse = [jsonParser objectWithString:connectionResponse];
    NSDictionary *results = (NSDictionary *)jsonResponse;
    NSDictionary *photoset = [results objectForKey:@"photoset"];
    NSDictionary *photos = [photoset objectForKey:@"photo"];
    
    NSMutableArray *photoids=(NSMutableArray*) [photos valueForKey:@"id"];
    NSMutableArray *secrets=(NSMutableArray*) [photos valueForKey:@"secret"];
    NSMutableArray *servers=(NSMutableArray*) [photos valueForKey:@"server"];
    NSMutableArray *farms=(NSMutableArray*) [photos valueForKey:@"farm"];
    NSMutableArray *titles=(NSMutableArray*) [photos valueForKey:@"title"];
    NSMutableArray *datesUpload =(NSMutableArray*) [photos valueForKey:@"dateupload"];
    NSMutableArray *originalURLs =(NSMutableArray*) [photos valueForKey:@"url_o"];
    NSMutableArray *commentsCount =(NSMutableArray*) [photos valueForKey:@"count_comments"];
    NSMutableArray *favoritesCount =(NSMutableArray*) [photos valueForKey:@"count_faves"];
    NSMutableArray *isFavorites =(NSMutableArray*) [photos valueForKey:@"isfavorite"];
    
    NSMutableArray *photoList = [[NSMutableArray alloc] init];
    
    int ndx;
    for (ndx = 0; ndx < photoids.count; ndx++) {
        FlickrPhoto *aPhoto = [FlickrPhoto flickrPhotoWithID:(NSString *)[photoids objectAtIndex:ndx]];
        aPhoto.secret = (NSString *)[secrets objectAtIndex:ndx];
        aPhoto.server = (NSString *)[servers objectAtIndex:ndx];
        aPhoto.farm = (NSString *)[farms objectAtIndex:ndx];
        aPhoto.title = (NSString *)[titles objectAtIndex:ndx];
        aPhoto.dateupload = (NSString *)[datesUpload objectAtIndex:ndx];
        aPhoto.originalURL = (NSString *)[originalURLs objectAtIndex:ndx];
        aPhoto.favoritesCount = (NSString *)[favoritesCount objectAtIndex:ndx];
        aPhoto.commentsCount = (NSString *)[commentsCount objectAtIndex:ndx];
        aPhoto.isFavorite = (NSString *)[isFavorites objectAtIndex:ndx];
        aPhoto.ownerNSID = buddy.nsid;
        aPhoto.ownerName = buddy.username;
        [photoList addObject:aPhoto];
    }

    return photoList;
}

//flickr.photosets.getList
-(NSMutableArray*)getAlbumList:(NSString*)flickr_nsid {
    
    NSString *flrMethod = @"flickr.photosets.getList";
    
    NSString *flickr_token = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrToken"];
    
    NSString *flrSigStr = [NSString stringWithFormat:@"%@api_key%@auth_token%@format%smethod%@nojsoncallback%suser_id%@", flrSecret, flrAPIKey, flickr_token, "json", flrMethod, "1", flickr_nsid];
    NSLog(@"FlickrAPI Signature String: %@", flrSigStr);
    NSLog(@"FlickrAPI Signature MD5: %@", flrSigStr.MD5);
    
    NSString *urlString = [NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=%@&user_id=%@&api_key=%@&auth_token=%@&api_sig=%@&format=json&nojsoncallback=1", flrMethod, flickr_nsid, flrAPIKey, flickr_token, flrSigStr.MD5 ];
    NSLog(@"FlickrAPI %@ URL: %@", flrMethod, urlString);
    NSURL *url = [NSURL URLWithString:urlString];
    
    // 2. Get URLResponse string & parse JSON to Foundation objects.
    
    NSString *connectionResponse = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    
    SBJsonParser *jsonParser = [SBJsonParser new];
    id jsonResponse = [jsonParser objectWithString:connectionResponse];
    NSDictionary *results = (NSDictionary *)jsonResponse;
    NSDictionary *photosets = [results objectForKey:@"photosets"];
    NSDictionary *photoset = [photosets objectForKey:@"photoset"];
    NSMutableArray *setids=(NSMutableArray*) [photoset valueForKey:@"id"];
    NSMutableArray *primarypics=(NSMutableArray*) [photoset valueForKey:@"primary"];
    NSMutableArray *secrets=(NSMutableArray*) [photoset valueForKey:@"secret"];
    NSMutableArray *servers=(NSMutableArray*) [photoset valueForKey:@"server"];
    NSMutableArray *farms=(NSMutableArray*) [photoset valueForKey:@"farm"];
    NSMutableArray *photoscnt=(NSMutableArray*) [photoset valueForKey:@"photos"];
    NSDictionary *titles_dict = [photoset valueForKey:@"title"];
    NSMutableArray *titles=(NSMutableArray*) [titles_dict valueForKey:@"_content"];
    NSDictionary *descriptions_dict = [photoset valueForKey:@"description"];
    NSMutableArray *descriptions=(NSMutableArray*) [descriptions_dict valueForKey:@"_content"];
    
    NSMutableArray *albumList = [[NSMutableArray alloc] init];
    
    int ndx;
    for (ndx = 0; ndx < setids.count; ndx++) {
        FlickrAlbum *anAlbum = [FlickrAlbum flickrAlbumWithID:(NSString *)[setids objectAtIndex:ndx]];
        anAlbum.primary_photo = (NSString *)[primarypics objectAtIndex:ndx];
        anAlbum.secret = (NSString *)[secrets objectAtIndex:ndx];
        anAlbum.server = (NSString *)[servers objectAtIndex:ndx];
        anAlbum.farm = (NSString *)[farms objectAtIndex:ndx];
        anAlbum.photo_count = (NSString *)[photoscnt objectAtIndex:ndx];
        anAlbum.title = (NSString *)[titles objectAtIndex:ndx];
        anAlbum.description = (NSString *)[descriptions objectAtIndex:ndx];
        // only add seene relevant albums
        int settype=0;
        if ([anAlbum.title caseInsensitiveCompare:@"Public Seenes"] == NSOrderedSame) settype=1;
        if ([anAlbum.title caseInsensitiveCompare:@"Private Seenes"] == NSOrderedSame) settype=2;
        if ([anAlbum.title rangeOfString:@"Seene Set:" options:NSCaseInsensitiveSearch].location != NSNotFound) settype=3;
        anAlbum.settype = settype;
        if (settype>0) {
            NSLog(@"FlickrAPI Seene relevant albums: %@ - %@", anAlbum.title, anAlbum.description);
            [albumList addObject:anAlbum];
        }
    }

    return albumList;
}

//flickr.contacts.getList
-(NSMutableArray*)getContactList {
    
    // 1. Call Flickr API Method "contacts.getList" with MD5 signed parameters. (Parameters must be concatenated in alphabetical order for signing!)
    
    NSString *flrMethod = @"flickr.contacts.getList";
    
    NSString *flickr_token = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrToken"];
    
    NSString *flrSigStr = [NSString stringWithFormat:@"%@api_key%@auth_token%@format%smethod%@nojsoncallback%s", flrSecret, flrAPIKey, flickr_token, "json", flrMethod, "1"];
    NSLog(@"FlickrAPI Signature String: %@", flrSigStr);
    NSLog(@"FlickrAPI Signature MD5: %@", flrSigStr.MD5);
    
    NSString *urlString = [NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=%@&api_key=%@&auth_token=%@&api_sig=%@&format=json&nojsoncallback=1", flrMethod, flrAPIKey, flickr_token, flrSigStr.MD5 ];
    NSLog(@"FlickrAPI %@ URL: %@", flrMethod, urlString);
    NSURL *url = [NSURL URLWithString:urlString];
    
    // 2. Get URLResponse string & parse JSON to Foundation objects.
    
    NSString *connectionResponse = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    
    SBJsonParser *jsonParser = [SBJsonParser new];
    id jsonResponse = [jsonParser objectWithString:connectionResponse];
    NSDictionary *results = (NSDictionary *)jsonResponse;
    NSDictionary *contacts = [results objectForKey:@"contacts"];
    NSString *total = [contacts objectForKey:@"total"];
    NSLog(@"FlickrAPI contacts: %@", total);
    NSDictionary *buddies = [contacts objectForKey:@"contact"];
    
    NSMutableArray *nsids=(NSMutableArray*) [buddies valueForKey:@"nsid"];
    NSMutableArray *usernames=(NSMutableArray*) [buddies valueForKey:@"username"];
    NSMutableArray *realnames=(NSMutableArray*) [buddies valueForKey:@"realname"];
    NSMutableArray *locations=(NSMutableArray*) [buddies valueForKey:@"location"];
    NSMutableArray *pathaliases=(NSMutableArray*) [buddies valueForKey:@"path_alias"];
    NSMutableArray *iconservers=(NSMutableArray*) [buddies valueForKey:@"iconserver"];
    NSMutableArray *iconfarms=(NSMutableArray*) [buddies valueForKey:@"iconfarm"];
    
    NSMutableArray *buddyList = [[NSMutableArray alloc] init];
    
    int ndx;
    for (ndx = 0; ndx < nsids.count; ndx++) {
        FlickrBuddy *aBuddy = [FlickrBuddy flickrBuddyWithID:(NSString *)[nsids objectAtIndex:ndx]];
        aBuddy.username = (NSString *)[usernames objectAtIndex:ndx];
        aBuddy.realname = (NSString *)[realnames objectAtIndex:ndx];
        aBuddy.location = (NSString *)[locations objectAtIndex:ndx];
        aBuddy.pathalias = (NSString *)[pathaliases objectAtIndex:ndx];
        aBuddy.iconserver = (NSString *)[iconservers objectAtIndex:ndx];
        aBuddy.iconfarm = (NSString *)[iconfarms objectAtIndex:ndx];
        NSLog(@"FlickrAPI following: %@ - %@", aBuddy.nsid, aBuddy.username);
        [buddyList addObject:aBuddy];
    }
    
    return buddyList;
}


// Retrieving Profile Icon URL
-(NSString*)getProfileIconURL:(NSString*)flickr_nsid {
    
    NSString *flrMethod = @"flickr.people.getInfo";
    
    NSString *urlString = [NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=%@&api_key=%@&user_id=%@&format=json&nojsoncallback=1", flrMethod, flrAPIKey, flickr_nsid];
    NSLog(@"FlickrAPI %@ URL: %@", flrMethod, urlString);
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSString *connectionResponse = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    //[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    SBJsonParser *jsonParser = [SBJsonParser new];
    id jsonResponse = [jsonParser objectWithString:connectionResponse];
    NSDictionary *results = (NSDictionary *)jsonResponse;
    NSDictionary *person = [results objectForKey:@"person"];
    NSString *iconserver = [person objectForKey:@"iconserver"];
    NSString *iconfarm = [person objectForKey:@"iconfarm"];
    
    NSString *iconUrl = [NSString stringWithFormat:@"https://farm%@.staticflickr.com/%@/buddyicons/%@.jpg", iconfarm, iconserver, flickr_nsid];
    NSLog(@"FlickrAPI: Profile Icon URL: %@", iconUrl);
    
    return iconUrl;
}

// Authorization by MiniToken to FullToken exchange
-(void)exchangeMiniTokenToFullToken:(NSString*)miniToken {
    
    // 1. Call Flickr API Method "getFullToken" with MD5 signed parameters. (Parameters must be concatenated in alphabetical order for signing!)
    
    NSString *flrMethod = @"flickr.auth.getFullToken";
    
    NSString *flrSigStr = [NSString stringWithFormat:@"%@api_key%@format%smethod%@mini_token%@nojsoncallback%s", flrSecret, flrAPIKey, "json", flrMethod, miniToken, "1"];
    NSLog(@"FlickrAPI Signature String: %@", flrSigStr);
    NSLog(@"FlickrAPI Signature MD5: %@", flrSigStr.MD5);
    NSString *urlString = [NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=%@&api_key=%@&mini_token=%@&api_sig=%@&format=json&nojsoncallback=1", flrMethod, flrAPIKey, miniToken, flrSigStr.MD5 ];
    NSLog(@"FlickrAPI %@ URL: %@", flrMethod, urlString);
    NSURL *url = [NSURL URLWithString:urlString];
    
    // 2. Get URLResponse string & parse JSON to Foundation objects.
    
    NSString *connectionResponse = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    
    SBJsonParser *jsonParser = [SBJsonParser new];
    id jsonResponse = [jsonParser objectWithString:connectionResponse];
    NSDictionary *results = (NSDictionary *)jsonResponse;
    
    NSDictionary *auth_json = [results objectForKey:@"auth"];
    NSDictionary *token_json = [auth_json objectForKey:@"token"];
    NSDictionary *user_json = [auth_json objectForKey:@"user"];
    NSString *token = [token_json objectForKey:@"_content"];
    NSString *nsid = [user_json objectForKey:@"nsid"];
    NSString *username = [user_json objectForKey:@"username"];
    NSString *fullname = [user_json objectForKey:@"fullname"];
    NSLog(@"FlickrAPI Token received: %@", token);
    NSLog(@"FlickrAPI NSID received: %@", nsid);
    NSLog(@"FlickrAPI received: %@", username);
    NSLog(@"FlickrAPI received: %@", fullname);
    
    // 3. Store Token & userdata to UserDefaults
    
    [[NSUserDefaults standardUserDefaults] setValue:token forKey:@"FlickrToken"];
    [[NSUserDefaults standardUserDefaults] setValue:nsid forKey:@"FlickrNSID"];
    [[NSUserDefaults standardUserDefaults] setValue:username forKey:@"FlickrUsername"];
    [[NSUserDefaults standardUserDefaults] setValue:fullname forKey:@"FlickrFullname"];
    
    // 4. Call API again for User's profile icon & store the URL to UserDefaults
    [[NSUserDefaults standardUserDefaults] setValue:[self getProfileIconURL:nsid] forKey:@"FlickrProfileIconURL"];
    
}


@end