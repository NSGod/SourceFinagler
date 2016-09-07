//
//  TKVTFImageRep.mm
//  Texture Kit
//
//  Created by Mark Douma on 9/25/2010.
//  Copyright (c) 2010-2014 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKVTFImageRep.h>
#import <TextureKit/TKError.h>
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>
#import "TKPrivateInterfaces.h"
#import "MDFoundationAdditions.h"
#import <VTF/VTF.h>
#import "TKPrivateCPPInterfaces.h"


#define TK_DEBUG 1



using namespace VTFLib;


enum {
	TKVTFHandlerNone,
	TKVTFHandlerNative,
	TKVTFHandlerVTFConvert,
};
typedef NSUInteger TKVTFHandler;


#define TKNone			TKVTFOperationNone
#define VTF_R			TKVTFOperationRead
#define VTF_RW			TKVTFOperationRead | TKVTFOperationWrite


typedef struct TKVTFFormatCreationInfo {
	TKPixelFormat			inputPixelFormat;
} TKVTFFormatCreationInfo;

static const TKVTFFormatCreationInfo TKVTFNoFormatCreationInfo = { };


typedef struct TKVTFFormatInfo {
	TKVTFFormat					format;
	VTFImageFormat				vtfFormat;
	VTFImageFormat				vtfConvertedFormat;
	TKPixelFormat				originalPixelFormat;
	TKVTFOperation				operationMask;
	TKVTFHandler				handler;
	TKPixelFormat				convertedPixelFormat;
	NSString					*description;
	TKVTFFormatCreationInfo		creationInfo;
} TKVTFFormatInfo;


