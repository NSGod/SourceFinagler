//
//  TKVTFImageRep.mm
//  Texture Kit
//
//  Created by Mark Douma on 9/25/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKVTFImageRep.h>
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>
#import <VTF/VTF.h>

#define TK_DEBUG 1

#if TK_DEBUG
#import "MDFoundationAdditions.h"
#endif

using namespace VTFLib;


struct TKVTFFormatMapping {
	TKVTFFormat		format;
	VTFImageFormat	vtfFormat;
	TKPixelFormat	pixelFormat;
	NSString		*description;
};
	
static const TKVTFFormatMapping TKVTFFormatMappingTable[] = {
	{ TKVTFFormatRGBA,			IMAGE_FORMAT_RGBA8888, TKPixelFormatRGBA, @"RGBA" },
	{ TKVTFFormatABGR,			IMAGE_FORMAT_ABGR8888, TKPixelFormatRGBA, @"ABGR" },
	{ TKVTFFormatRGB,			IMAGE_FORMAT_RGB888, TKPixelFormatRGBA, @"RGB" },
	{ TKVTFFormatBGR,			IMAGE_FORMAT_BGR888, TKPixelFormatRGBA, @"BGR"  },
	{ TKVTFFormatRGB565,		IMAGE_FORMAT_RGB565, TKPixelFormatRGBA, @"RGB565" },
	{ TKVTFFormatI,				IMAGE_FORMAT_I8, TKPixelFormatRGBA, @"I" },
	{ TKVTFFormatIA,			IMAGE_FORMAT_IA88, TKPixelFormatRGBA, @"IA" },
	{ TKVTFFormatP,				IMAGE_FORMAT_P8, TKPixelFormatRGBA, @"P" },
	{ TKVTFFormatA,				IMAGE_FORMAT_A8, TKPixelFormatRGBA, @"A" },
	{ TKVTFFormatBluescreenRGB,	IMAGE_FORMAT_RGB888_BLUESCREEN, TKPixelFormatRGBA, @"BluescreenRGB" },
	{ TKVTFFormatBluescreenBGR,	IMAGE_FORMAT_BGR888_BLUESCREEN, TKPixelFormatRGBA, @"BluescreenBGR"  },
	{ TKVTFFormatARGB,			IMAGE_FORMAT_ARGB8888, TKPixelFormatARGB, @"ARGB" },
	{ TKVTFFormatBGRA,			IMAGE_FORMAT_BGRA8888, TKPixelFormatRGBA, @"BGRA" },
	{ TKVTFFormatDXT1,			IMAGE_FORMAT_DXT1, TKPixelFormatRGBA, @"DXT1" },
	{ TKVTFFormatDXT3,			IMAGE_FORMAT_DXT3, TKPixelFormatRGBA, @"DXT3" },
	{ TKVTFFormatDXT5,			IMAGE_FORMAT_DXT5, TKPixelFormatRGBA, @"DXT5" },
	{ TKVTFFormatBGRX,			IMAGE_FORMAT_BGRX8888, TKPixelFormatRGBA, @"BGRX" },
	{ TKVTFFormatBGR565,		IMAGE_FORMAT_BGR565, TKPixelFormatRGBA, @"BGR565" },
	{ TKVTFFormatBGRX5551,		IMAGE_FORMAT_BGRX5551, TKPixelFormatRGBA, @"BGRX5551" },
	{ TKVTFFormatBGRA4444,		IMAGE_FORMAT_BGRA4444, TKPixelFormatRGBA, @"BGRA4444" },
	{ TKVTFFormatDXT1a,			IMAGE_FORMAT_DXT1_ONEBITALPHA, TKPixelFormatRGBA, @"DXT1a" },
	{ TKVTFFormatBGRA5551,		IMAGE_FORMAT_BGRA5551, TKPixelFormatRGBA, @"BGRA5551"  },
	{ TKVTFFormatUV,			IMAGE_FORMAT_UV88, TKPixelFormatRGBA, @"UV"  },
	{ TKVTFFormatUVWQ,			IMAGE_FORMAT_UVWQ8888, TKPixelFormatRGBA, @"UVWQ"  },
	{ TKVTFFormatRGBA16161616F,	IMAGE_FORMAT_RGBA16161616F, TKPixelFormatRGBA, @"RGBA16161616F" },
	{ TKVTFFormatRGBA16161616,	IMAGE_FORMAT_RGBA16161616, TKPixelFormatRGBA16161616, @"RGBA16161616"  },
	{ TKVTFFormatUVLX,			IMAGE_FORMAT_UVLX8888, TKPixelFormatRGBA, @"UVLX"  },
	{ TKVTFFormatR32F,			IMAGE_FORMAT_R32F, TKPixelFormatRGBA, @"R32F" },
	{ TKVTFFormatRGB323232F,	IMAGE_FORMAT_RGB323232F, TKPixelFormatRGBA, @"RGB323232F" },
	{ TKVTFFormatRGBA32323232F,	IMAGE_FORMAT_RGBA32323232F, TKPixelFormatRGBA32323232F, @"RGBA32323232F" },
	{ TKVTFFormatNVDST16,		IMAGE_FORMAT_NV_DST16, TKPixelFormatRGBA, @"NVDST16"  },
	{ TKVTFFormatNVDST24,		IMAGE_FORMAT_NV_DST24, TKPixelFormatRGBA, @"NVDST24" },
	{ TKVTFFormatNVINTZ,		IMAGE_FORMAT_NV_INTZ, TKPixelFormatRGBA, @"NVINTZ" },
	{ TKVTFFormatNVRAWZ,		IMAGE_FORMAT_NV_RAWZ, TKPixelFormatRGBA, @"NVRAWZ"  },
	{ TKVTFFormatATIDST16,		IMAGE_FORMAT_ATI_DST16, TKPixelFormatRGBA, @"ATIDST16" },
	{ TKVTFFormatATIDST24,		IMAGE_FORMAT_ATI_DST24, TKPixelFormatRGBA, @"ATIDST24"  },
	{ TKVTFFormatNVNULL,		IMAGE_FORMAT_NV_NULL, TKPixelFormatRGBA, @"NVNULL"  },
	{ TKVTFFormatATI2N,			IMAGE_FORMAT_ATI2N, TKPixelFormatRGBA, @"ATI2N" },
	{ TKVTFFormatATI1N,			IMAGE_FORMAT_ATI1N, TKPixelFormatRGBA, @"ATI1N" }
};

