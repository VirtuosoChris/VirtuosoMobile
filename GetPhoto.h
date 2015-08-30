//
//  CameraTest.h
//  HelloWorld
//
//  Created by Admin on 7/1/13.
//  Copyright (c) 2013 Virtuoso Engine. All rights reserved.
//

#ifndef HelloWorld_CameraTest_h
#define HelloWorld_CameraTest_h

#include "SystemImage.h"
#include <memory>
#include <functional>

///\todo ios specific stuff
#include <UIKit/UIKit.h>

bool isCameraAvailable();
bool isPhotoLibraryAvailable();
bool isCameraRollAvailable();


typedef std::shared_ptr<SystemImage> SystemImagePtr ;

void getPhotoFromCamera( std::function<void (SystemImage)  > onFinish,
                        bool allowEditing=false );


void getPhotoFromLibrary(
                         std::function<void (SystemImage)  > onFinish,
                         bool allowEditing=false
                         );


 

void getPhotoFromRecentPictures(std::function<void (SystemImage)  > onFinish,bool allowEditing=false);

bool hasFrontCamera();
bool hasBackCamera();

void savePhotoToAlbum (const SystemImage& img, const std::function<void (const SystemImage&)>& fun );

void savePhotoToAlbum (const SystemImage& img);

void savePhotoToAlbum (const SystemImage& img, const std::string& albumName, const std::function<void (const SystemImage&)>& fun );

void savePhotoToAlbum (const SystemImage& img, const std::string& albumName);


void getPhotoFromCamera(UIViewController* controllerIn,std::function<void (SystemImage)  > onFinish, bool allowEditing);

void getPhotoFromLibrary(UIViewController* controllerIn,std::function<void (SystemImage)  > onFinish,
                         bool allowEditing
                         );


void getPhotoFromRecentPictures(UIViewController* controllerIn, std::function<void (SystemImage)  > onFinish, bool allowEditing);



#endif
