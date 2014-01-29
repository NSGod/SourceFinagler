//
//  TKDDSImageRep.mm
//  Texture Kit
//
//  Created by Mark Douma on 9/25/2010.
//  Copyright (c) 2010-2013 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKDDSImageRep.h>
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>
#import <NVTextureTools/NVTextureTools.h>

#import "MDFoundationAdditions.h"


static NSData *TKImageDataFromNSData(NSData *data, NSUInteger pixelCount, NSUInteger bitsPerPixel, CGBitmapInfo sourceBitmapInfo, CGBitmapInfo destinationBitmapInfo);
static NSData *TKBGRADataFromImageData(NSData *data, NSUInteger pixelCount, NSUInteger bitsPerPixel, CGBitmapInfo aCGBitmapInfo);


using namespace nv;
using namespace nvtt;


struct TKDDSFormatMapping {
	TKDDSFormat		format;
	D3DFORMAT		d3dFormat;
	FOURCC			fourcc;
	DXGI_FORMAT		dxgiFormat;
	Format			ddsFormat;
	TKPixelFormat	pixelFormat;
	TKPixelFormat	nativePixelFormat;
	NSString		*description;
};
	
static const TKDDSFormatMapping TKDDSFormatMappingTable[] = {
	{ TKDDSFormatDXT1,		D3DFMT_NONE,	FOURCC_DXT1,	DXGI_FORMAT_UNKNOWN,	Format_DXT1,	TKPixelFormatRGB,	TKPixelFormatRGB,	@"DXT1" },
	{ TKDDSFormatDXT1a,		D3DFMT_NONE,	FOURCC_DXT1,	DXGI_FORMAT_UNKNOWN,	Format_DXT1a,	TKPixelFormatRGBA,	TKPixelFormatRGBA,	@"DXT1a" },
	{ TKDDSFormatDXT3,		D3DFMT_NONE,	FOURCC_DXT3,	DXGI_FORMAT_UNKNOWN,	Format_DXT3,	TKPixelFormatRGBA,	TKPixelFormatRGBA,	@"DXT3" },
	{ TKDDSFormatDXT5, 		D3DFMT_NONE,	FOURCC_DXT5,	DXGI_FORMAT_UNKNOWN,	Format_DXT5,	TKPixelFormatRGBA,	TKPixelFormatRGBA,	@"DXT5" },
	{ TKDDSFormatDXT5n, 	D3DFMT_NONE,	FOURCC_DXT5,	DXGI_FORMAT_UNKNOWN,	Format_DXT5n,	TKPixelFormatRGBA,	TKPixelFormatRGBA,	@"DXT5n" },
	
	{ TKDDSFormatRGB,		D3DFMT_R8G8B8,		FOURCC_NONE,	DXGI_FORMAT_UNKNOWN,	Format_RGB,		TKPixelFormatRGB, TKPixelFormatRGB,		@"RGB" },
	{ TKDDSFormatRGB565,	D3DFMT_R5G6B5,		FOURCC_NONE,	DXGI_FORMAT_UNKNOWN,	Format_RGB,		TKPixelFormatRGB, TKPixelFormatRGB,		@"RGB565" },
	
	{ TKDDSFormatARGB,		D3DFMT_A8R8G8B8,	FOURCC_NONE,	DXGI_FORMAT_UNKNOWN,	Format_RGBA,	TKPixelFormatARGB, TKPixelFormatARGB,	@"ARGB" },
	{ TKDDSFormatARGB4444, 	D3DFMT_A4R4G4B4,	FOURCC_NONE,	DXGI_FORMAT_UNKNOWN,	Format_RGBA,	TKPixelFormatARGB, TKPixelFormatARGB,	@"ARGB4444" },
	{ TKDDSFormatARGB1555, 	D3DFMT_A1R5G5B5,	FOURCC_NONE,	DXGI_FORMAT_UNKNOWN,	Format_RGBA,	TKPixelFormatARGB, TKPixelFormatARGB,	@"ARGB1555" },
	{ TKDDSFormatARGB8332, 	D3DFMT_A8R3G3B2,	FOURCC_NONE,	DXGI_FORMAT_UNKNOWN,	Format_RGBA,	TKPixelFormatARGB, TKPixelFormatARGB,	@"ARGB8332" },
	{ TKDDSFormatARGB2101010, 	D3DFMT_A2R10G10B10,	FOURCC_NONE,	DXGI_FORMAT_UNKNOWN,	Format_RGBA,	TKPixelFormatARGB, TKPixelFormatRGBA16161616,	@"ARGB2101010" },

	{ TKDDSFormatXRGB,		D3DFMT_X8R8G8B8,	FOURCC_NONE,	DXGI_FORMAT_UNKNOWN,	Format_RGBA,	TKPixelFormatXRGB, TKPixelFormatXRGB,	@"XRGB" },
	{ TKDDSFormatXRGB1555, 	D3DFMT_X1R5G5B5,	FOURCC_NONE,	DXGI_FORMAT_UNKNOWN,	Format_RGBA,	TKPixelFormatXRGB1555, TKPixelFormatXRGB1555,	@"XRGB1555" },
	{ TKDDSFormatXRGB4444, 	D3DFMT_X4R4G4B4,	FOURCC_NONE,	DXGI_FORMAT_UNKNOWN,	Format_RGBA,	TKPixelFormatXRGB, TKPixelFormatXRGB,	@"XRGB4444" },

	{ TKDDSFormatABGR,		D3DFMT_A8B8G8R8,	FOURCC_NONE,	DXGI_FORMAT_UNKNOWN,	Format_RGBA,	TKPixelFormatABGR, TKPixelFormatARGB,	@"ABGR" },
	{ TKDDSFormatXBGR,		D3DFMT_X8B8G8R8,	FOURCC_NONE,	DXGI_FORMAT_UNKNOWN,	Format_RGBA,	TKPixelFormatXBGR, TKPixelFormatXRGB,	@"XBGR" },
	{ TKDDSFormatABGR2101010, 	D3DFMT_A2B10G10R10,	FOURCC_NONE,	DXGI_FORMAT_UNKNOWN,	Format_RGBA,	TKPixelFormatARGB, TKPixelFormatRGBA16161616,	@"ABGR2101010" },
	{ TKDDSFormatABGR16161616,		D3DFMT_A16B16G16R16,	FOURCC_NONE,	DXGI_FORMAT_UNKNOWN,	Format_RGBA,	TKPixelFormatARGB, TKPixelFormatARGB,	@"ABGR16161616" },
	
	{ TKDDSFormatA,			D3DFMT_A8,			FOURCC_NONE,	DXGI_FORMAT_UNKNOWN,	Format_RGBA,	TKPixelFormatA,		TKPixelFormatA,		@"A" },

	{ TKDDSFormatP,			D3DFMT_P8,			FOURCC_NONE,	DXGI_FORMAT_UNKNOWN,	Format_RGBA,	TKPixelFormatL,		TKPixelFormatL,		@"P" },
	{ TKDDSFormatAP,		D3DFMT_A8P8,		FOURCC_NONE,	DXGI_FORMAT_UNKNOWN,	Format_RGBA,	TKPixelFormatLA,	TKPixelFormatLA,	@"AP" },
	
	{ TKDDSFormatL,			D3DFMT_L8,			FOURCC_NONE,	DXGI_FORMAT_UNKNOWN,	Format_RGBA,	TKPixelFormatL,		TKPixelFormatA,		@"L" },
	{ TKDDSFormatAL,		D3DFMT_A8L8,		FOURCC_NONE,	DXGI_FORMAT_UNKNOWN,	Format_RGBA,	TKPixelFormatA,		TKPixelFormatA,		@"AL" },
	{ TKDDSFormatA4L4,		D3DFMT_A8,			FOURCC_NONE,	DXGI_FORMAT_UNKNOWN,	Format_RGBA,	TKPixelFormatA,		TKPixelFormatA,		@"AL44" },
	{ TKDDSFormatL16,		D3DFMT_A8,			FOURCC_NONE,	DXGI_FORMAT_UNKNOWN,	Format_RGBA,	TKPixelFormatA,		TKPixelFormatA,		@"L16" },

	
//	{ TKDDSFormatRGB, Format_RGB, TKPixelFormatRGB, @"RGB" },
//	{ TKDDSFormatRGBA, Format_RGBA, TKPixelFormatRGBA, @"RGBA" },
//	{ TKDDSFormatBC4, Format_BC4, TKPixelFormatRGBA, @"BC4 (ATI1)" },
//	{ TKDDSFormatBC5, Format_BC5, TKPixelFormatRGBA, @"BC5 (3DC, ATI2)" },
//	{ TKDDSFormatRGBE, Format_RGBE, TKPixelFormatRGBA /* ?? */, @"RGBE" }
};
static const NSUInteger TKDDSFormatMappingTableCount = sizeof(TKDDSFormatMappingTable)/sizeof(TKDDSFormatMappingTable[0]);
	
	
NSString *NSStringFromDDSFormat(TKDDSFormat aFormat) {
	for (NSUInteger i = 0; i < TKDDSFormatMappingTableCount; i++) {
		if (TKDDSFormatMappingTable[i].format == aFormat) {
			return TKDDSFormatMappingTable[i].description;
		}
	}
	return @"<Unknown>";
}

