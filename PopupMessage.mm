//
//  PopupMessage.mm
//  SingleViewTest
//
//  Created by Admin on 7/9/13.
//  Copyright (c) 2013 Virtuoso Engine.  All rights reserved.
//

#include <stdio.h>
#include "PopupMessage.h"
#include <string>
#include <iostream>
#import <Foundation/NSString.h>
#import <UIKit/UIKit.h>



@interface SimplePopupDelegateException : NSObject   <UIAlertViewDelegate>
{
    std::string str;
}

-(id) initWithString : (const char*) string;
@end


@implementation SimplePopupDelegateException


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    throw std::runtime_error(str);
}

-(id) initWithString : (const char*) string{
    self =[super init];
    str = string;
    return self;
}


@end


///global instance of the delegate
SimplePopupDelegateException* delegate =nil;


void popupThenException(const char* message)
{
    NSString * myString = [NSString stringWithFormat:@"%s",message];
    
    if(!delegate)delegate = [[SimplePopupDelegateException alloc ]initWithString: message];
    
    UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                          message:myString
                                                         delegate:delegate
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles: nil];
    [myAlertView show];
}


void popupThenException(const std::string& message)
{
    popupThenException(message.c_str());
}


void popupMessage(const char* message, const char* title)
{
    NSString * myString = [NSString stringWithFormat:@"%s",message];
    NSString * titleString = [NSString stringWithFormat:@"%s",title];
    
    UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:titleString
                                                          message:myString
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles: nil];
    [myAlertView show];
}



void popupMessage(const std::string&  message, const std::string& title)
{
    popupMessage(message.c_str(), title.c_str());
}


@interface PopupBoxDelegate : NSObject   <UIAlertViewDelegate>
{
     PopupBox* myPopup;
}
 
 -(id) initWithPopupBox : (PopupBox*) boxIn;
 @end



@implementation PopupBoxDelegate

///we find the button matching the input argument and execute its function object in the popup box map.  
 - (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString*  buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
     
    std::string toSearch(   [buttonTitle UTF8String ] );
    
    if(!myPopup)
    {
        throw std::runtime_error("popup box associated with delegate is null");
    }
    
    auto pred = [toSearch](const PopupBoxEntry& entry)
    {
         return entry.first == toSearch;
    };
     
    PopupBox::iterator it = std::find_if(myPopup->begin(), myPopup->end(), pred );
    
    if(it == myPopup->end())
    {
        throw std::runtime_error("Selected Button Not Found in Popup Box dictionary");
    }
     
    it->second(); //execute the function object
}


 -(id) initWithPopupBox : (PopupBox* ) boxIn
{
     self =[super init];
     myPopup = boxIn;
     return self;
}
 
 
@end


///platform dependent implementation of alert box on IOS is simply a delagate class that has a pointer to the popup box
class PopupBox::Implementation
{
public:
    
    PopupBoxDelegate* delegate;
    
    Implementation(PopupBox* boxIn)
    {
        delegate = [[PopupBoxDelegate alloc] initWithPopupBox : boxIn ];
    }
};


void PopupBox::display()
{
    UIAlertView* myAlertView = [[UIAlertView alloc] init];

    myAlertView.title = [NSString stringWithFormat:@"%s",title.c_str()];
    myAlertView.message = [NSString stringWithFormat:@"%s", message.c_str()];
    
    for(PopupBox::const_iterator it = begin(); it != end(); it++)
    {
        [myAlertView addButtonWithTitle: [NSString stringWithFormat:@"%s", it->first.c_str()]];
    }
    
    myAlertView.delegate = pImpl->delegate;
    
    [myAlertView show];
}


PopupBox::PopupBox(const std::string& titleIn, const std::string& messageIn)
:pImpl(new Implementation(this)),
title(titleIn),
message(messageIn)
{
}


PopupBox::PopupBox()
:pImpl(new Implementation(this))
{
}
