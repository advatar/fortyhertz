#import <UIKit/UIKit.h>
#import <AudioUnit/AudioUnit.h>

@interface ToneGeneratorController : NSObject
{
    AudioComponentInstance toneUnit;

@public
	float leftFrequency;
    float rightFrequency;
    float amplitude;

    float sampleRate;
	float rightTheta;
    float leftTheta;
}

@property (nonatomic) float carrierFrequency;
@property (nonatomic) float binauralFrequency;

- (void)stop;
- (void)togglePlay;
- (void)setup;

@end

