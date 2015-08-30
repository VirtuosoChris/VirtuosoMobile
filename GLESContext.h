//
//  GLESContext.h
//  SingleViewTest
//
//  Created by Admin on 7/24/13.
//  Copyright (c) 2013 Virtuoso Engine. All rights reserved.
//

#ifndef __SingleViewTest__GLESContext__
#define __SingleViewTest__GLESContext__

#include <iostream>
#include <memory>


class GLESContext
{
protected:
    class IMPLEMENTATION;
public: 
    
    enum GLVersion{GL_ES_1_1, GL_ES_2_0};
    
    std::shared_ptr<IMPLEMENTATION> pImpl;
    
    bool bind();
    
    static GLESContext currentContextThread();
    
    static GLESContext createContextShareResources(const GLESContext& contextIn);
    
    
    GLESContext();
    
    GLESContext(GLVersion version);
    
    
    operator bool()const;
    
    GLVersion supportedVersion()const;
    
    bool present()const;
    
    
};


#endif /* defined(__SingleViewTest__GLESContext__) */
