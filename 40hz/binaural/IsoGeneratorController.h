//
//  Binaural
#import <UIKit/UIKit.h>
#import <AudioUnit/AudioUnit.h>

@interface IsoGeneratorController: NSObject
{
    AudioComponentInstance toneUnit;

    NSTimer *isoTimer;
    
@public
	float monoFrequency;
    int frame;
    bool isOn;
    int sampleRate;
	float monoTheta;
    int multiplier;
    float amplitude;
    //int sampleDifferenceCompensation;
}

@property (nonatomic) float carrierFrequency;
@property (nonatomic) float binauralFrequency;

- (void)stop;
- (void)togglePlay;
- (void)setup;

@end

