//
//  GLView.h
//  SingleViewTest
//
//  Created by Admin on 7/24/13.
//  Copyright (c) 2013 Virtuoso Engine. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <stack>
#include <utility>
#include <functional>

struct InputHandler
{
    std::function <void (float, float)> touchBegin;
    std::function <void (float, float)> touchEnd;
    std::function <void (float, float)> touchMove;
};


#import "QuartzCore/CAEAGLLayer.h"

@interface GLViewIOS : UIView

{
    @public
    std::stack<InputHandler> inputHandler;
}

@property GLuint mainRenderBuffer;


-(std::pair<GLint,GLint>) getRenderBufferDimensions;

+(GLuint) allocateMainRenderBuffer:(CAEAGLLayer*) fromLayer withContext: (EAGLContext*)context;

///set will contain UITouch objects
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
///set will contain UITouch objects
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
///set will contain UITouch objects
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;

- (id)initWithFrame:(CGRect)frame;

@end