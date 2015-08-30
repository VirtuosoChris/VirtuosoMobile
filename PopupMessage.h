//
//  PopupMessage.h
//  SingleViewTest
//
//  Created by Admin on 7/9/13.
//  Copyright (c) 2013 Virtuoso Engine. All rights reserved.
//

#ifndef SingleViewTest_PopupMessage_h
#define SingleViewTest_PopupMessage_h

#include <string>
#include <list>
#include <functional>

typedef std::pair<std::string, std::function<void (void)> > PopupBoxEntry;


///inherits from map.  maps strings to void function objects.  Each entry in the map will be a button with the string written on it, that executes the function on button press
class PopupBox : public std::list<PopupBoxEntry>
{
   
protected:
    
    class Implementation; ///platform specific implementation class.  forward declared here and defined in the implementation files.
    
    typedef std::shared_ptr<Implementation> ImplementationPtr;///\todo should be unique ptr
    
    ImplementationPtr pImpl;  ///pointer to implementation
    
public:
    
    std::string title; ///title of message box
    std::string message; ///main message displayed to user before options are presented
    
    PopupBox(const std::string& titleIn, const std::string& messageIn);
    
    PopupBox();
    
    ///brings up the popup box for user interaction
    void display();
};


/***** basic message box functions *****/

///popup message box with OK option
void popupMessage(const char* message, const char* title = "ERROR");

///popup message box with OK option
void popupMessage(const std::string&  message, const std::string& title = "ERROR");

///popup message box with OK option, that throws a std::runtime_error with the input string when the user selects ok
void popupThenException(const char* message);

///popup message box with OK option, that throws a std::runtime_error with the input string when the user selects ok
void popupThenException(const std::string&  message);


#endif
