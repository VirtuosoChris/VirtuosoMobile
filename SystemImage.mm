//
//  SystemImage.mm
//  SingleViewTest
//
//  Created by Admin on 7/13/13.
//  Copyright (c) 2013 Virtuoso Engine. All rights reserved.
//

///ios implementation of system image

#include <stdio.h>

#include <SystemImage.h>

#include <memory>

#include <Image.h>

#include "SystemImageImplIos.h"

#include <iosHelpers.h>

#include <iostream>

#include <GLESContext.h>

#import <CoreImage/CoreImage.h>


CIContext *coreImageContext=nil;

void releaseData (
                            void *info,
                            const void *data,
                            size_t size
                            )
{
    delete[] (unsigned char*)data;
}



class ImageProcessingResultIMPL
{
public:
    
    CIImage* result;
    
    ImageProcessingResultIMPL(CIImage* resultIn):result(resultIn)
    {
        if(!resultIn)
        {
            std::cout<<"PASSING IN CIIMAGE RESULT AS NIL"<<std::endl;
        }
    }
    
    void print()
    {
        std::cout<<(size_t)result<<std::endl;
    }
};


class ImageProcessingResultIOS : public ImageProcessingResult
{
    public:
    
    ImageProcessingResultIOS(CIImage* result) :
        ImageProcessingResult(ImageProcessingResult::ImplPtr(new ImageProcessingResultIMPL(result) ))
    {
    }
    
    
};


///\todo hack
class GLESContext::IMPLEMENTATION
{
public:
    
    EAGLContext* context;
    
    IMPLEMENTATION(EAGLContext* contextIn):context(contextIn)
    {
    }
    
    IMPLEMENTATION():context(nil)
    {
    }
    
    operator bool ()
    {
        return context;
    }
};


void ImageProcessingResult::print()
{
    impl->print();
}


SystemImage::SystemImage(const SystemImage& sysIn):
data(sysIn.data), channels(sysIn.channels)
{
    if(!toUIImage(*this))
    {
    }
}


SystemImage& SystemImage::operator=(const SystemImage& imgIn)
{
    data = imgIn.data;
    
    channels=imgIn.channels;
    
    if(!toUIImage(*this))
    {
        throw std::runtime_error("SJDFHSKJDFH");
    }
    
    return *this;
}




///forces an image processing result to render, producing a SystemImage (UIImage on IOS)
SystemImage& SystemImage::operator=(const ImageProcessingResult& result)
{
    CGRect extent = [result.impl->result extent];
    
    CGImageRef cgImage = [coreImageContext createCGImage:result.impl->result fromRect:extent];
    
    data.reset(new SystemImage::SystemImageData([UIImage imageWithCGImage:cgImage]));
    
    CGImageRelease(cgImage);
    
    UIImage* img =  this->data->data ;
    
    channels = (unsigned int)(CGImageGetBitsPerPixel (img.CGImage)/ CGImageGetBitsPerComponent(img.CGImage));
    
    return *this;///\todo make sure all channels are initialized.  better yet, just calculate.
}


SystemImage::SystemImage(const ImageProcessingResult& result)
{
    CGRect extent = [result.impl->result extent];
    
    CGImageRef cgImage = [coreImageContext createCGImage:result.impl->result fromRect:extent];   // 5
    
    ///\todo data initialized, shared ptr on assign?
    
    this->data.reset(new SystemImage::SystemImageData([UIImage imageWithCGImage:cgImage]));
    
    CGImageRelease(cgImage);
    
    UIImage* img =  this->data->data ;
    
    channels = (unsigned int )(CGImageGetBitsPerPixel (img.CGImage)/ CGImageGetBitsPerComponent(img.CGImage));
}