static const NSUInteger TKVTFImageFormatMappingTableCount = sizeof(TKVTFFormatMappingTable)/sizeof(TKVTFFormatMapping);


NSString *NSStringFromVTFFormat(TKVTFFormat aFormat) {
	for (NSUInteger i = 0; i < TKVTFImageFormatMappingTableCount; i++) {
		if (TKVTFFormatMappingTable[i].format == aFormat) {
			return TKVTFFormatMappingTable[i].description;
		}
	}
	return @"<Unknown>";
}
	
static inline VTFImageFormat VTFImageFormatFromTKVTFFormat(TKVTFFormat aFormat) {
	for (NSUInteger i = 0; i < TKVTFImageFormatMappingTableCount; i++) {
		if (TKVTFFormatMappingTable[i].format == aFormat) {
			return TKVTFFormatMappingTable[i].vtfFormat;
		}
	}
	return IMAGE_FORMAT_NONE;
}

static inline TKPixelFormat TKPixelFormatFromVTFImageFormat(VTFImageFormat aFormat) {
	for (NSUInteger i = 0; i < TKVTFImageFormatMappingTableCount; i++) {
		if (TKVTFFormatMappingTable[i].vtfFormat == aFormat) {
			return TKVTFFormatMappingTable[i].pixelFormat;
		}
	}
	return TKPixelFormatUnknown;
}




NSString * const TKVTFType			= @"com.valvesoftware.source.vtf";
NSString * const TKVTFFileType		= @"vtf";
NSString * const TKVTFPboardType	= @"TKVTFPboardType";


@interface TKVTFImageRep (TKPrivate)
+ (NSArray *)imageRepsWithData:(NSData *)aData firstRepresentationOnly:(BOOL)firstRepOnly;
@end


static TKVTFFormat defaultVTFFormat = TKVTFFormatDefault;


@implementation TKVTFImageRep

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
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	static NSArray *imageUnfilteredPasteboardTypes = nil;
	
	if (imageUnfilteredPasteboardTypes == nil) {
		NSArray *types = [super imageUnfilteredPasteboardTypes];
		NSLog(@"[%@ %@] super's imageUnfilteredPasteboardTypes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), types);
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
	return defaultVTFFormat;
}

+ (void)setDefaultFormat:(TKVTFFormat)aFormat {
	defaultVTFFormat = aFormat;
}


+ (NSData *)VTFRepresentationOfImageRepsInArray:(NSArray *)tkImageReps {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[self class] VTFRepresentationOfImageRepsInArray:tkImageReps usingFormat:defaultVTFFormat quality:[[self class] defaultDXTCompressionQuality] createMipmaps:YES];
}