static const TKVTFFormatInfo TKVTFFormatInfoTable[] = {
	{ TKVTFNoFormat,				IMAGE_FORMAT_NONE,				IMAGE_FORMAT_NONE,			TKPixelFormatUnknown,			TKNone,		TKVTFHandlerNone,			TKPixelFormatUnknown,		@"TKVTFNoFormat",	TKVTFNoFormatCreationInfo },
	
	{ TKVTFFormatDXT1,				IMAGE_FORMAT_DXT1,				IMAGE_FORMAT_RGB888,		TKPixelFormatUnknown,			VTF_RW,		TKVTFHandlerVTFConvert,		TKPixelFormatRGB,			@"DXT1",			{TKPixelFormatRGB} },
	{ TKVTFFormatDXT1a,				IMAGE_FORMAT_DXT1_ONEBITALPHA,	IMAGE_FORMAT_RGBA8888,		TKPixelFormatUnknown,			VTF_RW,		TKVTFHandlerVTFConvert,		TKPixelFormatRGBA,			@"DXT1a",			{TKPixelFormatRGBA} },
	{ TKVTFFormatDXT3,				IMAGE_FORMAT_DXT3,				IMAGE_FORMAT_RGBA8888,		TKPixelFormatUnknown,			VTF_RW,		TKVTFHandlerVTFConvert,		TKPixelFormatRGBA,			@"DXT3",			{TKPixelFormatRGBA} },
	{ TKVTFFormatDXT5,				IMAGE_FORMAT_DXT5,				IMAGE_FORMAT_RGBA8888,		TKPixelFormatUnknown,			VTF_RW,		TKVTFHandlerVTFConvert,		TKPixelFormatRGBA,			@"DXT5",			{TKPixelFormatRGBA} },

	{ TKVTFFormatI,					IMAGE_FORMAT_I8,				IMAGE_FORMAT_NONE,			TKPixelFormatL,					VTF_RW,		TKVTFHandlerNative,			TKPixelFormatL,				@"I",				{TKPixelFormatL}},
	{ TKVTFFormatIA,				IMAGE_FORMAT_IA88,				IMAGE_FORMAT_NONE,			TKPixelFormatLA,				VTF_RW,		TKVTFHandlerNative,			TKPixelFormatLA,			@"IA",				{TKPixelFormatLA} },
	{ TKVTFFormatP,					IMAGE_FORMAT_P8,				IMAGE_FORMAT_NONE,			TKPixelFormatUnknown,			TKNone,		TKVTFHandlerNone,			TKPixelFormatUnknown,		@"P",				TKVTFNoFormatCreationInfo },
	{ TKVTFFormatA,					IMAGE_FORMAT_A8,				IMAGE_FORMAT_NONE,			TKPixelFormatA,					VTF_RW,		TKVTFHandlerNative,			TKPixelFormatA,				@"A",				{TKPixelFormatA} },
	
	{ TKVTFFormatRGB565,			IMAGE_FORMAT_RGB565,			IMAGE_FORMAT_RGB888,		TKPixelFormatUnknown,			VTF_RW,		TKVTFHandlerVTFConvert,		TKPixelFormatRGB,			@"RGB565",			{TKPixelFormatRGB} },
	{ TKVTFFormatBGR565,			IMAGE_FORMAT_BGR565,			IMAGE_FORMAT_RGB888,		TKPixelFormatUnknown,			VTF_RW,		TKVTFHandlerVTFConvert,		TKPixelFormatRGB,			@"BGR565",			{TKPixelFormatRGB} },
	
	{ TKVTFFormatBGRA5551,			IMAGE_FORMAT_BGRA5551,			IMAGE_FORMAT_BGRA8888,		TKPixelFormatUnknown,			VTF_RW,		TKVTFHandlerVTFConvert,		TKPixelFormatBGRA,			@"BGRA5551",		{TKPixelFormatBGRA} },
	{ TKVTFFormatBGRA4444,			IMAGE_FORMAT_BGRA4444,			IMAGE_FORMAT_BGRA8888,		TKPixelFormatUnknown,			VTF_RW,		TKVTFHandlerVTFConvert,		TKPixelFormatBGRA,			@"BGRA4444",		{TKPixelFormatBGRA} },
	
	{ TKVTFFormatBGRX5551,			IMAGE_FORMAT_BGRX5551,			IMAGE_FORMAT_BGRX8888,		TKPixelFormatUnknown,			VTF_RW,		TKVTFHandlerVTFConvert,		TKPixelFormatBGRX,			@"BGRX5551",		{TKPixelFormatBGRX} },
	
	{ TKVTFFormatRGB,				IMAGE_FORMAT_RGB888,			IMAGE_FORMAT_NONE,			TKPixelFormatRGB,				VTF_RW,		TKVTFHandlerNative,			TKPixelFormatRGB,			@"RGB",				{TKPixelFormatRGB} },
	{ TKVTFFormatARGB,				IMAGE_FORMAT_ARGB8888,			IMAGE_FORMAT_NONE,			TKPixelFormatARGB,				VTF_RW,		TKVTFHandlerNative,			TKPixelFormatARGB,			@"ARGB",			{TKPixelFormatARGB} },
	{ TKVTFFormatRGBA,				IMAGE_FORMAT_RGBA8888,			IMAGE_FORMAT_NONE,			TKPixelFormatRGBA,				VTF_RW,		TKVTFHandlerNative,			TKPixelFormatRGBA,			@"RGBA",			{TKPixelFormatRGBA} },
	
	{ TKVTFFormatBGR,				IMAGE_FORMAT_BGR888,			IMAGE_FORMAT_NONE,			TKPixelFormatBGR,				VTF_RW,		TKVTFHandlerNative,			TKPixelFormatRGB,			@"BGR",				{TKPixelFormatBGR} },
	{ TKVTFFormatBGRA,				IMAGE_FORMAT_BGRA8888,			IMAGE_FORMAT_NONE,			TKPixelFormatBGRA,				VTF_RW,		TKVTFHandlerNative,			TKPixelFormatBGRA,			@"BGRA",			{TKPixelFormatBGRA} },
	{ TKVTFFormatABGR,				IMAGE_FORMAT_ABGR8888,			IMAGE_FORMAT_NONE,			TKPixelFormatABGR,				VTF_RW,		TKVTFHandlerNative,			TKPixelFormatABGR,			@"ABGR",			{TKPixelFormatABGR} },
	{ TKVTFFormatBGRX,				IMAGE_FORMAT_BGRX8888,			IMAGE_FORMAT_NONE,			TKPixelFormatBGRX,				VTF_RW,		TKVTFHandlerNative,			TKPixelFormatBGRX,			@"BGRX",			{TKPixelFormatBGRX} },
	
	{ TKVTFFormatBluescreenRGB,		IMAGE_FORMAT_RGB888_BLUESCREEN, IMAGE_FORMAT_RGB888,		TKPixelFormatUnknown,			VTF_RW,		TKVTFHandlerVTFConvert,		TKPixelFormatRGB,			@"Bluescreen RGB",	{TKPixelFormatRGB} },
	{ TKVTFFormatBluescreenBGR,		IMAGE_FORMAT_BGR888_BLUESCREEN,	IMAGE_FORMAT_RGB888,		TKPixelFormatUnknown,			VTF_RW,		TKVTFHandlerVTFConvert,		TKPixelFormatRGB,			@"Bluescreen BGR",	{TKPixelFormatRGB} },
	
	{ TKVTFFormatRGBA16161616,		IMAGE_FORMAT_RGBA16161616,		IMAGE_FORMAT_NONE,			TKPixelFormatRGBA16161616,		VTF_RW,		TKVTFHandlerNative,			TKPixelFormatRGBA16161616,	@"RGBA16161616",	{TKPixelFormatRGBA16161616} },
	{ TKVTFFormatRGBA16161616F,		IMAGE_FORMAT_RGBA16161616F,		IMAGE_FORMAT_NONE,			TKPixelFormatRGBA16161616F,		VTF_RW,		TKVTFHandlerNative,			TKPixelFormatRGBA32323232F,	@"RGBA16161616F",	{TKPixelFormatRGBA16161616F} },
	
	{ TKVTFFormatR32F,				IMAGE_FORMAT_R32F,				IMAGE_FORMAT_NONE,			TKPixelFormatR32F,				VTF_RW,		TKVTFHandlerNative,			TKPixelFormatR32F,			@"R32F",			{TKPixelFormatR32F} },
	{ TKVTFFormatRGB323232F,		IMAGE_FORMAT_RGB323232F,		IMAGE_FORMAT_NONE,			TKPixelFormatRGB323232F,		VTF_RW,		TKVTFHandlerNative,			TKPixelFormatRGB323232F,	@"RGB323232F",		{TKPixelFormatRGB323232F} },
	{ TKVTFFormatRGBA32323232F,		IMAGE_FORMAT_RGBA32323232F,		IMAGE_FORMAT_NONE,			TKPixelFormatRGBA32323232F,		VTF_RW,		TKVTFHandlerNative,			TKPixelFormatRGBA32323232F, @"RGBA32323232F",	{TKPixelFormatRGBA32323232F} },
	
	{ TKVTFFormatUV,				IMAGE_FORMAT_UV88,				IMAGE_FORMAT_RGBA8888,		TKPixelFormatUnknown,			VTF_RW,		TKVTFHandlerVTFConvert,		TKPixelFormatRGBA,			@"UV",				{TKPixelFormatRGBA} },
	{ TKVTFFormatUVWQ,				IMAGE_FORMAT_UVWQ8888,			IMAGE_FORMAT_RGBA8888,		TKPixelFormatUnknown,			VTF_RW,		TKVTFHandlerVTFConvert,		TKPixelFormatRGBA,			@"UVWQ",			{TKPixelFormatRGBA} },
	{ TKVTFFormatUVLX,				IMAGE_FORMAT_UVLX8888,			IMAGE_FORMAT_RGBA8888,		TKPixelFormatUnknown,			VTF_RW,		TKVTFHandlerVTFConvert,		TKPixelFormatRGBA,			@"UVLX",			{TKPixelFormatRGBA} },
	
	{ TKVTFFormatNVDST16,			IMAGE_FORMAT_NV_DST16,			IMAGE_FORMAT_NV_DST16,		TKPixelFormatUnknown,			TKNone,		TKVTFHandlerNone,			TKPixelFormatUnknown,		@"NVDST16",			TKVTFNoFormatCreationInfo },
	{ TKVTFFormatNVDST24,			IMAGE_FORMAT_NV_DST24,			IMAGE_FORMAT_NV_DST24,		TKPixelFormatUnknown,			TKNone,		TKVTFHandlerNone,			TKPixelFormatUnknown,		@"NVDST24",			TKVTFNoFormatCreationInfo },
	{ TKVTFFormatNVINTZ,			IMAGE_FORMAT_NV_INTZ,			IMAGE_FORMAT_NV_INTZ,		TKPixelFormatUnknown,			TKNone,		TKVTFHandlerNone,			TKPixelFormatUnknown,		@"NVINTZ",			TKVTFNoFormatCreationInfo },
	{ TKVTFFormatNVRAWZ,			IMAGE_FORMAT_NV_RAWZ,			IMAGE_FORMAT_NV_RAWZ,		TKPixelFormatUnknown,			TKNone,		TKVTFHandlerNone,			TKPixelFormatUnknown,		@"NVRAWZ",			TKVTFNoFormatCreationInfo },
	
	{ TKVTFFormatATIDST16,			IMAGE_FORMAT_ATI_DST16,			IMAGE_FORMAT_ATI_DST16,		TKPixelFormatUnknown,			TKNone,		TKVTFHandlerNone,			TKPixelFormatUnknown,		@"ATIDST16",		TKVTFNoFormatCreationInfo },
	{ TKVTFFormatATIDST24,			IMAGE_FORMAT_ATI_DST24,			IMAGE_FORMAT_ATI_DST24,		TKPixelFormatUnknown,			TKNone,		TKVTFHandlerNone,			TKPixelFormatUnknown,		@"ATIDST24",		TKVTFNoFormatCreationInfo },
	
	{ TKVTFFormatNVNULL,			IMAGE_FORMAT_NV_NULL,			IMAGE_FORMAT_NV_NULL,		TKPixelFormatUnknown,			TKNone,		TKVTFHandlerNone,			TKPixelFormatUnknown,		@"NVNULL",			TKVTFNoFormatCreationInfo },
	
	{ TKVTFFormatATI1N,				IMAGE_FORMAT_ATI1N,				IMAGE_FORMAT_ATI1N,			TKPixelFormatUnknown,			TKNone,		TKVTFHandlerNone,			TKPixelFormatUnknown,		@"ATI1N",			TKVTFNoFormatCreationInfo },
	{ TKVTFFormatATI2N,				IMAGE_FORMAT_ATI2N,				IMAGE_FORMAT_ATI2N,			TKPixelFormatUnknown,			TKNone,		TKVTFHandlerNone,			TKPixelFormatUnknown,		@"ATI2N",			TKVTFNoFormatCreationInfo },
	
};
static const NSUInteger TKVTFFormatInfoTableCount = TK_ARRAY_SIZE(TKVTFFormatInfoTable);


