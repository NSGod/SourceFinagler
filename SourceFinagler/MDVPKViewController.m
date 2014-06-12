//
//  MDVPKViewController.m
//  Source Finagler
//
//  Created by Mark Douma on 12/13/2013.
//  Copyright (c) 2013 Mark Douma. All rights reserved.
//

#import "MDVPKViewController.h"
#import "MDVPKDocument.h"
#import <HLKit/HLKit.h>



#define MD_DEBUG 0


NSString * const MDVPKAlwaysOpenArchiveDirectoryFileKey = @"MDVPKAlwaysOpenArchiveDirectoryFile";



@implementation MDVPKViewController


@synthesize document;


+ (void)initialize {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	static BOOL initialized = NO;
	
	if (initialized == NO) {
		NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
		[defaults setObject:[NSNumber numberWithBool:NO] forKey:MDVPKAlwaysOpenArchiveDirectoryFileKey];
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
		[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaults];
		
		initialized = YES;
	}
	
}


- (id)init {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self initWithNibName:NSStringFromClass([self class]) bundle:nil];
}


- (void)awakeFromNib {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSParameterAssert(document != nil);
	
	HKVPKFile *vpkFile = (HKVPKFile *)document.file;
	
	NSString *archiveDirectoryFilePath = vpkFile.archiveDirectoryFilePath;
	
	if (archiveDirectoryFilePath) {
		
		[messageTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"The file \"%@\" is part of a multi-segment Source Valve Package file. Instead of opening this file, you need to open the \"%@\" Archive Directory file.", @""), vpkFile.filePath.lastPathComponent, archiveDirectoryFilePath.lastPathComponent]];
		
	} else {
		
		[messageTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"The file \"%@\" is part of a multi-segment Source Valve Package file. Instead of opening this file, you need to open the Archive Directory file.", @""), vpkFile.filePath.lastPathComponent]];
		
	}
	
}



- (IBAction)openDirectoryFile:(id)sender {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[document openDirectoryFile:sender];
}


@end



