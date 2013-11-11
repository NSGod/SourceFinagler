//
//  TKImageExportPreset.h
//  Texture Kit
//
//  Created by Mark Douma on 12/11/2010.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TextureKit/TextureKit.h>


TEXTUREKIT_EXTERN NSString * const TKImageExportNameKey;					// NSString with name
TEXTUREKIT_EXTERN NSString * const TKImageExportFileTypeKey;				// NSString with name
TEXTUREKIT_EXTERN NSString * const TKImageExportFormatKey;					// NSString with name
TEXTUREKIT_EXTERN NSString * const TKImageExportDXTCompressionQualityKey;	// NSString with name
TEXTUREKIT_EXTERN NSString * const TKImageExportMipmapGenerationKey;		// NSNumber with NSUInteger value



@interface TKImageExportPreset : NSObject <NSCoding, NSCopying> {
	NSString					*name;
	NSString					*fileType;
	NSString					*compressionFormat;
	NSString					*compressionQuality;
	TKMipmapGenerationType		mipmapGeneration;
	
}


+ (NSArray *)imageExportPresetsWithDictionaryRepresentations:(NSArray *)dictionaryRepresentations;
+ (NSArray *)dictionaryRepresentationsOfImageExportPresets:(NSArray *)presets;


+ (TKImageExportPreset *)originalImagePreset;


+ (id)imageExportPresetWithDictionary:(NSDictionary *)aDictionary;
- (id)initWithDictionary:(NSDictionary *)aDictionary;

+ (id)imageExportPresetWithName:(NSString *)aName fileType:(NSString *)aFileType compressionFormat:(NSString *)aCompressionFormat compressionQuality:(NSString *)aQuality mipmapGeneration:(TKMipmapGenerationType)aMipmapGeneration;
- (id)initWithName:(NSString *)aName fileType:(NSString *)aFileType compressionFormat:(NSString *)aCompressionFormat compressionQuality:(NSString *)aQuality mipmapGeneration:(TKMipmapGenerationType)aMipmapGeneration;


@property (retain) NSString	*name;
@property (retain) NSString *fileType;
@property (retain) NSString *compressionFormat;
@property (retain) NSString *compressionQuality;
@property (assign) TKMipmapGenerationType mipmapGeneration;


- (BOOL)isEqual:(id)object;
- (BOOL)isEqualToPreset:(TKImageExportPreset *)preset;

// matchesPreset: all but name is equal
- (BOOL)matchesPreset:(TKImageExportPreset *)preset;

- (NSDictionary *)dictionaryRepresentation;

@end


@interface TKDDSImageRep (TKImageExportPresetAdditions)
+ (NSData *)DDSRepresentationOfImageRepsInArray:(NSArray *)tkImageReps usingPreset:(TKImageExportPreset *)preset;
@end


@interface TKVTFImageRep (TKImageExportPresetAdditions)
+ (NSData *)VTFRepresentationOfImageRepsInArray:(NSArray *)tkImageReps usingPreset:(TKImageExportPreset *)preset;
@end



