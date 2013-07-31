//
//  TKDDSImageRep.h
//  Texture Kit
//
//  Created by Mark Douma on 9/25/2010.
//  Copyright (c) 2010-2013 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKImageRep.h>


enum {
	TKDDSFormatRGB		= 0,
	TKDDSFormatRGBA		= TKDDSFormatRGB,
	
	//	DirectX 9 formats
	TKDDSFormatDXT1		= 1,
	TKDDSFormatDXT1a	= 2,	// DXT1 with binary alpha
	TKDDSFormatDXT3		= 3,
	TKDDSFormatDXT5		= 4,
	TKDDSFormatDXT5n	= 5,
	
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
	
	TKDDSFormatRGBE		= 12,	// ??
	
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

