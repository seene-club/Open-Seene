//
//  UploadController.h
//  Open Seene
//
//  Created by Mathias Zettler on 22.10.16.
//  Copyright © 2016 Mathias Zettler. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UploadController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end