///\todo make sure EVERY image manipulation function preserves channel count
//extracts a rectangle of a systemImage as another systemImage
SystemImage SystemImage::extractRectangle(unsigned int x, unsigned int y, unsigned int widthIn, unsigned int heightIn) const
{
    UIImage* original = toUIImage(*this);
    
    CGColorSpaceRef colorSpaceRef;
    CGBitmapInfo info ;

    switch(channels)
    {
        case 3:
            info= kCGImageAlphaNone|kCGBitmapByteOrderDefault;//kCGBitmapByteOrder32Big | kCGImageAlphaNone;
            colorSpaceRef  = CGColorSpaceCreateDeviceRGB();
            break;
        case 4:
            info= kCGImageAlphaPremultipliedLast
            |kCGBitmapByteOrderDefault;//info= kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
            colorSpaceRef  = CGColorSpaceCreateDeviceRGB();
            break;
        case 1:
            info= kCGImageAlphaNone|kCGBitmapByteOrderDefault;//  info= kCGBitmapByteOrder32Big | kCGImageAlphaOnly;
            colorSpaceRef = CGColorSpaceCreateDeviceGray();
            break;
        default:
            throw std::runtime_error("Unsupported number of color channels extract rectangle");
    }
    
    CGContextRef cgcontext = CGBitmapContextCreate(NULL, widthIn , heightIn , 8, 0, colorSpaceRef, info);
    
    if(!cgcontext)
    {
        throw std::runtime_error("NULL CONTEXT");
    }
    
    CGContextSetBlendMode(cgcontext, kCGBlendModeNormal);
    CGContextClearRect(cgcontext, CGRectMake(0, 0, widthIn, heightIn));
    CGContextDrawImage(cgcontext,  CGRectMake(-CGFloat(x), -CGFloat(y), x + widthIn, y + heightIn), original.CGImage);
    CGColorSpaceRelease( colorSpaceRef );
    CGImageRef cgImage = CGBitmapContextCreateImage(cgcontext);
    
    UIImage *img2 = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);///\to ok?
    
    CGContextRelease(cgcontext);
    
    return SystemImageIOS(img2);
}



SystemImage SystemImage::operator=(const LDRImage& ldrImage)
{
    const LDRImage::index_type&  dims = ldrImage.getDimensions();
    unsigned int w= dims[1], h= dims[2];
 
    return SystemImage(ldrImage.dataPtr(),w,h);
}


LDRImage toLDRImage(const SystemImage& inImg)
{
    std::shared_ptr<unsigned char> ptr =  inImg.extractRectangleData(0, 0, inImg.getWidth(), inImg.getHeight());
    
    ///\todo systemimage with not 4 channels?
    LDRImage::index_type arr = {{inImg.channels,inImg.getWidth(), inImg.getHeight()}};
    
    return MultidimensionalArray<unsigned char, 3>(ptr, arr);
}


