//
//  TKVTFImageRep.mm
//  Texture Kit
//
//  Created by Mark Douma on 9/25/2010.
//  Copyright (c) 2010-2013 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKVTFImageRep.h>
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>
#import <VTF/VTF.h>

#define TK_DEBUG 1

#import "TKPrivateInterfaces.h"



#if TK_DEBUG
#import "MDFoundationAdditions.h"
#endif

using namespace VTFLib;


struct TKVTFFormatMapping {
	TKVTFFormat		format;
	VTFImageFormat	vtfFormat;
	TKPixelFormat	pixelFormat;
	TKPixelFormat	nativePixelFormat;
	NSString		*description;
};
	
static const TKVTFFormatMapping TKVTFFormatMappingTable[] = {
	{ TKVTFFormatRGB,			IMAGE_FORMAT_RGB888,			TKPixelFormatRGB,		TKPixelFormatRGB,		@"RGB" },
	{ TKVTFFormatDXT1,			IMAGE_FORMAT_DXT1,				TKPixelFormatRGB,		TKPixelFormatRGB,		@"DXT1" },
	{ TKVTFFormatDXT1a,			IMAGE_FORMAT_DXT1_ONEBITALPHA,	TKPixelFormatRGBA,		TKPixelFormatRGBA,		@"DXT1a" },
	{ TKVTFFormatDXT3,			IMAGE_FORMAT_DXT3,				TKPixelFormatRGBA,		TKPixelFormatRGBA,		@"DXT3" },
	{ TKVTFFormatDXT5,			IMAGE_FORMAT_DXT5,				TKPixelFormatRGBA,		TKPixelFormatRGBA,		@"DXT5" },
	
	{ TKVTFFormatRGBA,			IMAGE_FORMAT_RGBA8888,			TKPixelFormatRGBA,		TKPixelFormatRGBA,		@"RGBA" },
	{ TKVTFFormatARGB,			IMAGE_FORMAT_ARGB8888,			TKPixelFormatARGB,		TKPixelFormatARGB,		@"ARGB" },
	
	{ TKVTFFormatBluescreenRGB,	IMAGE_FORMAT_RGB888_BLUESCREEN, TKPixelFormatRGB,		TKPixelFormatRGB,		@"BluescreenRGB" },
	{ TKVTFFormatRGB565,		IMAGE_FORMAT_RGB565,			TKPixelFormatRGB565,	TKPixelFormatRGB,		@"RGB565" },
	
	{ TKVTFFormatBGR,			IMAGE_FORMAT_BGR888,			TKPixelFormatRGB,		TKPixelFormatRGB,		@"BGR"  },
	{ TKVTFFormatBGRA,			IMAGE_FORMAT_BGRA8888,			TKPixelFormatBGRA,		TKPixelFormatRGBA,		@"BGRA" },
	{ TKVTFFormatBGRX,			IMAGE_FORMAT_BGRX8888,			TKPixelFormatRGBA,		TKPixelFormatRGB,		@"BGRX" },
	{ TKVTFFormatABGR,			IMAGE_FORMAT_ABGR8888,			TKPixelFormatARGB,		TKPixelFormatRGBA,		@"ABGR" },
	
	{ TKVTFFormatBluescreenBGR,	IMAGE_FORMAT_BGR888_BLUESCREEN,	TKPixelFormatRGBA,		TKPixelFormatRGBA,		 @"BluescreenBGR"  },
	{ TKVTFFormatBGR565,		IMAGE_FORMAT_BGR565,			TKPixelFormatRGBA,		TKPixelFormatRGBA,		 @"BGR565" },
	{ TKVTFFormatBGRX5551,		IMAGE_FORMAT_BGRX5551,			TKPixelFormatRGBA,		TKPixelFormatRGBA,		 @"BGRX5551" },
	{ TKVTFFormatBGRA5551,		IMAGE_FORMAT_BGRA5551,			TKPixelFormatRGBA,		TKPixelFormatRGBA,		 @"BGRA5551"  },
	{ TKVTFFormatBGRA4444,		IMAGE_FORMAT_BGRA4444,			TKPixelFormatRGBA,		TKPixelFormatRGBA,			@"BGRA4444" },
	
	{ TKVTFFormatRGBA16161616,	IMAGE_FORMAT_RGBA16161616, TKPixelFormatRGBA16161616,	TKPixelFormatRGBA16161616,		 @"RGBA16161616"  },
	{ TKVTFFormatRGBA16161616F,	IMAGE_FORMAT_RGBA16161616F, TKPixelFormatRGBA16161616F,	TKPixelFormatRGBA32323232F,		 @"RGBA16161616F" },
	
	{ TKVTFFormatR32F,			IMAGE_FORMAT_R32F,				TKPixelFormatL32F,		TKPixelFormatL32F,				@"R32F" },
	{ TKVTFFormatRGB323232F,	IMAGE_FORMAT_RGB323232F,		TKPixelFormatRGB323232F,		TKPixelFormatRGB323232F,		 @"RGB323232F" },
	{ TKVTFFormatRGBA32323232F,	IMAGE_FORMAT_RGBA32323232F,		TKPixelFormatRGBA32323232F, TKPixelFormatRGBA32323232F,			@"RGBA32323232F" },
	
	{ TKVTFFormatI,				IMAGE_FORMAT_I8,				TKPixelFormatL,			TKPixelFormatL,						@"I" },
	{ TKVTFFormatIA,			IMAGE_FORMAT_IA88,				TKPixelFormatLA,		TKPixelFormatLA,				@"IA" },
//	{ TKVTFFormatP,				IMAGE_FORMAT_P8, TKPixelFormatRGBA, @"P" },
	{ TKVTFFormatA,				IMAGE_FORMAT_A8,				TKPixelFormatA,			TKPixelFormatA,								@"A" },
	
	{ TKVTFFormatUV,			IMAGE_FORMAT_UV88,				TKPixelFormatRGBA,		TKPixelFormatRGBA,							@"UV"  },
	{ TKVTFFormatUVWQ,			IMAGE_FORMAT_UVWQ8888,			TKPixelFormatRGBA,		TKPixelFormatRGBA,							@"UVWQ"  },
	{ TKVTFFormatUVLX,			IMAGE_FORMAT_UVLX8888,			TKPixelFormatRGBA,		TKPixelFormatRGBA,							@"UVLX"  },
	{ TKVTFFormatNVDST16,		IMAGE_FORMAT_NV_DST16,			TKPixelFormatRGBA,		TKPixelFormatRGBA,							@"NVDST16"  },
	{ TKVTFFormatNVDST24,		IMAGE_FORMAT_NV_DST24,			TKPixelFormatRGBA,		TKPixelFormatRGBA,							@"NVDST24" },
	{ TKVTFFormatNVINTZ,		IMAGE_FORMAT_NV_INTZ,			TKPixelFormatRGBA,		TKPixelFormatRGBA,							@"NVINTZ" },
	{ TKVTFFormatNVRAWZ,		IMAGE_FORMAT_NV_RAWZ,			TKPixelFormatRGBA,		TKPixelFormatRGBA,							@"NVRAWZ"  },
	{ TKVTFFormatATIDST16,		IMAGE_FORMAT_ATI_DST16,			TKPixelFormatRGBA,		TKPixelFormatRGBA,							@"ATIDST16" },
	{ TKVTFFormatATIDST24,		IMAGE_FORMAT_ATI_DST24,			TKPixelFormatRGBA,		TKPixelFormatRGBA,							@"ATIDST24"  },
	{ TKVTFFormatNVNULL,		IMAGE_FORMAT_NV_NULL,			TKPixelFormatRGBA,		TKPixelFormatRGBA,							@"NVNULL"  },
	{ TKVTFFormatATI2N,			IMAGE_FORMAT_ATI2N,				TKPixelFormatRGBA,		TKPixelFormatRGBA,							@"ATI2N" },
	{ TKVTFFormatATI1N,			IMAGE_FORMAT_ATI1N,				TKPixelFormatRGBA,		TKPixelFormatRGBA,							@"ATI1N" }
};
static const NSUInteger TKVTFFormatMappingTableCount = sizeof(TKVTFFormatMappingTable)/sizeof(TKVTFFormatMappingTable[0]);


