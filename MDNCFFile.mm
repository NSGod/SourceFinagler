//
//  MDNCFFile.mm
//  Source Finagler
//
//  Created by Mark Douma on 10/27/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDNCFFile.h"
#import "MDFile.h"
#import "MDFolder.h"
#import "MDHLPrivateInterfaces.h"
#import <HL/HL.h>


using namespace HLLib;


@implementation MDNCFFile


- (id)initWithContentsOfFile:(NSString *)aPath mode:(HLFileMode)permission showInvisibleItems:(BOOL)showInvisibleItems sortDescriptors:(NSArray *)sortDescriptors error:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithContentsOfFile:aPath mode:permission showInvisibleItems:showInvisibleItems sortDescriptors:sortDescriptors error:outError])) {
		fileType = MDHLFileNCFType;
		
		_privateData = new CNCFFile();
		
		if (_privateData) {
			if (static_cast<CNCFFile *>(_privateData)->Open((const hlChar *)[filePath fileSystemRepresentation], permission)) {
				const CDirectoryFolder *rootFolder = static_cast<CNCFFile *>(_privateData)->GetRoot();
				if (rootFolder) {
					items = [[MDFolder alloc] initWithParent:nil directoryFolder:rootFolder showInvisibleItems:showInvisibleItems sortDescriptors:sortDescriptors container:self];
					
				}
			}
		}
	}
	return self;
}


- (void)dealloc {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (_privateData) {
		static_cast<CNCFFile *>(_privateData)->Close();
		delete static_cast<CNCFFile *>(_privateData);
	}
	[super dealloc];
}


- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithString:@""];
	[description appendFormat:@"\tfilePath == %@\n", filePath];
	return [NSString stringWithFormat:@"%@", description];
}


@end



