//
//  Social.h
//  Color-Fy
//
//  Created by Admin on 11/19/13.
//  Copyright (c) 2013 Virtuoso Engine. All rights reserved.
//

#ifndef Color_Fy_Social_h
#define Color_Fy_Social_h

#include <set>

enum PostType{FACEBOOK, TWITTER, NUM_SOCIAL_TYPES};

extern NSString* serviceType[NUM_SOCIAL_TYPES];

bool canTweet();

bool canFacebook();

class SocialPostIOS
{
    
protected:

    std::set<NSURL*> urls;
    std::set<UIImage*> images;
    
    NSString* text;///initial text
    
public:
    
    
    bool serviceTypeAvailable(NSString* serviceType) const;
    
    void addImage(UIImage* img);
    
    void addURL(NSURL* url);
    
    void clearImages();
    
    void clearURLS();
    
    bool display(NSString* serviceType) const;
    
    void setInitialText(NSString* str);
    
    
};




#endif
