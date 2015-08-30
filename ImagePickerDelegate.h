//
//  CameraViewController.h
//  HelloWorld
//
//  Created by Admin on 7/1/13.
//  Copyright (c) 2013 Virtuoso Engine. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <functional>
#include "SystemImage.h"
#import <UIKit/UIImagePickerController.h>


@interface ImagePickerDelegate : NSObject <UIImagePickerControllerDelegate , UINavigationControllerDelegate>

    
    @property std::function<void (SystemImage)  > onFinish;
    

@end
