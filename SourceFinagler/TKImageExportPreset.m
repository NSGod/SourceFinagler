//
//  TKImageExportPreset.m
//  Source Finagler
//
//  Created by Mark Douma on 12/11/2010.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//

#import "TKImageExportPreset.h"

NSString * const TKImageExportNameKey						= @"TKImageExportName";
NSString * const TKImageExportFileTypeKey					= @"TKImageExportFileType";
NSString * const TKImageExportFormatKey						= @"TKImageExportFormat";
NSString * const TKImageExportDXTCompressionQualityKey		= @"TKImageExportDXTCompressionQuality";
NSString * const TKImageExportMipmapGenerationKey					= @"TKImageExportMipmaps";


#define TK_DEBUG 1


@interface TKImageExportPreset (TKPrivate)
- (void)updateName;
@end



extern NSString * const TKImageExportPresetsKey;


static TKImageExportPreset *originalImagePreset = nil;

static NSMutableArray *imagePresets = nil;


@implementation TKImageExportPreset

@synthesize name, fileType, compressionFormat, compressionQuality, mipmapGeneration;

+ (void)initialize {
	if (imagePresets == nil) {
		imagePresets = [[NSMutableArray alloc] init];
		[imagePresets setArray:[TKImageExportPreset imageExportPresetsWithDictionaryRepresentations:[[NSUserDefaults standardUserDefaults] objectForKey:TKImageExportPresetsKey]]];
	}
}


+ (NSArray *)imageExportPresetsWithDictionaryRepresentations:(NSArray *)dictionaryRepresentations {
	if (dictionaryRepresentations == nil) return nil;
	NSMutableArray *imageExportPresets = [NSMutableArray array];
	for (NSDictionary *dictionary in dictionaryRepresentations) {
		TKImageExportPreset *preset = [TKImageExportPreset imageExportPresetWithDictionary:dictionary];
		if (preset) [imageExportPresets addObject:preset];
	}
	NSArray *rImageExportPresets = [imageExportPresets copy];
	return [rImageExportPresets autorelease];
}


+ (NSArray *)dictionaryRepresentationsOfImageExportPresets:(NSArray *)presets {
	if (presets == nil) return nil;
	NSMutableArray *dictReps = [NSMutableArray array];
	for (TKImageExportPreset *preset in presets) {
		NSDictionary *dictRep = [preset dictionaryRepresentation];
		if (dictRep) [dictReps addObject:dictRep];
	}
	NSArray *rDictReps = [dictReps copy];
	return [rDictReps autorelease];
}


+ (TKImageExportPreset *)originalImagePreset {
	@synchronized(self) {
		if (originalImagePreset == nil) {
#if TK_DEBUG
			NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
			originalImagePreset = [[[self class] alloc] initWithName:NSLocalizedString(@"Original", @"") fileType:nil compressionFormat:nil compressionQuality:nil mipmapGeneration:TKMipmapGenerationNoMipmaps];
		}
	}
	return originalImagePreset;
}


+ (id)imageExportPresetWithDictionary:(NSDictionary *)aDictionary {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[[[self class] alloc] initWithDictionary:aDictionary] autorelease];
}

+ (id)imageExportPresetWithName:(NSString *)aName fileType:(NSString *)aFileType compressionFormat:(NSString *)aCompressionFormat compressionQuality:(NSString *)aQuality mipmapGeneration:(TKMipmapGenerationType)aMipmapGeneration {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[[[self class] alloc] initWithName:aName fileType:aFileType compressionFormat:aCompressionFormat compressionQuality:aQuality mipmapGeneration:aMipmapGeneration] autorelease];
}


- (id)initWithName:(NSString *)aName fileType:(NSString *)aFileType compressionFormat:(NSString *)aCompressionFormat compressionQuality:(NSString *)aQuality mipmapGeneration:(TKMipmapGenerationType)aMipmapGeneration {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super init])) {
		name = [aName retain];
		fileType = [aFileType retain];
		compressionFormat = [aCompressionFormat retain];
		compressionQuality = [aQuality retain];
		mipmapGeneration = aMipmapGeneration;
	}
	return self;
}


- (id)initWithDictionary:(NSDictionary *)aDictionary {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super init])) {
		name = [[aDictionary objectForKey:TKImageExportNameKey] retain];
		fileType = [[aDictionary objectForKey:TKImageExportFileTypeKey] retain];
		compressionFormat = [[aDictionary objectForKey:TKImageExportFormatKey] retain];
		compressionQuality = [[aDictionary objectForKey:TKImageExportDXTCompressionQualityKey] retain];
		mipmapGeneration = [[aDictionary objectForKey:TKImageExportMipmapGenerationKey] unsignedIntegerValue];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super init])) {
		name = [[coder decodeObjectForKey:TKImageExportNameKey] retain];
		fileType = [[coder decodeObjectForKey:TKImageExportFileTypeKey] retain];
		compressionFormat = [[coder decodeObjectForKey:TKImageExportFormatKey] retain];
		compressionQuality = [[coder decodeObjectForKey:TKImageExportDXTCompressionQualityKey] retain];
		mipmapGeneration = [[coder decodeObjectForKey:TKImageExportMipmapGenerationKey] unsignedIntegerValue];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[coder encodeObject:name forKey:TKImageExportNameKey];
	[coder encodeObject:fileType forKey:TKImageExportFileTypeKey];
	[coder encodeObject:compressionFormat forKey:TKImageExportFormatKey];
	[coder encodeObject:compressionQuality forKey:TKImageExportDXTCompressionQualityKey];
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:mipmapGeneration] forKey:TKImageExportMipmapGenerationKey];
}

