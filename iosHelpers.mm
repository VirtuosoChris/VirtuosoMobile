//
//  iosHelpers.mm
//  Color-Fy
//
//  Created by Admin on 10/1/13.
//  Copyright (c) 2013 Virtuoso Engine. All rights reserved.
//

#include <stdio.h>
#include "SystemImage.h"
#include "iosHelpers.h"
#include "SystemImageImplIos.h"
#include <sys/types.h>
#include <sys/sysctl.h>

UIImage* toUIImage(const SystemImage& sysImg)
{
    return sysImg.getData().data;
}

#ifdef GL_INTEROP
SystemImage textureToSystemImage(const GLTexture& tex)
{
    //there's no getTexImage so we'll just render to the screen and do a readpixels
    static GLuint framebuffer=0;
    
    if(!framebuffer)
    {
        glGenFramebuffers(1, &framebuffer);
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex.tex ,0);
    
    SystemImage result =  framebufferToSystemImage(tex.width, tex.height);
    
    ///\todo hack
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    
    return result;
}
#endif

#ifndef APP_EXTENSION
UIViewController* topMostController()
{
    UIWindow *topWindow = [[UIApplication sharedApplication].delegate window];
    UIViewController *topController = topWindow.rootViewController;
    
    while (topController.presentedViewController)
    {
        topController = topController.presentedViewController;
    }
    
    return topController;
}
#endif


UIImage* resizedCopyGauss(SystemImage img, float scale)
{
    if(scale >= 1.0)
    {
        float newW = scale * img.getWidth();
        float newH = scale * img.getHeight();
        return resizedCopy(toUIImage(img), newW, newH);
    }
    
    const float gaussRad = .50f / scale;
    
    ImageProcessingResult gaussResult = gaussianBlur(affineTile(img), gaussRad);
    
    float swapW = img.getWidth();
    float swapH = img.getHeight();
    
    switch(toUIImage(img).imageOrientation)
    {
        case UIImageOrientationUp:
            break;
            
        case UIImageOrientationDown:   // 180 deg rotation
            break;
        case UIImageOrientationLeft:    // 90 deg CW
            std::swap(swapW,swapH);
            break;
        case UIImageOrientationRight:   // 90 deg CCW
            std::swap(swapW,swapH);
            break;
        case UIImageOrientationUpMirrored:    // as above but image mirrored along other axis. horizontal flip
            break;
        case UIImageOrientationDownMirrored:  // horizontal flip
            break;
        case UIImageOrientationLeftMirrored:   // vertical flip
            std::swap(swapW,swapH);
            break;
        case UIImageOrientationRightMirrored: // vertical flip
            std::swap(swapW,swapH);
            break;
        default:
            break;
    }
    
    SystemImage gauss = crop(gaussResult, 0,0,swapW,swapH);
    
    UIImage* gaussRot = [UIImage imageWithCGImage: toUIImage(gauss).CGImage scale:1.0f orientation:
                         toUIImage(img).imageOrientation
                         ];
    
    return resizedCopy(gaussRot, scale * img.getWidth(), scale * img.getHeight());
}

UIImage* resizedCopyGauss(UIImage* img, float scale)
{
    return resizedCopyGauss(SystemImageIOS(img), scale);
}