NSString *NSStringFromVTFFormat(TKVTFFormat aFormat) {
	for (NSUInteger i = 0; i < TKVTFFormatMappingTableCount; i++) {
		if (TKVTFFormatMappingTable[i].format == aFormat) {
			return TKVTFFormatMappingTable[i].description;
		}
	}
	return @"<Unknown>";
}

TKVTFFormat TKVTFFormatFromString(NSString *aFormat) {
	for (NSUInteger i = 0; i < TKVTFFormatMappingTableCount; i++) {
		if ([TKVTFFormatMappingTable[i].description isEqualToString:aFormat]) {
			return TKVTFFormatMappingTable[i].format;
		}
	}
	return [TKVTFImageRep defaultFormat];
}

	
static inline VTFImageFormat VTFImageFormatFromTKVTFFormat(TKVTFFormat aFormat) {
	for (NSUInteger i = 0; i < TKVTFFormatMappingTableCount; i++) {
		if (TKVTFFormatMappingTable[i].format == aFormat) {
			return TKVTFFormatMappingTable[i].vtfFormat;
		}
	}
	return IMAGE_FORMAT_NONE;
}

static inline TKPixelFormat TKPixelFormatFromVTFImageFormat(VTFImageFormat aFormat) {
	for (NSUInteger i = 0; i < TKVTFFormatMappingTableCount; i++) {
		if (TKVTFFormatMappingTable[i].vtfFormat == aFormat) {
			return TKVTFFormatMappingTable[i].pixelFormat;
		}
	}
	return TKPixelFormatUnknown;
}

static inline TKPixelFormat TKNativePixelFormatFromVTFImageFormat(VTFImageFormat aFormat) {
	for (NSUInteger i = 0; i < TKVTFFormatMappingTableCount; i++) {
		if (TKVTFFormatMappingTable[i].vtfFormat == aFormat) {
			return TKVTFFormatMappingTable[i].nativePixelFormat;
		}
	}
	return TKPixelFormatUnknown;
}



struct TKVTFMipmapGenerationMapping {
	VTFMipmapFilter				mipmapFilter;
	TKMipmapGenerationType		mipmapGenerationType;
};
static const TKVTFMipmapGenerationMapping TKVTFMipmapGenerationMappingTable[] = {
	{ MIPMAP_FILTER_BOX, TKMipmapGenerationUsingBoxFilter },
	{ MIPMAP_FILTER_TRIANGLE, TKMipmapGenerationUsingTriangleFilter },
	{ MIPMAP_FILTER_KAISER, TKMipmapGenerationUsingKaiserFilter }
};
static const NSUInteger TKVTFMipmapGenerationTableCount = sizeof(TKVTFMipmapGenerationMappingTable)/sizeof(TKVTFMipmapGenerationMappingTable[0]);

