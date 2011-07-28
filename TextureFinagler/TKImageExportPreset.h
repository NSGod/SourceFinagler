//
//  TKImageExportPreset.h
//  Texture Kit
//
//  Created by Mark Douma on 12/11/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TextureKit/TextureKit.h>


TEXTUREKIT_EXTERN NSString * const TKImageExportNameKey;					// NSString with name
TEXTUREKIT_EXTERN NSString * const TKImageExportFileTypeKey;				// NSString with name
TEXTUREKIT_EXTERN NSString * const TKImageExportFormatKey;					// NSString with name
TEXTUREKIT_EXTERN NSString * const TKImageExportDXTCompressionQualityKey;	// NSString with name
TEXTUREKIT_EXTERN NSString * const TKImageExportMipmapsKey;					// NSNumber with BOOL value



@interface TKImageExportPreset : NSObject <NSCoding, NSCopying> {
	NSString					*name;
	NSString					*fileType;
	NSString					*format;
	NSString					*compressionQuality;
	BOOL						mipmaps;
	
}


+ (NSArray *)imageExportPresetsWithDictionaryRepresentations:(NSArray *)dictionaryRepresentations;
+ (NSArray *)dictionaryRepresentationsOfImageExportPresets:(NSArray *)presets;


+ (id)originalImagePreset;


+ (id)imageExportPresetWithDictionary:(NSDictionary *)aDictionary;
- (id)initWithDictionary:(NSDictionary *)aDictionary;

+ (id)imageExportPresetWithName:(NSString *)aName fileType:(NSString *)aFileType format:(NSString *)aFormat compressionQuality:(NSString *)aQuality mipmaps:(BOOL)aMipmaps;
- (id)initWithName:(NSString *)aName fileType:(NSString *)aFileType format:(NSString *)aFormat compressionQuality:(NSString *)aQuality mipmaps:(BOOL)aMipmaps;


@property (retain) NSString	*name;
@property (retain) NSString *fileType;
@property (retain) NSString *format;
@property (retain) NSString *compressionQuality;
@property (assign) BOOL mipmaps;

- (BOOL)isEqual:(id)object;
- (BOOL)isEqualToPreset:(TKImageExportPreset *)preset;

// matchesPreset: is all but name is equal
- (BOOL)matchesPreset:(TKImageExportPreset *)preset;

- (NSDictionary *)dictionaryRepresentation;

@end


@interface TKDDSImageRep (TKImageExportPresetAdditions)

+ (NSData *)DDSRepresentationOfImageRepsInArray:(NSArray *)tkImageReps usingPreset:(TKImageExportPreset *)preset;

@end


@interface TKVTFImageRep (TKImageExportPresetAdditions)

+ (NSData *)VTFRepresentationOfImageRepsInArray:(NSArray *)tkImageReps usingPreset:(TKImageExportPreset *)preset;

@end