TKDDSFormat TKDDSFormatFromString(NSString *aFormat) {
	for (NSUInteger i = 0; i < TKDDSFormatMappingTableCount; i++) {
		if ([TKDDSFormatMappingTable[i].description isEqualToString:aFormat]) {
			return TKDDSFormatMappingTable[i].format;
		}
	}
	return [TKDDSImageRep defaultFormat];
}

static inline Format FormatFromTKDDSFormat(TKDDSFormat aFormat) {
	for (NSUInteger i = 0; i < TKDDSFormatMappingTableCount; i++) {
		if (TKDDSFormatMappingTable[i].format == aFormat) {
			return TKDDSFormatMappingTable[i].ddsFormat;
		}
	}
	return Format_DXT1;
}

struct TKWrapModeMapping {
	WrapMode		wrapMode;
	TKWrapMode		tkWrapMode;
};
static const TKWrapModeMapping TKWrapModeMappingTable[] = {
	{ WrapMode_Clamp, TKWrapModeClamp },
	{ WrapMode_Repeat, TKWrapModeRepeat },
	{ WrapMode_Mirror, TKWrapModeMirror }
};
static const NSUInteger TKWrapModeTableCount = sizeof(TKWrapModeMappingTable)/sizeof(TKWrapModeMappingTable[0]);

static inline WrapMode WrapModeFromTKWrapMode(TKWrapMode wrapMode) {
	for (NSUInteger i = 0; i < TKWrapModeTableCount; i++) {
		if (TKWrapModeMappingTable[i].tkWrapMode == wrapMode) {
			return TKWrapModeMappingTable[i].wrapMode;
		}
	}
	return WrapMode_Clamp;
}