static TKVTFFormat availableFormats[TKVTFFormatInfoTableCount];



__attribute__((constructor)) static void TKVTFAvailableFormatsInit() {
	NSUInteger availableFormatsIndex = 0;
	
	for (NSUInteger i = 0; i < TKVTFFormatInfoTableCount; i++) {
		if (TKVTFFormatInfoTable[i].format != TKVTFNoFormat) {
			availableFormats[availableFormatsIndex] = TKVTFFormatInfoTable[i].format;
			availableFormatsIndex++;
		}
	}
	availableFormats[availableFormatsIndex] = TKVTFNoFormat;
}


TEXTUREKIT_STATIC_INLINE TKVTFFormatInfo TKVTFFormatInfoFromVTFFormat(TKVTFFormat aFormat) {
	NSCParameterAssert(aFormat < TKVTFFormatInfoTableCount);
	return TKVTFFormatInfoTable[aFormat];
}


TEXTUREKIT_STATIC_INLINE TKVTFFormatInfo TKVTFFormatInfoFromVTFImageFormat(VTFImageFormat aFormat) {
	for (NSUInteger i = 0; i < TKVTFFormatInfoTableCount; i++) {
		if (TKVTFFormatInfoTable[i].vtfFormat == aFormat) return TKVTFFormatInfoTable[i];
	}
	return TKVTFFormatInfoTable[0];
}



NSString * const TKVTFType			= @"com.valvesoftware.source.vtf";
NSString * const TKVTFFileType		= @"vtf";
NSString * const TKVTFPboardType	= @"com.valvesoftware.source.vtf";

NSString * const TKVTFUnsupportedFormatException	= @"TKVTFUnsupportedFormatException";


// NSCoding keys
static NSString * const TKVTFFormatKey				= @"TKVTFFormat";



static TKVTFFormat defaultVTFFormat = TKVTFFormatDefault;



@implementation TKVTFImageRep

@synthesize format;


+ (void)initialize {
	static BOOL vtfInitialized = NO;
	
	@synchronized(self) {
#if TK_DEBUG
		NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		if (!vtfInitialized) {
			vlInitialize();
			vtfInitialized = YES;
		}
	}
}


/* Implemented by subclassers to indicate what UTI-identified data types they can deal with. */
+ (NSArray *)imageUnfilteredTypes {
	static NSArray *imageUnfilteredTypes = nil;
	
	@synchronized(self) {
		if (imageUnfilteredTypes == nil) {
			imageUnfilteredTypes = [[NSArray alloc] initWithObjects:TKVTFType, nil];
		}
	}
	return imageUnfilteredTypes;
}



