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
    NSString *publicUp;
    UIImagePickerController *picker;
    Boolean pickerPicked;
    ALAssetRepresentation *representation;
}

@end

@implementation UploadController

- (void)viewDidLoad {
    flickrAPI = [[FlickrAPI alloc] init];
    fileHelper = [[FileHelper alloc] initFileHelper];
    
    publicUp = @"1";
    
    picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    pickerPicked = false;
    
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    _tapRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:_tapRecognizer];
}

- (void)handleSingleTap:(UITapGestureRecognizer *) sender {
    [self.view endEditing:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    
    if (!pickerPicked) {
    
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
                              
                              
                              if ([self isSeene: representation.metadata]) {
                                  [_uploadButton setEnabled:YES];
                                  self.imageView.image = [self overlay3DLogo:photo withLogoName:@"3d-256.png"];
                              } else { // Not a Seene!
                                  [_uploadButton setEnabled:NO];
                                  self.imageView.image = [self overlay3DLogo:photo withLogoName:@"no3d.png"];
                                  [self flatAlert:@"The most recent image in your camera roll does not contain a depthmap. Do you want to select another image?"];
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
    }
    
}

- (void)flatAlert:(NSString*)msg {
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Flat like a pancake!"
                          message:msg
                          delegate:self cancelButtonTitle:@"Cancel"
                          otherButtonTitles:@"Yes", nil];
    [alert show];
}

- (UIImage*)overlay3DLogo:(UIImage*)photo withLogoName:(NSString*)logoName {
    UIImage *logo3d = [UIImage imageNamed:logoName];
    
    UIGraphicsBeginImageContext(photo.size);
    [photo drawInRect:CGRectMake(0, 0, photo.size.width, photo.size.height)];
    [logo3d drawInRect:CGRectMake(photo.size.width - logo3d.size.width - 25 , 25, logo3d.size.width, logo3d.size.height)];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    pickerPicked = NO;
    // Yes button response
    if (buttonIndex == 1) {
        [self presentViewController:picker animated:YES completion:NULL];
    }
    // Cancel button response
    if (buttonIndex == 0) {
        self.tabBarController.selectedIndex=0;
    }
}

-(IBAction)indexChanged:(UISegmentedControl *)sender
{
    switch (self.privacyToggle.selectedSegmentIndex)
    {
        case 0:
            publicUp = @"1";
            break;
        case 1:
            publicUp = @"0";
            break;
        default: 
            break; 
    } 
}


- (IBAction)uploadButtonPressed:(id)sender {
    NSString *cachedSeenePath = [fileHelper cacheUploadImage:representation];
    [flickrAPI uploadSeene:cachedSeenePath withTitle:_titleTextField.text withDescription:_DescriptionTextView.text isPublic:publicUp];
}

- (IBAction)cameraRolePressed:(id)sender {
    pickerPicked = NO;
    [self presentViewController:picker animated:YES completion:NULL];
}

// Is it a Seene? Better way could be to look inside the picture. But looking at metadata should be ok!?
- (Boolean)isSeene:(NSDictionary*)metadata {
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
    
    pickerPicked = YES;
    // unfortunately the "PickerController" does not deliver metadata, so we have to build an ALAsset from the referenceURL
    NSURL *referenceUrl = info[UIImagePickerControllerReferenceURL];

    NSLog(@"referenceUrl=%@", referenceUrl);
    
    if (!referenceUrl) {
        NSLog(@"Media did not have reference URL.");
    } else {
        ALAssetsLibrary *assetsLib = [[ALAssetsLibrary alloc] init];
        [assetsLib assetForURL:referenceUrl
                   resultBlock:^(ALAsset *result) {
                       
                       representation = [result defaultRepresentation];
                       
                       UIImage *photo = [UIImage imageWithCGImage:[representation fullResolutionImage]];
                       
                       if ([self isSeene: representation.metadata]) {
                           [_uploadButton setEnabled:YES];
                           self.imageView.image = [self overlay3DLogo:photo withLogoName:@"3d-256.png"];
                       } else {
                           [_uploadButton setEnabled:NO];
                           self.imageView.image = [self overlay3DLogo:photo withLogoName:@"no3d.png"];
                           [self flatAlert:@"The image you have chosen is not a Seene. Do you want to select another image?"];
                       }
                      
                   }
                  failureBlock:^(NSError *error) {
                      NSLog(@"Failed to get asset: %@", error);
                  }];
    }
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    pickerPicked = NO;
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}


@end