struct TKDDSMipmapGenerationMapping {
	MipmapFilter				mipmapFilter;
	TKMipmapGenerationType		mipmapGenerationType;
};
static const TKDDSMipmapGenerationMapping TKDDSMipmapGenerationMappingTable[] = {
	{ MipmapFilter_Box, TKMipmapGenerationUsingBoxFilter },
	{ MipmapFilter_Triangle, TKMipmapGenerationUsingTriangleFilter },
	{ MipmapFilter_Kaiser, TKMipmapGenerationUsingKaiserFilter }
};
static const NSUInteger TKDDSMipmapGenerationTableCount = sizeof(TKDDSMipmapGenerationMappingTable)/sizeof(TKDDSMipmapGenerationMappingTable[0]);

static inline MipmapFilter DDSMipmapFilterFromTKMipmapGenerationType(TKMipmapGenerationType mipmapGenerationType) {
	for (NSUInteger i = 0; i < TKDDSMipmapGenerationTableCount; i++) {
		if (TKDDSMipmapGenerationMappingTable[i].mipmapGenerationType == mipmapGenerationType) {
			return TKDDSMipmapGenerationMappingTable[i].mipmapFilter;
		}
	}
	return MipmapFilter_Box;
}

struct TKRoundModeMapping {
	RoundMode		roundMode;
	TKRoundMode		tkRoundMode;
};
static const TKRoundModeMapping TKRoundModeMappingTable[] = {
	{ RoundMode_None, TKRoundModeNone },
	{ RoundMode_ToNextPowerOfTwo, TKRoundModeNextPowerOfTwo },
	{ RoundMode_ToNearestPowerOfTwo, TKRoundModeNearestPowerOfTwo },
	{ RoundMode_ToPreviousPowerOfTwo, TKRoundModePreviousPowerOfTwo }
};
static const NSUInteger TKRoundModeTableCount = sizeof(TKRoundModeMappingTable)/sizeof(TKRoundModeMappingTable[0]);

static inline RoundMode RoundModeFromTKRoundMode(TKRoundMode roundMode) {
	for (NSUInteger i = 0; i < TKRoundModeTableCount; i++) {
		if (TKRoundModeMappingTable[i].tkRoundMode == roundMode) {
			return TKRoundModeMappingTable[i].roundMode;
		}
	}
	return RoundMode_None;
}

static AlphaMode AlphaModeFromAlphaInfo(CGImageAlphaInfo alphaInfo) {
	if (alphaInfo == kCGImageAlphaNone || alphaInfo == kCGImageAlphaNoneSkipLast ||
		alphaInfo == kCGImageAlphaNoneSkipFirst) {
		return AlphaMode_None;
	} else if (alphaInfo == kCGImageAlphaPremultipliedLast || alphaInfo == kCGImageAlphaPremultipliedFirst) {
		return AlphaMode_Premultiplied;
	} else if (alphaInfo == kCGImageAlphaLast || alphaInfo == kCGImageAlphaFirst) {
		return AlphaMode_Transparency;
	}
	return AlphaMode_None;
}


struct TKDDSDXTQualityMapping {
	TKDXTCompressionQuality		quality;
	Quality						ddsDXTQuality;
};
static const TKDDSDXTQualityMapping TKDDSDXTQualityMappingTable[] = {
	{TKDXTCompressionLowQuality, Quality_Fastest },
	{TKDXTCompressionMediumQuality, Quality_Normal },
	{TKDXTCompressionHighQuality, Quality_Production },
	{TKDXTCompressionHighestQuality, Quality_Highest }
};
static const NSUInteger TKDDSDXTQualityMappingTableCount = sizeof(TKDDSDXTQualityMappingTable)/sizeof(TKDDSDXTQualityMappingTable[0]);

static inline Quality DDSDXTQualityFromTKDXTCompressionQuality(TKDXTCompressionQuality compressionQuality) {
	for (NSUInteger i = 0; i < TKDDSDXTQualityMappingTableCount; i++) {
		if (TKDDSDXTQualityMappingTable[i].quality == compressionQuality) {
			return TKDDSDXTQualityMappingTable[i].ddsDXTQuality;
		}
	}
	return Quality_Production;
}


#define TK_DEBUG 1



NSString * const TKDDSType			= @"com.microsoft.dds";
NSString * const TKDDSFileType		= @"dds";
NSString * const TKDDSPboardType	= @"com.microsoft.dds";



@interface TKDDSImageRep (TKPrivate)
+ (NSArray *)imageRepsWithData:(NSData *)aData firstRepresentationOnly:(BOOL)firstRepOnly;
@end


struct TKOutputHandler : public OutputHandler {
	
	TKOutputHandler(NSMutableData *imageData) : imageData(imageData) {
		
	}
	
	virtual ~TKOutputHandler() { }
	
    virtual void beginImage(int size, int width, int height, int depth, int face, int miplevel) {
#if TK_DEBUG
		printf("TKOutputHandler::beginImage(size == %d, width == %d, height == %d, depth == %d, face == %d, mipmapLevel == %d)\n", size, width, height, depth, face, miplevel);
#endif
		
        // ignore.
    }
	
    virtual bool writeData(const void * data, int size) {
#if TK_DEBUG
//		printf("TKOutputHandler::writeData()\n");
#endif
		
		if (this->imageData) [this->imageData appendBytes:data length:size];
        return true;
    }
	
	virtual void endImage() {
#if TK_DEBUG
		printf("TKOutputHandler::endImage()\n");
#endif
		
	}
	
	NSMutableData *imageData;
};


struct TKMipmapOutputHandler : public OutputHandler {
	
	TKMipmapOutputHandler(NSMutableData *imageData) : imageData(imageData) {
		
	}
	
	virtual ~TKMipmapOutputHandler() {
		
	}
	
