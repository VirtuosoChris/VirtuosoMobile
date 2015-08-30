//
//  ActionSheet.cpp
//  SingleViewTest
//
//  Created by Admin on 8/15/13.
//  Copyright (c) 2013 Virtuoso Engine. All rights reserved.
//

#include "ActionSheet.h"

#import <Foundation/NSString.h>
#import <UIKit/UIActionSheet.h>

@implementation ActionSheetDelegate



-(void) actionSheet:(UIActionSheet*) sheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    NSString*  buttonTitle = [sheet buttonTitleAtIndex:buttonIndex];
    
    std::string toSearch(   [buttonTitle UTF8String ] );
    
    if(!myActionSheet)
    {
        throw std::runtime_error("popup box associated with delegate is null");
    }
    
    auto pred = [toSearch](const ActionSheetEntry& entry)
    {
        return entry.text == toSearch;
    };
    
    ActionSheet::iterator it = std::find_if(myActionSheet->begin(), myActionSheet->end(), pred );
    
    if(it == myActionSheet->end())
    {
        throw std::runtime_error("Selected Button Not Found in Popup Box dictionary");
    }
    
    it->function();

    
}

/// we find the button matching the input argument and execute its function object in the popup box map.
- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
   /* NSString*  buttonTitle = [sheet buttonTitleAtIndex:buttonIndex];
    
    std::string toSearch(   [buttonTitle UTF8String ] );
    
    if(!myActionSheet)
    {
        throw std::runtime_error("popup box associated with delegate is null");
    }

    auto pred = [toSearch](const ActionSheetEntry& entry)
    {
        return entry.text == toSearch;
    };
    
    
    ActionSheet::iterator it = std::find_if(myActionSheet->begin(), myActionSheet->end(), pred );
    
    if(it == myActionSheet->end())
    {
        throw std::runtime_error("Selected Button Not Found in Popup Box dictionary");
    }
    
    it->function();
    */
}



-(id) initWithActionSheet : (ActionSheet* ) sheetIn
{
    self =[super init];
    myActionSheet = sheetIn;
    
    return self;
}


@end


///platform dependent implementation of alert box on IOS is simply a delagate class that has a pointer to the popup box
class ActionSheet::Implementation
{
public:
    
    ActionSheetDelegate* delegate;
    
    Implementation(ActionSheet* sheetIn)
    {
        delegate = [[ ActionSheetDelegate alloc] initWithActionSheet : sheetIn ];
    }
};


ActionSheet::ActionSheet(const std::string& titleIn)
:
pImpl(new Implementation(this)),
title(titleIn)
{
}



ActionSheet::ActionSheet()
:pImpl(new Implementation(this))
{
}




ActionSheetDelegate* ActionSheet::getUIDelegate()
{
    return pImpl->delegate;
}




void ActionSheet::display()
{
    UIActionSheet* myActionSheet = [[UIActionSheet alloc] init];
    
    myActionSheet.title = [NSString stringWithFormat:@"%s",title.c_str()];
    
    unsigned int index = 0;
    for(ActionSheet::const_iterator it = begin(); it != end(); it++, index++)
    {
        [myActionSheet addButtonWithTitle: [NSString stringWithFormat:@"%s", it->text.c_str()]];
        
        if(it->type == CANCEL_ENTRY)
        {
            myActionSheet.cancelButtonIndex = index;
        }
        else if(it->type==DESTRUCTIVE_ENTRY)
        {
            myActionSheet.destructiveButtonIndex = index;
        }
        
    }
 
    [myActionSheet setDelegate:pImpl->delegate];
    
    UIView* mainView = [[[[UIApplication sharedApplication] keyWindow] subviews] lastObject];
    
    [myActionSheet showInView: mainView];
}