///\todo is there a write error message too?
bool SystemImage::writeToFile(const std::string& filename)
{
    UIImage* img = toUIImage(*this);
    
    if(!img)
    {
        throw std::runtime_error("Image::Write called on incomplete image");
    }
    
    std::string extension = filename.substr(filename.length()-4, 4);
    
    NSString* path =[NSString stringWithFormat:@"%s", filename.c_str()];
    
    ///\todo more robust extension handling
    if(extension == ".png")
    {
        ///\todo hack
        CGSize destinationSize = CGSizeMake(getWidth(), getHeight());
        UIGraphicsBeginImageContext(destinationSize);
        [img drawInRect:CGRectMake(0,0,destinationSize.width,destinationSize.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        NSData *data = UIImagePNGRepresentation(newImage);
        UIGraphicsEndImageContext();
        
        if(!data)
        {
            throw std::runtime_error("Unable to convert to png");
        }
       
        NSError* error = nil;
        bool rval =  ([data writeToFile: path options:NSDataWritingAtomic error:&error]);

        if(!rval)
        {
            NSLog(@"%@",[error localizedDescription]);
        }
        return rval;
    }
    
    else if(extension == ".jpg")
    {
        NSData* data = UIImageJPEGRepresentation(img, 1.0);
        return (data && [data writeToFile:path atomically:YES]);
    }
    else
    {
        throw std::runtime_error("Unimplemented extension for image writer");
    }
    
    return false;
}


SystemImage resizedCopy(const SystemImage& sysImg, unsigned int width, unsigned int height)
{
    return SystemImageIOS(resizedCopy(toUIImage(sysImg), width, height));
}




///\todo push render on app load or new drawing
SystemImage::SystemImage( const unsigned char* dataIn, unsigned int imgWidth, unsigned int imgHeight, unsigned int channelsIn)
{
    channels = channelsIn;
    NSInteger lengthInBytes  = (imgWidth*imgHeight*channels);
    
    unsigned char* data2 = new unsigned char[lengthInBytes];
    
    //copy over
    memcpy(data2, dataIn, lengthInBytes);
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL,
                                                              data2,
                                                              lengthInBytes,
                                                              releaseData);
    
    CGColorSpaceRef colorSpaceRef;
    CGBitmapInfo info ;
    
    switch(channels)
    {
        case 3:
            info= kCGImageAlphaNone|kCGBitmapByteOrderDefault;//kCGBitmapByteOrder32Big | kCGImageAlphaNone;
            colorSpaceRef  = CGColorSpaceCreateDeviceRGB();
            break;
        case 4:
            info= kCGImageAlphaLast//kCGImageAlphaNone
            |kCGBitmapByteOrderDefault;//info= kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
            colorSpaceRef  = CGColorSpaceCreateDeviceRGB();
            break;
        case 1:
            info= kCGImageAlphaNone|kCGBitmapByteOrderDefault;//  info= kCGBitmapByteOrder32Big | kCGImageAlphaOnly;
            colorSpaceRef = CGColorSpaceCreateDeviceGray();
            break;
        default:
            throw std::runtime_error("Unsupported number of color channels system image ctor");
    }

    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGImageRef imageRef = CGImageCreate(imgWidth,
                                        imgHeight,
                                        8,
                                        channels*8,
                                        channels*imgWidth,
                                        colorSpaceRef,
                                        //bitmapInfo, //
                                        info,
                                        
                                        provider,
                                        NULL,
                                        NO,
                                        renderingIntent);
    
    CGFloat scale = 1.0;
    NSInteger widthInPoints = imgWidth;
    NSInteger heightInPoints = imgHeight;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(widthInPoints, heightInPoints), NO, scale);///\todo NO on opaque always?
    
    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
    
    // UIKit coordinate system is upside down to GL/Quartz coordinate system
    // Flip the CGImage by rendering it to the flipped bitmap context
    // The size of the destination area is measured in POINTS
    CGContextSetBlendMode(cgcontext, kCGBlendModeNormal);

    ///\todo why is this necessary?
    CGContextClearRect(cgcontext, CGRectMake(0, 0, imgWidth, imgHeight));
    
    UIImage *img2 = [UIImage imageWithCGImage:imageRef];
    
    [img2 drawInRect: CGRectMake(0, 0, imgWidth, imgHeight)];
    
    UIImage* img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    data=  std::shared_ptr<SystemImageData>(new SystemImageData(img));
    
    CGDataProviderRelease(provider);
    CGColorSpaceRelease( colorSpaceRef );
    CGImageRelease(imageRef);
    
}






SystemImage::operator bool()const{

    return data->data;
}


SystemImage::SystemImage(): data( new SystemImage::SystemImageData(nil) ){

}




void SystemImage::saveToLibrary()const{
    // Save the new image (original or edited) to the Camera Roll

    UIImageWriteToSavedPhotosAlbum (data->data, nil, nil , nil);

}

///linear indexing
  unsigned char SystemImage::operator[](unsigned int idx)const{

    unsigned int rowLengthBytes = channels * getWidth(); //12

    unsigned int tmp = idx % rowLengthBytes;

    unsigned int x = tmp / channels;

    unsigned int channel = tmp %channels;

    unsigned int y = idx / rowLengthBytes;

    return this->operator()(x,y,channel);

}

///array indexing
  unsigned char SystemImage::operator()(unsigned int x, unsigned int y, unsigned int channel)const{

    auto pixelPtr = extractRectangleData(x,y,1,1);

    return pixelPtr.get()[channel];

}


///populates an LDRImage with the arraybuffer buffer type and returns it.  in essence we are extracing the raw data
LDRImage SystemImage::rawImage()const
{
    LDRImage::index_type dimensions =  {{4, getWidth(), getHeight()}};

    auto dataPtr = extractDataPtr();

    return LDRImage(dataPtr, dimensions);
}




unsigned int SystemImage::getWidth()const{

    return data->data.size.width;
}



unsigned int SystemImage::getHeight()const{
    return data->data.size.height;
}




std::shared_ptr<unsigned char> SystemImage::extractDataPtr()const{

    return  extractRectangleData(0,0,getWidth(), getHeight());

}



