#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface SimpleVideoFilterViewController : UIViewController
{
    GPUImageVideoCamera *videoCamera;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageMovieWriter *movieWriter;
  
  BOOL isRecording;
}


- (IBAction)recordAction:(UIButton *)sender;
- (IBAction)updateSliderValue:(id)sender;

@end
