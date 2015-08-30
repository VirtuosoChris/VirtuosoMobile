//
//  SocialIOS.mm
//  Color-Fy
//
//  Created by Admin on 11/19/13.
//  Copyright (c) 2013 Virtuoso Engine. All rights reserved.
//



#include <stdio.h>
#include "SocialIOS.h"
#include <Social/Social.h>
#import <Accounts/Accounts.h>
#include "iosHelpers.h"
#include "SystemImageImplIos.h"
#include <set>
#include "PopupMessage.h"


NSString* serviceType[NUM_SOCIAL_TYPES] = {SLServiceTypeFacebook, SLServiceTypeTwitter};


bool instagramImage(UIImage* img, NSString* caption )
{
    unsigned int w =  img.size.width;
    unsigned int h = img.size.height;
    
    const unsigned int minDimension = 612u; //instagram requirement
    
    unsigned int dimToScale = std::min<unsigned int>(w,h);
    
    UIImage* img2 = nil;
    
    if(w > minDimension && h > minDimension)
    {//instagram automatically downscales, but not upscales
       
        SystemImageIOS imgIn(img);
        
        img2 = resizedCopyGauss(imgIn, (float)minDimension / imgIn.getWidth() );
    }
    else
    {//upscale image
        float scale = (float)minDimension / dimToScale;
        unsigned int newW = w * scale;
        unsigned int newH = h * scale;
        
        std::cout<<"Scaling for instagram to "<<newW<<" "<<newH<<std::endl;
        
        img2 =  resizedCopy(img, newW, newH);
    }
    
    //save image to temp file with extension ig
    
    NSString* file  = [NSString stringWithFormat: @"%@%s", appDocumentsPath() , "/instagramtemp.ig"];
    
    NSData* data = UIImagePNGRepresentation(img2);
    
    if(!(data && [data writeToFile: file atomically:YES]))
    {
        return false;
    }
    
    NSURL* url = [NSURL URLWithString: [NSString stringWithFormat:@"file:/%@",file]];
    
    UIDocumentInteractionController* dic = [UIDocumentInteractionController interactionControllerWithURL:url];
    
    if(caption)
    {
        NSString* objectStr =caption;
        NSString* keyStr = @"InstagramCaption";
        
        NSDictionary* annotation = [NSDictionary dictionaryWithObjects:&objectStr forKeys:&keyStr count:1];
    
        dic.annotation = annotation;
    }
    
    dic.UTI = @"com.instagram.photo";
    
    UIViewController *controller = topMostController();
    
    CGRect rect = controller.view.bounds;
    
    std::cout<<"RECT OF VC IS "<<rect.size.width<<" "<<rect.size.height<<std::endl;
    
    [dic presentOpenInMenuFromRect: rect    inView: controller.view animated: YES ];

    return true;
}




void SocialPostIOS::setInitialText(NSString* str)
{
    text=str;
}



bool canTweet()
{
    return [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
}


bool canFacebook()
{
    return [SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook];
}


bool SocialPostIOS::serviceTypeAvailable(NSString* serviceType)const{
        
        return [SLComposeViewController isAvailableForServiceType: serviceType];
}


void SocialPostIOS::addImage(UIImage* img){
    images.insert(img);
}


void SocialPostIOS::addURL(NSURL* url){
    urls.insert(url);
}


void SocialPostIOS::clearImages(){
        
    urls.clear();
}


void SocialPostIOS::clearURLS(){
    images.clear();
}


bool SocialPostIOS::display(NSString* serviceType)const{
    
    SLComposeViewController* controller = [SLComposeViewController composeViewControllerForServiceType: serviceType];
        
    if(!controller)return false;
        
    if(text)
    {
        [controller setInitialText:text];
    }
        
    for(std::set<UIImage*>::iterator it = images.begin(); it != images.end(); it++)
    {
        [controller addImage:*it];
    }
        
    for(std::set<NSURL*>::iterator it = urls.begin(); it != urls.end(); it++)
    {
        [controller addURL:*it];
    }
    
    [controller setCompletionHandler:^(SLComposeViewControllerResult result)
    {
        switch (result)
        {
            case SLComposeViewControllerResultCancelled:
                break;
            case SLComposeViewControllerResultDone:
                popupMessage("Your picture has been posted!", "");
                break;
            default:
                break;
            }
        }
     ];
        
        
    [topMostController() presentViewController:controller animated:YES completion:nil];
        
    return true;
}

