//
//  TKImageExportPreset.m
//  Texture Kit
//
//  Created by Mark Douma on 12/11/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import "TKImageExportPreset.h"

NSString * const TKImageExportNameKey						= @"TKImageExportName";
NSString * const TKImageExportFileTypeKey					= @"TKImageExportFileType";
NSString * const TKImageExportFormatKey						= @"TKImageExportFormat";
NSString * const TKImageExportDXTCompressionQualityKey		= @"TKImageExportDXTCompressionQuality";
NSString * const TKImageExportMipmapsKey					= @"TKImageExportMipmaps";


#define TK_DEBUG 1


extern NSString * const TKImageExportPresetsKey;


static TKImageExportPreset *originalImagePreset = nil;

//static NSMutableArray *savedPresets = nil;


//@interface TKImageExportPreset (TKPrivate)
//
//- (void)updateName;
//
//@end


@implementation TKImageExportPreset

@synthesize name, fileType, format, compressionQuality, mipmaps;

//@synthesize name;
//
//@dynamic fileType, format, compressionQuality, mipmaps;


//+ (void)initialize {
//	if (savedPresets == nil) {
//		savedPresets = [[NSMutableArray alloc] init];
//		[savedPresets setArray:[TKImageExportPreset imageExportPresetsWithDictionaryRepresentations:[[NSUserDefaults standardUserDefaults] objectForKey:TKImageExportPresetsKey]]];
//	}
//}


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


+ (id)originalImagePreset {
	@synchronized(self) {
		if (originalImagePreset == nil) {
#if TK_DEBUG
			NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
			originalImagePreset = [[[self class] alloc] initWithName:NSLocalizedString(@"Original", @"") fileType:nil format:nil compressionQuality:nil mipmaps:NO];
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

+ (id)imageExportPresetWithName:(NSString *)aName fileType:(NSString *)aFileType format:(NSString *)aFormat compressionQuality:(NSString *)aQuality mipmaps:(BOOL)aMipmaps {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[[[self class] alloc] initWithName:aName fileType:aFileType format:aFormat compressionQuality:aQuality mipmaps:aMipmaps] autorelease];
}


- (id)initWithName:(NSString *)aName fileType:(NSString *)aFileType format:(NSString *)aFormat compressionQuality:(NSString *)aQuality mipmaps:(BOOL)aMipmaps {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super init])) {
		[self setName:aName];
		fileType = [aFileType retain];
		format = [aFormat retain];
		compressionQuality = [aQuality retain];
		mipmaps = aMipmaps;
	}
	return self;
}


- (id)initWithDictionary:(NSDictionary *)aDictionary {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super init])) {
		[self setName:[aDictionary objectForKey:TKImageExportNameKey]];
		fileType = [[aDictionary objectForKey:TKImageExportFileTypeKey] retain];
		format = [[aDictionary objectForKey:TKImageExportFormatKey] retain];
		compressionQuality = [[aDictionary objectForKey:TKImageExportDXTCompressionQualityKey] retain];
		mipmaps = [[aDictionary objectForKey:TKImageExportMipmapsKey] boolValue];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super init])) {
		[self setName:[coder decodeObjectForKey:TKImageExportNameKey]];
		
		fileType = [[coder decodeObjectForKey:TKImageExportFileTypeKey] retain];
		format = [[coder decodeObjectForKey:TKImageExportFormatKey] retain];
		compressionQuality = [[coder decodeObjectForKey:TKImageExportDXTCompressionQualityKey] retain];
		mipmaps = [[coder decodeObjectForKey:TKImageExportMipmapsKey] boolValue];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[coder encodeObject:name forKey:TKImageExportNameKey];
	[coder encodeObject:fileType forKey:TKImageExportFileTypeKey];
	[coder encodeObject:format forKey:TKImageExportFormatKey];
	[coder encodeObject:compressionQuality forKey:TKImageExportDXTCompressionQualityKey];
	[coder encodeObject:[NSNumber numberWithBool:mipmaps] forKey:TKImageExportMipmapsKey];
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
																   format:format
													   compressionQuality:compressionQuality
																  mipmaps:mipmaps];
	
	return copy;
}


