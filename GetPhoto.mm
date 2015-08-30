
//
//  CameraTest.mm
//  HelloWorld
//
//  Created by Admin on 7/1/13.
//  Copyright (c) 2013 Virtuoso Engine. All rights reserved.
//

#include <stdio.h>

#include "GetPhoto.h"


#include <stdexcept>
#import <MobileCoreServices/UTCoreTypes.h>
#import <UIKit/UIImagePickerController.h>
#import "ImagePickerDelegate.h"
#include <iostream>
#include "PopupMessage.h"
#include <iosHelpers.h>
#import <AssetsLibrary/AssetsLibrary.h>

#include "SystemImageImplIos.h"

ImagePickerDelegate* DELEGATE;

ALAssetsLibrary* library;

///\todo APP_EXTENSION define gets rid of functionality that isn't supported in app extension

void savePhotoToAlbum (const SystemImage& imgSys, const std::string& albumName,  std::function<void (const SystemImage&)>* ctx  )
{
    if(!library)
    {
        library = [[ALAssetsLibrary alloc] init];
    }
    
    NSString* albumNameNS = [NSString stringWithFormat:@"%s", albumName.c_str()];
    
    __block ALAssetsGroup* groupToAddTo;
    
    UIImage* img = toUIImage(imgSys);///\todo why does doing this inline fail? copy ctor?
    
    //async
    [library addAssetsGroupAlbumWithName:albumNameNS
                             resultBlock:^(ALAssetsGroup *group) {
                                 NSLog(@"added album:%@", albumNameNS);
                            
                                 //doesn't say that this is async
                                 [library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                                                        usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                                            
                                                            if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:albumNameNS]) {
                                                                NSLog(@"found album %@", albumNameNS);
                                                                groupToAddTo = group;
                                                                *stop = YES;
                                                            }
                                                            
                                                        }
                                                      failureBlock:^(NSError* error) {
                                                          NSLog(@"failed to enumerate albums:\nError: %@", [error localizedDescription]);
                                                      }];
                                 
                                 
                                 [library writeImageToSavedPhotosAlbum: img.CGImage
                                                          orientation :(ALAssetOrientation)[img imageOrientation]
                                                       completionBlock:
                                  
                                  ^(NSURL* assetURL, NSError* error) {
                                      
                                      if (error.code == 0) {
                                          NSLog(@"saved image completed:\nurl: %@", assetURL);
                                          
                                          // try to get the asset
                                          [library assetForURL:assetURL
                                           
                                           
                                                   resultBlock:^(ALAsset *asset) {

                                                       // assign the photo to the album
                                                       [groupToAddTo addAsset:asset];
                                                       
                                                       
                                                       NSLog(@"Added %@ to %@", [[asset defaultRepresentation] filename], albumNameNS);
                                                    
                                                       
                                                       if(ctx){
                                                           (*ctx)(SystemImageIOS(img));
                                                       }
                                                       
                                                   }
                                                  failureBlock:^(NSError* error) {
                                                      NSLog(@"failed to retrieve image asset:\nError: %@ ", [error localizedDescription]);
                                                  }];
                                      }
                                      else {
                                          NSLog(@"saved image failed.\nerror code %li\n%@", (long)error.code, [error localizedDescription]);
                                      }
                                  }
                                  
                                  ];
                                 
                             }
                            failureBlock:^(NSError *error) {
                                NSLog(@"error adding album");
                            }];
}


void savePhotoToAlbum (const SystemImage& imgSys, const std::string& albumName, const std::function<void (const SystemImage&)>& fun ){
    
    std::function<void (const SystemImage&)>* ctx = new std::function<void (const SystemImage&)>(fun); //copy in case the variable passed in goes out of scope
    
    savePhotoToAlbum(imgSys, albumName, ctx);
    
   
}


void savePhotoToAlbum (const SystemImage& imgSys, const std::string& albumName){
    
    savePhotoToAlbum(imgSys, albumName, NULL);
}


