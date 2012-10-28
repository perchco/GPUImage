#import "GPUImageMotionDetector.h"

NSString *const kGPUImageMotionComparisonFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform highp float intensity;
 
 void main()
 {
     lowp vec3 currentImageColor = texture2D(inputImageTexture, textureCoordinate).rgb;
     lowp vec3 lowPassImageColor = texture2D(inputImageTexture2, textureCoordinate2).rgb;
     
     mediump float colorDistance = distance(currentImageColor, lowPassImageColor); // * 0.57735
     lowp float movementThreshold = step(0.2, colorDistance);
     
     gl_FragColor = movementThreshold * vec4(textureCoordinate2.x, textureCoordinate2.y, 1.0, 1.0);
 }
);


@implementation GPUImageMotionDetector

@synthesize lowPassFilterStrength, motionDetectionBlock;

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super init]))
    {
		return nil;
    }

    self.enabled = YES;

    // Start with a low pass filter to define the component to be removed
    lowPassFilter = [[GPUImageLowPassFilter alloc] init];
    [self addFilter:lowPassFilter];
    
    // Take the difference of the current frame from the low pass filtered result to get the high pass
    frameComparisonFilter = [[GPUImageTwoInputFilter alloc] initWithFragmentShaderFromString:kGPUImageMotionComparisonFragmentShaderString];
    [self addFilter:frameComparisonFilter];
  
    // Texture location 0 needs to be the original image for the difference blend
    [lowPassFilter addTarget:frameComparisonFilter atTextureLocation:1];
  
    // End with the average color for the scene to determine the centroid
    averageColor = [[GPUImageAverageColor alloc] init];

    __unsafe_unretained GPUImageMotionDetector *weakSelf = self;

    averageColor.colorAverageProcessingFinishedBlock = ^(CGFloat redComponent, CGFloat greenComponent, CGFloat blueComponent, CGFloat alphaComponent, CMTime frameTime) {
      if (weakSelf.motionDetectionBlock != NULL)
      {
        weakSelf.motionDetectionBlock(CGPointMake(redComponent / alphaComponent, greenComponent / alphaComponent), alphaComponent, frameTime);
      }

      if (weakSelf.sampleInterval) {
        [weakSelf disableSampling];
      }
//        NSLog(@"COLOR COMPONENTS > RED %f | GREEN %f | BLUE %f | ALPHA %f", redComponent, greenComponent, blueComponent, alphaComponent);
//        NSLog(@"Average X: %f, Y: %f total: %f", redComponent / alphaComponent, greenComponent / alphaComponent, alphaComponent);
    };
    [frameComparisonFilter addTarget:averageColor];

    self.lowPassFilterStrength = 0.5;
    self.initialFilters = [NSArray arrayWithObjects:lowPassFilter, frameComparisonFilter, nil];
    self.terminalFilter = frameComparisonFilter;

    return self;
}

- (void)dealloc;
{
}

- (void)disableSampling;
{
  self.enabled = NO;
}

- (void)enableSampling;
{
  self.enabled = YES;
}


- (void)endProcessing {
  [self removeAllTargets];

  [averageColor endProcessing];
  [frameComparisonFilter endProcessing];
  [frameComparisonFilter removeAllTargets];
  [lowPassFilter endProcessing];
  [lowPassFilter removeAllTargets];

  [sampleTimer invalidate];
  sampleTimer = nil;

  [super endProcessing];
}


#pragma mark -
#pragma mark Accessors

- (void)setLowPassFilterStrength:(CGFloat)newValue;
{
    lowPassFilter.filterStrength = newValue;
}

- (CGFloat)lowPassFilterStrength;
{
    return lowPassFilter.filterStrength;
}


- (void)setSampleInterval:(NSTimeInterval)sampleInterval;
{
  _sampleInterval = sampleInterval;

  [sampleTimer invalidate];
  sampleTimer = nil;

  if (_sampleInterval > 0.0) {
    sampleTimer = [NSTimer scheduledTimerWithTimeInterval:_sampleInterval target:self selector:@selector(enableSampling) userInfo:nil repeats:YES];
    NSLog(@"Motion detection sample interval %f", _sampleInterval);
  }
}


@end
