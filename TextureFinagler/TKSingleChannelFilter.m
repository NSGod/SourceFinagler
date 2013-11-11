//
//  TKSingleChannelFilter.m
//  Source Finagler
//
//  Created by Mark Douma on 10/20/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import "TKSingleChannelFilter.h"


#define TK_DEBUG 1


static CIKernel *TKSingleChannelFilterKernel = nil;


@implementation TKSingleChannelFilter

@synthesize redScale;
@synthesize greenScale;
@synthesize blueScale;
@synthesize alphaScale;



- (id)init {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super init])) {
		if (TKSingleChannelFilterKernel == nil) {
			NSBundle *bundle = [NSBundle bundleForClass:[self class]];
			NSArray *kernels = [CIKernel kernelsWithString:[NSString stringWithContentsOfFile:[bundle pathForResource:@"TKSingleChannelFilter" ofType:@"cikernel"]
																					 encoding:NSUTF8StringEncoding
																						error:NULL]];
			if ([kernels count]) {
				TKSingleChannelFilterKernel = [[kernels objectAtIndex:0] retain];
			}
		}
		self.redScale = [NSNumber numberWithDouble:1.0/3.0];
		self.greenScale = [NSNumber numberWithDouble:1.0/3.0];
		self.blueScale = [NSNumber numberWithDouble:1.0/3.0];
		self.alphaScale = [NSNumber numberWithDouble:1.0/3.0];
		
		self.name = @"grayscaleFilter";
	}
	return self;
}


- (void)dealloc {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[inputImage release];
	[redScale release];
	[greenScale release];
	[blueScale release];
	[alphaScale release];
	[super dealloc];
}


- (NSDictionary *)customAttributes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			
			[NSDictionary dictionaryWithObjectsAndKeys:
			 [NSNumber numberWithDouble:  0.0], kCIAttributeMin,
			 [NSNumber numberWithDouble:  0.0], kCIAttributeSliderMin,
			 [NSNumber numberWithDouble:  1.0], kCIAttributeSliderMax,
			 [NSNumber numberWithDouble:0.333], kCIAttributeDefault,
			 [NSNumber numberWithDouble:1.0], kCIAttributeIdentity,
			 kCIAttributeTypeScalar,           kCIAttributeType,
			 nil],                               @"redScale",
			
			[NSDictionary dictionaryWithObjectsAndKeys:
			 [NSNumber numberWithDouble:  0.0], kCIAttributeMin,
			 [NSNumber numberWithDouble:  0.0], kCIAttributeSliderMin,
			 [NSNumber numberWithDouble:  1.0], kCIAttributeSliderMax,
			 [NSNumber numberWithDouble:0.333], kCIAttributeDefault,
			 [NSNumber numberWithDouble:1.0], kCIAttributeIdentity,
			 kCIAttributeTypeScalar,           kCIAttributeType,
			 nil],                               @"greenScale",
			
			[NSDictionary dictionaryWithObjectsAndKeys:
			 [NSNumber numberWithDouble:  0.0], kCIAttributeMin,
			 [NSNumber numberWithDouble:  0.0], kCIAttributeSliderMin,
			 [NSNumber numberWithDouble:  1.0], kCIAttributeSliderMax,
			 [NSNumber numberWithDouble:0.333], kCIAttributeDefault,
			 [NSNumber numberWithDouble:1.0], kCIAttributeIdentity,
			 kCIAttributeTypeScalar,           kCIAttributeType,
			 nil],                               @"blueScale",
			
			[NSDictionary dictionaryWithObjectsAndKeys:
			 [NSNumber numberWithDouble:  0.0], kCIAttributeMin,
			 [NSNumber numberWithDouble:  0.0], kCIAttributeSliderMin,
			 [NSNumber numberWithDouble:  1.0], kCIAttributeSliderMax,
			 [NSNumber numberWithDouble:0.333], kCIAttributeDefault,
			 [NSNumber numberWithDouble:1.0], kCIAttributeIdentity,
			 kCIAttributeTypeScalar,           kCIAttributeType,
			 nil],                               @"alphaScale",
			
			nil];
	
}


// called when setting up for fragment program and also calls fragment program
- (CIImage *)outputImage {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
    
    CISampler *src = [CISampler samplerWithImage:inputImage];
	
    return [self apply:TKSingleChannelFilterKernel,
			src,
			redScale,
			greenScale,
			blueScale,
			alphaScale,
			nil];
}



@end