std::shared_ptr<unsigned char> SystemImage::extractRectangleData(unsigned int x, unsigned int y, unsigned int width, unsigned int height)const
{
    auto numElements = (getWidth() * getHeight() * channels);
    unsigned char* ptr = new unsigned char[numElements];

    auto deleter = [](unsigned char del[])
    {
        delete[] del;
    };

    std::shared_ptr<unsigned char> rval(ptr, deleter);

    CGImageRef imageRef=  data->data.CGImage;

    CGColorSpaceRef colorSpaceRef;
    CGBitmapInfo info ;
    
    switch(channels)
    {
        case 3:
            info= kCGImageAlphaNone|kCGBitmapByteOrderDefault;//kCGBitmapByteOrder32Big | kCGImageAlphaNone;
            colorSpaceRef  = CGColorSpaceCreateDeviceRGB();
            break;
        case 4:
            info= kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault;//info= kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
            colorSpaceRef  = CGColorSpaceCreateDeviceRGB();
            break;
        case 1:
            info= kCGImageAlphaNone|kCGBitmapByteOrderDefault;//  info= kCGBitmapByteOrder32Big | kCGImageAlphaOnly;
            colorSpaceRef = CGColorSpaceCreateDeviceGray();
            break;
        default:
            std::cout<<"channels "<<channels<<std::endl;
            throw std::runtime_error("Unsupported number of color channels extract rectangle data");
    }


    CGContextRef context = CGBitmapContextCreate(ptr, width, height,
                                                 8, width*channels, colorSpaceRef,
                                                info);

    if(!context)
    {
        throw std::runtime_error("CGContextRef is null");
    }

    CGContextClearRect(context, CGRectMake(0, 0, width, height));
    
    CGContextDrawImage(context, CGRectMake(x, y, width, height), imageRef);
    CGContextRelease(context);

    CGColorSpaceRelease(colorSpaceRef);

    
    if(channels==4)
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
    
    return rval;
}




SystemImage::SystemImage(const std::string& file){

    NSString* nsFileString =  [NSString stringWithFormat:@"%s",file.c_str()];
   
    UIImage* img = [UIImage imageNamed: nsFileString];///\todo imageNamed vs imageWIthCOntents

    if(!img)
    {
        img = [UIImage imageWithContentsOfFile:nsFileString];
    }
    
    /*imageNamed: imageNamed cache’s your images and you lose control over the memory - there's no guarantee that releasing the object will actually release the image but does provide faster loading of images second time around as they are cached. If you are using Interface Builder, and setting the image in Image View Attributes, that is also equal to imageNamed method. The image will be cached immediately when the app is ran
     
     imageWithContentsOfFile : imageWithContentsOfFile does not cache images and is more memory friendly however as it does not cache images and they are loaded much slower. imageWithContentsOfFile: requires you to put the full path. I don't see why imageNamed: wouldn't be recommended, besides the fact that you can't access files outside of the application bundle.*/
    
    if(!img)
    {
        throw std::runtime_error("unable to open image");
    }
    
    data=  std::shared_ptr<SystemImageData>(new SystemImageData(img));

    channels=   CGImageGetBitsPerPixel (img.CGImage)/ CGImageGetBitsPerComponent(img.CGImage);
}


extern GLESContext context;///\todo hack

///how big should a gaussian kernel be to have a smooth falloff to zero at the edges
inline int idealGaussianKernelSize(double stdev)
{
    return static_cast<int>(std::ceil(stdev)) * 6 + 1;
}


CGImage* getCGImage(const SystemImage& img)
{
    return toUIImage(img).CGImage;
}


CIImage* getCIImage(const SystemImage& img)
{
    UIImage* iosImg = toUIImage(img);
    return  iosImg.CIImage ?  iosImg.CIImage : [[CIImage alloc] initWithCGImage:iosImg.CGImage options:nil];
}


