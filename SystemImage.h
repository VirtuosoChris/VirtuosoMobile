//
//  SystemImage.h
//  SingleViewTest
//
//  Created by Admin on 7/10/13.
//  Copyright (c) 2013 Virtuoso Engine. All rights reserved.
//

#ifndef SingleViewTest_SystemImage_h
#define SingleViewTest_SystemImage_h

class SystemImageType;

#include <memory>
#include <Image.h>

#define NO_BOOST
#define GL_ES_BUILD

#ifdef GL_INTEROP
#include "GLShader.h"
#include "GLTexture.h"
#include "Mesh.h"
#include "Quad.h"
#include "GpuMesh.h"
#endif

//glsl shader to output a seamless version of an image.  requires GL_REPEAT texturing mode
extern const char* makeSeamlessProg;

class ImageProcessingResult;


enum ImageRotation
{
    UP_ORIENT ,
    DOWN_ORIENT,   // 180 deg rotation
    LEFT_ORIENT,   // 90 deg CW
    RIGHT_ORIENT
};// 90 deg CCW


///SystemImage can double as a Virtuoso::MultidimensionalArray buffer type
///operators are const because system images are immutable.
class SystemImage
{

protected:
    struct SystemImageData;
    
    ///\todo error when this is a unique ptr... why???
    std::shared_ptr<SystemImageData> data; //pointer to platform specific implementation of an image
   
    
public:
    
    unsigned int channels;
    
    const  SystemImageData& getData()const{return *(data.get());}
    
    SystemImage extractRectangle(unsigned int x, unsigned int y, unsigned int width, unsigned int height)const;
    
    std::shared_ptr<unsigned char> extractDataPtr()const; ///makes a pointer to (copied) raw bytes for the whole image
    
    ///copies raw bytes for a rectangle of the image
    std::shared_ptr<unsigned char> extractRectangleData(unsigned int x, unsigned int y, unsigned int width, unsigned int height)const;

    ///save image to photo library
    void saveToLibrary()const;
    
    bool writeToFile(const std::string& filename);
    
    ///linear indexing.  read only
    unsigned char operator[](unsigned int idx)const;
    
    ///array indexing.  read only
    unsigned char operator()(unsigned int x, unsigned int y, unsigned int channel)const;
    
    ///populates an LDRImage with the arraybuffer buffer type and returns it.  in essence we are extracing the raw data
    LDRImage rawImage()const;
    
    unsigned int getWidth()const;
    
    unsigned int getHeight()const;
    
    SystemImage();
    
    SystemImage(const std::string& file);
    SystemImage( const unsigned char* dataIn, unsigned int imgWidth, unsigned int imgHeight, unsigned int channels=4u);
    SystemImage(const ImageProcessingResult& result);
    
    SystemImage(const SystemImage& sysIn);
    SystemImage& operator=(const SystemImage& imgIn);
    
    
    operator bool()const;
    
    SystemImage operator=(const LDRImage& ldrImage);

    SystemImage& operator=(const ImageProcessingResult& result);
    
    
    
};




class ImageProcessingResultIMPL;


class ImageProcessingResult
{
    
public:
    
    std::shared_ptr<ImageProcessingResultIMPL> impl;
   
    typedef      std::shared_ptr<ImageProcessingResultIMPL> ImplPtr ;
   
    ImageProcessingResult(  ImplPtr implIn ):impl(implIn)
    {
        if(!impl.get())
        {
        }
    }
    
    ImageProcessingResult():impl(NULL)
    {
    }
    
    void print();
};




///makes a copy of a systemimage that is resized to width, height
SystemImage resizedCopy(const SystemImage& sysImg, unsigned int width, unsigned int height);


LDRImage toLDRImage(const SystemImage& inImg);

ImageProcessingResult conv3x3(const SystemImage& img, float matrix[9]);
ImageProcessingResult conv3x3(const ImageProcessingResult& img, float matrix[9]);

ImageProcessingResult sobelHorizontal(const SystemImage& img);
ImageProcessingResult sobelHorizontal(const ImageProcessingResult& img);

ImageProcessingResult sobelVertical(const SystemImage& img);
ImageProcessingResult sobelVertical(const ImageProcessingResult& img);

ImageProcessingResult highpassFilter(const SystemImage& img, double sigma);

ImageProcessingResult highpassFilter(const ImageProcessingResult& img, double radius);

///\todo result version
ImageProcessingResult UnsharpMask(SystemImage& img, double radius=2.5, double intensity=.5);

ImageProcessingResult colorControl(ImageProcessingResult& img, double saturation, double brightness, double contrast);
ImageProcessingResult colorControl(SystemImage& img, double saturation, double brightness, double contrast);

ImageProcessingResult noiseReduction(ImageProcessingResult& img, double thresh=.02, double sharpness=.4);

ImageProcessingResult gaussianBlur(const ImageProcessingResult& img, double radius);

ImageProcessingResult gaussianBlur(const SystemImage& img, double radius);

ImageProcessingResult UnsharpMask(ImageProcessingResult& img, double radius, double intensity);

ImageProcessingResult colorMap(const SystemImage& filteredImage, const SystemImage& LUT);

ImageProcessingResult maximumComponent(const ImageProcessingResult& img);
ImageProcessingResult maximumComponent(const SystemImage& img);

ImageProcessingResult sharpenLuminance(const SystemImage& img, double sharpness);

ImageProcessingResult negative(const SystemImage& img);

ImageProcessingResult affineClamp(const SystemImage& img);

///\todo interface is a little unwieldly?
ImageProcessingResult affineTile(const SystemImage& img, float a, float b, float c, float d, float tx, float ty);

ImageProcessingResult affineTile(const SystemImage& img);


ImageProcessingResult affineTransform(const SystemImage& img,float a, float b, float c, float d, float tx, float ty);

ImageProcessingResult crop(const ImageProcessingResult& img, float locX, float locY, float sizeX, float sizeY);
ImageProcessingResult crop(const SystemImage& img, float locX, float locY, float sizeX, float sizeY);

ImageProcessingResult affineTransform(const ImageProcessingResult& img,float a, float b, float c, float d, float tx, float ty);


ImageProcessingResult highlightShadowAdjust(const SystemImage& img, float highlight = .30f, float shadow=.50);

ImageProcessingResult highlightShadowAdjust(const ImageProcessingResult& img, float highlight=.30f, float shadow=.50f);

ImageProcessingResult highpassFilter(const ImageProcessingResult& img, double radius1, double radius2);

ImageProcessingResult differenceABSImage(const ImageProcessingResult& a, const ImageProcessingResult& b);

ImageProcessingResult minimumComposite(const ImageProcessingResult& a, const ImageProcessingResult& b);


///\todo other impl
ImageProcessingResult pixellate(const SystemImage& img);


#ifndef APP_EXTENSION
#ifdef GL_INTEROP
SystemImage makeImageSeamless(const GLTexture& texIn);
SystemImage makeImageSeamless(const SystemImage& imgIn);
#endif
#endif

#endif
