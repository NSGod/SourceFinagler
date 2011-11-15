//
//  TKIWIImageRep.h
//  Texture Kit
//
//  Created by Mark Douma on 9/25/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKImageRep.h>


#pragma pack(1)

struct TKIWIHeader {
	UInt8		magic[3];		// 3 bytes - 'IWi'
	UInt8		version;		// 1 byte
	UInt8		format;			// 1 
	UInt8		flags;			// 1
	UInt16		width;			// 2
	UInt16		height;			// 2
	UInt16		unknown[4];		// 8
} TKIWIHeader;

#pragma pack()

typedef TKIWIHeader TKIWIHeader;


enum {
	TKIWIFormatARGB8			= 0x01,	// 32 bpp
	TKIWIFormatRGB8				= 0x02,	// 24 bpp
	
	TKIWIFormatARGB4			= 0x03,	// 24 bpp
	
	TKIWIFormatA8				= 0x04,	// 8  bpp - Alpha
	
	TKIWIFormatJPG				= 0x07,	// 24 bpp 
	
	TKIWIFormatDXT1				= 0x0b,	// 4 bpp
	TKIWIFormatDXT3				= 0x0c,	// 8 bpp
	TKIWIFormatDXT5				= 0x0d,	// 8 bpp
	
	
	TKIWIFormatDefault			= TKIWIFormatDXT5,
	
	TKIWINoFormat				= 1000
};
typedef NSUInteger TKIWIFormat;


enum {
	TKIWIFlagsNoMipmaps			= 0x03,
	TKIWIFlagsDoNotTile			= 0xc0
};



//TEXTUREKIT_EXTERN NSString *NSStringFromIWIFormat(TKIWIFormat aFormat);
//TEXTUREKIT_EXTERN TKIWIFormat TKIWIFormatFromString(NSString *aFormat);



TEXTUREKIT_EXTERN NSString * const TKIWIType;			//	com.infinityward.iwi
TEXTUREKIT_EXTERN NSString * const TKIWIFileType;		//	iwi
TEXTUREKIT_EXTERN NSString * const TKIWIPboardType;		

enum {
	TKIWIMagic					= 'IWi'
};



@interface TKIWIImageRep : TKImageRep <NSCoding, NSCopying> {
//	TKIWIHeader			header;
	
}

+ (NSArray *)imageRepsWithData:(NSData *)aData;

+ (id)imageRepWithData:(NSData *)aData;
- (id)initWithData:(NSData *)aData;

+ (TKIWIFormat)defaultFormat;
+ (void)setDefaultFormat:(TKIWIFormat)aFormat;


+ (NSData *)IWIRepresentationOfImageRepsInArray:(NSArray *)tkImageReps options:(NSDictionary *)options;
+ (NSData *)IWIRepresentationOfImageRepsInArray:(NSArray *)tkImageReps usingFormat:(TKIWIFormat)aFormat quality:(TKDXTCompressionQuality)aQuality options:(NSDictionary *)options;

@end


