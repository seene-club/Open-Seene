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
    
    // Simulator
    if ([[device platformString] isEqualToString:@"Simulator"]) {
        if (([device screenWidth] == 320) && ([device screenHeight] == 568)) return @"Main_iPhone5";
        if (([device screenWidth] == 375) && ([device screenHeight] == 667)) return @"Main_iPhone6";
        if (([device screenWidth] == 414) && ([device screenHeight] == 736)) return @"Main_iPhone6Plus";
    } else { // Real device
        // handle iPhone SE (Size of iPhone 5/5s)
        if ([[device platformString] isEqualToString:@"iPhone SE"]) return @"Main_iPhone5";
        
        // handle iPhone 6/6s (and Plus models)
        if ([[device platformString] rangeOfString:@"iPhone 6"].location != NSNotFound) {
            if ([[device platformString] rangeOfString:@"Plus"].location != NSNotFound) return @"Main_iPhone6Plus";
            return @"Main_iPhone6";
        }
        
        // handle iPhone 7/7 Plus (same size as 6/6s)
        if ([[device platformString] rangeOfString:@"iPhone 7"].location != NSNotFound) {
            if ([[device platformString] rangeOfString:@"Plus"].location != NSNotFound) return @"Main_iPhone6Plus";
            return @"Main_iPhone6";
        }
    }
    return @"Main";
}

-(void)storyboardNameToUserDefaults {
     [[NSUserDefaults standardUserDefaults] setValue:[self storyboardNameForCurrentDevice] forKey:@"StoryboardName"];
}

@end
