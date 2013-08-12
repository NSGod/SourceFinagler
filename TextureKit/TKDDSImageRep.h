//
//  TKDDSImageRep.h
//  Texture Kit
//
//  Created by Mark Douma on 9/25/2010.
//  Copyright (c) 2010-2013 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKImageRep.h>


enum {
	
	//	DirectX 9 formats
	TKDDSFormatDXT1		= 0,
	TKDDSFormatDXT1a,		// DXT1 with binary alpha
	TKDDSFormatDXT3,
	TKDDSFormatDXT5,
	TKDDSFormatDXT5n,		// Compressed HILO: R=1, G=y, B=0, A=x
	
	
	TKDDSFormatRGB,
	TKDDSFormatRGB565,
	
	TKDDSFormatARGB,
	TKDDSFormatARGB4444,
	TKDDSFormatARGB1555,
	TKDDSFormatARGB8332,
	TKDDSFormatARGB2101010,
	
	TKDDSFormatXRGB,
	TKDDSFormatXRGB1555,
	TKDDSFormatXRGB4444,
	
	TKDDSFormatABGR,
	TKDDSFormatXBGR,
	TKDDSFormatABGR2101010,
	TKDDSFormatABGR16161616,
	
	TKDDSFormatA,
	
	TKDDSFormatP,
	TKDDSFormatAP,
	
	TKDDSFormatL,
	TKDDSFormatAL,
	TKDDSFormatA4L4,
	TKDDSFormatL16,
	
	TKDDSFormatGR1616,
	
	TKDDSFormatQWVU16161616,
	
	TKDDSFormatR16F,
	TKDDSFormatGR1616F,
	TKDDSFormatABGR16161616F,
	
	TKDDSFormatR32F,
	TKDDSFormatGR3232F,
	TKDDSFormatABGR32323232F,
	
	
};


enum {
//	TKDDSFormatRGB		= 0,
	TKDDSFormatRGBA		= TKDDSFormatRGB,
	
	//	DirectX 9 formats
//	TKDDSFormatDXT1		= 1,
//	TKDDSFormatDXT1a	= 2,	// DXT1 with binary alpha
//	TKDDSFormatDXT3		= 3,
//	TKDDSFormatDXT5		= 4,
//	TKDDSFormatDXT5n	= 5,	// Compressed HILO: R=1, G=y, B=0, A=x
	
	TKDDSFormatBC1		= TKDDSFormatDXT1,
	TKDDSFormatBC1a		= TKDDSFormatDXT1a,
	TKDDSFormatBC2		= TKDDSFormatDXT3,
	TKDDSFormatBC3		= TKDDSFormatDXT5,
	TKDDSFormatBC4		= 6,	// ATI1
	TKDDSFormatBC5		= 7,	// 3DC, ATI2
	
	TKDDSFormatDXT1n	= 8,	// not supported yet
	TKDDSFormatCTX1		= 9,	// not supported yet
	
	TKDDSFormatBC6		= 10,	// not supported yet
	TKDDSFormatBC7		= 11,	// not supported yet
	
//	TKDDSFormatRGBE		= 12,	// ??
	
	TKDDSFormatDefault	= TKDDSFormatDXT1,
	TKDDSNoFormat		= 1000
};
typedef NSUInteger TKDDSFormat;


TEXTUREKIT_EXTERN NSString *NSStringFromDDSFormat(TKDDSFormat aFormat);
TEXTUREKIT_EXTERN TKDDSFormat TKDDSFormatFromString(NSString *aFormat);

TEXTUREKIT_EXTERN NSString * const TKDDSType;			// UTI Type
TEXTUREKIT_EXTERN NSString * const TKDDSFileType;		// filename extension
TEXTUREKIT_EXTERN NSString * const TKDDSPboardType;

enum {
	TKDDSMagic		= 'DDS '
};



@interface TKDDSImageRep : TKImageRep <NSCoding, NSCopying> {
	
}

+ (NSArray *)imageRepsWithData:(NSData *)aData;

+ (id)imageRepWithData:(NSData *)aData;
- (id)initWithData:(NSData *)aData;

+ (TKDDSFormat)defaultFormat;
+ (void)setDefaultFormat:(TKDDSFormat)aFormat;



+ (NSData *)DDSRepresentationOfImageRepsInArray:(NSArray *)tkImageReps options:(NSDictionary *)options;

+ (NSData *)DDSRepresentationOfImageRepsInArray:(NSArray *)tkImageReps usingFormat:(TKDDSFormat)aFormat quality:(TKDXTCompressionQuality)aQuality options:(NSDictionary *)options;


@end




//enum {
//	TKDDSFormatRGB		= 0,
//	TKDDSFormatRGBA		= TKDDSFormatRGB,
//	
//	//	DirectX 9 formats
//	TKDDSFormatDXT1		= 1,
//	TKDDSFormatDXT1a	= 2,	// DXT1 with binary alpha
//	TKDDSFormatDXT3		= 3,
//	TKDDSFormatDXT5		= 4,
//	TKDDSFormatDXT5n	= 5,	// Compressed HILO: R=1, G=y, B=0, A=x
//	
//	TKDDSFormatBC1		= TKDDSFormatDXT1,
//	TKDDSFormatBC1a		= TKDDSFormatDXT1a,
//	TKDDSFormatBC2		= TKDDSFormatDXT3,
//	TKDDSFormatBC3		= TKDDSFormatDXT5,
//	TKDDSFormatBC4		= 6,	// ATI1
//	TKDDSFormatBC5		= 7,	// 3DC, ATI2
//	
//	TKDDSFormatDXT1n	= 8,	// not supported yet
//	TKDDSFormatCTX1		= 9,	// not supported yet
//	
//	TKDDSFormatBC6		= 10,	// not supported yet
//	TKDDSFormatBC7		= 11,	// not supported yet
//	
////	TKDDSFormatRGBE		= 12,	// ??
//	
//	TKDDSFormatDefault	= TKDDSFormatDXT1,
//	TKDDSNoFormat		= 1000
//};
//typedef NSUInteger TKDDSFormat;


//enum {
//	TKDDSFormatABGR8888			= 0,
//	TKDDSFormatGR1616,
//	TKDDSFormatABGR2101010,
//	TKDDSFormatARGB1555,
//	TKDDSFormatRGB565,
//	TKDDSFormatA8,
//	TKDDSFormatARGB8888,
//	TKDDSFormatXRGB8888,
//	TKDDSFormatXBGR8888,
//	TKDDSFormatARGB2101010,
//	TKDDSFormatRGB888,
//	TKDDSFormatXRGB1555,
//	TKDDSFormatARGB4444,
//	TKDDSFormatXRGB4444,
//	TKDDSFormatARGB8332,
//	TKDDSFormatAL88,
//	TKDDSFormatL16,
//	TKDDSFormatL8,
//	TKDDSFormatA4L4,
//	
//	TKDDSFormatABGR16161616,
//	TKDDSFormatQWVU16161616,
//	TKDDSFormatR16F,
//	TKDDSFormatGR1616F,
//	TKDDSFormatABGR16161616F,
//	TKDDSFormatR32F,
//	TKDDSFormatGR3232F,
//	TKDDSFormatABGR32323232F,
//	
//	
//};



