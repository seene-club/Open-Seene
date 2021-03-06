//
//  StoryboardFinder.m
//  Open Seene
//
//  Created by Mathias Zettler on 22.11.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StoryboardFinder.h"

@interface StoryboardFinder () {
    
    DeviceRecognition *device;
}

@end

@implementation StoryboardFinder

/* Instance (-) custom constructor method */
- (id)initStoryboardFinder {
    
    self = [super init]; //call to default super constructor
    
    if (self) { //check that that construction did not return a nil object.
        device = [[DeviceRecognition alloc] init];
        NSLog(@"StoryboardFinder initialized for Device Type: %@ - Plattform: %@ (%@) - Screen: %.0fx%.0f pixels",
              [device type],[device platform],[device platformString],[device screenWidth],[device screenHeight]);
    }
    
    return self;
}

/* Class (+) custom "convenient" constructor */
+ (StoryboardFinder*)storyboardFinder {
    return [[self alloc] initStoryboardFinder];
}


-(NSString*)storyboardNameForCurrentDevice {
    if (([device screenWidth] == 320) && ([device screenHeight] == 568)) return @"Main_iPhone5";        // iPhone 5(S/E) normal mode, iPhone 6/7 zoomed
    if (([device screenWidth] == 375) && ([device screenHeight] == 667)) return @"Main_iPhone6";        // iPhone 6/7    normal mode, iPhone 6/7 Plus zoomed
    if (([device screenWidth] == 414) && ([device screenHeight] == 736)) return @"Main_iPhone6Plus";    // iPhone 6/7 Plus normal mode
    return @"Main";
}

-(void)storyboardNameToUserDefaults {
     [[NSUserDefaults standardUserDefaults] setValue:[self storyboardNameForCurrentDevice] forKey:@"StoryboardName"];
}

@end