    virtual void beginImage(int size, int width, int height, int depth, int face, int miplevel) {
#if TK_DEBUG
		printf("TKMipmapOutputHandler::beginImage(size == %d, width == %d, height == %d, depth == %d, face == %d, mipmapLevel == %d)\n", size, width, height, depth, face, miplevel);
#endif
		
        // ignore.
    }
	
    virtual bool writeData(const void *data, int size) {
#if TK_DEBUG
//		printf("TKMipmapOutputHandler::writeData()\n");
#endif
		
		if (this->imageData) [this->imageData appendBytes:data length:size];
        return true;
    }
	
	
	virtual void endImage() {
#if TK_DEBUG
		printf("TKMipmapOutputHandler::endImage()\n");
#endif
		
	}
	
	NSMutableData		*imageData;
};




static TKDDSFormat defaultDDSFormat = TKDDSFormatDefault;

@implementation TKDDSImageRep

/* Implemented by subclassers to indicate what UTI-identified data types they can deal with. */
+ (NSArray *)imageUnfilteredTypes {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	static NSArray *types = nil;
	if (types == nil) types = [[NSArray alloc] initWithObjects:TKDDSType, nil];
	return types;
}


+ (NSArray *)imageUnfilteredFileTypes {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	static NSArray *fileTypes = nil;
	if (fileTypes == nil) fileTypes = [[NSArray alloc] initWithObjects:TKDDSFileType, nil];
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
		imageUnfilteredPasteboardTypes = [[types arrayByAddingObject:TKDDSPboardType] retain];
	}
	return imageUnfilteredPasteboardTypes;
}


//+ (BOOL)canInitWithPasteboard:(NSPasteboard *)pasteboard {
//	
//}


+ (BOOL)canInitWithData:(NSData *)data {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([data length] < sizeof(OSType)) return NO;
	OSType magic = 0;
	[data getBytes:&magic length:sizeof(magic)];
	magic = NSSwapBigIntToHost(magic);
	return (magic == TKDDSMagic);
}


+ (Class)imageRepClassForType:(NSString *)type {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([type isEqualToString:TKDDSType]) {
		return [self class];
	}
	return [super imageRepClassForType:type];
}

+ (Class)imageRepClassForFileType:(NSString *)fileType {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([fileType isEqualToString:TKDDSFileType]) {
		return [self class];
	}
	return [super imageRepClassForFileType:fileType];
}


+ (TKDDSFormat)defaultFormat {
	TKDDSFormat defaultFormat = 0;
	@synchronized(self) {
		defaultFormat = defaultDDSFormat;
	}
	return defaultFormat;
}

+ (void)setDefaultFormat:(TKDDSFormat)aFormat {
	@synchronized(self) {
		defaultDDSFormat = aFormat;
	}
}