- (id)copyWithZone:(NSZone *)zone {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (self == originalImagePreset) {
		NSLog(@"[%@ %@] **** attempting to copy originalImagePreset; returning self", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return [originalImagePreset retain];
	}
	
	TKImageExportPreset *copy = [[TKImageExportPreset alloc] initWithName:name
																 fileType:fileType
																   compressionFormat:compressionFormat
													   compressionQuality:compressionQuality
														 mipmapGeneration:mipmapGeneration];
	return copy;
}


- (void)dealloc {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[name release];
	[fileType release];
	[compressionFormat release];
	[compressionQuality release];
	[super dealloc];
}


- (void)setNilValueForKey:(NSString *)key {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([key isEqualToString:@"mipmapGeneration"]) {
		mipmapGeneration = TKMipmapGenerationNoMipmaps;
	} else {
		[super setNilValueForKey:key];
	}
}


- (void)updateName {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([imagePresets containsObject:self]) {
		
	}
	
	for (TKImageExportPreset *preset in imagePresets) {
		if ([preset matchesPreset:self]) {
			[self setName:[preset name]];
			return;
		}
	}
	[self setName:NSLocalizedString(@"[Custom]", @"")];
}


- (NSString *)name {
    return name;
}

- (void)setName:(NSString *)value {
	[value retain];
	[name release];
	name = value;
//	[self updateName];
}

- (NSString *)fileType {
    return fileType;
}

- (void)setFileType:(NSString *)value {
	[value retain];
	[fileType release];
	fileType = value;
	[self updateName];
}

- (NSString *)compressionFormat {
    return compressionFormat;
}

- (void)setCompressionFormat:(NSString *)value {
	[value retain];
	[compressionFormat release];
	compressionFormat = value;
	[self updateName];
}

- (NSString *)compressionQuality {
    return compressionQuality;
}

- (void)setCompressionQuality:(NSString *)value {
	[value retain];
	[compressionQuality release];
	compressionQuality = value;
	[self updateName];
}


- (TKMipmapGenerationType)mipmapGeneration {
	return mipmapGeneration;
}

- (void)setMipmapGeneration:(TKMipmapGenerationType)aMipmapGeneration {
	mipmapGeneration = aMipmapGeneration;
	[self updateName];
}


- (NSDictionary *)dictionaryRepresentation {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSDictionary *dictionaryRepresentation = [NSDictionary dictionaryWithObjectsAndKeys:name,TKImageExportNameKey,
											  fileType,TKImageExportFileTypeKey,
											  compressionFormat,TKImageExportFormatKey,
											  compressionQuality,TKImageExportDXTCompressionQualityKey,
											  [NSNumber numberWithUnsignedInteger:mipmapGeneration],TKImageExportMipmapGenerationKey, nil];
	return dictionaryRepresentation;
}


- (BOOL)isEqual:(id)object {
	return [self isEqualToPreset:object];
}


- (BOOL)isEqualToPreset:(TKImageExportPreset *)preset {
	if ([preset isKindOfClass:[self class]]) {
		
		if ([[preset name] isEqualToString:NSLocalizedString(@"Original", @"")] &&
			[name isEqualToString:NSLocalizedString(@"Original", @"")] &&
			[[preset name] isEqualToString:name]) {
			return YES;
		}
		
		return ([[preset name] isEqualToString:name] &&
				[[preset fileType] isEqualToString:fileType] &&
				[[preset compressionFormat] isEqualToString:compressionFormat] &&
				[[preset compressionQuality] isEqualToString:compressionQuality] &&
				[preset mipmapGeneration] == mipmapGeneration);
	}
	return NO;
}


// matchesPreset: all but name is equal
- (BOOL)matchesPreset:(TKImageExportPreset *)preset {
	if ([preset isKindOfClass:[self class]]) {
		return ([[preset fileType] isEqualToString:fileType] &&
				[[preset compressionFormat] isEqualToString:compressionFormat] &&
				[[preset compressionQuality] isEqualToString:compressionQuality] &&
				[preset mipmapGeneration] == mipmapGeneration);
	}
	return NO;
}




- (NSString *)description {
//	NSMutableString *description = [NSMutableString stringWithString:[super description]];
	NSMutableString *description = [NSMutableString string];
	[description appendFormat:@" %@, ", name];
	[description appendFormat:@"%@, ", fileType];
	[description appendFormat:@"%@, ", compressionFormat];
	[description appendFormat:@"%@, ", compressionQuality];
	[description appendFormat:@"mipmapGeneration == %lu", (unsigned long)mipmapGeneration];
	return description;
}

@end


@implementation TKDDSImageRep (TKImageExportPresetAdditions)

+ (NSData *)DDSRepresentationOfImageRepsInArray:(NSArray *)tkImageReps usingPreset:(TKImageExportPreset *)preset {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
//	return [[self class] DDSRepresentationOfImageRepsInArray:tkImageReps
//												 usingFormat:TKDDSFormatFromString([preset compressionFormat])
//													 quality:TKDXTCompressionQualityFromString([preset compressionQuality])
//													 options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:[preset mipmapGeneration]],TKImageMipmapGenerationKey, nil]];
	return nil;
}

@end


@implementation TKVTFImageRep (TKImageExportPresetAdditions)

+ (NSData *)VTFRepresentationOfImageRepsInArray:(NSArray *)tkImageReps usingPreset:(TKImageExportPreset *)preset {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
//	return [[self class] VTFRepresentationOfImageRepsInArray:tkImageReps
//												 usingFormat:TKVTFFormatFromString([preset compressionFormat])
//													 quality:TKDXTCompressionQualityFromString([preset compressionQuality])
//													 options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:[preset mipmapGeneration]],TKImageMipmapGenerationKey, nil]];
	return nil;
}

@end