///\todo put this in an ios specific implementation
void savePhotoToAlbum(UIImage* img, const std::function<void (const SystemImage&) >& fun ){
    
    
    std::function<void (const SystemImage&)>* ctx = new std::function<void (const SystemImage&)>(fun); //copy in case the variable passed in goes out of scope
    
    if(!DELEGATE){
        DELEGATE  = [[ImagePickerDelegate alloc] init];
    }
    
    SEL sel = @selector(image:didFinishSavingWithError:contextInfo:);
    
    UIImageWriteToSavedPhotosAlbum(img, DELEGATE, sel, ctx);
    
    
    
}


void savePhotoToAlbum (const SystemImage& img, const std::function<void (const SystemImage&)>& fun ){
    
    UIImage* uimg =toUIImage(img);

    std::function<void (const SystemImage&)>* ctx = new std::function<void (const SystemImage&)>(fun);
    
    if(!DELEGATE){
        DELEGATE  = [[ImagePickerDelegate alloc] init];
    }
    
    SEL sel = @selector(image:didFinishSavingWithError:contextInfo:);
    
    UIImageWriteToSavedPhotosAlbum(uimg, DELEGATE, sel, ctx);

    
}


void savePhotoToAlbum(UIImage* img){
    
    if(!DELEGATE)
    {
        DELEGATE  = [[ImagePickerDelegate alloc] init];
    }
    
    UIImageWriteToSavedPhotosAlbum(img, DELEGATE, nil, nil);
}


void savePhotoToAlbum (const SystemImage& img)
{
    UIImage* uimg = toUIImage(img);
    
    if(!uimg){
        std::cout<<"IMAGE IS NIL"<<std::endl;
    }
    savePhotoToAlbum(uimg);
}


bool hasFrontCamera()
{
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
}