ImageProcessingResult filterImage(CIImage *image, NSString* filterName, NSDictionary* parameters)
{
#ifdef APP_EXTENSION
   static GLESContext context = GLESContext(GLESContext::GL_ES_2_0);
#endif
    
    NSDictionary *options = @{ kCIContextWorkingColorSpace : [NSNull null] };
    
    auto myEAGLContext =     //[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];//
    context.pImpl->context;
    
    if(!myEAGLContext)
    {
        std::cout<<"EAGL CONTEXT IS NIL"<<std::endl;
    }
    
    ///\todo OSX version
    if(!coreImageContext){
        coreImageContext = [CIContext contextWithEAGLContext:myEAGLContext options:options];
    }
    
    if(!coreImageContext)
    {
        std::cout<<"CORE IMAGE CONTEXT IS NIL"<<std::endl;
    }
    
    CIFilter *filter = [CIFilter filterWithName: filterName];
    
    if(!filter)
    {
        
        throw std::runtime_error("Unable to create filter");
    }
    
    [filter setDefaults];
    
    ///\todo error checking here
    [filter setValue:image forKey:kCIInputImageKey];
    
    if(!image)
    {
    }
    
    for(id key in parameters)
    {
        [filter setValue : [parameters valueForKey: key] forKey: key ];
    }
    
    //gets result 'recipe' but doesn't calculate it until the cgImage is generated.
    //you can use this to "chain" filters together by passing this as the kCIInputImageKey of another filter
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    
    
    if(!result)
    {
        std::cout<<"RESULT IS NIL IN PROCESS FUNCTION"<<std::endl;
    }
    
    //coreImageContext = nil;
    
    //filter=nil;

    return ImageProcessingResultIOS(result);
    
    ///\todo Some Core Image filters produce images of infinite extent, such as those in the CICategoryTileEffect category. Prior to rendering, infinite images must either be cropped (CICrop filter) or you must specify a rectangle of finite dimensions for rendering the image.
}




ImageProcessingResult gaussianBlur(const SystemImage& img, double radius)
{
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble : radius], @"inputRadius", nil];
    
    CIImage* ciimage = getCIImage(img);
    if(!ciimage)
    {
    }
    
    return filterImage(ciimage, @"CIGaussianBlur", params);
}



ImageProcessingResult gaussianBlur(const ImageProcessingResult& img, double radius)
{
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble : radius], @"inputRadius", nil];
    
    return filterImage(img.impl->result, @"CIGaussianBlur", params);
}



ImageProcessingResult differenceABSImage(const SystemImage& a, const SystemImage& b)
{
    NSDictionary* params = [  NSDictionary dictionaryWithObjectsAndKeys: getCIImage(b) , @"inputBackgroundImage", nil];
    
    return filterImage(getCIImage(a), @"CIDifferenceBlendMode", params);
}


ImageProcessingResult minimumComposite(const ImageProcessingResult& a, const ImageProcessingResult& b)
{
    NSDictionary* params = [  NSDictionary dictionaryWithObjectsAndKeys: b.impl->result, @"inputBackgroundImage", nil];
    
    return filterImage(a.impl->result, @"CIMinimumCompositing", params);
}


ImageProcessingResult differenceABSImage(const ImageProcessingResult& a, const ImageProcessingResult& b)
{
    NSDictionary* params = [  NSDictionary dictionaryWithObjectsAndKeys: b.impl->result, @"inputBackgroundImage", nil];
    
    return filterImage(a.impl->result, @"CIDifferenceBlendMode", params);
}


ImageProcessingResult differenceABSImage(const SystemImage& a, const ImageProcessingResult& b)
{
    NSDictionary* params = [  NSDictionary dictionaryWithObjectsAndKeys: b.impl->result, @"inputBackgroundImage", nil];
    
    return filterImage(getCIImage(a), @"CIDifferenceBlendMode", params);
}


ImageProcessingResult differenceABSImage(const ImageProcessingResult& a, const SystemImage& b)
{
    return differenceABSImage(b,a); //this is abs, so order doesn't matter
}


ImageProcessingResult highpassFilter(const SystemImage& img, double radius)
{
    if(!toUIImage(img))
    {
    }
    
    ImageProcessingResult gauss = gaussianBlur(img, radius);
    
    return differenceABSImage(img, gauss);
}


ImageProcessingResult highpassFilter(const ImageProcessingResult& img, double radius)
{
    ImageProcessingResult gauss = gaussianBlur(img, radius);
    return differenceABSImage(img, gauss);
}