UIImage* resizedCopy(UIImage* img, unsigned int width, unsigned int height)
{
    CGSize destinationSize = CGSizeMake( (CGFloat)width, (CGFloat)height);
    
    UIGraphicsBeginImageContext(destinationSize);
    [img drawInRect:CGRectMake(0,0,destinationSize.width,destinationSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}



std::string getWorkingDirectory()
{
    std::stringstream sstr;
    sstr<<[[NSFileManager defaultManager] currentDirectoryPath];
    return sstr.str();
}


bool deleteFileOrDirectory(NSString* file, std::ostream* osp)
{
    NSFileManager* manager =     [NSFileManager defaultManager];
    
    if(! [manager isDeletableFileAtPath:file])return false;
    
    NSError* err;
    
    bool success =  [manager removeItemAtPath:file error:&err];
    
    if(!success && osp)
    {
        std::ostream& os = *osp;
        os<<"Error deleting file : "<<[err domain]<<std::endl;
    }
    
    return success;
}


bool deleteFileOrDirectory(const char* str, std::ostream* spr)
{
    return deleteFileOrDirectory( [NSString stringWithFormat:@"%s", str], spr);
}

bool deleteFileOrDirectory(const std::string& str, std::ostream* spr)
{
    return deleteFileOrDirectory(str.c_str(), spr);
}


NSString* appDocumentsPath()
{
    NSArray *path =
	NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
	return [path objectAtIndex:0];
}



bool fileExistsAtPath(NSString* path)
{
    BOOL isDir=NO;
    
    NSFileManager *NSFm= [NSFileManager defaultManager];
    
    BOOL exists = [NSFm fileExistsAtPath:path isDirectory:&isDir];
    
    return exists && !(isDir);
}


bool directoryExistsAtPath(NSString* path)
{
    BOOL isDir=NO;
    
    NSFileManager *NSFm= [NSFileManager defaultManager];
    
    BOOL exists = [NSFm fileExistsAtPath:path isDirectory:&isDir];
    
    return exists && (isDir);
}


bool createDirectory(NSString* path, std::ostream* osp)
{
    NSFileManager *NSFm= [NSFileManager defaultManager];
    
    NSError* error;
    
    bool success = [NSFm createDirectoryAtPath:path
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:&error
                    ];
    
    if(!success)
    {
        if(osp)
        {
            std::ostream& os = *osp;
            os<<"Error Creating Directory: "<<[error domain]<<std::endl;
        }
    }

    return success;
}


bool setWorkingDirectory(NSString* str)
{
    return [[NSFileManager defaultManager] changeCurrentDirectoryPath:str];
}


bool setWorkingDirectory(const char* str)
{
    return setWorkingDirectory([NSString stringWithFormat:@"%s", str]);
}

bool setWorkingDirectory(const std::string& str)
{
    return setWorkingDirectory(str.c_str());
}


std::string DeviceVersionToString(const DeviceVersion::DeviceType& type)
{
    switch(type)
    {
        case DeviceVersion::IPHONE : return "iPhone";
        case DeviceVersion::IPOD : return "iPod Touch";
        case DeviceVersion::IPAD : return "iPad";
        case DeviceVersion::IPHONE_SIMULATOR: return "iPhone Simulator";
        case DeviceVersion::IPAD_SIMULATOR : return "iPad Simulator";
            
        default : return "unknown";
    }
}


std::ostream& operator<<(std::ostream& str, const DeviceVersion& version)
{
    str<<DeviceVersionToString(version.device)<<" "<<version.version_major<<"."<<version.version_minor;
    
    if(version.name)
    {
        str<<" AKA "<<NSStringToString(version.name);
    }
    
    return str;
}


DeviceVersion getDeviceVersion()
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *model = (char*)malloc(size);
    sysctlbyname("hw.machine", model, &size, NULL, 0);
    NSString *hardware = [NSString stringWithCString:model encoding:NSUTF8StringEncoding];
    free(model);
    
    DeviceVersion tmp;
    
    NSRange separatorRange = [hardware rangeOfString:@","];
    
    bool parseVersion = !(separatorRange.location == NSNotFound);
    
    NSUInteger nameEnd;

    NSRange range = [hardware rangeOfString:@"iPhone"];
    
    if(range.location != NSNotFound)
    {
        //we know it's an iphone
        tmp.device = DeviceVersion::IPHONE;
        
        if(!parseVersion)
        {
            tmp.name = @"Unknown iPhone Device";
        }
        
        
        NSUInteger  nameStart = range.location;
        nameEnd = nameStart + range.length;
        
    }
    else if((range = [hardware rangeOfString:@"iPad"]).location != NSNotFound)
    {
        //we know it's an ipad
        tmp.device = DeviceVersion::IPAD;
        
        if(!parseVersion){
            
            tmp.name = @"Unknown iPad Device";
            
        }
        
        
       NSUInteger  nameStart = range.location;
        nameEnd = nameStart + range.length;
    }
    else if((range = [hardware rangeOfString:@"iPod"]).location != NSNotFound)
    {
        
        //we know it's an ipod touch
        tmp.device = DeviceVersion::IPOD;
        
        if(!parseVersion)
        {
            tmp.name = @"Unknown iPod Device";
        }
        
        
       NSUInteger nameStart = range.location;
        nameEnd = nameStart + range.length;

    }
    else
    {
        if ([hardware isEqualToString:@"i386"] || [hardware isEqualToString:@"x86_64"])
        {
            
            tmp.name= [UIDevice currentDevice].model;//@"Simulator";
            
            if([tmp.name isEqualToString:@"iPad Simulator"])
            {
                
                tmp.device = DeviceVersion::IPAD_SIMULATOR;
                
            }
            else if([tmp.name isEqualToString:@"iPhone Simulator"])
            {
                
                tmp.device = DeviceVersion::IPHONE_SIMULATOR;
            
            }
            else
            {
                tmp.device = DeviceVersion::UNKNOWN;
            }
        }
        else
        {
            tmp.name=nil; //unknown
            tmp.device = DeviceVersion::UNKNOWN;
        }
        
        return tmp;
    }
    
    
    
    //read from the first digit after the name to the comma
    NSString* majorString = [hardware substringWithRange:NSMakeRange(nameEnd, separatorRange.location - nameEnd)];
    
    //read from after the comma to the end
    NSString* minorString = [hardware substringWithRange:NSMakeRange(separatorRange.location+1,
                                                                     hardware.length - (separatorRange.location+1)
                                                                     )];
    
    
    

    
    if(parseVersion)
    {
        
        NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        NSNumber * majorNumber = [f numberFromString:majorString];
        NSNumber * minorNumber = [f numberFromString:minorString];
    
        if(majorNumber)
        {
            tmp.version_major = [majorNumber intValue];
        }else
        {
            tmp.name = @"Unknown Device";
        }
    
        if(minorNumber)
        {
            tmp.version_minor = [minorNumber intValue];
        }else
        {
            tmp.name = @"Unknown Device";
        }
    }
    
    
    if ([hardware isEqualToString:@"iPhone1,1"]) tmp.name= @"iPhone 2G";
    if ([hardware isEqualToString:@"iPhone1,2"]) tmp.name= @"iPhone 3G";
    if ([hardware isEqualToString:@"iPhone2,1"]) tmp.name= @"iPhone 3GS";
    if ([hardware isEqualToString:@"iPhone3,1"]) tmp.name= @"iPhone 4";
    if ([hardware isEqualToString:@"iPhone3,2"]) tmp.name= @"iPhone 4";
    if ([hardware isEqualToString:@"iPhone3,3"]) tmp.name= @"iPhone 4 (CDMA)";
    if ([hardware isEqualToString:@"iPhone4,1"]) tmp.name= @"iPhone 4S";
    if ([hardware isEqualToString:@"iPhone5,1"]) tmp.name= @"iPhone 5";
    if ([hardware isEqualToString:@"iPhone5,2"]) tmp.name= @"iPhone 5 (GSM+CDMA)";
    
    if ([hardware isEqualToString:@"iPod1,1"]) tmp.name= @"iPod Touch (1 Gen)";
    if ([hardware isEqualToString:@"iPod2,1"]) tmp.name= @"iPod Touch (2 Gen)";
    if ([hardware isEqualToString:@"iPod3,1"]) tmp.name= @"iPod Touch (3 Gen)";
    if ([hardware isEqualToString:@"iPod4,1"]) tmp.name= @"iPod Touch (4 Gen)";
    if ([hardware isEqualToString:@"iPod5,1"]) tmp.name= @"iPod Touch (5 Gen)";
    
    if ([hardware isEqualToString:@"iPad1,1"]) tmp.name= @"iPad";
    if ([hardware isEqualToString:@"iPad1,2"]) tmp.name= @"iPad 3G";
    if ([hardware isEqualToString:@"iPad2,1"]) tmp.name= @"iPad 2 (WiFi)";
    if ([hardware isEqualToString:@"iPad2,2"]) tmp.name= @"iPad 2";
    if ([hardware isEqualToString:@"iPad2,3"]) tmp.name= @"iPad 2 (CDMA)";
    if ([hardware isEqualToString:@"iPad2,4"]) tmp.name= @"iPad 2";
    if ([hardware isEqualToString:@"iPad2,5"]) tmp.name= @"iPad Mini (WiFi)";
    if ([hardware isEqualToString:@"iPad2,6"]) tmp.name= @"iPad Mini";
    if ([hardware isEqualToString:@"iPad2,7"]) tmp.name= @"iPad Mini (GSM+CDMA)";
    if ([hardware isEqualToString:@"iPad3,1"]) tmp.name= @"iPad 3 (WiFi)";
    if ([hardware isEqualToString:@"iPad3,2"]) tmp.name= @"iPad 3 (GSM+CDMA)";
    if ([hardware isEqualToString:@"iPad3,3"]) tmp.name= @"iPad 3";
    if ([hardware isEqualToString:@"iPad3,4"]) tmp.name= @"iPad 4 (WiFi)";
    if ([hardware isEqualToString:@"iPad3,5"]) tmp.name= @"iPad 4";
    if ([hardware isEqualToString:@"iPad3,6"]) tmp.name= @"iPad 4 (GSM+CDMA)";

    return tmp;    
}


