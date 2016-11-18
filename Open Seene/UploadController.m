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
#import "SVProgressHUD.h"
#import "FlickrAPI.h"
#import "FileHelper.h"

@interface UploadController() {
    FlickrAPI *flickrAPI;
    FileHelper *fileHelper;
    NSString *publicUp;
    NSTimer *uploadProcessTimer;
    UIImagePickerController *uploadPicker;
    Boolean pickerPicked;
    ALAssetRepresentation *representation;
    NSString *cachedSeenePath;
}

@end

@implementation UploadController

- (void)viewDidLoad {
    flickrAPI = [[FlickrAPI alloc] init];
    fileHelper = [[FileHelper alloc] initFileHelper];
    
    publicUp = @"1";
    
    uploadPicker = [[UIImagePickerController alloc] init];
    uploadPicker.delegate = self;
    uploadPicker.allowsEditing = NO;
    uploadPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
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
                              
                              // this is the most recent saved photo
                              representation = [result defaultRepresentation];
                              [self uploadPreProcessing:@"The most recent image in your camera roll"];
                              
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

-(void)uploadPreProcessing:(NSString*)words {
    UIImage *photo = [UIImage imageWithCGImage:[representation fullResolutionImage]];
    
    if ([self isSeene: representation.metadata]) {
        if ([fileHelper alreadyUploadedCheck:[representation filename]]) {
            [_uploadButton setEnabled:NO];
            cachedSeenePath = nil;
            self.imageView.image = [self overlay3DLogo:photo withLogoName:@"uploaded.png"];
            [self noUpAlert:@"Already uploaded!" withMessage:[NSString stringWithFormat:@"%@ has been uploaded already. Do you want to select another image?", words]];
        } else {
            [_uploadButton setEnabled:YES];
            cachedSeenePath = [fileHelper cacheUploadImage:representation];
            self.imageView.image = [self overlay3DLogo:photo withLogoName:@"3d-256.png"];
        }
    } else { // Not a Seene!
        [_uploadButton setEnabled:NO];
        cachedSeenePath = nil;
        self.imageView.image = [self overlay3DLogo:photo withLogoName:@"no3d.png"];
        [self noUpAlert:@"Flat like a pancake!" withMessage:[NSString stringWithFormat:@"%@ does not contain a depthmap. Do you want to select another image?", words]];
    }
}

- (void)noUpAlert:(NSString*)alertTitle withMessage:(NSString*)msg {
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:alertTitle
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
        [self presentViewController:uploadPicker animated:YES completion:NULL];
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
    NSLog(@"Uploading from cache: %@", cachedSeenePath);
    [SVProgressHUD showWithStatus:@"preparing upload"];
    if ([_titleTextField.text length] == 0) _titleTextField.text = [NSString stringWithFormat:@"A 3D Seene by @%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"FlickrUsername"]];
    uploadProcessTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(processUploadResponse) userInfo:nil repeats:YES];
    [flickrAPI uploadSeene:cachedSeenePath withTitle:_titleTextField.text withDescription:_DescriptionTextView.text isPublic:publicUp];
}

- (void)processUploadResponse {
    NSString *uploadProgress = [[NSUserDefaults standardUserDefaults] stringForKey:@"UploadProgress"];
    NSLog(@"Upload Status: %@", uploadProgress);
    [SVProgressHUD showWithStatus:uploadProgress];
    if ([uploadProgress rangeOfString:@"error"].location != NSNotFound) {
        [self stopUploadResponseTimer];
        [SVProgressHUD showErrorWithStatus:uploadProgress];
    }
    if ([uploadProgress rangeOfString:@"success"].location != NSNotFound) {
        [fileHelper moveUploadedImage:cachedSeenePath];
        [self stopUploadResponseTimer];
        [SVProgressHUD showSuccessWithStatus:uploadProgress];
        self.tabBarController.selectedIndex=0;
    }
    
}

-(void)stopUploadResponseTimer {
    if ([uploadProcessTimer isValid]) [uploadProcessTimer invalidate];
    uploadProcessTimer = nil;
}

- (IBAction)cameraRolePressed:(id)sender {
    pickerPicked = NO;
    [self presentViewController:uploadPicker animated:YES completion:NULL];
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
                       [self uploadPreProcessing:@"The image you have chosen"];
                      
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
