//
//  HKSGAFile.mm
//  HLKit
//
//  Created by Mark Douma on 10/27/2010.
//  Copyright (c) 2009-2012 Mark Douma LLC. All rights reserved.
//

#import <HLKit/HKSGAFile.h>
#import <HLKit/HKFile.h>
#import <HLKit/HKFolder.h>
#import "HKPrivateInterfaces.h"
#import <HL/HL.h>

#define HK_DEBUG 1

@implementation HKSGAFile



- (id)initWithContentsOfFile:(NSString *)aPath mode:(HLFileMode)permission showInvisibleItems:(BOOL)showInvisibleItems sortDescriptors:(NSArray *)sortDescriptors error:(NSError **)outError {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithContentsOfFile:aPath mode:permission showInvisibleItems:showInvisibleItems sortDescriptors:sortDescriptors error:outError])) {
		fileType = HKArchiveFileSGAType;
		
		_privateData = new CSGAFile();
		
		if (_privateData) {
			if (static_cast<CSGAFile *>(_privateData)->Open((const hlChar *)[filePath fileSystemRepresentation], permission)) {
				const CDirectoryFolder *rootFolder = static_cast<CSGAFile *>(_privateData)->GetRoot();
				if (rootFolder) {
					items = [[HKFolder alloc] initWithParent:nil directoryFolder:rootFolder showInvisibleItems:showInvisibleItems sortDescriptors:sortDescriptors container:self];
					
					HLAttribute majorVersion;
					HLAttribute minorVersion;
					
					
					if (static_cast<CSGAFile *>(_privateData)->GetAttribute(HL_SGA_PACKAGE_VERSION_MAJOR, majorVersion)) {
						
						if (static_cast<CSGAFile *>(_privateData)->GetAttribute(HL_SGA_PACKAGE_VERSION_MAJOR, minorVersion)) {
							
							version = [[NSString stringWithFormat:@"%lu.%lu",
										(unsigned long)majorVersion.Value.UnsignedInteger.uiValue, 
										(unsigned long)minorVersion.Value.UnsignedInteger.uiValue] retain];
						}
					}
					
				}
			}
		}
	}
	return self;
}


- (void)dealloc {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (_privateData) {
		static_cast<CSGAFile *>(_privateData)->Close();
		delete static_cast<CSGAFile *>(_privateData);
	}
	[super dealloc];
}


- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithString:@""];
	[description appendFormat:@"\tfilePath == %@\n", filePath];
	[description appendFormat:@"\tversion == %@\n", version];
	return [NSString stringWithFormat:@"%@", description];
}



@end










