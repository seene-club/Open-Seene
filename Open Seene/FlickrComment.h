//
//  FlickrComment.h
//  Open Seene
//
//  Created by Mathias Zettler on 04.10.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FlickrComment : NSObject {
    
    NSString *commentid;
    NSString *authorNSID;
    NSString *author_is_deleted;
    NSString *authorname;
    NSString *iconserver;
    NSString *iconfarm;
    NSString *dateCreate;
    NSString *commentText;
}

//non thread-safe getter and setter will be generated.
@property (nonatomic, copy) NSString *commentid;
@property (nonatomic, copy) NSString *authorNSID;
@property (nonatomic, copy) NSString *author_is_deleted;
@property (nonatomic, copy) NSString *authorname;
@property (nonatomic, copy) NSString *iconserver;
@property (nonatomic, copy) NSString *iconfarm;
@property (nonatomic, copy) NSString *dateCreate;
@property (nonatomic, copy) NSString *commentText;


/* Public methods */
//Instance (-) custom constructor method
- (id)initFlickrCommentWithID:(NSString*)cid;

//Class (+) custom "convenient" constructor
+ (FlickrComment*)flickrCommentWithID:(NSString*)cid;

@end
