//
//  VirtuosoSlider.h
//  Letterboxer
//
//  Created by Chris Pugh on 9/6/14.
//  Copyright (c) 2014 Virtuoso Engine. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <boost/circular_buffer.hpp>
#include <Timer.h>

struct SliderEntry
{
    CGFloat duration;
    CGFloat value;
    CGFloat velocity;
};

@interface VirtuosoSlider : UISlider
@property boost::circular_buffer<SliderEntry> ringBuffer;
@property Timer sliderTimer;
@property CGFloat selectedValue;
@property CGFloat maxDistanceTime;
@property CGFloat maxDistanceValue;
@property CGFloat holdTime;
@property bool accelerationEnabled;
@end
