//
//  FlickrAPI.m
//  Open Seene
//
//  Created by Mathias Zettler on 22.09.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import <Foundation/Foundation.h>
@import MobileCoreServices;
#import "FlickrAPI.h"
#import "FlickrBuddy.h"
#import "FlickrComment.h"
#import "FlickrAlbum.h"
#import "FlickrPhoto.h"
#import "FileHelper.h"
#import "SBJson.h"
#import "NSString+MD5.h"

@interface FlickrAPI () {
    
    NSString *postResult;
}

@end

@implementation FlickrAPI

//POST-Request:https://up.flickr.com/services/upload/
-(NSString*)uploadSeene:(NSString*)filePath withTitle:(NSString*)title isPublic:(int)publicint {
    
    NSURL *url = [NSURL URLWithString:@"https://up.flickr.com/services/upload/"];
    NSString *fieldName=@"photo";
    
    NSString *flickr_token = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrToken"];
    
    NSString *flrSigStr = [NSString stringWithFormat:@"%@api_key%@auth_token%@", flrSecret, flrAPIKey, flickr_token];
    NSLog(@"FlickrAPI Signature String: %@", flrSigStr);
    NSLog(@"FlickrAPI Signature MD5: %@", flrSigStr.MD5);
    
    NSDictionary *params = @{@"api_key"     : flrAPIKey,
                             @"auth_token"  : flickr_token,
                             @"api_sig"     : flrSigStr.MD5};
    
    
    NSString *boundary = [self generateBoundaryString];
    
    // configure the request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    // set content type
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    // create body
    NSData *httpBody = [self createBodyWithBoundary:boundary parameters:params paths:@[filePath] fieldName:fieldName];
    NSString *httpBodyString = [[NSString alloc] initWithData:httpBody encoding:NSUTF8StringEncoding];
    NSLog(@"FlickrAPI httpBody:\n%@", httpBodyString);
    
    request.HTTPBody = httpBody;
    
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            NSLog(@"error = %@", connectionError);
            postResult = [NSString stringWithFormat:@"error = %@", connectionError];
            return;
        }
        
        postResult = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"result = %@", postResult);
    }];
    
    return postResult;
}

