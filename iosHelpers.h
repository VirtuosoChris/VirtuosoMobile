//
//  iosHelpers.h
//  Color-Fy
//
//  Created by Admin on 10/1/13.
//  Copyright (c) 2013 Virtuoso Engine. All rights reserved.
//

#ifndef Color_Fy_iosHelpers_h
#define Color_Fy_iosHelpers_h


#include <SystemImage.h>

#ifdef GL_INTEROP
//#include <GLTexture.h>
#endif

#include <SystemImage.h>

#include <UIKit/UIKit.h>


bool instagramImage(UIImage* img, NSString* caption = nil);

UIImage* toUIImage(const SystemImage& sysImg);


UIImage* resizedCopyGauss(SystemImage img, float scale);
UIImage* resizedCopyGauss(UIImage* img, float scale);
UIImage* resizedCopy(UIImage* img, unsigned int width, unsigned int height);

std::string getWorkingDirectory();

bool deleteFileOrDirectory(NSString* file, std::ostream* osp);

bool deleteFileOrDirectory(const char* str, std::ostream* spr);

bool deleteFileOrDirectory(const std::string& str, std::ostream* spr);

NSString* appDocumentsPath();

bool fileExistsAtPath(NSString* path);

bool directoryExistsAtPath(NSString* path);

bool createDirectory(NSString* path, std::ostream* osp);

bool setWorkingDirectory(NSString* str);

bool setWorkingDirectory(const char* str);

bool setWorkingDirectory(const std::string& str);

inline std::string NSStringToString(NSString* str){
    
    return std::string([str UTF8String]);
    
}

inline UIColor* imageToUIColor(UIImage* img){
    
    return [UIColor colorWithPatternImage:img];
}

#ifndef APP_EXTENSION
UIViewController* topMostController();
#endif

#ifndef APP_EXTENSION ///\todo ?
inline float screenScale()
{
    UIScreen* screen= [UIScreen mainScreen];
    
    ///\todo test on a 6+ device
    if([screen respondsToSelector:@selector(nativeScale)])
    {
        return [screen nativeScale];
    }
    else
    {
        return [screen scale];
    }
}
#endif

struct DeviceVersion
{
    
    enum DeviceType {IPHONE, IPOD, IPAD, IPHONE_SIMULATOR, IPAD_SIMULATOR, UNKNOWN};
    
    DeviceType device;
    unsigned int version_major;
    unsigned int version_minor;
    
    NSString* name;
    
};


DeviceVersion getDeviceVersion();

inline bool isIpad(){
    return (getDeviceVersion().device == DeviceVersion::IPAD) || (getDeviceVersion().device == DeviceVersion::IPAD_SIMULATOR);
}


std::ostream& operator<<(std::ostream& str, const DeviceVersion& version);


#ifdef GL_INTEROP
inline SystemImage framebufferToSystemImage(unsigned int width, unsigned int height, unsigned int xpos =0, unsigned int ypos = 0)
{
    LDRImage::index_type dims= {{ (std::size_t)4,(std::size_t)width, (std::size_t)height}};
    
    LDRImage img(dims);
    
    glReadPixels(xpos, ypos, width, height, GL_RGBA, GL_UNSIGNED_BYTE, img.dataPtr());
    
    return SystemImage(img.dataPtr(), width, height, 4);
}


SystemImage textureToSystemImage(const GLTexture& tex);

inline void systemImageToSubTexture(GLTexture& tex, const SystemImage& imgIn, bool flipVert = false, bool flipHoriz = false)
{   ///\todo error bounds checks here
    CGImageRef cgImg = toUIImage(imgIn).CGImage;
    
    size_t width = CGImageGetWidth(cgImg);
    size_t height = CGImageGetHeight(cgImg);
    
    GLubyte * pixels = (GLubyte *) malloc(width*height * 4);
    
    CGContextRef spriteContext = CGBitmapContextCreate(pixels, width, height, 8, width*4,
                                                       CGImageGetColorSpace(cgImg), kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), cgImg);
    
    CGContextRelease(spriteContext);
    
    LDRImage::index_type arr= {4,width,height};
    
    auto pixPtr = std::shared_ptr<unsigned char>(pixels,[](unsigned char*){});
    
    LDRImage img(pixPtr, arr);
    
    if(flipHoriz)flipHorizontal(img);
    if(flipVert)flipVertical(img);
    
    auto numElements = img.numElements();
    auto ptr = img.dataPtr();
    if(imgIn.channels==4)
    {
        //unpremultiply
        for(unsigned int i =0; i <numElements>>2; i++)
        {
            for(unsigned int ch = 0; ch < 3; ch++)
            {
                ptr[(i<<2) + ch] =255 *  (float) ptr[(i<<2) + ch] / (float)ptr[(i<<2 )+ 3];
            }
        }
    }
    
    glBindTexture(GL_TEXTURE_2D, tex.tex);
    
    GLsizei xoff = 0u;
    auto yoff = 0u;
    
    ///\todo do this properly
    
    glTexSubImage2D(GL_TEXTURE_2D, 0, xoff, yoff, width, height, GL_RGBA, GL_UNSIGNED_BYTE, ptr);
    
    free(pixels);

    if(auto err = glGetError() != GL_NO_ERROR)
    {
        std::cout<<err<<std::endl;
    }
}


inline GLTexture systemImageToTexture(const SystemImage& imgIn, bool flipVert = false, bool flipHoriz = false)
{
    CGImageRef cgImg = toUIImage(imgIn).CGImage;
    
    size_t width = CGImageGetWidth(cgImg);
    size_t height = CGImageGetHeight(cgImg);
    
    GLubyte * pixels = (GLubyte *) malloc(width*height * 4);
    
    CGContextRef spriteContext = CGBitmapContextCreate(pixels, width, height, 8, width*4,
                                                       CGImageGetColorSpace(cgImg), kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), cgImg);
    
    CGContextRelease(spriteContext);

    LDRImage::index_type arr= {4,width,height};

    auto pixPtr = std::shared_ptr<unsigned char>(pixels,[](unsigned char*){});
    
    LDRImage img(pixPtr, arr);
    
    if(flipHoriz)flipHorizontal(img);
    if(flipVert)flipVertical(img);
    
    auto numElements = img.numElements();
    auto ptr = img.dataPtr();
    if(imgIn.channels==4)
    {
        //unpremultiply
        for(unsigned int i =0; i <numElements>>2; i++)
        {
            for(unsigned int ch = 0; ch < 3; ch++)
            {
                ptr[(i<<2) + ch] =255 *  (float) ptr[(i<<2) + ch] / (float)ptr[(i<<2 )+ 3];
            }
        }
    }

    
    GLTexture tex(img);
    
    free(pixels);

    return tex;
}

#endif

#endif