+ (NSArray *)imageUnfilteredFileTypes {
	static NSArray *imageUnfilteredFileTypes = nil;
	
	@synchronized(self) {
		if (imageUnfilteredFileTypes == nil) {
			imageUnfilteredFileTypes = [[NSArray alloc] initWithObjects:TKVTFFileType, nil];
		}
	}
	return imageUnfilteredFileTypes;
}


+ (NSArray *)imageUnfilteredPasteboardTypes {
	static NSArray *imageUnfilteredPasteboardTypes = nil;
	
	@synchronized(self) {
		if (imageUnfilteredPasteboardTypes == nil) {
			imageUnfilteredPasteboardTypes = [[[super imageUnfilteredPasteboardTypes] arrayByAddingObject:TKVTFPboardType] retain];
		}
	}
	return imageUnfilteredPasteboardTypes;
}


//+ (BOOL)canInitWithPasteboard:(NSPasteboard *)pasteboard {
//	
//}


+ (BOOL)canInitWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([aData length] < 4) return NO;
	OSType magic = 0;
	[aData getBytes:&magic length:sizeof(magic)];
	magic = NSSwapBigIntToHost(magic);
	return (magic == TKVTFMagic);
}

+ (Class)imageRepClassForType:(NSString *)type {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([type isEqualToString:TKVTFType]) {
		return [self class];
	}
	return [super imageRepClassForType:type];
}

+ (Class)imageRepClassForFileType:(NSString *)fileType {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([fileType isEqualToString:TKVTFFileType]) {
		return [self class];
	}
	return [super imageRepClassForFileType:fileType];
}


+ (const TKVTFFormat *)availableFormats {
	return (const TKVTFFormat *)availableFormats;
}


+ (NSArray *)availableFormatsForOperationMask:(TKVTFOperation)operationMask {
	NSMutableArray *availableFormats = [NSMutableArray array];
	
	for (NSUInteger i = 0; i < TKVTFFormatInfoTableCount; i++) {
		if (TKVTFFormatInfoTable[i].operationMask & operationMask) {
			[availableFormats addObject:[NSNumber numberWithUnsignedInteger:TKVTFFormatInfoTable[i].format]];
		}
	}
	return availableFormats;
}



+ (NSString *)localizedNameOfFormat:(TKVTFFormat)format {
	NSParameterAssert(format < TKVTFFormatInfoTableCount);
	return TKVTFFormatInfoTable[format].description;
}


+ (NSString *)localizedNameOfVTFImageFormat:(VTFImageFormat)format {
	NSParameterAssert(format < IMAGE_FORMAT_COUNT);
	return TKVTFFormatInfoFromVTFImageFormat(format).description;
}



+ (TKVTFOperation)operationMaskForFormat:(TKVTFFormat)format {
#if TK_DEBUG
//	NSLog(@"[%@ %@] format == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [[self class] localizedNameOfFormat:format]);
#endif
	NSParameterAssert(format < TKVTFFormatInfoTableCount);
	return TKVTFFormatInfoTable[format].operationMask;
}


+ (void)raiseUnsupportedFormatExceptionWithVTFFormat:(TKVTFFormat)aFormat {
#if TK_DEBUG
	NSLog(@"[%@ %@] aFormat == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [[self class] localizedNameOfFormat:aFormat]);
#endif
	[[NSException exceptionWithName:TKVTFUnsupportedFormatException reason:[NSString stringWithFormat:NSLocalizedString(@"\"%@\" is not a supported VTF format.", @""), [[self class] localizedNameOfFormat:aFormat]] userInfo:nil] raise];
}


+ (TKVTFFormat)defaultFormat {
	TKVTFFormat defaultFormat = 0;
	@synchronized(self) {
		defaultFormat = defaultVTFFormat;
	}
	return defaultFormat;
}

+ (void)setDefaultFormat:(TKVTFFormat)format {
	@synchronized(self) {
		if (([[self class] operationMaskForFormat:format] & TKVTFOperationWrite) != TKVTFOperationWrite) {
			[[self class] raiseUnsupportedFormatExceptionWithVTFFormat:format];
		}
		defaultVTFFormat = format;
	}
}


+ (BOOL)isDXTCompressionQualityApplicableToFormat:(TKVTFFormat)format {
	return (format == TKVTFFormatDXT1 ||
			format == TKVTFFormatDXT1a ||
			format == TKVTFFormatDXT3 ||
			format == TKVTFFormatDXT5);
}


#pragma mark - reading

+ (NSArray *)imageRepsWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[self class] imageRepsWithData:aData error:NULL];
}


+ (NSArray *)imageRepsWithData:(NSData *)aData error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[self class] imageRepsWithData:aData firstRepresentationOnly:NO error:outError];
}


+ (NSArray *)imageRepsWithData:(NSData *)aData firstRepresentationOnly:(BOOL)firstRepOnly error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	OSType magic = 0;
	[aData getBytes:&magic length:sizeof(magic)];
	magic = NSSwapBigIntToHost(magic);