ImageProcessingResult imageDifference(ImageProcessingResult& a, ImageProcessingResult& b)
{
   return differenceABSImage(a,   minimumComposite(a, b) );
}


ImageProcessingResult highpassFilter(const ImageProcessingResult& img, double radius1, double radius2)
{
    ImageProcessingResult gauss = gaussianBlur(img, radius1);
    ImageProcessingResult gauss2 = gaussianBlur(img, radius2);
    
    return imageDifference( gauss,gauss2);
}


///\todo result version
ImageProcessingResult UnsharpMask(SystemImage& img, double radius, double intensity)
{
    NSDictionary* params = [  NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithDouble:radius],
                            @"inputRadius",
                            [NSNumber numberWithDouble:intensity],
                            @"inputIntensity",
                            nil];
    
    return filterImage(getCIImage(img), @"CIUnsharpMask", params);
}



ImageProcessingResult UnsharpMask(ImageProcessingResult& img, double radius, double intensity)
{
    NSDictionary* params = [  NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithDouble:radius],
                            @"inputRadius",
                            [NSNumber numberWithDouble:intensity],
                            @"inputIntensity",
                            nil];
    
    return filterImage(img.impl->result, @"CIUnsharpMask", params);
}




ImageProcessingResult colorControl(ImageProcessingResult& img, double saturation, double brightness, double contrast)
{
    NSDictionary* params = [  NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithDouble:saturation],
                            @"inputSaturation",
                            
                            
                            [NSNumber numberWithDouble:brightness],
                            @"inputBrightness",
                            
                            
                            [NSNumber numberWithDouble:contrast],
                            @"inputContrast",
                            
                            nil];
    
    return filterImage(img.impl->result, @"CIColorControls", params);
}


ImageProcessingResult colorControl(SystemImage& img, double saturation, double brightness, double contrast)
{
    NSDictionary* params = [  NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithDouble:saturation],
                            @"inputSaturation",
                            
                            
                            [NSNumber numberWithDouble:brightness],
                            @"inputBrightness",
                            
                            
                            [NSNumber numberWithDouble:contrast],
                            @"inputContrast",
                            
                            nil];
    
    return filterImage( getCIImage(img), @"CIColorControls", params);
}


ImageProcessingResult colorMap(const SystemImage& filteredImage, const SystemImage& LUT)
{
    NSDictionary* params = [  NSDictionary dictionaryWithObjectsAndKeys:
                         
                            getCIImage(LUT),
                            @"inputGradientImage",
                            
                            
                            nil];
    
    CIImage*  img = getCIImage( filteredImage);
    return filterImage(img , @"CIColorMap", params);
    
}


ImageProcessingResult maximumComponent(const ImageProcessingResult& img)
{

    return filterImage(img.impl->result, @"CIMaximumComponent", nil);
}


ImageProcessingResult maximumComponent(const SystemImage& img)
{
    return filterImage( getCIImage(img), @"CIMaximumComponent", nil);
}


ImageProcessingResult sharpenLuminance(const SystemImage& img, double sharpness)
{
    NSDictionary* params = [  NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithDouble:sharpness],
                            @"inputSharpness",
                            nil];
    
    return filterImage(getCIImage(img), @"CISharpenLuminance", params);
}


ImageProcessingResult negative(const SystemImage& img)
{
    return filterImage(getCIImage(img), @"CIColorInvert", nil);
}


ImageProcessingResult affineClamp(const SystemImage& img)
{
    NSDictionary* params = [  NSDictionary dictionaryWithObjectsAndKeys:
                            
                            [NSValue valueWithBytes:&CGAffineTransformIdentity
                                           objCType:@encode(CGAffineTransform)],
                            
                            @"inputTransform",
                            
                            nil];

    return filterImage(getCIImage(img), @"CIAffineClamp", params);
}


ImageProcessingResult affineTransform(const SystemImage& img,float a, float b, float c, float d, float tx, float ty)
{
    CGAffineTransform transform = CGAffineTransformMake(a, b, c, d, tx, ty);
    
    NSDictionary* params = [  NSDictionary dictionaryWithObjectsAndKeys:
                            
                            [NSValue valueWithBytes:&transform
                                           objCType:@encode(CGAffineTransform)],
                            
                            @"inputTransform",
                            nil];
    
    return filterImage(getCIImage(img), @"CIAffineTransform", params);
}


