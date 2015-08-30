//
//  GLView.m
//  SingleViewTest
//
//  Created by Admin on 7/24/13.
//  Copyright (c) 2013 Virtuoso Engine. All rights reserved.
//

#import "GLViewIOS.h"
#include <iostream>
#include <iosHelpers.h>
#import <OpenGLES/ES2/gl.h>

@implementation GLViewIOS


///set will contain UITouch objects
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
 
    UITouch* touch = (UITouch*)[touches anyObject];
    
    CGPoint pt = [touch locationInView:self];
    
    float normX = pt.x  / touch.view.frame.size.width;
    float normY = 1.0f - (pt.y  / touch.view.frame.size.height);

    if(!inputHandler.empty())
    {
        inputHandler.top().touchBegin(normX,normY);
    }
}


///set will contain UITouch objects
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    UITouch* touch = (UITouch*)[touches anyObject];
    
    CGPoint pt = [touch locationInView:self];
    
    float normX = pt.x  / touch.view.frame.size.width;
    float normY = 1.0f - (pt.y  / touch.view.frame.size.height);
    
    if(!inputHandler.empty())
    {
        inputHandler.top().touchMove(normX,normY);
    }
}


///set will contain UITouch objects
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    [super touchesEnded:touches withEvent:event];
    
    UITouch* touch = (UITouch*)[touches anyObject];
    
    CGPoint pt = [touch locationInView:self];
    
    float normX = pt.x  / touch.view.frame.size.width;
    float normY = 1.0f - (pt.y  / touch.view.frame.size.height);
    
    if(!inputHandler.empty())
    {
        inputHandler.top().touchEnd(normX,normY);
    }
}



- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame isOpaque:YES];
}


- (id)initWithFrame:(CGRect)frame isOpaque: (BOOL) opacity
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.contentScaleFactor = screenScale();
        
        CAEAGLLayer* layer = (CAEAGLLayer*)self.layer;
        
        layer.opaque=opacity;//gives improved performance
        
        ///\todo experiment with kEAGLColorFormatRGB565 16 bit rgb color.  not a priority really tho.  
        
        NSArray *keys = [NSArray arrayWithObjects: kEAGLDrawablePropertyColorFormat,
                         kEAGLDrawablePropertyRetainedBacking,
                         nil];
        
        NSArray *objects = [NSArray arrayWithObjects: kEAGLColorFormatRGBA8, //32 bit rgba color
                             [NSNumber   numberWithBool:NO],///\todo
                            nil];
        
        NSDictionary* propertyDict = [NSDictionary dictionaryWithObjects:objects
                                                                 forKeys:keys];
        
        layer.drawableProperties = propertyDict;
    }
    return self;
}


- (void) setOpacity: (BOOL) opacity
{
    CAEAGLLayer* layer = (CAEAGLLayer*)self.layer;
    
    layer.opaque=opacity;
}


+(GLuint) allocateMainRenderBuffer:(CAEAGLLayer*) fromLayer withContext: (EAGLContext*)context
{
    GLuint rval=0;
    
    GLint oldBuffer=0;
    
    glGetIntegerv(GL_RENDERBUFFER_BINDING, &oldBuffer);
    
    glGenRenderbuffers(1,&rval);
    glBindRenderbuffer(GL_RENDERBUFFER, rval);
    
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:nil];
    
    if(![context renderbufferStorage:GL_RENDERBUFFER fromDrawable:fromLayer])
    {
        std::cout<<"ERROR CREATING RENDERBUFFER"<<std::endl;
    }
    
    if(!context)std::cout<<"problem!!!!"<<std::endl;
    glBindRenderbuffer(GL_RENDERBUFFER, oldBuffer);
    
    return rval;
}



-(std::pair<GLint,GLint>) getRenderBufferDimensions
{
    std::pair<GLint, GLint> rval(0,0);
    
    GLint oldBuffer;
    
    glGetIntegerv(GL_RENDERBUFFER_BINDING, &oldBuffer);
    
    glBindRenderbuffer(GL_RENDERBUFFER, _mainRenderBuffer);
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &rval.first);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &rval.second);
    
    glBindRenderbuffer(GL_RENDERBUFFER, oldBuffer);
    
    return rval;
}


+ (Class) layerClass
{
    return [CAEAGLLayer class];
}



@end