#if TK_DEBUG
//	NSLog(@"[%@ %@] magic == 0x%x, %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), magic, NSFileTypeForHFSTypeCode(magic));
#endif
	
	CVTFFile file;
	
	if (file.Load([aData bytes], [aData length], vlFalse) == NO) {
		NSLog(@"[%@ %@] file.Load() failed! %@ appear to be a valid VTF; magic == 0x%x, %@, vlGetLastError() == %s", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (magic == TKVTFMagic ? @"DOES" : @"DOES NOT"), (unsigned int)magic, NSFileTypeForHFSTypeCode(magic), vlGetLastError());
		
		if (outError) {
			NSDictionary *userInfo = nil;
			
			const vlChar *errorString = vlGetLastError();
			
			if (errorString) {
				userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%s", errorString], NSLocalizedDescriptionKey, nil];
			}
			
			*outError = [NSError errorWithDomain:TKErrorDomain code:TKErrorCorruptVTFFile userInfo:userInfo];
		}
		return nil;
	}
	
	const VTFImageFormat imageFormat = file.GetFormat();
	
	const TKVTFFormatInfo formatInfo = TKVTFFormatInfoFromVTFImageFormat(imageFormat);
	
	if ((formatInfo.operationMask & TKVTFOperationRead) != TKVTFOperationRead) {
		if (outError) {
			*outError = [NSError errorWithDomain:TKErrorDomain
											code:TKErrorUnsupportedVTFFormat
										userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:NSLocalizedString(@"\"%@\" is not a supported VTF format.", @""), formatInfo.description], NSLocalizedDescriptionKey, nil]];
		}
		return nil;
	}
	
	const vlUInt frameCount = file.GetFrameCount();
	const vlUInt faceCount = file.GetFaceCount();
	const vlUInt mipmapCount = file.GetMipmapCount();
	const vlUInt sliceCount = file.GetDepth();
	
	const vlUInt imageWidth = file.GetWidth();
	const vlUInt imageHeight = file.GetHeight();
	