static inline VTFMipmapFilter VTFMipmapFilterFromTKMipmapGenerationType(TKMipmapGenerationType mipmapGenerationType) {
	for (NSUInteger i = 0; i < TKVTFMipmapGenerationTableCount; i++) {
		if (TKVTFMipmapGenerationMappingTable[i].mipmapGenerationType == mipmapGenerationType) {
			return TKVTFMipmapGenerationMappingTable[i].mipmapFilter;
		}
	}
	return MIPMAP_FILTER_BOX;
}

struct TKVTFDXTQualityMapping {
	TKDXTCompressionQuality		quality;
	VTFDXTQuality				vtfDXTQuality;
};

static const TKVTFDXTQualityMapping TKVTFDXTQualityMappingTable[] = {
	{TKDXTCompressionLowQuality, DXT_QUALITY_LOW },
	{TKDXTCompressionMediumQuality, DXT_QUALITY_MEDIUM },
	{TKDXTCompressionHighQuality, DXT_QUALITY_HIGH },
	{TKDXTCompressionHighestQuality, DXT_QUALITY_HIGHEST }
};
static const NSUInteger TKVTFDXTQualityMappingTableCount = sizeof(TKVTFDXTQualityMappingTable)/sizeof(TKVTFDXTQualityMappingTable[0]);

static inline VTFDXTQuality VTFDXTQualityFromTKDXTCompressionQuality(TKDXTCompressionQuality compressionQuality) {
	for (NSUInteger i = 0; i < TKVTFDXTQualityMappingTableCount; i++) {
		if (TKVTFDXTQualityMappingTable[i].quality == compressionQuality) {
			return TKVTFDXTQualityMappingTable[i].vtfDXTQuality;
		}
	}
	return DXT_QUALITY_HIGH;
}



NSString * const TKVTFType			= @"com.valvesoftware.source.vtf";
NSString * const TKVTFFileType		= @"vtf";
NSString * const TKVTFPboardType	= @"com.valvesoftware.source.vtf";


@interface TKVTFImageRep (TKPrivate)
+ (NSArray *)imageRepsWithData:(NSData *)aData firstRepresentationOnly:(BOOL)firstRepOnly;
@end


static TKVTFFormat defaultVTFFormat = TKVTFFormatDefault;

static BOOL vtfInitialized = NO;

@implementation TKVTFImageRep


+ (void)initialize {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (!vtfInitialized) {
		vlInitialize();
	}
}


/* Implemented by subclassers to indicate what UTI-identified data types they can deal with. */
+ (NSArray *)imageUnfilteredTypes {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	static NSArray *types = nil;
	if (types == nil) types = [[NSArray alloc] initWithObjects:TKVTFType, nil];
	return types;
}



+ (NSArray *)imageUnfilteredFileTypes {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
//	NSArray *superTypes = [super imageUnfilteredFileTypes];
//	NSLog(@"[%@ %@] superTypes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), superTypes);
	
	static NSArray *fileTypes = nil;
	if (fileTypes == nil) fileTypes = [[NSArray alloc] initWithObjects:TKVTFFileType, nil];
	return fileTypes;
}