- (void)dealloc {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[name release];
	[fileType release];
	[format release];
	[compressionQuality release];
	[super dealloc];
}


- (void)setNilValueForKey:(NSString *)key {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([key isEqualToString:@"mipmaps"]) {
		mipmaps = NO;
	} else {
		[super setNilValueForKey:key];
	}
}


//- (void)updateName {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	@synchronized(savedPresets) {
//		[savedPresets setArray:[TKImageExportPreset imageExportPresetsWithDictionaryRepresentations:[[NSUserDefaults standardUserDefaults] objectForKey:TKImageExportPresetsKey]]];
//		
//		for (TKImageExportPreset *preset in savedPresets) {
//			if ([preset matchesPreset:self]) {
//				[self setName:[preset name]];
//				return;
//			}
//		}
//	}
//	
//	[self setName:@"[Custom]"];
//	
//}



//- (NSString *)fileType {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//    return fileType;
//}
//
//- (void)setFileType:(NSString *)value {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	[value retain];
//	[fileType release];
//	fileType = value;
//	[self updateName];
//}
//
//- (NSString *)format {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//    return format;
//}
//
//- (void)setFormat:(NSString *)value {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	[value retain];
//	[format release];
//	format = value;
//	[self updateName];
//}
//
//- (NSString *)compressionQuality {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//    return compressionQuality;
//}
//
//- (void)setCompressionQuality:(NSString *)value {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	[value retain];
//	[compressionQuality release];
//	compressionQuality = value;
//	[self updateName];
//}
//
//- (BOOL)mipmaps {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//    return mipmaps;
//}
//
//- (void)setMipmaps:(BOOL)value {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	mipmaps = value;
//	[self updateName];
//}


- (NSDictionary *)dictionaryRepresentation {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSDictionary *dictionaryRepresentation = [NSDictionary dictionaryWithObjectsAndKeys:name,TKImageExportNameKey,
											  fileType,TKImageExportFileTypeKey,
											  format,TKImageExportFormatKey,
											  compressionQuality,TKImageExportDXTCompressionQualityKey,
											  [NSNumber numberWithBool:mipmaps],TKImageExportMipmapsKey, nil];
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
				[[preset format] isEqualToString:format] &&
				[[preset compressionQuality] isEqualToString:compressionQuality] &&
				[preset mipmaps] == mipmaps);
	}
	return NO;
}


// matchesPreset: is all but name is equal
- (BOOL)matchesPreset:(TKImageExportPreset *)preset {
	if ([preset isKindOfClass:[self class]]) {
		return ([[preset fileType] isEqualToString:fileType] &&
				[[preset format] isEqualToString:format] &&
				[[preset compressionQuality] isEqualToString:compressionQuality] &&
				[preset mipmaps] == mipmaps);
	}
	return NO;
}




- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithString:[super description]];
	[description appendFormat:@" %@, ", name];
	[description appendFormat:@"%@, ", fileType];
	[description appendFormat:@"%@, ", format];
	[description appendFormat:@"%@, ", compressionQuality];
	[description appendFormat:@"mipmaps == %@", (mipmaps ? @"YES" : @"NO")];
	return description;
}

@end


@implementation TKDDSImageRep (TKImageExportPresetAdditions)

+ (NSData *)DDSRepresentationOfImageRepsInArray:(NSArray *)tkImageReps usingPreset:(TKImageExportPreset *)preset {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[self class] DDSRepresentationOfImageRepsInArray:tkImageReps
												 usingFormat:TKDDSFormatFromString([preset format])
													 quality:TKDXTCompressionQualityFromString([preset compressionQuality])
											   createMipmaps:[preset mipmaps]];
}

@end


@implementation TKVTFImageRep (TKImageExportPresetAdditions)

+ (NSData *)VTFRepresentationOfImageRepsInArray:(NSArray *)tkImageReps usingPreset:(TKImageExportPreset *)preset {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	return [[self class] VTFRepresentationOfImageRepsInArray:tkImageReps
												 usingFormat:TKVTFFormatFromString([preset format])
													 quality:TKDXTCompressionQualityFromString([preset compressionQuality])
											   createMipmaps:[preset mipmaps]];
}

@end