#if TK_DEBUG
//	NSLog(@"[%@ %@] sliceCount == %u, faceCount == %u, frameCount == %u, mipmapCount == %u", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sliceCount, faceCount, frameCount, mipmapCount);
#endif
	
	const TKPixelFormatInfo pixelFormatInfo = TKPixelFormatInfoFromPixelFormat(formatInfo.convertedPixelFormat);
	
	NSMutableArray *bitmapImageReps = [NSMutableArray array];
	
	for (NSUInteger mipmapIndex = 0; mipmapIndex < mipmapCount; mipmapIndex++) {
		for (NSUInteger frameIndex = 0; frameIndex < frameCount; frameIndex++) {
			for (NSUInteger faceIndex = 0; faceIndex < faceCount; faceIndex++) {
				for (NSUInteger sliceIndex = 0; sliceIndex < sliceCount; sliceIndex++) {
					
					vlUInt mipmapWidth = 0;
					vlUInt mipmapHeight = 0;
					vlUInt mipmapDepth = 0;
					
					NSData *mipmapData = nil;
					
					CVTFFile::ComputeMipmapDimensions(imageWidth, imageHeight, sliceCount, mipmapIndex, mipmapWidth, mipmapHeight, mipmapDepth);
					
					vlByte *existingBytes = file.GetData(frameIndex, faceIndex, sliceIndex, mipmapIndex);
					
					if (existingBytes == 0) {
						NSLog(@"[%@ %@] failed to get existing data for sliceIndex == %lu, faceIndex == %lu, frameIndex == %lu, mipmapIndex == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)sliceIndex, (unsigned long)faceIndex, (unsigned long)frameIndex, (unsigned long)mipmapIndex);
						continue;
					}
					
					if (formatInfo.handler == TKVTFHandlerVTFConvert) {
						// need to convert existing VTF format data into something compatible with Quartz by using VTFLib-based conversion
						
						vlUInt mipmapBytesLength = CVTFFile::ComputeMipmapSize(imageWidth, imageHeight, sliceCount, mipmapIndex, formatInfo.vtfConvertedFormat);
						
						vlByte *convertedBytes = new vlByte[mipmapBytesLength]();
						
						if (convertedBytes == 0) {
							NSLog(@"[%@ %@] new [%lu] failed! sliceIndex == %lu, faceIndex == %lu, frameIndex == %lu, mipmapIndex == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)mipmapBytesLength,(unsigned long) sliceIndex, (unsigned long)faceIndex, (unsigned long)frameIndex, (unsigned long)mipmapIndex);
							continue;
						}
						
						if (!CVTFFile::Convert(existingBytes, convertedBytes, mipmapWidth, mipmapHeight, imageFormat, formatInfo.vtfConvertedFormat)) {
							NSLog(@"[%@ %@] CVTFFile::Convert() failed! sliceIndex == %lu, faceIndex == %lu, frameIndex == %lu, mipmapIndex == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)sliceIndex, (unsigned long)faceIndex, (unsigned long)frameIndex, (unsigned long)mipmapIndex);
							delete [] convertedBytes;
							continue;
						}
						
						mipmapData = [[NSData alloc] initWithBytes:convertedBytes length:mipmapBytesLength];
						
						delete [] convertedBytes;
						
					} else if (formatInfo.handler == TKVTFHandlerNative) {
						
						// no VTFLib-based conversion needed
						
						vlUInt mipmapBytesLength = CVTFFile::ComputeMipmapSize(imageWidth, imageHeight, sliceCount, mipmapIndex, formatInfo.vtfFormat);
						
						NSData *surfaceData = [[NSData alloc] initWithBytes:existingBytes length:mipmapBytesLength];
						
						if (formatInfo.originalPixelFormat != formatInfo.convertedPixelFormat) {
							// need to convert data before Quartz can use it...
							// For example, we need to convert from TKPixelFormatRGBA16161616F (16 bpc floating point) to TKPixelFormatRGBA32323232F (32 bpc floating point), which Quartz can understand
							
							NSData *convertedMipmapData = [TKDDSImageRep dataByConvertingData:surfaceData
																					 inFormat:formatInfo.originalPixelFormat
																					 toFormat:formatInfo.convertedPixelFormat
																				   pixelCount:mipmapWidth * mipmapHeight
																					  options:(formatInfo.originalPixelFormat == TKPixelFormatRGBA16161616F ? TKPixelFormatConversionIgnoreAlpha : TKPixelFormatConversionOptionsDefault)];
							
							if (convertedMipmapData == nil) {
								NSLog(@"[%@ %@] ERROR: failed to convert data from %@ to %@! sliceIndex == %lu, faceIndex == %lu, frameIndex == %lu, mipmapIndex == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd),
									  TKStringFromPixelFormat(formatInfo.originalPixelFormat), TKStringFromPixelFormat(formatInfo.convertedPixelFormat), (unsigned long)sliceIndex, (unsigned long)faceIndex, (unsigned long)frameIndex, (unsigned long)mipmapIndex);
								[surfaceData release];
								continue;
							}
							
							mipmapData = [convertedMipmapData retain];
							
							[surfaceData release];
							
						} else {
							// no conversion necessary for Quartz to be able to use the data
							mipmapData = surfaceData;
							
						}
					}
					
#if 0
					if (pixelFormatInfo.bitmapInfo & kCGBitmapFloatComponents) {
						if (mipmapIndex == 0 && mipmapData.length > 512) {
							NSData *subdata = [mipmapData subdataWithRange:NSMakeRange(0, 512)];
							NSLog(@"[%@ %@] surfaceData == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [subdata enhancedFloatDescriptionForComponentCount:4]);
						}
					}
#endif
					
					CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)mipmapData);
					[mipmapData release];
					
//					CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName((CFStringRef)pixelFormatInfo.colorSpaceName);
//					CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName((CFStringRef)(formatInfo.originalPixelFormat == TKPixelFormatUnknown ? pixelFormatInfo.colorSpaceName : TKPixelFormatInfoFromPixelFormat(formatInfo.originalPixelFormat).colorSpaceName));
					
//					CGColorSpaceRef colorSpace = NULL;
//					
//					if (pixelFormatInfo.colorSpaceName) {
//						colorSpace = CGColorSpaceCreateWithName((CFStringRef)pixelFormatInfo.colorSpaceName);
//					}
					
					CGColorSpaceRef colorSpace = TKCreateColorSpaceFromColorSpace(pixelFormatInfo.colorSpace);
					
					CGImageRef imageRef = CGImageCreate(mipmapWidth,
														mipmapHeight,
														pixelFormatInfo.bitsPerComponent,
														pixelFormatInfo.bitsPerPixel,
														((pixelFormatInfo.bitsPerPixel + 7)/ 8) * mipmapWidth,
														colorSpace,
														pixelFormatInfo.bitmapInfo,
														provider,
														NULL,
														false,
														kCGRenderingIntentDefault);
					
					CGColorSpaceRelease(colorSpace);
					CGDataProviderRelease(provider);
					
					if (imageRef == NULL) {
						NSLog(@"[%@ %@] CGImageCreate() (for sliceIndex == %lu, faceIndex == %lu, frameIndex == %lu, mipmapIndex == %lu) failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)sliceIndex, (unsigned long)faceIndex, (unsigned long)frameIndex, (unsigned long)mipmapIndex);
						continue;
					}
					
					TKVTFImageRep *imageRep = [[TKVTFImageRep alloc] initWithCGImage:imageRef
																		  sliceIndex:(sliceCount > 1 ? sliceIndex : TKSliceIndexNone)
																				face:(faceCount > 1 ? faceIndex : TKFaceNone)
																		  frameIndex:(frameCount > 1 ? frameIndex : TKFrameIndexNone)
																		 mipmapIndex:mipmapIndex];
					
					imageRep.format = formatInfo.format;
					
					imageRep.imageProperties = [NSDictionary dictionaryWithObjectsAndKeys:
												[NSString stringWithFormat:@"%u.%u", file.GetMajorVersion(), file.GetMinorVersion()],TKImagePropertyVersion,
												[NSNumber numberWithBool:(pixelFormatInfo.bitmapInfo & kCGBitmapFloatComponents)],(id)kCGImagePropertyIsFloat,
												[NSNumber numberWithUnsignedInteger:imageRep.pixelsWide],kCGImagePropertyPixelWidth,
												[NSNumber numberWithUnsignedInteger:imageRep.pixelsHigh],kCGImagePropertyPixelHeight,
												[NSNumber numberWithUnsignedInteger:pixelFormatInfo.bitsPerComponent],kCGImagePropertyDepth,
												[NSNumber numberWithBool:TKHasAlpha((pixelFormatInfo.bitmapInfo & kCGBitmapAlphaInfoMask))],kCGImagePropertyHasAlpha,
												nil];
					
					CGImageRelease(imageRef);
					
					if (imageRep) [bitmapImageReps addObject:imageRep];
					
					[imageRep release];
					
					if (firstRepOnly && frameIndex == 0 && faceIndex == 0 && sliceIndex == 0 && mipmapIndex == 0) {
						return [[bitmapImageReps copy] autorelease];
					}
					
				}
			}
		}
	}
	return [[bitmapImageReps copy] autorelease];
}


+ (id)imageRepWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[self class] imageRepWithData:aData error:NULL];
}


+ (id)imageRepWithData:(NSData *)aData error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSArray *imageReps = [[self class] imageRepsWithData:aData firstRepresentationOnly:YES error:outError];
	if ([imageReps count]) return [imageReps objectAtIndex:0];
	return nil;
}


- (id)initWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self initWithData:aData error:NULL];
}


- (id)initWithData:(NSData *)aData error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSArray *imageReps = [[self class] imageRepsWithData:aData firstRepresentationOnly:YES error:outError];
	if ((imageReps == nil) || !([imageReps count] > 0)) {
		[self release];
		return nil;
	}
	self = [[imageReps objectAtIndex:0] retain];
	return self;
}


