//
//  MDPSDImageRep.h
//  Source Finagler
//
//  Created by Mark Douma on 11/21/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


//TEXTUREKIT_EXTERN NSString * const MDPSDType;	// UTI Type
//TEXTUREKIT_EXTERN NSString * const MDPSDFileType;

extern const OSType MDPSDMagic;

#if TARGET_CPU_PPC || TARGET_CPU_X86
	#pragma options align=mac68k
#elif TARGET_CPU_PPC64 || TARGET_CPU_X86_64
	#pragma pack(2)
#endif

enum {
	MDPSDBitmapColorMode		= 0,
	MDPSDGrayscaleColorMode		= 1,
	MDPSDIndexedColorMode		= 2,
	MDPSDRGBColorMode			= 3,
	MDPSDCMYKColorMode			= 4,
	MDPSDMultichannelColorMode	= 7,
	MDPSDDuotoneColorMode		= 8,
	MDPSDLabColorMode			= 9
};

//typedef UInt16 MDPSDColorMode;

// first 26 bytes is the PSD Header

typedef struct MDPSDHeader {
	UInt32			signature;		// always equal to '8BPS'. Do not try to read the file if the signature does not match this value.
	UInt16			version;		// always equal to 1. Do not try to read the file if the version does not match this value.
	UInt8			reserved[6];	// must be zero.
	UInt16			channelCount;	// The number of channels in the image, including any alpha channels. Supported range is 1 to 56.
	UInt32			height;			// The height of the image in pixels. Supported range is 1 to 30,000.
	UInt32			width;			// The width of the image in pixels. Supported range is 1 to 30,000.
	UInt16			bitsPerChannel;	// the number of bits per channel. Supported values are 1, 8, 16 and 32.
	UInt16			colorMode;		// The color mode of the file. Supported values are: Bitmap = 0; Grayscale = 1; Indexed = 2; RGB = 3;
									//	CMYK = 4; Multichannel = 7; Duotone = 8; Lab = 9.
} MDPSDHeader;


// Only indexed color and duotone have color mode data. (see the mode field in the File header section)
// For all other modes, this section is just the 4-byte length field, which is set to zero.
// Indexed color images: length is 768; color data contains the color table for the image, in non-interleaved order.
// Duotone images: color data contains the duotone specification (the format of which is not documented).
// Other applications that read Photoshop files can treat a duotone image as a gray image, 
// and just preserve the contents of the duotone information when reading and writing the file.

typedef struct MDPSDColorModeData {
	UInt32			length;
} MDPSDColorModeData;

typedef 


#pragma options align=reset


@interface MDPSDImageRep : NSImageRep {

}

@end
