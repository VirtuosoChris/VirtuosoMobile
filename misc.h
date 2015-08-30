//
//  misc.h
//  Color-Fy
//
//  Created by Admin on 9/17/13.
//  Copyright (c) 2013 Virtuoso Engine. All rights reserved.
//

#ifndef Color_Fy_misc_h
#define Color_Fy_misc_h

bool gyroSupported()
{
    CMMotionManager *motionManager = [[CMMotionManager alloc] init];
    return motionManager.gyroAvailable;
}


bool isAccelerometerSupported()
{
    CMMotionManager *motionManager = [[CMMotionManager alloc] init];
    return motionManager.accelerometerAvailable;
}

#endif