- (id)copyWithZone:(NSZone *)zone {
	TKVTFImageRep *copy = (TKVTFImageRep *)[super copyWithZone:zone];
#if TK_DEBUG
	NSLog(@"[%@ %@] copy == %@, class == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), copy, NSStringFromClass([copy class]));
#endif
	return copy;
}


- (id)initWithCoder:(NSCoder *)coder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithCoder:coder])) {
		format = [[coder decodeObjectForKey:TKVTFFormatKey] unsignedIntegerValue];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super encodeWithCoder:coder];
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:format] forKey:TKVTFFormatKey];
}


#pragma mark - writing

+ (NSData *)VTFRepresentationOfImageRepsInArray:(NSArray *)tkImageReps options:(NSDictionary *)options error:(NSError **)outError {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[self class] VTFRepresentationOfImageRepsInArray:tkImageReps usingFormat:[[self class] defaultFormat] quality:[TKImageRep defaultDXTCompressionQuality] options:options error:outError];
}


+ (NSData *)VTFRepresentationOfImageRepsInArray:(NSArray *)tkImageReps usingFormat:(TKVTFFormat)format quality:(TKDXTCompressionQuality)aQuality options:(NSDictionary *)options error:(NSError **)outError {
#if TK_DEBUG
//	NSLog(@"[%@ %@] aFormat == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [[self class] localizedNameOfFormat:format]);
#endif
	NSParameterAssert([tkImageReps count] > 0);
	
	// outError isn't implemented yet, so set it to nil in case it's tried to be used if we return nil
	if (outError) *outError = nil;
	
	if (([[self class] operationMaskForFormat:format] & TKVTFOperationWrite) != TKVTFOperationWrite) {
		[[self class] raiseUnsupportedFormatExceptionWithVTFFormat:format];
	}
	
	BOOL allRepsHaveDimensionsThatArePowerOfTwo = YES;
	
	NSMutableArray *revisedImageReps = [NSMutableArray array];
	
	for (NSImageRep *imageRep in tkImageReps) {
		if ([imageRep isKindOfClass:[TKImageRep class]]) {
			[revisedImageReps addObject:imageRep];
			allRepsHaveDimensionsThatArePowerOfTwo = allRepsHaveDimensionsThatArePowerOfTwo && [(TKImageRep *)imageRep hasDimensionsThatArePowerOfTwo];
		} else {
			NSLog(@"[%@ %@] imageRep (%@) is NOT a TKImageRep!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), imageRep);
		}
	}
	
	NSNumber *nMipmapType = [options objectForKey:TKImageMipmapGenerationKey];
//	NSNumber *nWrapMode = [options objectForKey:TKImageWrapModeKey];
	NSNumber *nResizeMode = [options objectForKey:TKImageResizeModeKey];
	NSNumber *nResizeFilter = [options objectForKey:TKImageResizeFilterKey];
	
	if (allRepsHaveDimensionsThatArePowerOfTwo == NO && nResizeMode && [nResizeMode unsignedIntegerValue] != TKResizeModeNone) {
		// need to resize the images to be a power of two prior to creating the VTF image
		
		TKResizeMode resizeMode = [nResizeMode unsignedIntegerValue];
		TKResizeFilter resizeFilter = [nResizeFilter unsignedIntegerValue];
		
		NSMutableArray *resizedImageReps = [NSMutableArray array];
		
		for (TKImageRep *imageRep in revisedImageReps) {
			TKImageRep *resizedImageRep = [imageRep imageRepByResizingUsingResizeMode:resizeMode resizeFilter:resizeFilter];
			if (resizedImageRep) [resizedImageReps addObject:resizedImageRep];
			
		}
		
		[revisedImageReps setArray:resizedImageReps];
	}
	
	NSUInteger maxWidth = 0;
	NSUInteger maxHeight = 0;
	
	NSUInteger sliceCount = 1;
	NSUInteger faceCount = 1;
	NSUInteger frameCount = 1;
	
	NSUInteger maxSliceIndex = 0;
	NSUInteger maxFaceIndex = 0;
	NSUInteger maxFrameIndex = 0;
	
	NSUInteger maxMipmapIndex = 0;
	
	
	for (TKImageRep *imageRep in revisedImageReps) {
		
		maxWidth = MAX(imageRep.pixelsWide, maxWidth);
		maxHeight = MAX(imageRep.pixelsHigh, maxHeight);
		
		if (imageRep.sliceIndex != TKSliceIndexNone) maxSliceIndex = MAX(imageRep.sliceIndex, maxSliceIndex);
		if (imageRep.face != TKFaceNone) maxFaceIndex = MAX(imageRep.face, maxFaceIndex);
		if (imageRep.frameIndex != TKFrameIndexNone) maxFrameIndex = MAX(imageRep.frameIndex, maxFrameIndex);
		
		maxMipmapIndex = MAX(imageRep.mipmapIndex, maxMipmapIndex);
	}
	
	if (maxSliceIndex > 0) sliceCount = maxSliceIndex + 1;
	if (maxFaceIndex > 0) faceCount = maxFaceIndex + 1;
	if (maxFrameIndex > 0) frameCount = maxFrameIndex + 1;
	
	
	if (nMipmapType && [nMipmapType unsignedIntegerValue] != TKMipmapGenerationNoMipmaps) {
		// generate mipmaps prior to creating VTF file
		
		TKMipmapGenerationType mipmapType = [nMipmapType unsignedIntegerValue];
		
		// gather all imageReps whose mipmapIndex == 0
		NSMutableArray *topLevelMipmaps = [NSMutableArray array];
		
		if (maxMipmapIndex > 0) {
			
			for (TKImageRep *imageRep in revisedImageReps) {
				if (imageRep.mipmapIndex == 0) [topLevelMipmaps addObject:imageRep];
			}
			
		} else {
			[topLevelMipmaps setArray:revisedImageReps];
		}
		
		NSMutableArray *allMipmapImageReps = [NSMutableArray arrayWithArray:topLevelMipmaps];
		
		for (TKImageRep *imageRep in topLevelMipmaps) {
			NSArray *mipmapImageReps = [imageRep mipmapImageRepsUsingFilter:mipmapType];
			if (mipmapImageReps) [allMipmapImageReps addObjectsFromArray:mipmapImageReps];
		}
		
		[revisedImageReps setArray:allMipmapImageReps];
	}
	
	vlSetInteger(VTFLIB_DXT_QUALITY, TKDXTCompressionQualityInfoFromDXTCompressionQuality(aQuality).vtfQuality);
	
	vlBool generateMipmaps = vlTrue;
	
	if (nMipmapType == nil || [nMipmapType unsignedIntegerValue] == TKMipmapGenerationNoMipmaps) {
		generateMipmaps = vlFalse;
	}
	
	// use pointer in case conversion is needed
	
	CVTFFile *vtfFile = new CVTFFile();
	
	TKVTFFormatInfo formatInfo = TKVTFFormatInfoFromVTFFormat(format);
	TKVTFFormatCreationInfo creationInfo = formatInfo.creationInfo;
	
	if (formatInfo.handler == TKVTFHandlerNative) {
		if (!vtfFile->Create(maxWidth, maxHeight, frameCount, faceCount, sliceCount, formatInfo.vtfFormat, vlFalse, generateMipmaps, vlTrue)) {
			NSLog(@"[%@ %@] vtfFile->Create() failed! vlGetLastError() == %s", NSStringFromClass([self class]), NSStringFromSelector(_cmd), vlGetLastError());
			
			if (outError) {
				NSDictionary *userInfo = nil;
				const vlChar *errorString = vlGetLastError();
				if (errorString) {
					userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%s", errorString], NSLocalizedDescriptionKey, nil];
				}
				// TODO: better error code
				*outError = [NSError errorWithDomain:TKErrorDomain code:TKErrorUnknown userInfo:userInfo];
			}
			
			delete vtfFile;
			return nil;
		}
	} else if (formatInfo.handler == TKVTFHandlerVTFConvert) {
		if (!vtfFile->Create(maxWidth, maxHeight, frameCount, faceCount, sliceCount, formatInfo.vtfConvertedFormat, vlFalse, generateMipmaps, vlTrue)) {
			NSLog(@"[%@ %@] vtfFile->Create() failed! vlGetLastError() == %s", NSStringFromClass([self class]), NSStringFromSelector(_cmd), vlGetLastError());
			
			if (outError) {
				NSDictionary *userInfo = nil;
				const vlChar *errorString = vlGetLastError();
				if (errorString) {
					userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%s", errorString], NSLocalizedDescriptionKey, nil];
				}
				// TODO: better error code
				*outError = [NSError errorWithDomain:TKErrorDomain code:TKErrorUnknown userInfo:userInfo];
			}
			
			delete vtfFile;
			return nil;
		}
	}
	
	for (TKImageRep *imageRep in revisedImageReps) {
		vlUInt frameIndex = (vlUInt)(imageRep.frameIndex == TKFrameIndexNone ? 0 : imageRep.frameIndex);
		vlUInt faceIndex = (vlUInt)(imageRep.face == TKFaceNone ? 0 : imageRep.face);
		vlUInt sliceIndex = (vlUInt)(imageRep.sliceIndex == TKSliceIndexNone ? 0 : imageRep.sliceIndex);
		vlUInt mipmapIndex = (vlUInt)(imageRep.mipmapIndex == TKMipmapIndexNone ? 0 : imageRep.mipmapIndex);
		
//		NSData *imageRepData = [imageRep dataByConvertingToPixelFormat:creationInfo.inputPixelFormat];
		NSData *imageRepData = [imageRep dataByConvertingToPixelFormat:creationInfo.inputPixelFormat options:TKPixelFormatConversionUseColorManagement];
		
		if (imageRepData == nil) {
			NSLog(@"[%@ %@] [imageRep dataByConvertingToPixelFormat:options:] attempt to convert %@   --->   %@ returned nil!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), TKStringFromPixelFormat(imageRep.pixelFormat), TKStringFromPixelFormat(creationInfo.inputPixelFormat));
			delete vtfFile;
			return nil;
		}
		
		vtfFile->SetData(frameIndex, faceIndex, sliceIndex, mipmapIndex, (vlByte *)[imageRepData bytes]);
	}
	
	if (formatInfo.handler == TKVTFHandlerVTFConvert) {
		CVTFFile *convertedFile = new CVTFFile(*vtfFile, formatInfo.vtfFormat);
		
		if (convertedFile == 0) {
			NSLog(@"[%@ %@] CVTFFile(copy) failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			delete vtfFile;
			return nil;
		}
		delete vtfFile;
		
		vtfFile = convertedFile;
		
	}
	
	unsigned char *fileBytes = (unsigned char *)malloc(vtfFile->GetSize());
	if (fileBytes == NULL) {
		NSLog(@"[%@ %@] malloc(%llu) failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long long)vtfFile->GetSize());
		delete vtfFile;
		return nil;
	}
	
	vlUInt totalSize = 0;
	
	if (!vtfFile->Save((vlVoid *)fileBytes, vtfFile->GetSize(), totalSize)) {
		NSLog(@"[%@ %@] vtfFile->Save() failed! vlGetLastError() == %s", NSStringFromClass([self class]), NSStringFromSelector(_cmd), vlGetLastError());
		free(fileBytes);
		delete vtfFile;
		return nil;
	}
	delete vtfFile;
	
	NSData *representation = [NSData dataWithBytes:fileBytes length:totalSize];
	free(fileBytes);
	return representation;
}



#pragma mark -


- (NSString *)description {
	return [[super description] stringByAppendingFormat:@" format == %@", [[self class] localizedNameOfFormat:format]];
}

@end