- (NSArray *)mipmapImageRepsUsingFilter:(TKMipmapGenerationType)filterType {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSParameterAssert(filterType != TKMipmapGenerationNoMipmaps);
	
	InputOptions inputOptions;
	inputOptions.setTextureLayout(TextureType_2D, [self pixelsWide], [self pixelsHigh]);
	inputOptions.setFormat(InputFormat_BGRA_8UB);
	
	inputOptions.setNormalMap(false);
	inputOptions.setConvertToNormalMap(false);
	inputOptions.setGamma(2.2, 2.2);
	
	inputOptions.setMipmapGeneration(true);
	inputOptions.setMipmapFilter(DDSMipmapFilterFromTKMipmapGenerationType(filterType));
	
	CGImageAlphaInfo cgAlphaInfo = [self alphaInfo];
#if TK_DEBUG
	NSLog(@"[%@ %@] alphaInfo == %u, bitmapFormat == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), cgAlphaInfo, (unsigned long)[self bitmapFormat]);
#endif
	
	inputOptions.setAlphaMode(AlphaModeFromAlphaInfo(cgAlphaInfo));
	
	NSData *imageData = [self data];
	NSData *swappedData = TKBGRADataFromImageData(imageData, [self pixelsWide] * [self pixelsHigh], [self bitsPerPixel], cgAlphaInfo);
	inputOptions.setMipmapData([swappedData bytes], [self pixelsWide], [self pixelsHigh], 1, (face == TKFaceNone ? 0 : face), mipmapIndex);
	
	
	
	CompressionOptions compressionOptions;
	compressionOptions.setFormat(Format_RGBA);
	compressionOptions.setQuality(Quality_Highest);
	
	Context context;
	context.enableCudaAcceleration(false);
	
	NSMutableData *mipmapData = [[NSMutableData alloc] init];
	
	TKMipmapOutputHandler outputHandler(mipmapData);
	
	OutputOptions outputOptions;
	outputOptions.setContainer(Container_DDS);
	outputOptions.setOutputHandler(&outputHandler);
	
	
	if (!context.process(inputOptions, compressionOptions, outputOptions)) {
		NSLog(@"[%@ %@] context.process() returned false!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	}
	
#if TK_DEBUG
	NSLog(@"[%@ %@] mipmapData length == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)[mipmapData length]);
#endif
	
	NSArray *ddsImageReps = [TKDDSImageRep imageRepsWithData:mipmapData];
	
#if TK_DEBUG
	NSLog(@"[%@ %@] description == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [super description]);
	
	NSLog(@"[%@ %@] ddsImageReps == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), ddsImageReps);
	
#endif
	
	NSMutableArray *tkImageReps = [NSMutableArray array];
	
	for (TKDDSImageRep *ddsImageRep in ddsImageReps) {
		if ([ddsImageRep mipmapIndex] == mipmapIndex) continue;
		TKImageRep *imageRep = [TKImageRep imageRepWithImageRep:ddsImageRep];
		if (imageRep) [tkImageReps addObject:imageRep];
	}
	
	[mipmapData release];
	
	return [[tkImageReps copy] autorelease];
}


- (NSArray *)imageRepsByApplyingNormalMapFilterWithHeightEvaluationWeights:(CIVector *)heightEvaluationWeights
															 filterWeights:(CIVector *)aFilterWeights
																  wrapMode:(TKWrapMode)aWrapMode
														  normalizeMipmaps:(BOOL)normalizeMipmaps 
														  normalMapLibrary:(TKNormalMapLibrary)normalMapLibrary {
	
	NSParameterAssert(normalMapLibrary >= TKNormalMapLibraryUseNVIDIATextureTools && normalMapLibrary <= TKNormalMapLibraryUseAccelerateFramework);
	
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (normalMapLibrary == TKNormalMapLibraryUseNVIDIATextureTools) {
		InputOptions inputOptions;
		inputOptions.setTextureLayout(TextureType_2D, [self pixelsWide], [self pixelsHigh]);
		inputOptions.setFormat(InputFormat_BGRA_8UB);
		
		inputOptions.setNormalMap(false);
		inputOptions.setGamma(1.0, 1.0);
		inputOptions.setConvertToNormalMap(true);
		
		if (heightEvaluationWeights == nil) heightEvaluationWeights = [CIVector vectorWithX:1.0/3.0 Y:1.0/3.0 Z:1.0/3.0 W:0.0];
		if (aFilterWeights == nil) aFilterWeights = [CIVector vectorWithX:1.0 Y:0.5 Z:0.25 W:0.125];
		
		inputOptions.setHeightEvaluation([heightEvaluationWeights X], [heightEvaluationWeights Y], [heightEvaluationWeights Z], [heightEvaluationWeights W]);
		inputOptions.setNormalFilter([aFilterWeights X], [aFilterWeights Y], [aFilterWeights Z], [aFilterWeights W]);
		
		inputOptions.setNormalizeMipmaps(normalizeMipmaps);
		
		inputOptions.setWrapMode(WrapModeFromTKWrapMode(aWrapMode));
		
		CGImageAlphaInfo cgAlphaInfo = [self alphaInfo];
#if TK_DEBUG
		NSLog(@"[%@ %@] alphaInfo == %u, bitmapFormat == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), cgAlphaInfo, (unsigned long)[self bitmapFormat]);
#endif
		inputOptions.setAlphaMode(AlphaModeFromAlphaInfo(cgAlphaInfo));

		NSData *imageData = [self data];
		NSData *swappedData = TKBGRADataFromImageData(imageData, [self pixelsWide] * [self pixelsHigh], [self bitsPerPixel], cgAlphaInfo);
		
		inputOptions.setMipmapData([swappedData bytes], [self pixelsWide], [self pixelsHigh], 1, 0, [self mipmapIndex]);
		
		CompressionOptions compressionOptions;
		compressionOptions.setFormat(Format_RGBA);
		compressionOptions.setQuality(Quality_Highest);
		
		Context context;
		context.enableCudaAcceleration(false);
		
		NSMutableData *normalMapData = [[NSMutableData alloc] init];
		
		TKOutputHandler outputHandler(normalMapData);
		
		OutputOptions outputOptions;
		outputOptions.setOutputHandler(&outputHandler);
		
		if (!context.process(inputOptions, compressionOptions, outputOptions)) {
			NSLog(@"[%@ %@] context.process() returned false!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		}
		
#if TK_DEBUG
		NSLog(@"[%@ %@] normalMapData length == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)[normalMapData length]);
#endif
		
		NSArray *ddsImageReps = [TKDDSImageRep imageRepsWithData:normalMapData];
		
#if TK_DEBUG
		NSLog(@"[%@ %@] description == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [super description]);
		
		NSLog(@"[%@ %@] ddsImageReps == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), ddsImageReps);
		
#endif
		
		NSMutableArray *tkImageReps = [NSMutableArray array];
		
		for (TKDDSImageRep *ddsImageRep in ddsImageReps) {
			//		if ([ddsImageRep mipmapIndex] == mipmapIndex) continue;
			TKImageRep *imageRep = [TKImageRep imageRepWithImageRep:ddsImageRep];
			if (imageRep) [tkImageReps addObject:imageRep];
		}
		
		[normalMapData release];
		
		return [[tkImageReps copy] autorelease];
		
	} else if (normalMapLibrary == TKNormalMapLibraryUseAccelerateFramework) {
		
		
		
		
		
		
		
		
		
		
		
	}
	return nil;
}


+ (NSData *)DDSRepresentationOfImageRepsInArray:(NSArray *)tkImageReps options:(NSDictionary *)options {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[self class] DDSRepresentationOfImageRepsInArray:tkImageReps usingFormat:[[self class] defaultFormat] quality:[TKImageRep defaultDXTCompressionQuality] options:options];
}


+ (NSData *)DDSRepresentationOfImageRepsInArray:(NSArray *)tkImageReps usingFormat:(TKDDSFormat)aFormat quality:(TKDXTCompressionQuality)aQuality options:(NSDictionary *)options {
#if TK_DEBUG
	NSLog(@"[%@ %@] tkImageReps == %@, options == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), tkImageReps, options);
#endif
	NSParameterAssert([tkImageReps count] != 0);
	
	NSNumber *nMipmapType = [options objectForKey:TKImageMipmapGenerationKey];
	NSNumber *nWrapMode = [options objectForKey:TKImageWrapModeKey];
	NSNumber *nRoundMode = [options objectForKey:TKImageRoundModeKey];
	
	NSUInteger maxWidth = 0;
	NSUInteger maxHeight = 0;
	
//	NSUInteger sliceCount = 1;
	NSUInteger faceCount = 1;
	
	for (NSImageRep *imageRep in tkImageReps) {
		if ([imageRep isKindOfClass:[TKImageRep class]]) {
			TKImageRep *tkImageRep = (TKImageRep *)imageRep;
			NSUInteger theFace = [tkImageRep face];
			
			if ([tkImageRep pixelsWide] > maxWidth) maxWidth = [tkImageRep pixelsWide];
			if ([tkImageRep pixelsHigh] > maxHeight) maxHeight = [tkImageRep pixelsHigh];
			
			if (theFace != TKFaceNone) faceCount++;
		} else {
			NSLog(@"[%@ %@] imageRep is NOT a TKImageRep!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		}
	}
	
	InputOptions inputOptions;
	inputOptions.setTextureLayout((faceCount == 1 ? TextureType_2D : TextureType_Cube), maxWidth, maxHeight);
	inputOptions.setFormat(InputFormat_BGRA_8UB);
	
	inputOptions.setWrapMode(WrapModeFromTKWrapMode([nWrapMode unsignedIntegerValue]));
	inputOptions.setRoundMode(RoundModeFromTKRoundMode([nRoundMode unsignedIntegerValue]));
	inputOptions.setNormalMap(false);
	inputOptions.setConvertToNormalMap(false);
	inputOptions.setGamma(2.2, 2.2);
	
	if (nMipmapType == nil || [nMipmapType unsignedIntegerValue] == TKMipmapGenerationNoMipmaps) {
		inputOptions.setMipmapGeneration(false);
	} else {
		inputOptions.setMipmapGeneration(true);
		inputOptions.setMipmapFilter(DDSMipmapFilterFromTKMipmapGenerationType([nMipmapType unsignedIntegerValue]));
	}
	
	for (NSImageRep *imageRep in tkImageReps) {
		if (![imageRep isKindOfClass:[TKImageRep class]]) {
			NSLog(@"[%@ %@] imageRep is NOT a TKImageRep!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			continue;
		}
		TKImageRep *tkImageRep = (TKImageRep *)imageRep;
		
		CGImageAlphaInfo cgAlphaInfo = [tkImageRep alphaInfo];
#if TK_DEBUG
		NSLog(@"[%@ %@] alphaInfo == %u, bitmapFormat == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), cgAlphaInfo, (unsigned long)[tkImageRep bitmapFormat]);
#endif
		
		inputOptions.setAlphaMode(AlphaModeFromAlphaInfo(cgAlphaInfo));

		NSData *imageData = [tkImageRep data];
		NSData *swappedData = TKBGRADataFromImageData(imageData,
													  [tkImageRep pixelsWide] * [tkImageRep pixelsHigh],
													  [tkImageRep bitsPerPixel],
													  cgAlphaInfo);
		
		if (!inputOptions.setMipmapData([swappedData bytes], [tkImageRep pixelsWide], [tkImageRep pixelsHigh], 1, ([tkImageRep face] == TKFaceNone ? 0 : [tkImageRep face]), [tkImageRep mipmapIndex])) {
			NSLog(@"[%@ %@] failed to inputOptions.setMipmapData() for ", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
		}
		
	}
	
	CompressionOptions compressionOptions;
	compressionOptions.setFormat(FormatFromTKDDSFormat(aFormat));
	compressionOptions.setQuality(DDSDXTQualityFromTKDXTCompressionQuality(aQuality));
//	compressionOptions.setQuality(static_cast<nvtt::Quality>(nCompressionQuality == nil ? [TKImageRep defaultDXTCompressionQuality] : [nCompressionQuality unsignedIntegerValue]));
	
	Context context;
	context.enableCudaAcceleration(false);
	
	NSMutableData *ddsData = [[NSMutableData alloc] init];
	
	TKOutputHandler outputHandler(ddsData);
	
	OutputOptions outputOptions;
	outputOptions.setOutputHandler(&outputHandler);
	
	if (!context.process(inputOptions, compressionOptions, outputOptions)) {
		NSLog(@"[%@ %@] context.process() returned false!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	}
#if TK_DEBUG
	NSLog(@"[%@ %@] ddsData length == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)[ddsData length]);
#endif
	NSData *copiedData = [ddsData copy];
	[ddsData release];
	return [copiedData autorelease];
}

static unsigned char *TKCreateRGBADataFromColor32(Color32 *pixels, NSUInteger pixelCount, NSUInteger bitsPerPixel, NSUInteger *length) CF_RETURNS_RETAINED;

//static unsigned char *TKCreateRGBADataFromColor32(Color32 *pixels, NSUInteger pixelCount, NSUInteger bitsPerPixel, NSUInteger *length) NS_RETURNS_RETAINED;

static unsigned char *TKCreateRGBADataFromColor32(Color32 *pixels, NSUInteger pixelCount, NSUInteger bitsPerPixel, NSUInteger *length) {
	if (pixels == NULL || pixelCount == 0 || bitsPerPixel == 0 || (bitsPerPixel != 24 && bitsPerPixel != 32) || length == NULL) {
		NSLog(@"TKCreateRGBADataFromColor32() invalid parameters!");
		return NULL;
	}
	NSUInteger newLength = pixelCount * 4;
	
	int col;
	unsigned char *cp = (unsigned char *)&col;
	
	unsigned int *bytes = (unsigned int *)malloc(newLength);
	
	if (bytes == NULL) {
		NSLog(@"TKCreateRGBADataFromColor32() malloc(%llu) failed!", (unsigned long long)newLength);
		return NULL;
	}
	
	*length = newLength;
	
	cp[3] = 0xff;	// default alpha if alpha channel isn't present
	
	Color32 pixel;
	
	for (unsigned int i = 0; i < pixelCount; i++) {
		pixel = pixels[i];
		cp[0] = pixel.r;	/* set R component of col	*/
		cp[1] = pixel.g;	/* set G component of col	*/
		cp[2] = pixel.b;	/* set B component of col	*/
							
		if (bitsPerPixel == 32) {
			cp[3] = pixel.a; /* set A component of col	*/
		}
		bytes[i] = col;
	}
	return (unsigned char *)bytes;
}


+ (NSArray *)imageRepsWithData:(NSData *)aData firstRepresentationOnly:(BOOL)firstRepOnly {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	OSType magic = 0;
	[aData getBytes:&magic length:sizeof(magic)];
	magic = NSSwapBigIntToHost(magic);
#if TK_DEBUG
	NSLog(@"[%@ %@] magic == 0x%x, %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd),  (unsigned int)magic, NSFileTypeForHFSTypeCode(magic));
#endif
	
	DirectDrawSurface *dds = new DirectDrawSurface((unsigned char *)[aData bytes], [aData length]);
	if (dds == 0) {
		NSLog(@"[%@ %@] new DirectDrawSurface() with data failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return nil;
	}
	
#if TK_DEBUG
	NSLog(@"[%@ %@] dds info == \n", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	dds->printInfo();
#endif
	
	if (!dds->isValid() || !dds->isSupported() || (dds->width() > 65535) || (dds->height() > 65535)) {
		if (!dds->isValid()) {
			NSLog(@"[%@ %@] dds image is not valid, info follows:", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		} else if (!dds->isSupported()) {
			NSLog(@"[%@ %@] dds image format is not supported, info follows:", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		} else {
			NSLog(@"[%@ %@] dds image dimensions are too large, info follows:", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		}
		dds->printInfo();
		delete dds;
		return nil;
	}
//#if TK_DEBUG
//	NSLog(@"[%@ %@] dds info == \n", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//	dds->printInfo();
//#endif
	
	NSMutableArray *bitmapImageReps = [NSMutableArray array];
	
	const NSUInteger mipmapCount = dds->mipmapCount();
	const NSUInteger faceCount = dds->isTextureCube() ? 6 : 1;
	
	for (NSUInteger mipmap = 0; mipmap < mipmapCount; mipmap++) {
		for (NSUInteger faceIndex = 0; faceIndex < faceCount; faceIndex++) {
			Image nvImage;
			dds->mipmap(&nvImage, faceIndex, mipmap);
			NSUInteger length = 0;
			unsigned char *bytes = TKCreateRGBADataFromColor32(nvImage.pixels(), nvImage.width() * nvImage.height(), (nvImage.format() == Image::Format_ARGB ? 32 : 24), &length);
			if (bytes) {
				NSData *convertedData = [[NSData alloc] initWithBytes:bytes length:length];
				free(bytes);
				CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)convertedData);
				[convertedData release];
				CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
				NSUInteger bitsPerPixel = (dds->hasAlpha() ? 32 : 24);
				CGImageRef imageRef = CGImageCreate(nvImage.width(),
													nvImage.height(),
													8,
													32,
													nvImage.width() * 4,
													colorSpace,
													(bitsPerPixel == 32 ? kCGImageAlphaLast : kCGImageAlphaNoneSkipLast),
													provider,
													NULL,
													false,
													kCGRenderingIntentDefault);
				CGColorSpaceRelease(colorSpace);
				CGDataProviderRelease(provider);
				
				if (imageRef) {
					
					TKDDSImageRep *imageRep = [[TKDDSImageRep alloc] initWithCGImage:imageRef
																		  sliceIndex:TKSliceIndexNone
																				face:faceIndex
																		  frameIndex:TKFrameIndexNone
																		 mipmapIndex:mipmap];
					
					CGImageRelease(imageRef);
					if (imageRep) {
						[bitmapImageReps addObject:imageRep];
						[imageRep release];
					}
					
					if (firstRepOnly && faceIndex == 0 && mipmap == 0) {
						delete dds;
						return [[bitmapImageReps copy] autorelease];
					}
					
				} else {
					NSLog(@"[%@ %@] CGImageCreate() (for faceIndex == %lu, mipmapIndex == %lu) failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)faceIndex, (unsigned long)mipmap);
				}
			}
		}
	}
	delete dds;
	return [[bitmapImageReps copy] autorelease];
	
}


/* create TKDDSImageRep(s) from NSBitmapImageRep(s) */

+ (id)imageRepWithImageRep:(NSBitmapImageRep *)aBitmapImageRep {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([aBitmapImageRep isKindOfClass:[TKImageRep class]]) {
		return [[[[self class] alloc] initWithCGImage:[aBitmapImageRep CGImage]
										   sliceIndex:[(TKImageRep *)aBitmapImageRep sliceIndex]
												 face:[(TKImageRep *)aBitmapImageRep face]
										   frameIndex:[(TKImageRep *)aBitmapImageRep frameIndex]
										  mipmapIndex:[(TKImageRep *)aBitmapImageRep mipmapIndex]] autorelease];
	}
	return [[[[self class] alloc] initWithCGImage:[aBitmapImageRep CGImage]] autorelease];
}


+ (NSArray *)imageRepsWithImageReps:(NSArray *)bitmapImageReps {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSMutableArray *imageReps = [NSMutableArray array];
	for (NSBitmapImageRep *imageRep in bitmapImageReps) {
		TKDDSImageRep *ddsImageRep = [[self class] imageRepWithImageRep:imageRep];
		if (ddsImageRep) [imageReps addObject:ddsImageRep];
	}
	return imageReps;
}


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
	TKDDSImageRep *copy = (TKDDSImageRep *)[super copyWithZone:zone];
	NSLog(@"[%@ %@] copy == %@, class == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), copy, NSStringFromClass([copy class]));
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


#pragma pack(1)

typedef struct TKColor24 {
	UInt8	x;
	UInt8	y;
	UInt8	z;
} TKColor24;


typedef struct TKColor32 {
	UInt8	x;
	UInt8	y;
	UInt8	z;
	UInt8	w;
} TKColor32;

#pragma pack()


enum {
	TKBGRA	= UINT_MAX
};

static NSData *TKImageDataFromNSData(NSData *inputData, NSUInteger pixelCount, NSUInteger bitsPerPixel, CGBitmapInfo sourceBitmapInfo, CGBitmapInfo destBitmapInfo) {
	NSCParameterAssert(inputData != nil);
	NSCParameterAssert(pixelCount != 0);
	NSCParameterAssert(bitsPerPixel != 0);
	NSCParameterAssert((bitsPerPixel == 24) || (bitsPerPixel == 32));
	
	NSUInteger newLength = pixelCount;
	
	if (destBitmapInfo == kCGImageAlphaNone) 
		newLength *= 3;
	else
		newLength *= 4;
	
	void *vBytes = malloc(newLength);
	
	
	if (sourceBitmapInfo == kCGImageAlphaNone) {
		TKColor24 *sourcePixels = (TKColor24 *)[inputData bytes];
		TKColor24 sourcePixel;
		
		
		if (destBitmapInfo == kCGImageAlphaNone) {
			free(vBytes);
			return inputData;
			
		} else {
			TKColor32 *destPixels = (TKColor32 *)vBytes;
			TKColor32 destPixel;
			
			for (NSUInteger i = 0; i < pixelCount; i++) {
				sourcePixel = sourcePixels[i];
				
				if (destBitmapInfo == TKBGRA) {
					
					destPixel.x = sourcePixel.z;
					destPixel.y = sourcePixel.y;
					destPixel.z = sourcePixel.x;
					
					destPixel.w = 0xff;
					
					
				} else if (destBitmapInfo == kCGImageAlphaPremultipliedFirst ||
					destBitmapInfo == kCGImageAlphaFirst ||
					destBitmapInfo == kCGImageAlphaNoneSkipFirst) {
					
					destPixel.x = 0xff;
					
					destPixel.y = sourcePixel.x;
					destPixel.z = sourcePixel.y;
					destPixel.w = sourcePixel.z;
					
				} else {
					
					destPixel.x = sourcePixel.x;
					destPixel.y = sourcePixel.y;
					destPixel.z = sourcePixel.z;
					
					destPixel.w = 0xff;
					
				}
				
				destPixels[i] = destPixel;
			}
			
			NSData *newData = [NSData dataWithBytes:destPixels length:newLength];
			free(vBytes);
			return newData;
			
		}
		
		
	} else {
		// 32 bit input image
		
		TKColor32 *sourcePixels = (TKColor32 *)[inputData bytes];
		TKColor32 sourcePixel;
		
		if (destBitmapInfo == kCGImageAlphaNone) {
			
			
		} else {
			TKColor32 *destPixels = (TKColor32 *)vBytes;
			TKColor32 destPixel;
			
			for (NSUInteger i = 0; i < pixelCount; i++) {
				sourcePixel = sourcePixels[i];
				
				if ((sourceBitmapInfo == kCGImageAlphaPremultipliedFirst ||
							sourceBitmapInfo == kCGImageAlphaFirst ||
							sourceBitmapInfo == kCGImageAlphaNoneSkipFirst) &&
						   destBitmapInfo == TKBGRA) {
					
					destPixel.x = sourcePixel.w;
					destPixel.y = sourcePixel.z;
					destPixel.z = sourcePixel.y;
					destPixel.w = sourcePixel.x;
					
					
				} else if ((sourceBitmapInfo == kCGImageAlphaPremultipliedLast ||
							sourceBitmapInfo == kCGImageAlphaLast ||
							sourceBitmapInfo == kCGImageAlphaNoneSkipLast) &&
						   destBitmapInfo == TKBGRA) {
					
					destPixel.x = sourcePixel.z;
					destPixel.y = sourcePixel.y;
					destPixel.z = sourcePixel.x;
					
					destPixel.w = sourcePixel.w;
					
				} else if ((sourceBitmapInfo == kCGImageAlphaPremultipliedFirst || sourceBitmapInfo == kCGImageAlphaFirst || sourceBitmapInfo == kCGImageAlphaNoneSkipFirst) &&
					(destBitmapInfo == kCGImageAlphaPremultipliedLast || destBitmapInfo == kCGImageAlphaLast || destBitmapInfo == kCGImageAlphaNoneSkipLast)) {
					
					destPixel.x = sourcePixel.y;
					destPixel.y = sourcePixel.z;
					destPixel.z = sourcePixel.w;
					destPixel.w = sourcePixel.x;
					
				}
				destPixels[i] = destPixel;
			}
			
			NSData *newData = [NSData dataWithBytes:destPixels length:newLength];
			free(vBytes);
			return newData;
			
		}
		
	}
	return nil;
}

static NSData *TKBGRADataFromImageData(NSData *data, NSUInteger pixelCount, NSUInteger bitsPerPixel, CGBitmapInfo sourceBitmapInfo) {
	return TKImageDataFromNSData(data, pixelCount, bitsPerPixel, sourceBitmapInfo, TKBGRA);
}