ImageProcessingResult affineTransform(const ImageProcessingResult& img,float a, float b, float c, float d, float tx, float ty)
{
    CGAffineTransform transform = CGAffineTransformMake(a, b, c, d, tx, ty);
    
    NSDictionary* params = [  NSDictionary dictionaryWithObjectsAndKeys:
                            
                            [NSValue valueWithBytes:&transform
                                           objCType:@encode(CGAffineTransform)],
                            
                            @"inputTransform",
                            
                            nil];
    
    return filterImage(img.impl->result, @"CIAffineTransform", params);
}


ImageProcessingResult affineTile(const SystemImage& img, float a, float b, float c, float d, float tx, float ty)
{
    CGAffineTransform transform = CGAffineTransformMake(a, b, c, d, tx, ty);
    
    NSDictionary* params = [  NSDictionary dictionaryWithObjectsAndKeys:
                            
                            [NSValue valueWithBytes:&transform
                                           objCType:@encode(CGAffineTransform)],
                            
                            @"inputTransform",
                            
                            nil];
    
    return filterImage(getCIImage(img), @"CIAffineTile", params);
}


ImageProcessingResult affineTile(const SystemImage& img)
{
    NSDictionary* params = [  NSDictionary dictionaryWithObjectsAndKeys:
                            
                            [NSValue valueWithBytes:&CGAffineTransformIdentity
                                           objCType:@encode(CGAffineTransform)],
                            
                            @"inputTransform",
                            
                            nil];
    
    return filterImage(getCIImage(img), @"CIAffineTile", params);
}


ImageProcessingResult crop(const ImageProcessingResult& img, float locX, float locY, float sizeX, float sizeY)
{
    NSDictionary* params = [  NSDictionary dictionaryWithObjectsAndKeys:
                            
                            [CIVector vectorWithX:locX Y:locY Z:sizeX W:sizeY ],
                            
                            @"inputRectangle",
                            
                            nil];
    
    return filterImage(img.impl->result, @"CICrop", params);
    
    
}



ImageProcessingResult pixellate(const SystemImage& img)
{
    int val = img.getWidth()  * (.01f);
    val = std::max(val,2);
    
    NSDictionary* params = [  NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:val],
                            @"inputScale",
                            nil];
    
    return filterImage(getCIImage(img), @"CIPixellate", params);
}

ImageProcessingResult crop(const SystemImage& img, float locX, float locY, float sizeX, float sizeY)
{
    NSDictionary* params = [  NSDictionary dictionaryWithObjectsAndKeys:
                            
                            [CIVector vectorWithX:locX Y:locY Z:sizeX W:sizeY ],
                            
                            @"inputRectangle",
                            
                            nil];
    
    return filterImage(getCIImage(img), @"CICrop", params);
}

ImageProcessingResult conv3x3(const SystemImage& img, const float matrix[9]){
   
    CGFloat matrix2[9];
    
    for(unsigned int i =0; i < 9; i++)
    {
        matrix2[i]=matrix[i];
    }

    NSDictionary* params = [  NSDictionary dictionaryWithObjectsAndKeys:
                        
                            [CIVector vectorWithValues:matrix2 count:9],
                            
                            @"inputWeights",
                            
                            [NSNumber numberWithDouble:0.500],
                            @"inputBias",
                            
                            nil];
    
    return filterImage(getCIImage(img), @"CIConvolution3X3", params);
}



ImageProcessingResult conv3x3(const ImageProcessingResult& img, const float matrix[9])
{
    CGFloat matrix2[9];
    
    for(unsigned int i =0; i < 9; i++)
    {
        matrix2[i]=matrix[i];
    }
    
    NSDictionary* params = [  NSDictionary dictionaryWithObjectsAndKeys:
                            
                            [CIVector vectorWithValues:matrix2 count:9],
                            
                            @"inputWeights",
                            
                            [NSNumber numberWithDouble:0.500],
                            @"inputBias",
                            
                            nil];
    
    
    return filterImage(img.impl->result, @"CIConvolution3X3", params);
}