+ (NSData *)VTFRepresentationOfImageRepsInArray:(NSArray *)tkImageReps usingFormat:(TKVTFFormat)aFormat quality:(TKDXTCompressionQuality)aQuality createMipmaps:(BOOL)createMipmaps {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([tkImageReps count] == 0) {
		return nil;
	}
	NSUInteger maxWidth = 0;
	NSUInteger maxHeight = 0;
	
	NSUInteger sliceCount = 1;
	NSUInteger faceCount = 1;
	NSUInteger frameCount = 1;
//	NSUInteger mipmapCount = 1;
	
	for (NSImageRep *imageRep in tkImageReps) {
		if ([imageRep isKindOfClass:[TKImageRep class]]) {
			TKImageRep *textureImageRep = (TKImageRep *)imageRep;
			NSUInteger theSliceIndex = [textureImageRep sliceIndex];
			NSUInteger theFace	= [textureImageRep face];
			NSUInteger theFrameIndex = [textureImageRep frameIndex];
			
			if ([textureImageRep pixelsWide] > maxWidth) maxWidth = [textureImageRep pixelsWide];
			if ([textureImageRep pixelsHigh] > maxHeight) maxHeight = [textureImageRep pixelsHigh];
			
			if (theSliceIndex > 0) {
				if (theSliceIndex > (sliceCount - 1)) {
					sliceCount = theSliceIndex - 1;
				}
			}
			if (theFace != TKFaceNone) {
				faceCount++;
			}
			if (theFrameIndex > 0) {
				frameCount++;
			}
			
		} else {
			NSLog(@"[%@ %@] imageRep is NOT A TKImageRep!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
		}
	}
	
	VTFImageFormat imageFormat = VTFImageFormatFromTKVTFFormat(aFormat);
	TKPixelFormat aPixelFormat = TKPixelFormatFromVTFImageFormat(imageFormat);
	
	
	CVTFFile *vtfFile = new CVTFFile();
	
	if (aPixelFormat == TKPixelFormatRGBA) {
		if (!vtfFile->Create(maxWidth, maxHeight, frameCount, faceCount, sliceCount, IMAGE_FORMAT_RGBA8888, vlFalse, createMipmaps, vlTrue)) {
//		if (!vtfFile->Create(maxWidth, maxHeight, frameCount, faceCount, sliceCount, IMAGE_FORMAT_RGBA8888, vlTrue, createMipmaps, vlTrue)) {
			delete vtfFile;
			NSLog(@"[%@ %@] vtfFile->Create() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return nil;
		}
		
		for (NSImageRep *imageRep in tkImageReps) {
			
			if ([imageRep isKindOfClass:[TKImageRep class]]) {
				
				vlUInt theFrameIndex = (vlUInt)[(TKImageRep *)imageRep frameIndex];
				vlUInt theFace = (vlUInt)[(TKImageRep *)imageRep face];
				vlUInt theSliceIndex = (vlUInt)[(TKImageRep *)imageRep sliceIndex];
				vlUInt theMipmapIndex = (vlUInt)[(TKImageRep *)imageRep mipmapIndex];
				NSData *rgbaData = [(TKImageRep *)imageRep RGBAData];
				vlByte *rgbaBytes = (vlByte *)[rgbaData bytes];
				
				vtfFile->SetData(theFrameIndex, theFace, theSliceIndex, theMipmapIndex, rgbaBytes);
				
//				vtfFile->SetData((vlUInt)[(TKImageRep *)imageRep frameIndex],
//								 (vlUInt)[(TKImageRep *)imageRep face],
//								 (vlUInt)[(TKImageRep *)imageRep sliceIndex],
//								 (vlUInt)[(TKImageRep *)imageRep mipmapIndex],
//								 (vlByte *)[[(TKImageRep *)imageRep RGBAData] bytes]);
				
			} else {
				
			}
		}
		
#if TK_DEBUG
		NSString *destPath = [@"/Users/mdouma46/Documents/Programming (Resources)/Source Finagler/test images/generated/testImageBeforeMipmaps.vtf" stringByAssuringUniqueFilename];
		
		if (!vtfFile->Save((const vlChar *)[destPath fileSystemRepresentation])) {
			NSLog(@"[%@ %@] failed to save file to %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), destPath);
		}

#endif
		if (createMipmaps) {
			vlBool success = vtfFile->GenerateMipmaps(MIPMAP_FILTER_BOX, SHARPEN_FILTER_DEFAULT);
			if (!success) {
				NSLog(@"[%@ %@] vtfFile->GenerateMipmaps() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
			}
		}
		
#if TK_DEBUG
		destPath = [@"/Users/mdouma46/Documents/Programming (Resources)/Source Finagler/test images/generated/testImageAfterMipmaps.vtf" stringByAssuringUniqueFilename];
		
		if (!vtfFile->Save((const vlChar *)[destPath fileSystemRepresentation])) {
			NSLog(@"[%@ %@] failed to save file to %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), destPath);
		}

#endif
		
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
//		if (!vtfFile->Create(maxWidth, maxHeight, frameCount, faceCount, sliceCount, imageFormat, vlTrue, createMipmaps, vlTrue)) {
		if (!vtfFile->Create(maxWidth, maxHeight, frameCount, faceCount, sliceCount, imageFormat, vlFalse, createMipmaps, vlTrue)) {
			delete vtfFile;
			NSLog(@"[%@ %@] vtfFile->Create() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return nil;
		}
		
		for (NSImageRep *imageRep in tkImageReps) {
			
			if ([imageRep isKindOfClass:[TKImageRep class]]) {
				
				vlUInt theFrameIndex = (vlUInt)[(TKImageRep *)imageRep frameIndex];
				vlUInt theFace = (vlUInt)[(TKImageRep *)imageRep face];
				vlUInt theSliceIndex = (vlUInt)[(TKImageRep *)imageRep sliceIndex];
				vlUInt theMipmapIndex = (vlUInt)[(TKImageRep *)imageRep mipmapIndex];
				NSData *pixelData = [(TKImageRep *)imageRep representationUsingPixelFormat:aPixelFormat];
				vlByte *pixelBytes = (vlByte *)[pixelData bytes];
				
				vtfFile->SetData(theFrameIndex, theFace, theSliceIndex, theMipmapIndex, pixelBytes);
				
//				vtfFile->SetData((vlUInt)[(TKImageRep *)imageRep frameIndex],
//								 (vlUInt)[(TKImageRep *)imageRep face],
//								 (vlUInt)[(TKImageRep *)imageRep sliceIndex],
//								 (vlUInt)[(TKImageRep *)imageRep mipmapIndex],
//								 (vlByte *)[[(TKImageRep *)imageRep representationUsingPixelFormat:aPixelFormat] bytes]);
				
			} else {
				
			}
		}
		
#if TK_DEBUG
		NSString *destPath = [@"/Users/mdouma46/Documents/Programming (Resources)/Source Finagler/test images/generated/testImageBeforeMipmaps.vtf" stringByAssuringUniqueFilename];
		
		if (!vtfFile->Save((const vlChar *)[destPath fileSystemRepresentation])) {
			NSLog(@"[%@ %@] failed to save file to %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), destPath);
		}
		
#endif
		
		if (createMipmaps) {
			vlBool success = vtfFile->GenerateMipmaps(MIPMAP_FILTER_BOX, SHARPEN_FILTER_DEFAULT);
//			vlBool success = vtfFile->GenerateMipmaps();
			if (!success) {
				NSLog(@"[%@ %@] vtfFile->GenerateMipmaps() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
				
			}
		}
		
#if TK_DEBUG
		destPath = [@"/Users/mdouma46/Documents/Programming (Resources)/Source Finagler/test images/generated/testImageAfterMipmaps.vtf" stringByAssuringUniqueFilename];
		
		if (!vtfFile->Save((const vlChar *)[destPath fileSystemRepresentation])) {
			NSLog(@"[%@ %@] failed to save file to %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), destPath);
		}
		
#endif
		
		
		
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
	
	VTFImageFormat destFormat = IMAGE_FORMAT_NONE;
	
	if (imageFormat == IMAGE_FORMAT_RGBA16161616F ||
		imageFormat == IMAGE_FORMAT_RGBA16161616 ||
		imageFormat == IMAGE_FORMAT_R32F ||
		imageFormat == IMAGE_FORMAT_RGB323232F ||
		imageFormat == IMAGE_FORMAT_RGBA32323232F) {
		
		destFormat = IMAGE_FORMAT_RGBA32323232F;
	} else {
		destFormat = (file->GetFlags() & (TEXTUREFLAGS_ONEBITALPHA | TEXTUREFLAGS_EIGHTBITALPHA)) ? IMAGE_FORMAT_RGBA8888 : IMAGE_FORMAT_RGB888;
	}
	
	NSMutableArray *bitmapImageReps = [NSMutableArray array];
	
	for (vlUInt mipmapNumber = 0; mipmapNumber < mipmapCount; mipmapNumber++) {
		for (vlUInt frame = 0; frame < frameCount; frame++) {
			for (vlUInt faceIndex = 0; faceIndex < faceCount; faceIndex++) {
				for (vlUInt slice = 0; slice < sliceCount; slice++) {
					
					vlUInt mipmapWidth = 0;
					vlUInt mipmapHeight = 0;
					vlUInt mipmapDepth = 0;
					
					file->ComputeMipmapDimensions(imageWidth, imageHeight, sliceCount, mipmapNumber, mipmapWidth, mipmapHeight, mipmapDepth);
					
#if TK_DEBUG
//					NSLog(@"[%@ %@] sliceIndex == %u, faceIndex == %u, frameIndex == %u, mipmapIndex == %u; mipmapWidth == %u, mipmapHeight == %u, mipmapDepth == %u", NSStringFromClass([self class]), NSStringFromSelector(_cmd), slice, faceIndex, frame, mipmapNumber, mipmapWidth, mipmapHeight, mipmapDepth);
#endif
					vlUInt convertedMipmapLength = 0;
					convertedMipmapLength = file->ComputeMipmapSize(imageWidth, imageHeight, sliceCount, mipmapNumber, destFormat);
#if TK_DEBUG
//					NSLog(@"[%@ %@] slice == %u, face == %u, frame == %u, mipmap == %u; mipmapLength == %u", NSStringFromClass([self class]), NSStringFromSelector(_cmd), slice, faceIndex, frame, mipmapNumber, convertedMipmapLength);
#endif
					vlByte *bytes = new vlByte[convertedMipmapLength];
					
					if (bytes == 0) {
						NSLog(@"[%@ %@] new [%lu] failed! slice == %u, face == %u, frame == %u, mipmap == %u", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)convertedMipmapLength, slice, faceIndex, frame, mipmapNumber);
						continue;
					}
					
					vlByte *existingBytes = existingBytes = file->GetData(frame, faceIndex, slice, mipmapNumber);
					
					if (existingBytes == 0) {
						NSLog(@"[%@ %@] failed to get existing data for slice == %u, face == %u, frame == %u, mipmap == %u", NSStringFromClass([self class]), NSStringFromSelector(_cmd), slice, faceIndex, frame, mipmapNumber);
						continue;
					}
					
					
					if (existingBytes) {
						if ( file->Convert(existingBytes, bytes, mipmapWidth, mipmapHeight, imageFormat, destFormat)) {
							
							size_t bitsPerComponent = 0;
							size_t bitsPerPixel = 0;
							size_t bytesPerRow = 0;
							CGBitmapInfo bitmapInfo = 0;
							
							bitsPerComponent = (destFormat == IMAGE_FORMAT_RGBA32323232F ? 32 : 8);
							if (destFormat == IMAGE_FORMAT_RGBA32323232F) {
								bitsPerComponent = 32;
								bitsPerPixel = 128;
								bytesPerRow = (bitsPerPixel/ 8) * mipmapWidth;
								bitmapInfo = kCGImageAlphaLast | kCGBitmapFloatComponents;
								
							} else if (destFormat == IMAGE_FORMAT_RGBA8888) {
								bitsPerComponent = 8;
								bitsPerPixel = 32;
								bytesPerRow = (bitsPerPixel/ 8) * mipmapWidth;
								bitmapInfo = kCGImageAlphaLast;
								
							} else if (destFormat == IMAGE_FORMAT_RGB888) {
								bitsPerComponent = 8;
								bitsPerPixel = 24;
								bytesPerRow = (bitsPerPixel/ 8) * mipmapWidth;
								bitmapInfo = kCGImageAlphaNone;
							}
							
							
							NSData *convertedData = [[NSData alloc] initWithBytes:bytes length:convertedMipmapLength];
							delete [] bytes;
							CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)convertedData);
							[convertedData release];
							CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
							CGImageRef imageRef = CGImageCreate(mipmapWidth,
																mipmapHeight,
																bitsPerComponent,
																bitsPerPixel,
																bytesPerRow,
																colorSpace,
																bitmapInfo,
																provider,
																NULL,
																false,
																kCGRenderingIntentDefault);
							
							CGColorSpaceRelease(colorSpace);
							CGDataProviderRelease(provider);
							
							if (imageRef) {
								
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
								
								if (firstRepOnly && frame == 0 && faceIndex == 0 && slice == 0 && mipmapNumber == 0) {
									delete file;
									return [[bitmapImageReps copy] autorelease];
								}
							} else {
								NSLog(@"[%@ %@] CGImageCreate() (for sliceIndex == %u, faceIndex == %u, frameIndex == %u, mipmapIndex == %u) failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), slice, faceIndex, frame, mipmapNumber);
								
							}
						}
					}
				}
			}
		}
	}
	delete file;
	return [[bitmapImageReps copy] autorelease];

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
	TKVTFImageRep *copy = (TKVTFImageRep *)[super copyWithZone:zone];
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

