//
//  VirtuosoSlider.m
//  Letterboxer
//
//  Created by Chris Pugh on 9/6/14.
//  Copyright (c) 2014 Virtuoso Engine. All rights reserved.
//

#import "VirtuosoSlider.h"
#include <iostream>
#include <boost/circular_buffer.hpp>

@implementation VirtuosoSlider

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self customInit];
    }
    return self;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self customInit];
    }
    return self;
}


-(void) customInit
{
    _selectedValue = self.value;
    _sliderTimer.reset();
    _ringBuffer = boost::circular_buffer<SliderEntry>(8);
    
    _maxDistanceTime = .25f;
    _maxDistanceValue = .15;
    _holdTime = .05f;
    
    _accelerationEnabled = true;
}


-(CGFloat) getValueOffset: (UITouch*)touch
{
    CGPoint previousLocation = [touch previousLocationInView:self];
    CGPoint currentLocation  = [touch locationInView:self];
    CGFloat trackingOffset = currentLocation.x - previousLocation.x;
    CGRect trackRect = [self trackRectForBounds:self.bounds];
    
    CGFloat rval = (self.maximumValue - self.minimumValue) * (trackingOffset / trackRect.size.width);
    
    return rval;
}


- (void) endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    //[super endTrackingWithTouch:touch withEvent:event];
    
    float elapsedTime = _sliderTimer.getDelta();

    float timeAccum = elapsedTime;
    
    if(elapsedTime < _holdTime)
    {
        for(unsigned int i = 0; i < _ringBuffer.size(); i++)
        {
            timeAccum += _ringBuffer[i].duration;
            
            float valDiff = fabs(_ringBuffer[i].value - self.value);
            
            float valDiffNorm = valDiff / (self.maximumValue - self.minimumValue);
            
            bool valTooFar = valDiffNorm > _maxDistanceValue;
            bool timeTooFar = timeAccum > _maxDistanceTime;
            
            if(timeTooFar || valTooFar)return;
            
            if(_ringBuffer[i].duration >= _holdTime)
            {
                //[self setValue:_ringBuffer[i].value animated:YES];
                
                [UIView animateWithDuration:.250 animations:^{
                    [self setValue:_ringBuffer[i].value animated:YES];
                }];
                
                //self.value = _ringBuffer[i].value;
                [self sendActionsForControlEvents:UIControlEventValueChanged];
                //std::cout<<"SNAP BACK"<<std::endl;
            }
        }
    }
}


-(BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    _sliderTimer.reset();
    _selectedValue = self.value;
    
    return [super beginTrackingWithTouch:touch withEvent:event];
}


- (BOOL) continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (self.tracking)
    {
        CGFloat valueOffset = [self getValueOffset:touch];
        
        CGFloat candidatePosition = valueOffset + self.value;
       
        ///\todo velocity is per time
      
        float elapsedTime = _sliderTimer.getDelta();
        float velocity = valueOffset;//self.value - _selectedValue;
        
        _ringBuffer.push_front({elapsedTime, _selectedValue, velocity});
        
        if(_accelerationEnabled && _ringBuffer.size())
        {
            float totalWeight = 0.0f;
            const float currentFrameWeight = .5f;
            const float previousFramesWeight = 1.0f - currentFrameWeight;
            float previousFramesSum = 0.0f;
            float triHeight = 2.0f * previousFramesWeight / _ringBuffer.size();
            
            for(unsigned int i =0;  i < _ringBuffer.size(); i++)
            {
                float rampLoc = float(i) / _ringBuffer.size();
                float rampScale = (1.0f - rampLoc) * triHeight;
                float weight =  _ringBuffer[i].duration * rampScale;
                
                previousFramesSum += _ringBuffer[i].velocity * weight;
                
                totalWeight +=weight;
            }
            
            float prevVal = (previousFramesSum / totalWeight);
            
            float vel = currentFrameWeight * velocity + previousFramesWeight * prevVal;
            
            candidatePosition = vel + self.value;
            
        }
    
        if(candidatePosition != _selectedValue)
        {
             self.value = candidatePosition;
            _selectedValue = self.value;
            _sliderTimer.reset();
        }
        
        if (self.continuous)
        {
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
    }
    
    return self.tracking;
}


@end
