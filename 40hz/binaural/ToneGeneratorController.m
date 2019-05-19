//
//  Binaural
//
//  Created by Russell Dobda 2015.
//  Copyright 2015 Russell Dobda. All rights reserved.
//

#import "ToneGeneratorController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "math.h"

OSStatus RenderTone(
	void *inRefCon, 
	AudioUnitRenderActionFlags 	*ioActionFlags, 
	const AudioTimeStamp 		*inTimeStamp, 
	UInt32 						inBusNumber, 
	UInt32 						inNumberFrames, 
	AudioBufferList 			*ioData)

{

	// Get the tone parameters out of the view controller
	ToneGeneratorController *viewController =
    (__bridge ToneGeneratorController *)inRefCon;
	//double leftTheta = viewController->leftTheta;
    //double rightTheta = viewController->rightTheta;

    float left_theta_increment = 2.0f * M_PI * viewController->leftFrequency / viewController->sampleRate;
    float right_theta_increment = 2.0f * M_PI * viewController->rightFrequency / viewController->sampleRate;
    float amplitude = 0.25f ;

    
	const int leftChannel = 0;
    const int rightChannel = 1;

    Float32 *leftBuffer = (Float32 *)ioData->mBuffers[leftChannel].mData;
	
	// Generate the samples
	for (UInt32 frame = 0; frame < inNumberFrames; frame++) 
	{
		leftBuffer[frame] = sin(viewController->leftTheta) * amplitude;
		
		viewController->leftTheta += left_theta_increment;
		if (viewController->leftTheta > 2.0 * M_PI)
		{
			viewController->leftTheta -= 2.0 * M_PI;
		}
	}

    Float32 *rightBuffer = (Float32 *)ioData->mBuffers[rightChannel].mData;
    
    // Generate the samples
    for (UInt32 frame = 0; frame < inNumberFrames; frame++)
    {
        rightBuffer[frame] = sin(viewController->rightTheta) * amplitude;
        
        viewController->rightTheta += right_theta_increment;
        if (viewController->rightTheta > 2.0 * M_PI)
        {
            viewController->rightTheta -= 2.0 * M_PI;
        }
    }
    
	return noErr;
}


@implementation ToneGeneratorController


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
	input.inputProc = RenderTone;
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
	streamFormat.mFormatFlags =
		kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
	streamFormat.mBytesPerPacket = four_bytes_per_float;
	streamFormat.mFramesPerPacket = 1;	
	streamFormat.mBytesPerFrame = four_bytes_per_float;		
	streamFormat.mChannelsPerFrame = 2;
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


	sampleRate = 44100.f;
    _carrierFrequency = 200;
    _binauralFrequency = 40;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    //round carrier slider to only use two decimal places
    _carrierFrequency = roundf(_carrierFrequency * 100) / 100;

    //round binaural to only use two decimal places
    _binauralFrequency = roundf(_binauralFrequency * 100) / 100;

    //check for out of range and adjust accordingly
    if (_carrierFrequency - (_binauralFrequency / 2) < .1)
    {
        _carrierFrequency = (_binauralFrequency / 2) + .1;
    }

    leftFrequency  = _carrierFrequency - (_binauralFrequency / 2);
    rightFrequency = _carrierFrequency + (_binauralFrequency / 2);
    amplitude = 0.25;

}


@end