bool hasBackCamera()
{
    return  [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
}


/****  delegate object must conform to the UIImagePickerControllerDelegate and UINavigationControllerDelegate
****/

void getPicture(UIImagePickerControllerSourceType source,
                std::function<void (SystemImage)  > onFinish,
                bool allowEditing)
{
    UIImagePickerController* picker =
    [[UIImagePickerController alloc] init];
        
    
    //set the image picker to get from the camera
    picker.sourceType = source;
        
    
    NSArray* availableTypes = [UIImagePickerController availableMediaTypesForSourceType:picker.sourceType];
        
        
    NSString* desired=(NSString*)kUTTypeImage;
    
    if(![availableTypes containsObject:desired])
    {
        throw std::runtime_error("available capture modes for back camera does not include still picture");
    }
        
        
    //only use still images in the picker, no video
    picker.mediaTypes =  [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
        
    picker.allowsEditing = allowEditing;
        
    if(!DELEGATE)
    {
        DELEGATE  = [[ImagePickerDelegate alloc] init];
    }
    
    DELEGATE.onFinish=onFinish;
        
    picker.delegate =DELEGATE ;
    
#ifndef APP_EXTENSION
    
    if(topMostController())
    {
        //std::cout<<"NOT NULL"<<std::endl;
    }
    else
    {
        std::cout<<"TOPMOST IS NULL"<<std::endl;
    }
    
    [topMostController() presentViewController:picker animated:TRUE completion: nil];
    
#else
    ///\todo 
#endif
}



void getPicture(UIViewController* controllerIn,
                UIImagePickerControllerSourceType source,
                std::function<void (SystemImage)  > onFinish,
                bool allowEditing)
{
    UIImagePickerController* picker =
    [[UIImagePickerController alloc] init];
    
    
    //set the image picker to get from the camera
    picker.sourceType = source;
    
    
    NSArray* availableTypes = [UIImagePickerController availableMediaTypesForSourceType:picker.sourceType];
    
    
    NSString* desired=(NSString*)kUTTypeImage;
    
    if(![availableTypes containsObject:desired])
    {
        throw std::runtime_error("available capture modes for back camera does not include still picture");
    }
    
    
    //only use still images in the picker, no video
    picker.mediaTypes =  [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
    
    picker.allowsEditing = allowEditing;
    
    if(!DELEGATE)
    {
        DELEGATE  = [[ImagePickerDelegate alloc] init];
    }
    
    DELEGATE.onFinish=onFinish;
    
    picker.delegate =DELEGATE ;
    
    [controllerIn presentViewController:picker animated:TRUE completion: nil];
}


void getPhotoFromCamera(std::function<void (SystemImage)  > onFinish, bool allowEditing)
{
    try
    {
        if(!isCameraAvailable())
        {
            throw std::runtime_error("Camera not available");
        }
        
        getPicture(UIImagePickerControllerSourceTypeCamera, onFinish, allowEditing);
    }
    catch(const std::exception& e)
    {
#ifndef APP_EXTENSION
        popupThenException(e.what());
#endif
    }
}


void getPhotoFromLibrary(std::function<void (SystemImage)  > onFinish,
                         bool allowEditing
                         )
{
    try
    {
        if(!isPhotoLibraryAvailable())
        {
            throw std::runtime_error("Photo library not available on device");
        }
    
        //set the image picker to get from the camera
        getPicture(UIImagePickerControllerSourceTypePhotoLibrary, onFinish,  allowEditing);
    }
    catch(const std::exception& e)
    {
#ifndef APP_EXTENSION
        popupThenException(e.what());
#endif
    }
}



void getPhotoFromRecentPictures(std::function<void (SystemImage)  > onFinish, bool allowEditing)
{
    try
    {
        if(!isCameraRollAvailable())
        {
            throw std::runtime_error("Camera Roll not available on device");
        }
        
        //set the image picker to get from the camera
        getPicture(UIImagePickerControllerSourceTypeSavedPhotosAlbum, onFinish, allowEditing);
    }
    
    catch(const std::exception& e)
    {
#ifndef APP_EXTENSION
        popupThenException(e.what());
#endif
    }
}


bool isCameraRollAvailable()
{
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum] == YES? true:false;
}


bool isPhotoLibraryAvailable()
{
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] == YES? true:false;
}


bool isCameraAvailable()
{
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == YES? true:false;
}




void getPhotoFromCamera(UIViewController* controllerIn,std::function<void (SystemImage)  > onFinish, bool allowEditing)
{
    try
    {
        if(!isCameraAvailable())
        {
            throw std::runtime_error("Camera not available");
        }
        
        getPicture(controllerIn,UIImagePickerControllerSourceTypeCamera, onFinish, allowEditing);
    }
    catch(const std::exception& e)
    {
#ifndef APP_EXTENSION
        popupThenException(e.what());
#endif
    }
}


void getPhotoFromLibrary(UIViewController* controllerIn,std::function<void (SystemImage)  > onFinish,
                         bool allowEditing
                         )
{
    try
    {
        if(!isPhotoLibraryAvailable())
        {
            throw std::runtime_error("Photo library not available on device");
        }
        
        //set the image picker to get from the camera
        getPicture(controllerIn, UIImagePickerControllerSourceTypePhotoLibrary, onFinish,  allowEditing);
    }
    catch(const std::exception& e)
    {
#ifndef APP_EXTENSION
        popupThenException(e.what());
#endif
    }
}



void getPhotoFromRecentPictures(UIViewController* controllerIn, std::function<void (SystemImage)  > onFinish, bool allowEditing)
{
    try
    {
        if(!isCameraRollAvailable())
        {
            throw std::runtime_error("Camera Roll not available on device");
        }
        
        //set the image picker to get from the camera
        getPicture(controllerIn, UIImagePickerControllerSourceTypeSavedPhotosAlbum, onFinish, allowEditing);
    }
    
    catch(const std::exception& e)
    {
#ifndef APP_EXTENSION
        popupThenException(e.what());
#endif
    }
}



