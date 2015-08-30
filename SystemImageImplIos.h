//
//  SystemImageImplIos.h
//  Color-Fy
//
//  Created by Admin on 10/1/13.
//  Copyright (c) 2013 Virtuoso Engine. All rights reserved.
//

#ifndef Color_Fy_SystemImageImplIos_h
#define Color_Fy_SystemImageImplIos_h

#include "SystemImage.h"
#import <UIKit/UIKit.h>


///IOS implementation of data struct
struct SystemImage::SystemImageData
{
    UIImage* data;
    
    SystemImageData(UIImage* in):data(in)
    {
    }
};


class SystemImageIOS: public SystemImage
{
public:
    
    SystemImageIOS(UIImage* iosImage)
    {
        if(iosImage && CGImageGetBitsPerComponent(iosImage.CGImage))
        {
            channels=   CGImageGetBitsPerPixel (iosImage.CGImage)/ CGImageGetBitsPerComponent(iosImage.CGImage);
        }
        else
        {
            channels=0;
        }
        
        data->data = iosImage;
    }
};

#endif
