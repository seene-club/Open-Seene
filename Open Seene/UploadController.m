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


@interface UploadController() {
    FlickrAPI *flickrAPI;
}

@end

@implementation UploadController

- (void)viewDidLoad {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    // Retrieve the most recent image from PhotoLibrary
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (nil != group) {
            // be sure to filter the group so you only get photos
             [group setAssetsFilter:[ALAssetsFilter allPhotos]];
             
             if (group.numberOfAssets > 0) {
                 [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:group.numberOfAssets - 1] options:0 usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                      if (nil != result) {
                          ALAssetRepresentation *repr = [result defaultRepresentation];
                          // this is the most recent saved photo
                          UIImage *photo = [UIImage imageWithCGImage:[repr fullResolutionImage]];
                          [self checkSelectedPhoto: photo];
                          self.imageView.image = photo;
                          
                          NSDictionary *metadata = repr.metadata;
                          
                          NSLog(@"image data %@", metadata);
                          
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

- (Boolean)checkSelectedPhoto:(UIImage*)photo {
    //UIImage *photo = self.imageView.image;
    CGDataProviderRef provider = CGImageGetDataProvider(photo.CGImage);
    NSData* data = (id)CFBridgingRelease(CGDataProviderCopyData(provider));
    const uint8_t* bytes = [data bytes];

    NSLog(@"image data %s", bytes);
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
