//
//  ActionSheet.h
//  SingleViewTest
//
//  Created by Admin on 8/15/13.
//  Copyright (c) 2013 Virtuoso Engine. All rights reserved.
//

#ifndef __SingleViewTest__ActionSheet__
#define __SingleViewTest__ActionSheet__

#include <iostream>
#include <string>
#include <list>
#include <functional>

enum ActionSheetEntryType {NORMAL_ENTRY, DESTRUCTIVE_ENTRY, CANCEL_ENTRY};

struct ActionSheetEntry
{
    std::string text;
    std::function<void (void)>  function;
    ActionSheetEntryType type;
    
    ActionSheetEntry(const std::string& textIn,
                    const  std::function<void (void)>&  functionIn,
                    ActionSheetEntryType typeIn = NORMAL_ENTRY)
        : text(textIn), function(functionIn), type(typeIn)
    {
        
    }

    
};


class ActionSheet;


@interface ActionSheetDelegate : NSObject   <UIActionSheetDelegate>
{
    ActionSheet* myActionSheet;
}

-(id) initWithActionSheet : (ActionSheet*) boxIn;
@end



///inherits from map.  maps strings to void function objects.  Each entry in the map will be a button with the string written on it, that executes the function on button press
class ActionSheet : public std::list<ActionSheetEntry> {
    
//protected:
  
public:
    class Implementation; ///platform specific implementation class.  forward declared here and defined in the implementation files.
    
    typedef std::shared_ptr<Implementation> ImplementationPtr; ///\todo unique ptr fails for some reason
    
    ImplementationPtr pImpl;  ///pointer to implementation
    
public:
    
    std::string title; ///title of message box
    
    ActionSheet(const std::string& titleIn);
    
    ActionSheet();
    
    ActionSheetDelegate* getUIDelegate();
    
    ///brings up the popup box for user interaction
    void display();
    
    
};




#endif /* defined(__SingleViewTest__ActionSheet__) */