+ (NSArray *)imageUnfilteredPasteboardTypes {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	static NSArray *imageUnfilteredPasteboardTypes = nil;
	
	if (imageUnfilteredPasteboardTypes == nil) {
		NSArray *types = [super imageUnfilteredPasteboardTypes];
#if TK_DEBUG
//		NSLog(@"[%@ %@] super's imageUnfilteredPasteboardTypes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), types);
#endif
		imageUnfilteredPasteboardTypes = [[types arrayByAddingObject:TKVTFPboardType] retain];
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


+ (TKVTFFormat)defaultFormat {
	TKVTFFormat defaultFormat = 0;
	@synchronized(self) {
		defaultFormat = defaultVTFFormat;
	}
	return defaultFormat;
}

+ (void)setDefaultFormat:(TKVTFFormat)aFormat {
	@synchronized(self) {
		defaultVTFFormat = aFormat;
	}
}


+ (NSData *)VTFRepresentationOfImageRepsInArray:(NSArray *)tkImageReps options:(NSDictionary *)options {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[self class] VTFRepresentationOfImageRepsInArray:tkImageReps usingFormat:[[self class] defaultFormat] quality:[TKImageRep defaultDXTCompressionQuality] options:options];
}


+ (NSData *)VTFRepresentationOfImageRepsInArray:(NSArray *)tkImageReps usingFormat:(TKVTFFormat)aFormat quality:(TKDXTCompressionQuality)aQuality options:(NSDictionary *)options {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSParameterAssert([tkImageReps count] != 0);
	
	NSNumber *nMipmapType = [options objectForKey:TKImageMipmapGenerationKey];
//	NSNumber *nWrapMode = [options objectForKey:TKImageWrapModeKey];
//	NSNumber *nRoundMode = [options objectForKey:TKImageRoundModeKey];
//	NSNumber *nImageFormat = [options objectForKey:TKImageVTFFormatKey];
	
	NSUInteger maxWidth = 0;
	NSUInteger maxHeight = 0;
	
	NSUInteger sliceCount = 1;
	NSUInteger faceCount = 1;
	NSUInteger frameCount = 1;
	
	NSUInteger highestSliceIndex = 0;
	NSUInteger highestFaceIndex = 0;
	NSUInteger highestFrameIndex = 0;
	
	for (NSImageRep *imageRep in tkImageReps) {
		if ([imageRep isKindOfClass:[TKImageRep class]]) {
			TKImageRep *tkImageRep = (TKImageRep *)imageRep;
			NSUInteger theSliceIndex = [tkImageRep sliceIndex];
			NSUInteger theFace	= [tkImageRep face];
			NSUInteger theFrameIndex = [tkImageRep frameIndex];
			
			if ([tkImageRep pixelsWide] > maxWidth) maxWidth = [tkImageRep pixelsWide];
			if ([tkImageRep pixelsHigh] > maxHeight) maxHeight = [tkImageRep pixelsHigh];
			
			if (theSliceIndex != TKSliceIndexNone) {
				if (theSliceIndex > highestSliceIndex) highestSliceIndex = theSliceIndex;
			}
			
			if (theFace != TKFaceNone) {
				if (theFace > highestFaceIndex) highestFaceIndex = theFace;
			}
			
			if (theFrameIndex != TKFrameIndexNone) {
				if (theFrameIndex > highestFrameIndex) highestFrameIndex = theFrameIndex;
			}
			
		} else {
			NSLog(@"[%@ %@] imageRep is NOT a TKImageRep!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		}
	}
	
	if (highestSliceIndex > 0) sliceCount = highestSliceIndex + 1;
	if (highestFaceIndex > 0) faceCount = highestFaceIndex + 1;
	if (highestFrameIndex > 0) frameCount = highestFrameIndex + 1;
	
	
	VTFDXTQuality compressionQuality = VTFDXTQualityFromTKDXTCompressionQuality(aQuality);
	
	vlSetInteger(VTFLIB_DXT_QUALITY, compressionQuality);
	
	VTFImageFormat imageFormat = VTFImageFormatFromTKVTFFormat(aFormat);
	TKPixelFormat aPixelFormat = TKPixelFormatFromVTFImageFormat(imageFormat);
	
	CVTFFile *vtfFile = new CVTFFile();
	
	vlBool generateMipmaps = vlTrue;
	
	if (nMipmapType == nil || [nMipmapType unsignedIntegerValue] == TKMipmapGenerationNoMipmaps) {
		generateMipmaps = NO;
	}
	
	
	if (aPixelFormat == TKPixelFormatRGBA) {
		if (!vtfFile->Create(maxWidth, maxHeight, frameCount, faceCount, sliceCount, IMAGE_FORMAT_RGBA8888, vlFalse, generateMipmaps, vlTrue)) {
//		if (!vtfFile->Create(maxWidth, maxHeight, frameCount, faceCount, sliceCount, IMAGE_FORMAT_RGBA8888, vlTrue, generateMipmaps, vlTrue)) {
			delete vtfFile;
			NSLog(@"[%@ %@] vtfFile->Create() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return nil;
		}
		
		for (NSImageRep *imageRep in tkImageReps) {
			
			if ([imageRep isKindOfClass:[TKImageRep class]]) {
				
				vlUInt theFrameIndex = (vlUInt)([(TKImageRep *)imageRep frameIndex] == TKFrameIndexNone ? 0 : [(TKImageRep *)imageRep frameIndex]);
				vlUInt theFace = (vlUInt)([(TKImageRep *)imageRep face] == TKFaceNone ? 0 : [(TKImageRep *)imageRep face]);
				vlUInt theSliceIndex = (vlUInt)([(TKImageRep *)imageRep sliceIndex] == TKSliceIndexNone ? 0 : [(TKImageRep *)imageRep sliceIndex]);
				vlUInt theMipmapIndex = (vlUInt)([(TKImageRep *)imageRep mipmapIndex] == TKMipmapIndexNone ? 0 : [(TKImageRep *)imageRep mipmapIndex]);
				
				NSData *rgbaData = [(TKImageRep *)imageRep representationUsingPixelFormat:TKPixelFormatRGBA];
				vlByte *rgbaBytes = (vlByte *)[rgbaData bytes];
				
				vtfFile->SetData(theFrameIndex, theFace, theSliceIndex, theMipmapIndex, rgbaBytes);
				
			} else {
				
			}
		}
		
		if (generateMipmaps) {
			vlBool success = vtfFile->GenerateMipmaps(VTFMipmapFilterFromTKMipmapGenerationType([nMipmapType unsignedIntegerValue]), SHARPEN_FILTER_DEFAULT);
			if (!success) {
				NSLog(@"[%@ %@] vtfFile->GenerateMipmaps() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
			}
		}
		
		CVTFFile *convertedFile = new CVTFFile(*vtfFile, imageFormat);
		if (convertedFile == 0) {
			NSLog(@"[%@ %@] CVTFFile(copy) failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			delete vtfFile;
			return nil;
		}
		
		unsigned char *fileBytes = (unsigned char *)malloc(convertedFile->GetSize());
		if (fileBytes == NULL) {
			NSLog(@"[%@ %@] malloc(%llu) failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long long)convertedFile->GetSize());
			delete vtfFile;
			delete convertedFile;
			return nil;
		}
		
		vlUInt totalSize = 0;
		
		if (!convertedFile->Save((vlVoid *)fileBytes, convertedFile->GetSize(), totalSize)) {
			NSLog(@"[%@ %@] convertedFile->Save() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
		}
		NSData *representation = [NSData dataWithBytes:fileBytes length:totalSize];
		free(fileBytes);
		delete vtfFile;
		delete convertedFile;
		return representation;
		
	} else {
//		if (!vtfFile->Create(maxWidth, maxHeight, frameCount, faceCount, sliceCount, imageFormat, vlTrue, generateMipmaps, vlTrue)) {
		if (!vtfFile->Create(maxWidth, maxHeight, frameCount, faceCount, sliceCount, imageFormat, vlFalse, generateMipmaps, vlTrue)) {
			delete vtfFile;
			NSLog(@"[%@ %@] vtfFile->Create() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return nil;
		}
		
		for (NSImageRep *imageRep in tkImageReps) {
			
			if ([imageRep isKindOfClass:[TKImageRep class]]) {
				
				vlUInt theFrameIndex = (vlUInt)([(TKImageRep *)imageRep frameIndex] == TKFrameIndexNone ? 0 : [(TKImageRep *)imageRep frameIndex]);
				vlUInt theFace = (vlUInt)([(TKImageRep *)imageRep face] == TKFaceNone ? 0 : [(TKImageRep *)imageRep face]);
				vlUInt theSliceIndex = (vlUInt)([(TKImageRep *)imageRep sliceIndex] == TKSliceIndexNone ? 0 : [(TKImageRep *)imageRep sliceIndex]);
				vlUInt theMipmapIndex = (vlUInt)([(TKImageRep *)imageRep mipmapIndex] == TKMipmapIndexNone ? 0 : [(TKImageRep *)imageRep mipmapIndex]);
				
				NSData *pixelData = [(TKImageRep *)imageRep representationUsingPixelFormat:aPixelFormat];
				vlByte *pixelBytes = (vlByte *)[pixelData bytes];
				
				vtfFile->SetData(theFrameIndex, theFace, theSliceIndex, theMipmapIndex, pixelBytes);
				
			}
		}
		
		if (generateMipmaps) {
			vlBool success = vtfFile->GenerateMipmaps(VTFMipmapFilterFromTKMipmapGenerationType([nMipmapType unsignedIntegerValue]), SHARPEN_FILTER_DEFAULT);
			if (!success) {
				NSLog(@"[%@ %@] vtfFile->GenerateMipmaps() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			}
		}
		
		unsigned char *fileBytes = (unsigned char *)malloc(vtfFile->GetSize());
		if (fileBytes == NULL) {
			NSLog(@"[%@ %@] malloc(%llu) failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long long)vtfFile->GetSize());
			delete vtfFile;
			return nil;
		}
		
		vlUInt totalSize = 0;
		
		if (!vtfFile->Save((vlVoid *)fileBytes, vtfFile->GetSize(), totalSize)) {
			NSLog(@"[%@ %@] vtfFile->Save() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		}
		NSData *representation = [NSData dataWithBytes:fileBytes length:totalSize];
		free(fileBytes);
		delete vtfFile;
		return representation;
	}
	return nil;
}


+ (NSArray *)imageRepsWithData:(NSData *)aData firstRepresentationOnly:(BOOL)firstRepOnly {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	OSType magic = 0;
	[aData getBytes:&magic length:sizeof(magic)];
	magic = NSSwapBigIntToHost(magic);
#if TK_DEBUG
//	NSLog(@"[%@ %@] magic == 0x%x, %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), magic, NSFileTypeForHFSTypeCode(magic));
#endif
	CVTFFile *file = new CVTFFile();
	if (file == 0) {
		NSLog(@"[%@ %@] CVTFFile() returned 0!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return nil;
	}
	
	if (file->Load([aData bytes], [aData length], vlFalse) == NO) {
		if (magic == TKVTFMagic) {
			NSLog(@"[%@ %@] file->Load() failed! (DOES appear to be a valid VTF; magic == 0x%x, %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned int)magic, NSFileTypeForHFSTypeCode(magic));
		} else {
			NSLog(@"[%@ %@] file->Load() failed! (does not appear to be a valid VTF; magic == 0x%x, %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned int)magic, NSFileTypeForHFSTypeCode(magic));
		}
		delete file;
		return nil;
	}
	
	vlUInt frameCount = file->GetFrameCount();
	vlUInt faceCount = file->GetFaceCount();
	vlUInt mipmapCount = file->GetMipmapCount();
	vlUInt sliceCount = file->GetDepth();
	
	vlUInt imageWidth = file->GetWidth();
	vlUInt imageHeight = file->GetHeight();
	
#if TK_DEBUG
//	NSLog(@"[%@ %@] sliceCount == %u, faceCount == %u, frameCount == %u, mipmapCount == %u", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sliceCount, faceCount, frameCount, mipmapCount);
#endif
	
	VTFImageFormat imageFormat = file->GetFormat();
	
	VTFImageFormat destFormat = IMAGE_FORMAT_RGB888;
	
	BOOL conversionNeeded = NO;
	
	if (imageFormat == IMAGE_FORMAT_DXT1 || imageFormat == IMAGE_FORMAT_DXT3 || imageFormat == IMAGE_FORMAT_DXT5 || imageFormat == IMAGE_FORMAT_DXT1_ONEBITALPHA) {
		conversionNeeded = YES;
		if (imageFormat != IMAGE_FORMAT_DXT1) destFormat = IMAGE_FORMAT_RGBA8888;
	}
	
	
	TKPixelFormat destinationPixelFormat = TKNativePixelFormatFromVTFImageFormat(imageFormat);
	
	TKPixelFormatInfo pixelFormatInfo = TKPixelFormatInfoFromPixelFormat(destinationPixelFormat);
	
	NSMutableArray *bitmapImageReps = [NSMutableArray array];
	
	for (vlUInt mipmapNumber = 0; mipmapNumber < mipmapCount; mipmapNumber++) {
		for (vlUInt frame = 0; frame < frameCount; frame++) {
			for (vlUInt faceIndex = 0; faceIndex < faceCount; faceIndex++) {
				for (vlUInt slice = 0; slice < sliceCount; slice++) {
					
					NSLog(@"[%@ %@] mipmapIndex == %lu, frameIndex == %lu, face == %lu, sliceIndex == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)mipmapNumber, (unsigned long)frame, (unsigned long)faceIndex, (unsigned long)slice);

					
					
					vlUInt mipmapWidth = 0;
					vlUInt mipmapHeight = 0;
					vlUInt mipmapDepth = 0;
					
					CVTFFile::ComputeMipmapDimensions(imageWidth, imageHeight, sliceCount, mipmapNumber, mipmapWidth, mipmapHeight, mipmapDepth);
					
					vlInt convertedBytesLength = 0;
					vlByte *convertedBytes = 0;
					
					if (conversionNeeded) {
						convertedBytesLength = CVTFFile::ComputeMipmapSize(imageWidth, imageHeight, sliceCount, mipmapNumber, destFormat);
						convertedBytes = new vlByte[convertedBytesLength];
						
						if (convertedBytes == 0) {
							NSLog(@"[%@ %@] new [%lu] failed! slice == %u, face == %u, frame == %u, mipmap == %u", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)convertedBytesLength, slice, faceIndex, frame, mipmapNumber);
							continue;
						}
					}					
					
					vlUInt existingBytesLength = CVTFFile::ComputeMipmapSize(imageWidth, imageHeight, sliceCount, mipmapNumber, imageFormat);
					
					vlByte *existingBytes = file->GetData(frame, faceIndex, slice, mipmapNumber);
					
					if (existingBytes == 0) {
						NSLog(@"[%@ %@] failed to get existing data for slice == %u, face == %u, frame == %u, mipmap == %u", NSStringFromClass([self class]), NSStringFromSelector(_cmd), slice, faceIndex, frame, mipmapNumber);
						delete [] convertedBytes;
						continue;
					}
					
					if (conversionNeeded) {
						if (!CVTFFile::Convert(existingBytes, convertedBytes, mipmapWidth, mipmapHeight, imageFormat, destFormat)) {
							NSLog(@"[%@ %@] CVTFFile::Convert() failed! slice == %u, face == %u, frame == %u, mipmap == %u", NSStringFromClass([self class]), NSStringFromSelector(_cmd), slice, faceIndex, frame, mipmapNumber);
							delete [] convertedBytes;
							continue;
						}
					}
					
					
					NSData *data = nil;
					
					
					if (imageFormat == IMAGE_FORMAT_RGBA16161616F) {
						
						NSData *existingData = [NSData dataWithBytes:existingBytes length:existingBytesLength];
						
						data = [[TKImageRep dataRepresentationOfData:existingData inPixelFormat:TKPixelFormatRGBA16161616F size:NSMakeSize(mipmapWidth, mipmapHeight) usingPixelFormat:TKPixelFormatRGBA32323232F] retain];
						
					} else if (conversionNeeded) {
						
						data = [[NSData alloc] initWithBytes:convertedBytes length:convertedBytesLength];
						
					} else {
						data = [[NSData alloc] initWithBytes:existingBytes length:existingBytesLength];
						
					}
					
					CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
					[data release];
					
					NSString *colorSpaceName = nil;
					
					if (pixelFormatInfo.colorSpaceModel == kCGColorSpaceModelRGB && pixelFormatInfo.bitmapInfo & kCGBitmapFloatComponents) {
						colorSpaceName = (NSString *)kCGColorSpaceGenericRGBLinear;
					} else if (pixelFormatInfo.colorSpaceModel == kCGColorSpaceModelRGB) {
						colorSpaceName = (NSString *)kCGColorSpaceGenericRGB;
					} else if (pixelFormatInfo.colorSpaceModel == kCGColorSpaceModelMonochrome) {
						colorSpaceName = (NSString *)kCGColorSpaceGenericGrayGamma2_2;
					}
					
					CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName((CFStringRef)colorSpaceName);
					
					CGImageRef imageRef = CGImageCreate(mipmapWidth,
														mipmapHeight,
														pixelFormatInfo.bitsPerComponent,
														pixelFormatInfo.bitsPerPixel,
														mipmapWidth * pixelFormatInfo.bitsPerPixel/8,
														colorSpace,
														pixelFormatInfo.bitmapInfo,
														provider,
														NULL,
														false,
														pixelFormatInfo.renderingIntent);
					
					CGColorSpaceRelease(colorSpace);
					CGDataProviderRelease(provider);
					
					if (imageRef == NULL) {
						NSLog(@"[%@ %@] CGImageCreate() (for sliceIndex == %u, faceIndex == %u, frameIndex == %u, mipmapIndex == %u) failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), slice, faceIndex, frame, mipmapNumber);
						delete [] convertedBytes;
						continue;
					}
					
					TKVTFImageRep *imageRep = [[TKVTFImageRep alloc] initWithCGImage:imageRef
																		  sliceIndex:slice
																				face:faceIndex
																		  frameIndex:frame
																		 mipmapIndex:mipmapNumber];
					
					CGImageRelease(imageRef);
					if (imageRep) {
						[bitmapImageReps addObject:imageRep];
						[imageRep release];
					}
					
					delete [] convertedBytes;
					
					if (firstRepOnly && frame == 0 && faceIndex == 0 && slice == 0 && mipmapNumber == 0) {
						delete file;
						return [[bitmapImageReps copy] autorelease];
					}
					
				}
			}
		}
	}
	delete file;
	return [[bitmapImageReps copy] autorelease];
}



//+ (NSArray *)imageRepsWithData:(NSData *)aData firstRepresentationOnly:(BOOL)firstRepOnly {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	
//	OSType magic = 0;
//	[aData getBytes:&magic length:sizeof(magic)];
//	magic = NSSwapBigIntToHost(magic);
//#if TK_DEBUG
////	NSLog(@"[%@ %@] magic == 0x%x, %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), magic, NSFileTypeForHFSTypeCode(magic));
//#endif
//	CVTFFile *file = new CVTFFile();
//	if (file == 0) {
//		NSLog(@"[%@ %@] CVTFFile() returned 0!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//		return nil;
//	}
//	
//	if (file->Load([aData bytes], [aData length], vlFalse) == NO) {
//		if (magic == TKVTFMagic) {
//			NSLog(@"[%@ %@] file->Load() failed! (DOES appear to be a valid VTF; magic == 0x%x, %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned int)magic, NSFileTypeForHFSTypeCode(magic));
//		} else {
//			NSLog(@"[%@ %@] file->Load() failed! (does not appear to be a valid VTF; magic == 0x%x, %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned int)magic, NSFileTypeForHFSTypeCode(magic));
//		}
//		delete file;
//		return nil;
//	}
//	
//	vlUInt frameCount = file->GetFrameCount();
//	vlUInt faceCount = file->GetFaceCount();
//	vlUInt mipmapCount = file->GetMipmapCount();
//	vlUInt sliceCount = file->GetDepth();
//	
//	vlUInt imageWidth = file->GetWidth();
//	vlUInt imageHeight = file->GetHeight();
//	
//#if TK_DEBUG
////	NSLog(@"[%@ %@] sliceCount == %u, faceCount == %u, frameCount == %u, mipmapCount == %u", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sliceCount, faceCount, frameCount, mipmapCount);
//#endif
//	
//	VTFImageFormat imageFormat = file->GetFormat();
//	
//	TKPixelFormat destinationPixelFormat = TKNativePixelFormatFromVTFImageFormat(imageFormat);
//	
//	TKPixelFormatInfo pixelFormatInfo = TKPixelFormatInfoFromPixelFormat(destinationPixelFormat);
//	
//	
//	
//	VTFImageFormat destFormat = IMAGE_FORMAT_NONE;
//	
//	if (imageFormat == IMAGE_FORMAT_RGBA16161616F ||
//		imageFormat == IMAGE_FORMAT_RGBA16161616 ||
//		imageFormat == IMAGE_FORMAT_R32F ||
//		imageFormat == IMAGE_FORMAT_RGB323232F ||
//		imageFormat == IMAGE_FORMAT_RGBA32323232F) {
//		
//		destFormat = IMAGE_FORMAT_RGBA32323232F;
//	} else {
//		destFormat = (file->GetFlags() & (TEXTUREFLAGS_ONEBITALPHA | TEXTUREFLAGS_EIGHTBITALPHA)) ? IMAGE_FORMAT_RGBA8888 : IMAGE_FORMAT_RGB888;
//	}
//	
//	NSMutableArray *bitmapImageReps = [NSMutableArray array];
//	
//	for (vlUInt mipmapNumber = 0; mipmapNumber < mipmapCount; mipmapNumber++) {
//		for (vlUInt frame = 0; frame < frameCount; frame++) {
//			for (vlUInt faceIndex = 0; faceIndex < faceCount; faceIndex++) {
//				for (vlUInt slice = 0; slice < sliceCount; slice++) {
//					
//					vlUInt mipmapWidth = 0;
//					vlUInt mipmapHeight = 0;
//					vlUInt mipmapDepth = 0;
//					
//					file->ComputeMipmapDimensions(imageWidth, imageHeight, sliceCount, mipmapNumber, mipmapWidth, mipmapHeight, mipmapDepth);
//					
//#if TK_DEBUG
////					NSLog(@"[%@ %@] sliceIndex == %u, faceIndex == %u, frameIndex == %u, mipmapIndex == %u; mipmapWidth == %u, mipmapHeight == %u, mipmapDepth == %u", NSStringFromClass([self class]), NSStringFromSelector(_cmd), slice, faceIndex, frame, mipmapNumber, mipmapWidth, mipmapHeight, mipmapDepth);
//#endif
//					vlUInt convertedMipmapLength = 0;
//					convertedMipmapLength = file->ComputeMipmapSize(imageWidth, imageHeight, sliceCount, mipmapNumber, destFormat);
//#if TK_DEBUG
////					NSLog(@"[%@ %@] slice == %u, face == %u, frame == %u, mipmap == %u; mipmapLength == %u", NSStringFromClass([self class]), NSStringFromSelector(_cmd), slice, faceIndex, frame, mipmapNumber, convertedMipmapLength);
//#endif
//					vlByte *bytes = new vlByte[convertedMipmapLength];
//					
//					if (bytes == 0) {
//						NSLog(@"[%@ %@] new [%lu] failed! slice == %u, face == %u, frame == %u, mipmap == %u", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)convertedMipmapLength, slice, faceIndex, frame, mipmapNumber);
//						continue;
//					}
//					
//					vlByte *existingBytes = existingBytes = file->GetData(frame, faceIndex, slice, mipmapNumber);
//					
//					if (existingBytes == 0) {
//						NSLog(@"[%@ %@] failed to get existing data for slice == %u, face == %u, frame == %u, mipmap == %u", NSStringFromClass([self class]), NSStringFromSelector(_cmd), slice, faceIndex, frame, mipmapNumber);
//						continue;
//					}
//					
//					
//					if (existingBytes) {
//						if ( file->Convert(existingBytes, bytes, mipmapWidth, mipmapHeight, imageFormat, destFormat)) {
//							
//							size_t bitsPerComponent = 0;
//							size_t bitsPerPixel = 0;
//							size_t bytesPerRow = 0;
//							CGBitmapInfo bitmapInfo = 0;
//							
//							bitsPerComponent = (destFormat == IMAGE_FORMAT_RGBA32323232F ? 32 : 8);
//							if (destFormat == IMAGE_FORMAT_RGBA32323232F) {
//								bitsPerComponent = 32;
//								bitsPerPixel = 128;
//								bytesPerRow = (bitsPerPixel/ 8) * mipmapWidth;
//								bitmapInfo = kCGImageAlphaLast | kCGBitmapFloatComponents;
//								
//							} else if (destFormat == IMAGE_FORMAT_RGBA8888) {
//								bitsPerComponent = 8;
//								bitsPerPixel = 32;
//								bytesPerRow = (bitsPerPixel/ 8) * mipmapWidth;
//								bitmapInfo = kCGImageAlphaLast;
//								
//							} else if (destFormat == IMAGE_FORMAT_RGB888) {
//								bitsPerComponent = 8;
//								bitsPerPixel = 24;
//								bytesPerRow = (bitsPerPixel/ 8) * mipmapWidth;
//								bitmapInfo = kCGImageAlphaNone;
//							}
//							
//							
//							NSData *convertedData = [[NSData alloc] initWithBytes:bytes length:convertedMipmapLength];
//							delete [] bytes;
//							CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)convertedData);
//							[convertedData release];
//							CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
//							CGImageRef imageRef = CGImageCreate(mipmapWidth,
//																mipmapHeight,
//																bitsPerComponent,
//																bitsPerPixel,
//																bytesPerRow,
//																colorSpace,
//																bitmapInfo,
//																provider,
//																NULL,
//																false,
//																kCGRenderingIntentDefault);
//							
//							CGColorSpaceRelease(colorSpace);
//							CGDataProviderRelease(provider);
//							
//							if (imageRef) {
//								
//								TKVTFImageRep *imageRep = [[TKVTFImageRep alloc] initWithCGImage:imageRef
//																					  sliceIndex:slice
//																							face:faceIndex
//																					  frameIndex:frame
//																					 mipmapIndex:mipmapNumber];
//								
//								CGImageRelease(imageRef);
//								if (imageRep) {
//									[bitmapImageReps addObject:imageRep];
//									[imageRep release];
//								}
//								
//								if (firstRepOnly && frame == 0 && faceIndex == 0 && slice == 0 && mipmapNumber == 0) {
//									delete file;
//									return [[bitmapImageReps copy] autorelease];
//								}
//							} else {
//								NSLog(@"[%@ %@] CGImageCreate() (for sliceIndex == %u, faceIndex == %u, frameIndex == %u, mipmapIndex == %u) failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), slice, faceIndex, frame, mipmapNumber);
//								
//							}
//						}
//					}
//				}
//			}
//		}
//	}
//	delete file;
//	return [[bitmapImageReps copy] autorelease];
//
//}

+ (NSArray *)imageRepsWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[self class] imageRepsWithData:aData firstRepresentationOnly:NO];
}

+ (id)imageRepWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSArray *imageReps = [[self class] imageRepsWithData:aData firstRepresentationOnly:YES];
	if ([imageReps count]) return [imageReps objectAtIndex:0];
	return nil;
}

- (id)initWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSArray *imageReps = [[self class] imageRepsWithData:aData firstRepresentationOnly:YES];
	if ((imageReps == nil) || !([imageReps count] > 0)) {
		[self release];
		return nil;
	}
	self = [[imageReps objectAtIndex:0] retain];
	return self;
}


- (id)copyWithZone:(NSZone *)zone {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
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
		
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super encodeWithCoder:coder];
	
}

@end