ImageProcessingResult highlightShadowAdjust(const ImageProcessingResult& img, float highlight, float shadow)
{
    NSDictionary* params = [  NSDictionary dictionaryWithObjectsAndKeys:
                            
                            [NSNumber numberWithDouble: highlight ], @"inputHighlightAmount",
                            
                            [NSNumber numberWithDouble:shadow ], @"inputShadowAmount",
                    
                            nil];
    
    
    return filterImage(img.impl->result, @"CIHighlightShadowAdjust", params);
}


ImageProcessingResult highlightShadowAdjust(const SystemImage& img, float highlight, float shadow)
{
    NSDictionary* params = [  NSDictionary dictionaryWithObjectsAndKeys:
                            
                            [NSNumber numberWithDouble: highlight ], @"inputHighlightAmount",
                            
                            [NSNumber numberWithDouble:shadow ], @"inputShadowAmount",
                            
                            nil];
    
    return filterImage(getCIImage(img), @"CIHighlightShadowAdjust", params);
}


ImageProcessingResult sobelHorizontal(const SystemImage& img)
{
    const float kernel[9] = {-.1250f, -.250f, -.1250f, 0.0f,0.0f,0.0f, .1250f,.250f,.1250f};
    return conv3x3(img, kernel);
}


ImageProcessingResult sobelHorizontal(const ImageProcessingResult& img){
    const float kernel[9] = {-.1250f, -.250f, -.1250f, 0.0f,0.0f,0.0f, .1250f,.250f,.1250f};
    return conv3x3(img, kernel);
}

ImageProcessingResult sobelVertical(const SystemImage& img)
{
    const float kernel[9] = {.1250f,0.0f,-.1250f, .250f,0.0f,-.250f,.1250f,0.0f,-.1250f};
    return conv3x3(img, kernel);
}

ImageProcessingResult sobelVertical(const ImageProcessingResult& img)
{
    const float kernel[9] = {.1250f,0.0f,-.1250f, .250f,0.0f,-.250f,.1250f,0.0f,-.1250f};
    return conv3x3(img, kernel);
}



#ifdef GL_INTEROP
#ifndef APP_EXTENSION
SystemImage makeImageSeamless(const SystemImage& imgIn)
{
    GLTexture tex = systemImageToTexture(imgIn);
    return  makeImageSeamless(tex);
}


SystemImage makeImageSeamless(const GLTexture& texIn)
{
    static const char* passthroughVert =
    
    "precision highp float;\n"
    "\n"
    "attribute vec3 position;\n"
    "attribute vec2 texcoord;\n"
    "\n"
    "varying vec2 texcoords;\n"
    "\n"
    "void main(){\n"
    "    texcoords = texcoord;\n"
    "    gl_Position = vec4(position,1.0);\n"
    "\n"
    "}\n";
    
    ImageFormat format;
    format.width =texIn.width;
    format.height = texIn.height;
    format.channels=4;
    
    GLTexture renderTarget = GLTexture(format);
    
    static GL::GLShader seamlessProg;
    static GLuint framebuffer=0;
    static bool init = false;
    
    auto bindLocs = [](GL::GLShader& shader)
    {
        glBindAttribLocation(shader.prog, 0, "position");
        glBindAttribLocation(shader.prog, 1, "texcoord");
        glLinkProgram(shader.prog);
    };
    
    auto screenQuad = []()
    {
        static Virtuoso::Quad q;
        static Virtuoso::GPUMesh quad(q);
        
        quad.push();
    };
    
    if(!init)
    {   seamlessProg.initializeShaderSource(passthroughVert, makeSeamlessProg);
        init = true;
        glGenFramebuffers(1, &framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
        seamlessProg.bind();
        bindLocs(seamlessProg);
    }
    
    seamlessProg.bind();
    
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, renderTarget.tex ,0);
    
    glViewport(0, 0, texIn.width,texIn.height);
    glClear(GL_COLOR_BUFFER_BIT);
    glDisable(GL_BLEND);
    
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D,texIn.tex);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    seamlessProg.bind();
    seamlessProg.setTexture("tex", 0);
    
    screenQuad();
    
    glFinish();
    
    return framebufferToSystemImage(renderTarget.width, renderTarget.height);
}
#endif
#endif


///\todo way to query the extent of an image processing result... to see if its infinite.  also bool finiteExtent();
