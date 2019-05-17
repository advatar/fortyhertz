//
//  Binaural
//
//  Created by Russell Dobda 2015.
//  Copyright 2015 Russell Dobda. All rights reserved.
//

#import "IsoGeneratorController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "math.h"

OSStatus RenderIso(
	void *inRefCon, 
	AudioUnitRenderActionFlags 	*ioActionFlags, 
	const AudioTimeStamp 		*inTimeStamp, 
	UInt32 						inBusNumber, 
	UInt32 						inNumberFrames, 
	AudioBufferList 			*ioData)

{
	// Get the tone parameters out of the view controller
    IsoGeneratorController *viewController = (__bridge IsoGeneratorController *)inRefCon;

    //int fader = viewController->multiplier - 250;
    int fader = viewController->multiplier - 400;
    //int fader = viewController->multiplier - 500;

    
    float mono_theta_increment = 2.0f * M_PI * viewController->monoFrequency / viewController->sampleRate;

	const int monoChannel = 0;

    float *monoBuffer = (float *)ioData->mBuffers[monoChannel].mData;
	
	// Generate the samples
	for (UInt32 frame = 0; frame < inNumberFrames; frame++) 
	{
        viewController->frame ++;

        if (viewController->frame == viewController->multiplier)
        {
            viewController->isOn = !viewController->isOn;
            if (viewController->isOn)
            {
                viewController->amplitude = .250f;
            }
            else
            {
                viewController->amplitude = .000f;
            }
            viewController->frame = 0;
        }
        
        //must fade to prevent chirping
        else if (viewController->frame >= fader)
        {
            if (viewController->isOn)
            {
                viewController->amplitude -= .000625f;
            }
            else
            {
                viewController->amplitude += .000625f;
            }
        }
        monoBuffer[frame] = sin(viewController->monoTheta) * viewController->amplitude;
		viewController->monoTheta += mono_theta_increment;
		if (viewController->monoTheta > 2.0 * M_PI)
		{
			viewController->monoTheta -= 2.0 * M_PI;
		}
	}
	return noErr;
}

@implementation IsoGeneratorController

-(void) ChangeCarrierFrequency
{
    //round carrier slider to only use two decimal places
    self.carrierFrequency = roundf(self.carrierFrequency * 100) / 100;
    monoFrequency = self.carrierFrequency;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setFloat:self.carrierFrequency forKey:@"isoCarrierFreq"];
    [defaults synchronize];
}

-(void) ChangeBinauralFrequency
{
    //round binaural to only use two decimal places
    self.binauralFrequency = roundf(self.binauralFrequency * 100) / 100;

    multiplier = (sampleRate/2)/self.binauralFrequency;
    self.binauralFrequency = ((float)sampleRate/2.f)/(float)multiplier;
    
    //used to compensate for precise seconds
    //sampleDifferenceCompensation = sampleRate - (multiplier * 2 * self.binauralSlider.value);
    frame = 0;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setFloat:self.binauralFrequency forKey:@"isoBeatsFreq"];
    [defaults synchronize];
}

- (void)createToneUnit
{
	// Configure the search parameters to find the default playback output unit
	// (called the kAudioUnitSubType_RemoteIO on iOS but
	// kAudioUnitSubType_DefaultOutput on Mac OS X)
	AudioComponentDescription defaultOutputDescription;
	defaultOutputDescription.componentType = kAudioUnitType_Output;
	defaultOutputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
	defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	defaultOutputDescription.componentFlags = 0;
	defaultOutputDescription.componentFlagsMask = 0;
	
	// Get the default playback output unit
	AudioComponent defaultOutput = AudioComponentFindNext(NULL, &defaultOutputDescription);
	NSAssert(defaultOutput, @"Can't find default output");
	
	// Create a new unit based on this that we'll use for output
	OSErr err = AudioComponentInstanceNew(defaultOutput, &toneUnit);
	NSAssert1(toneUnit, @"Error creating unit: %ld", (long)err);
	
	// Set our tone rendering function on the unit
	AURenderCallbackStruct input;
	input.inputProc = RenderIso;
    input.inputProcRefCon = (__bridge void * _Nullable)(self);
	err = AudioUnitSetProperty(toneUnit, 
		kAudioUnitProperty_SetRenderCallback, 
		kAudioUnitScope_Input,
		0, 
		&input, 
		sizeof(input));
	NSAssert1(err == noErr, @"Error setting callback: %ld", (long)err);
	
	// Set the format to 32 bit, single channel, floating point, linear PCM
	const int four_bytes_per_float = 4;
	const int eight_bits_per_byte = 8;
	AudioStreamBasicDescription streamFormat;
	streamFormat.mSampleRate = sampleRate;
	streamFormat.mFormatID = kAudioFormatLinearPCM;
	//original
    streamFormat.mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;

    //streamFormat.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
  
    streamFormat.mBytesPerPacket = four_bytes_per_float;
	streamFormat.mFramesPerPacket = 1;	
	streamFormat.mBytesPerFrame = four_bytes_per_float;		
	streamFormat.mChannelsPerFrame = 1;
	streamFormat.mBitsPerChannel = four_bytes_per_float * eight_bits_per_byte;
	err = AudioUnitSetProperty (toneUnit,
		kAudioUnitProperty_StreamFormat,
		kAudioUnitScope_Input,
		0,
		&streamFormat,
		sizeof(AudioStreamBasicDescription));
	NSAssert1(err == noErr, @"Error setting stream format: %ld", (long)err);
}



- (void) togglePlay
{
    if (toneUnit)
    {
        AudioOutputUnitStop(toneUnit);
        AudioUnitUninitialize(toneUnit);
        AudioComponentInstanceDispose(toneUnit);
        toneUnit = nil;
    }
    else
    {
        [self createToneUnit];
        
        // Stop changing parameters on the unit
        OSErr err = AudioUnitInitialize(toneUnit);
        NSAssert1(err == noErr, @"Error initializing unit: %ld", (long)err);
        
        // Start playback
        err = AudioOutputUnitStart(toneUnit);
        NSAssert1(err == noErr, @"Error starting unit: %ld", (long)err);

        //kick off the timer
        [self ChangeBinauralFrequency];
    }
}

- (void)stop
{
	if (toneUnit)
	{
		[self togglePlay];
	}
}

- (void)setup {

    sampleRate = 48000;
    _carrierFrequency = 200;
    _binauralFrequency = 40;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    [self ChangeCarrierFrequency];
    [self ChangeBinauralFrequency];
 }

@end
