#import "GPUImageFilterGroup.h"
#import "GPUImageLowPassFilter.h"
#import "GPUImageAverageColor.h"

@interface GPUImageMotionDetector : GPUImageFilterGroup
{
    GPUImageLowPassFilter *lowPassFilter;
    GPUImageTwoInputFilter *frameComparisonFilter;
    GPUImageAverageColor *averageColor;

    NSTimer *sampleTimer;
}

// This controls the low pass filter strength used to compare the current frame with previous ones to detect motion. This ranges from 0.0 to 1.0, with a default of 0.5.
@property(readwrite, nonatomic) CGFloat lowPassFilterStrength;

// Limit the amount of samples performed by a time interval. Default is 0 which will perform samples as fast as it can.
@property(readwrite, nonatomic) NSTimeInterval sampleInterval;

// For every frame, this will feed back the calculated centroid of the motion, as well as a relative intensity.
@property(nonatomic, copy) void(^motionDetectionBlock)(CGPoint motionCentroid, CGFloat motionIntensity, CMTime frameTime);

@end
