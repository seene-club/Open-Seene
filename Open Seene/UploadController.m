//
//  UploadController.m
//  Open Seene
//
//  Created by Mathias Zettler on 22.10.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import "UploadController.h"
#import "FlickrAPI.h"
#import "FileHelper.h"

@interface UploadController() {
    FlickrAPI *flickrAPI;
    FileHelper *fileHelper;
    ALAssetRepresentation *representation;
}

@end

@implementation UploadController

- (void)viewDidLoad {
    
    flickrAPI = [[FlickrAPI alloc] init];
    fileHelper = [[FileHelper alloc] initFileHelper];
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    // Retrieve the most recent image from PhotoLibrary
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (nil != group) {
            // filter the group for photos only
             [group setAssetsFilter:[ALAssetsFilter allPhotos]];
             
             if (group.numberOfAssets > 0) {
                 [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:group.numberOfAssets - 1] options:0 usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                      if (nil != result) {
                          representation = [result defaultRepresentation];
                          
                          
                          // this is the most recent saved photo
                          UIImage *photo = [UIImage imageWithCGImage:[representation fullResolutionImage]];
                          self.imageView.image = photo;
                          
                          if ([self isSeene: representation]) {
                              [_uploadButton setEnabled:YES];
                          } else {
                              [_uploadButton setEnabled:NO];
                          }

                          
                          // we only need the first (most recent) photo -- stop the enumeration
                          *stop = YES;
                      }
                  }];
             }
         }
         *stop = NO;
     } failureBlock:^(NSError *error) {
         NSLog(@"error: %@", error);
     }];
    
    
    //[self presentViewController:picker animated:YES completion:NULL];
}

- (IBAction)uploadButtonPressed:(id)sender {
    NSString *cachedSeenePath = [fileHelper cacheUploadImage:representation];
    [flickrAPI uploadSeene:cachedSeenePath withTitle:@"coming soon..." isPublic:0];
}

// Is it a Seene? Better way could be to look inside the picture. But looking at metadata should be ok!?
- (Boolean)isSeene:(ALAssetRepresentation*)repr {
    NSDictionary *metadata = repr.metadata;
    NSLog(@"checkSelectedPhoto -> Metadata: %@", metadata);
    NSDictionary *exif = [metadata objectForKey:@"{Exif}"];
    NSDictionary *iptc = [metadata objectForKey:@"{IPTC}"];
    NSString *dimX = (NSString*) [exif valueForKey:@"PixelXDimension"];
    NSString *dimY = (NSString*) [exif valueForKey:@"PixelYDimension"];
    NSMutableArray *keyW = (NSMutableArray*) [iptc valueForKey:@"Keywords"];
    
    // First check photo dimension (1936x1936)?
    if (([[NSString stringWithFormat:@"%@", dimX] isEqualToString:[NSString stringWithFormat:@"1936"]]) &&
        ([[NSString stringWithFormat:@"%@", dimY] isEqualToString:[NSString stringWithFormat:@"1936"]])) {
        // Does it contain "seene, depth" keywords?
        if (([keyW containsObject:@"seene, depth"])) return YES;
    }
    return NO;
}



- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    self.imageView.image = chosenImage;
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}


@end
