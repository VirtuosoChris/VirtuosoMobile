//
//  GLESContext.cpp
//  SingleViewTest
//
//  Created by Admin on 7/24/13.
//  Copyright (c) 2013 Virtuoso Engine. All rights reserved.
//

#include "GLESContext.h"
#import "QuartzCore/CAEAGLLayer.h"

#import <OpenGLES/ES2/gl.h>

class GLESContext::IMPLEMENTATION{
    
    
public:
    
    EAGLContext* context;
    
    
    IMPLEMENTATION(EAGLContext* contextIn):context(contextIn){
        if(context ==nil) {
            std::cout<<"PROBLEM HERE: "<<std::endl;
        }
        
    }
    
    IMPLEMENTATION():context(nil){
        
    }
    
    
    operator bool (){
        
        return context;
        
    }
    
    
};



bool GLESContext::bind(){
    
    if(currentContextThread()){
        
        glFlush();// dispatch any commands from the current context first
    }
    
    return [EAGLContext setCurrentContext: pImpl->context ];
    
}



///null context
GLESContext::GLESContext(): pImpl(new IMPLEMENTATION() ){
    
    
}


//static class method.
GLESContext GLESContext::currentContextThread(){
    
    GLESContext rval;
    
    rval.pImpl->context = [EAGLContext currentContext];
    
    return rval;
}


GLESContext::operator bool()const{
    
    return pImpl.get() && (*pImpl);

}



GLESContext::GLESContext(GLVersion version)
:pImpl(
       new IMPLEMENTATION(
                          [[EAGLContext alloc] initWithAPI: version == GL_ES_2_0 ? kEAGLRenderingAPIOpenGLES2 : kEAGLRenderingAPIOpenGLES1]
                          )
       )
{
}


GLESContext::GLVersion GLESContext::supportedVersion()const{
    
    if(!pImpl || !(*pImpl)){
        
        throw std::runtime_error("Context is null: Can't get supported GL Version");
    }
    
    if(pImpl->context.API == kEAGLRenderingAPIOpenGLES1){

        return GL_ES_1_1;
        
    }else if(pImpl->context.API == kEAGLRenderingAPIOpenGLES2){
        
        return GL_ES_2_0;
    }
    
    throw std::runtime_error("GLES context version unknown.  This error should never occur");
    
}



GLESContext GLESContext::createContextShareResources(const GLESContext& contextIn){
    
    GLESContext rval;
    
    rval.pImpl->context = [[EAGLContext alloc] initWithAPI:[contextIn.pImpl->context API] sharegroup: [contextIn.pImpl->context sharegroup]];
    
    return rval;
    
}

bool GLESContext::present()const{
    return [pImpl->context presentRenderbuffer: (NSUInteger)GL_RENDERBUFFER];
    
}


