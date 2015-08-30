//
//  pathString.mm
//  Color-Fy
//
//  Created by Admin on 9/16/13.
//  Copyright (c) 2013 Virtuoso Engine. All rights reserved.
//

#include <stdio.h>

#include <string>
std::string pathString()
{
    NSBundle *b = [NSBundle mainBundle];
    NSString *dir = [b resourcePath];
    NSArray *parts = [NSArray arrayWithObjects:
                      dir, (void *)nil];
    NSString *path = [NSString pathWithComponents:parts];
    const char *cpath = [path fileSystemRepresentation];
    
    return std::string(cpath)+'/';
}