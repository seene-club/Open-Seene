//
//  StoryboardFinder.h
//  Open Seene
//
//  Created by Mathias Zettler on 22.11.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//


#import "DeviceRecognition.h"

@interface StoryboardFinder : NSObject

// StoryboardFinder methods
- (NSString*)storyboardNameForCurrentDevice;             // returns the name of the storyboard for the current device
- (void)storyboardNameToUserDefaults;                    // saves the name of the storyboard to UserDefaults

//Instance (-) custom constructor method
- (id)initStoryboardFinder;

//Class (+) custom "convenient" constructor
+ (StoryboardFinder*)storyboardFinder;

@end
