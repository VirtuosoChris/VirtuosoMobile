//
//  CameraViewController.m
//  HelloWorld
//
//  Created by Admin on 7/1/13.
//  Copyright (c) 2013 Virtuoso Engine. All rights reserved.
//

#import "ImagePickerDelegate.h"

#import <MobileCoreServices/UTCoreTypes.h>
#import <UIKit/UIImagePickerController.h>
#include <iostream>
#include "SystemImage.h"
#include "SystemImageImplIos.h"
#include <functional>


@implementation ImagePickerDelegate

- (void)               image: (UIImage *) image
    didFinishSavingWithError: (NSError *) error
                 contextInfo: (void *) contextInfo
{
    if(error)
    {
        throw std::runtime_error("Failed to save image to library");
    }
    
    typedef  std::function<void (const SystemImage&)   > CONTEXT_PTR;
    
    const CONTEXT_PTR& funP =  *reinterpret_cast<CONTEXT_PTR*> (contextInfo);
    
    funP(SystemImageIOS(image));
    
    delete (&funP); //free mem since we copied the ptr
}


// For responding to the user tapping Cancel.
- (void) imagePickerControllerDidCancel: (UIImagePickerController *) picker {
    //std::cout<<"DID CANCEL"<<std::endl;
    
    
#ifndef APP_EXTENSION
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)])
    {
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }
#endif
    
    [picker dismissViewControllerAnimated:YES completion:nil ];
    //[picker release];
}

// For responding to the user accepting a newly-captured picture or movie
- (void) imagePickerController: (UIImagePickerController *) picker
 didFinishPickingMediaWithInfo: (NSDictionary *) info
{
    ///\todo this is kind of a hack.  in our apps we never want the status bar but this should be patched to set it to what it was before
    
#ifndef APP_EXTENSION
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)])
    {
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }
#endif
    
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    UIImage *originalImage, *editedImage, *imageToSave;
    
    // Handle a still image capture
    if (CFStringCompare ((CFStringRef) mediaType, kUTTypeImage, 0)
        == kCFCompareEqualTo)
    {
        editedImage = (UIImage *) [info objectForKey:
                                   UIImagePickerControllerEditedImage];
        originalImage = (UIImage *) [info objectForKey:
                                     UIImagePickerControllerOriginalImage];
        
        if (editedImage)
        {
            imageToSave = editedImage;
        }
        else
        {
            imageToSave = originalImage;
        }
    
        auto lambda = [=]()
        {
            SystemImage sysImg = SystemImageIOS(imageToSave);
            
            _onFinish(sysImg);
        };
        
        [picker dismissViewControllerAnimated: YES completion:lambda];
        
        picker = nil;
    }
    
    /*
    // Handle a movie capture
    if (CFStringCompare ((CFStringRef) mediaType, kUTTypeMovie, 0)
        == kCFCompareEqualTo) {
        
        NSString *moviePath = [[info objectForKey:
                                UIImagePickerControllerMediaURL] path];
        
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum (moviePath)) {
            
            std::cout<<"SAVING TO LIBRARY"<<std::endl;
            
            UISaveVideoAtPathToSavedPhotosAlbum (
                                                 moviePath, nil, nil, nil);
        }
    }
    */
    
}


@end