-(NSData *)createBodyWithBoundary:(NSString *)boundary
                        parameters:(NSDictionary *)parameters
                             paths:(NSArray *)paths
                         fieldName:(NSString *)fieldName
{
    NSMutableData *httpBody = [NSMutableData data];
    
    // add params (all params are strings)
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *parameterKey, NSString *parameterValue, BOOL *stop) {
        [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", parameterKey] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"%@\r\n", parameterValue] dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    
    // add image data
    for (NSString *path in paths) {
        NSString *filename  = [path lastPathComponent];
        NSData   *data      = [NSData dataWithContentsOfFile:path];
        NSString *mimetype  = [self mimeTypeForPath:path];
        
        [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", fieldName, filename] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mimetype] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:data];
        [httpBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [httpBody appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return httpBody;
}


// get a mime type for an extension using MobileCoreServices.framework
- (NSString *)mimeTypeForPath:(NSString *)path {
    
    CFStringRef extension = (__bridge CFStringRef)[path pathExtension];
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, extension, NULL);
    assert(UTI != NULL);
    
    NSString *mimetype = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType));
    assert(mimetype != NULL);
    
    CFRelease(UTI);
    
    return mimetype;
}

- (NSString *)generateBoundaryString {
    return [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
}



//flickr.photos.comments.addComment
-(Boolean)commentSeene:(FlickrPhoto*)photo withText:(NSString*)comment_text {
    
    NSString *flrMethod = @"flickr.photos.comments.addComment";
    
    NSString *flickr_token = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrToken"];
    
    NSString *flrSigStr = [NSString stringWithFormat:@"%@api_key%@auth_token%@comment_text%@format%smethod%@nojsoncallback%sphoto_id%@", flrSecret, flrAPIKey, flickr_token, comment_text, "json", flrMethod, "1", photo.photoid];
    NSLog(@"FlickrAPI Signature String: %@", flrSigStr);
    NSLog(@"FlickrAPI Signature MD5: %@", flrSigStr.MD5);
    
    // IMPORTANT: The comment_text must be url-encoded for the request, but it MUST NOT be url-encoded for the MD5-Signature!
    NSMutableCharacterSet *chars = NSCharacterSet.URLQueryAllowedCharacterSet.mutableCopy;
    [chars removeCharactersInRange:NSMakeRange('&', 1)]; // %26
    NSString *encodedComment = [comment_text stringByAddingPercentEncodingWithAllowedCharacters:chars];
    
    NSString *urlString = [NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=%@&photo_id=%@&comment_text=%@&api_key=%@&auth_token=%@&api_sig=%@&format=json&nojsoncallback=1", flrMethod, photo.photoid, encodedComment, flrAPIKey, flickr_token, flrSigStr.MD5 ];
    NSLog(@"FlickrAPI %@ URL: %@", flrMethod, urlString);
    NSURL *url = [NSURL URLWithString:urlString];
    
    // 2. Get URLResponse string & parse JSON to Foundation objects.
    
    NSString *connectionResponse = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    
    if (connectionResponse == nil) {
        [self lastFailToWithOrigin:flrMethod errorID:@"-1" errorText:@"Request execution failed"];
        return false;
    }
    
    NSLog(@"FlickrAPI %@ RESPONSE: %@", flrMethod, connectionResponse);
    
    if ([connectionResponse rangeOfString:@"\"stat\":\"ok\"}"].location == NSNotFound) {
        SBJsonParser *jsonParser = [SBJsonParser new];
        id jsonResponse = [jsonParser objectWithString:connectionResponse];
        NSDictionary *results = (NSDictionary *)jsonResponse;
        NSString *code = (NSString*) [results valueForKey:@"code"];
        NSString *message = (NSString*) [results valueForKey:@"message"];
        NSLog(@"FlickrAPI %@ ERROR: %@ - %@", flrMethod, code, message);
        [self lastFailToWithOrigin:flrMethod errorID:code errorText:message];
        
        return false;
    } else {
        NSLog(@"FlickrAPI %@ OK: %@ - %@", flrMethod, photo.photoid, encodedComment);
        return true;
    }
    
    return false;
}


//flickr.photos.comments.getList
-(NSMutableArray*)getComments:(NSString*)photoid {
    
    NSString *flrMethod = @"flickr.photos.comments.getList";
    
    NSString *flickr_token = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrToken"];
    
    NSString *flrSigStr = [NSString stringWithFormat:@"%@api_key%@auth_token%@format%smethod%@nojsoncallback%sphoto_id%@", flrSecret, flrAPIKey, flickr_token, "json", flrMethod, "1", photoid];
    NSLog(@"FlickrAPI Signature String: %@", flrSigStr);
    NSLog(@"FlickrAPI Signature MD5: %@", flrSigStr.MD5);
    
    NSString *urlString = [NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=%@&photo_id=%@&api_key=%@&auth_token=%@&api_sig=%@&format=json&nojsoncallback=1", flrMethod, photoid, flrAPIKey, flickr_token, flrSigStr.MD5 ];
    NSLog(@"FlickrAPI %@ URL: %@", flrMethod, urlString);
    NSURL *url = [NSURL URLWithString:urlString];
    
    // 2. Get URLResponse string & parse JSON to Foundation objects.
    
    NSString *connectionResponse = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    
    SBJsonParser *jsonParser = [SBJsonParser new];
    id jsonResponse = [jsonParser objectWithString:connectionResponse];
    NSDictionary *results = (NSDictionary *)jsonResponse;
    NSDictionary *commentsEnvelope = [results objectForKey:@"comments"];
    NSDictionary *comments = [commentsEnvelope objectForKey:@"comment"];
    NSMutableArray *commentids = (NSMutableArray*) [comments valueForKey:@"id"];
    NSMutableArray *authors = (NSMutableArray*) [comments valueForKey:@"author"];
    NSMutableArray *authorsdeleted = (NSMutableArray*) [comments valueForKey:@"author_is_deleted"];
    NSMutableArray *authornames = (NSMutableArray*) [comments valueForKey:@"authorname"];
    NSMutableArray *servers = (NSMutableArray*) [comments valueForKey:@"iconserver"];
    NSMutableArray *farms = (NSMutableArray*) [comments valueForKey:@"iconfarm"];
    NSMutableArray *datescreate = (NSMutableArray*) [comments valueForKey:@"datecreate"];
    NSMutableArray *commentsText = (NSMutableArray*) [comments valueForKey:@"_content"];
    
    NSMutableArray *commentList = [[NSMutableArray alloc] init];
    
    int ndx;
    for (ndx = 0; ndx < commentids.count; ndx++) {
        FlickrComment *aComment = [FlickrComment flickrCommentWithID:(NSString *)[commentids objectAtIndex:ndx]];
        aComment.authorname = (NSString *)[authornames objectAtIndex:ndx];
        aComment.authorNSID = (NSString *)[authors objectAtIndex:ndx];
        aComment.author_is_deleted = (NSString *)[authorsdeleted objectAtIndex:ndx];
        aComment.iconserver = (NSString *)[servers objectAtIndex:ndx];
        aComment.iconfarm = (NSString *)[farms objectAtIndex:ndx];
        aComment.dateCreate = (NSString *)[datescreate objectAtIndex:ndx];
        aComment.commentText = (NSString *)[commentsText objectAtIndex:ndx];
        [commentList addObject:aComment];
    }
    
    return commentList;
}

//flickr.test.login
-(Boolean)testFlickrLogin {
    
    NSString *flrMethod = @"flickr.test.login";
    
    NSString *flickr_token = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrToken"];
    NSString *flickr_nsid = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrNSID"];
    
    NSString *flrSigStr = [NSString stringWithFormat:@"%@api_key%@auth_token%@format%smethod%@nojsoncallback%s", flrSecret, flrAPIKey, flickr_token, "json", flrMethod, "1"];
    NSLog(@"FlickrAPI Signature String: %@", flrSigStr);
    NSLog(@"FlickrAPI Signature MD5: %@", flrSigStr.MD5);
    
    NSString *urlString = [NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=%@&api_key=%@&auth_token=%@&api_sig=%@&format=json&nojsoncallback=1", flrMethod, flrAPIKey, flickr_token, flrSigStr.MD5 ];
    NSLog(@"FlickrAPI %@ URL: %@", flrMethod, urlString);
    NSURL *url = [NSURL URLWithString:urlString];
    
    // 2. Get URLResponse string & parse JSON to Foundation objects.
    
    NSString *connectionResponse = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    
    NSLog(@"FlickrAPI %@ RESPONSE: %@", flrMethod, connectionResponse);
    
    if ([connectionResponse rangeOfString:flickr_nsid].location == NSNotFound) {
        SBJsonParser *jsonParser = [SBJsonParser new];
        id jsonResponse = [jsonParser objectWithString:connectionResponse];
        NSDictionary *results = (NSDictionary *)jsonResponse;
        NSString *code = (NSString*) [results valueForKey:@"code"];
        NSString *message = (NSString*) [results valueForKey:@"message"];
        NSLog(@"FlickrAPI %@ ERROR: %@ - %@", flrMethod, code, message);
        
        [self resetLoginUserDefaults];
        return false;
    } else {
        NSLog(@"FlickrAPI %@ : %@ valid login!", flrMethod, flickr_nsid);
        return true;
    }
    
    return false;
}

//flickr.favorites.add
-(Boolean)likeSeene:(FlickrPhoto*)photo {
    
    NSString *flrMethod = @"flickr.favorites.add";
    
    NSString *flickr_token = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrToken"];
    
    NSString *flrSigStr = [NSString stringWithFormat:@"%@api_key%@auth_token%@format%smethod%@nojsoncallback%sphoto_id%@", flrSecret, flrAPIKey, flickr_token, "json", flrMethod, "1", photo.photoid];
    NSLog(@"FlickrAPI Signature String: %@", flrSigStr);
    NSLog(@"FlickrAPI Signature MD5: %@", flrSigStr.MD5);
    
    NSString *urlString = [NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=%@&photo_id=%@&api_key=%@&auth_token=%@&api_sig=%@&format=json&nojsoncallback=1", flrMethod, photo.photoid, flrAPIKey, flickr_token, flrSigStr.MD5 ];
    NSLog(@"FlickrAPI %@ URL: %@", flrMethod, urlString);
    NSURL *url = [NSURL URLWithString:urlString];
    
    // 2. Get URLResponse string & parse JSON to Foundation objects.
    
    NSString *connectionResponse = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    
    NSLog(@"FlickrAPI %@ RESPONSE: %@", flrMethod, connectionResponse);
    
    if ([connectionResponse rangeOfString:@"{\"stat\":\"ok\"}"].location == NSNotFound) {
        SBJsonParser *jsonParser = [SBJsonParser new];
        id jsonResponse = [jsonParser objectWithString:connectionResponse];
        NSDictionary *results = (NSDictionary *)jsonResponse;
        NSString *code = (NSString*) [results valueForKey:@"code"];
        NSString *message = (NSString*) [results valueForKey:@"message"];
        NSLog(@"FlickrAPI %@ ERROR: %@ - %@", flrMethod, code, message);
        [self lastFailToWithOrigin:flrMethod errorID:code errorText:message];
        
        return false;
    } else {
        NSLog(@"FlickrAPI %@ OK: %@ - %@", flrMethod, photo.photoid, photo.ownerName);
        return true;
    }
    
    return false;
}

//flickr.favorites.remove
-(Boolean)removeLike:(FlickrPhoto*)photo {
    
    NSString *flrMethod = @"flickr.favorites.remove";
    
    NSString *flickr_token = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrToken"];
    
    NSString *flrSigStr = [NSString stringWithFormat:@"%@api_key%@auth_token%@format%smethod%@nojsoncallback%sphoto_id%@", flrSecret, flrAPIKey, flickr_token, "json", flrMethod, "1", photo.photoid];
    NSLog(@"FlickrAPI Signature String: %@", flrSigStr);
    NSLog(@"FlickrAPI Signature MD5: %@", flrSigStr.MD5);
    
    NSString *urlString = [NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=%@&photo_id=%@&api_key=%@&auth_token=%@&api_sig=%@&format=json&nojsoncallback=1", flrMethod, photo.photoid, flrAPIKey, flickr_token, flrSigStr.MD5 ];
    NSLog(@"FlickrAPI %@ URL: %@", flrMethod, urlString);
    NSURL *url = [NSURL URLWithString:urlString];
    
    // 2. Get URLResponse string & parse JSON to Foundation objects.
    
    NSString *connectionResponse = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    
    NSLog(@"FlickrAPI %@ RESPONSE: %@", flrMethod, connectionResponse);
    
    if ([connectionResponse rangeOfString:@"{\"stat\":\"ok\"}"].location == NSNotFound) {
        SBJsonParser *jsonParser = [SBJsonParser new];
        id jsonResponse = [jsonParser objectWithString:connectionResponse];
        NSDictionary *results = (NSDictionary *)jsonResponse;
        NSString *code = (NSString*) [results valueForKey:@"code"];
        NSString *message = (NSString*) [results valueForKey:@"message"];
        NSLog(@"FlickrAPI %@ ERROR: %@ - %@", flrMethod, code, message);
        [self lastFailToWithOrigin:flrMethod errorID:code errorText:message];
        
        return false;
    } else {
        NSLog(@"FlickrAPI %@ OK: %@ - %@", flrMethod, photo.photoid, photo.ownerName);
        return true;
    }
    
    return false;
}



//flickr.photosets.getPhotos
-(NSMutableArray*)getPublicSeenesList:(FlickrBuddy*)buddy {
    
    NSString *flrMethod = @"flickr.photosets.getPhotos";
    NSString *flrExtras = @"date_upload,url_o,url_q,count_comments,count_faves,isfavorite";               // ! some of them are not documented on official Flickr API !
    
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
    NSMutableArray *thumbnailURLs =(NSMutableArray*) [photos valueForKey:@"url_q"];
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
        aPhoto.thumbnailURL = (NSString *)[thumbnailURLs objectAtIndex:ndx];
        aPhoto.favoritesCount = (NSString *)[favoritesCount objectAtIndex:ndx];
        aPhoto.commentsCount = (NSString *)[commentsCount objectAtIndex:ndx];
        aPhoto.isFavorite = (NSString *)[isFavorites objectAtIndex:ndx];
        aPhoto.ownerNSID = buddy.nsid;
        aPhoto.ownerName = buddy.username;
        if(![aPhoto.originalURL isEqual:[NSNull null]]) {
            [photoList addObject:aPhoto];
        } else {
            NSLog(@"WARNING: %@'s Photo (%@) seems to be protected! Won't add it to the timeline!", buddy.username, aPhoto.photoid);
        }
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

//flickr.groups.members.getList - members of the "Seene" group.
-(NSMutableArray*)getGroupContactList {
    
    NSString *flrMethod = @"flickr.groups.members.getList";
    
    NSString *flickr_token = [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrToken"];
    
    NSString *flrSigStr = [NSString stringWithFormat:@"%@api_key%@auth_token%@format%sgroup_id%@method%@nojsoncallback%sper_page500", flrSecret, flrAPIKey, flickr_token, "json", seeneGroupID, flrMethod, "1"];
    NSLog(@"FlickrAPI Signature String: %@", flrSigStr);
    NSLog(@"FlickrAPI Signature MD5: %@", flrSigStr.MD5);
    
    NSString *urlString = [NSString stringWithFormat:@"https://api.flickr.com/services/rest/?method=%@&group_id=%@&per_page=500&api_key=%@&auth_token=%@&api_sig=%@&format=json&nojsoncallback=1", flrMethod, seeneGroupID, flrAPIKey, flickr_token, flrSigStr.MD5 ];
    NSLog(@"FlickrAPI %@ URL: %@", flrMethod, urlString);
    NSURL *url = [NSURL URLWithString:urlString];
    
    // 2. Get URLResponse string & parse JSON to Foundation objects.
    
    NSString *connectionResponse = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    
    SBJsonParser *jsonParser = [SBJsonParser new];
    id jsonResponse = [jsonParser objectWithString:connectionResponse];
    NSDictionary *results = (NSDictionary *)jsonResponse;
    NSDictionary *membersEnvelope = [results objectForKey:@"members"];
    NSString *total = [membersEnvelope objectForKey:@"total"];
    NSLog(@"FlickrAPI Seene group members: %@", total);
    NSDictionary *members = [membersEnvelope objectForKey:@"member"];
    
    NSMutableArray *nsids=(NSMutableArray*) [members valueForKey:@"nsid"];
    NSMutableArray *usernames=(NSMutableArray*) [members valueForKey:@"username"];
    NSMutableArray *realnames=(NSMutableArray*) [members valueForKey:@"realname"];
    NSMutableArray *locations=(NSMutableArray*) [members valueForKey:@"location"];
    NSMutableArray *pathaliases=(NSMutableArray*) [members valueForKey:@"path_alias"];
    NSMutableArray *iconservers=(NSMutableArray*) [members valueForKey:@"iconserver"];
    NSMutableArray *iconfarms=(NSMutableArray*) [members valueForKey:@"iconfarm"];
    
    NSMutableArray *memberList = [[NSMutableArray alloc] init];
    FileHelper *fileHelper = [[FileHelper alloc] initFileHelper];
    
    int ndx;
    for (ndx = 0; ndx < nsids.count; ndx++) {
        FlickrBuddy *aMember = [FlickrBuddy flickrBuddyWithID:(NSString *)[nsids objectAtIndex:ndx]];
        aMember.username = (NSString *)[usernames objectAtIndex:ndx];
        aMember.realname = (NSString *)[realnames objectAtIndex:ndx];
        aMember.location = (NSString *)[locations objectAtIndex:ndx];
        aMember.pathalias = (NSString *)[pathaliases objectAtIndex:ndx];
        aMember.iconserver = (NSString *)[iconservers objectAtIndex:ndx];
        aMember.iconfarm = (NSString *)[iconfarms objectAtIndex:ndx];
        NSLog(@"FlickrAPI Seene group member: %@ - %@", aMember.nsid, aMember.username);
        [fileHelper cacheMemberOnDevice:aMember];
        [memberList addObject:aMember];
    }
    
    return memberList;
}


//flickr.contacts.getList - flickr buddies of the logged-in user.
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

// persist last fail of an API-Call in UserDefaults
-(void) lastFailToWithOrigin:(NSString*)origin errorID:(NSString*)errid errorText:(NSString*)errtxt {
    [[NSUserDefaults standardUserDefaults] setValue:origin forKey:@"LastFailOrigin"];
    [[NSUserDefaults standardUserDefaults] setValue:errid forKey:@"LastFailID"];
    [[NSUserDefaults standardUserDefaults] setValue:errtxt forKey:@"LastFailText"];
}

-(NSString*) getLastFailOrigin {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"LastFailOrigin"];
}

-(NSString*) getLastFailID {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"LastFailID"];
}

-(NSString*) getLastFailText {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"LastFailText"];
}

-(void) lastFailClear {
    [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"LastFailOrigin"];
    [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"LastFailID"];
    [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"LastFailText"];
}

// reset the Login related UserDefaults (in case of logout, invalid token, ...)
-(void)resetLoginUserDefaults {
    [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"FlickrToken"];
    [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"FlickrNSID"];
    [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"FlickrUsername"];
    [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"FlickrFullname"];
    [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"FlickrProfileIconURL"];
    [self lastFailClear];
}




@end
