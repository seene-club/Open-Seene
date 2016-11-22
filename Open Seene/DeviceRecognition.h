//
//  DeviceRecognition.h
//  INTERnal
//  On which device I'm running? Cause I'm universal!
//
//  Created by Mathias Zettler on 16.10.13.
//  Copyright (c) 2013 Mathias Zettler. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeviceRecognition : NSObject

-(NSString *) platform;
-(NSString *) platformString;
-(NSString *) type;
-(float) screenWidth;
-(float) screenHeight;

@end
