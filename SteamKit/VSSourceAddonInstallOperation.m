//
//  VSSourceAddonInstallOperation.m
//  SteamKit
//
//  Created by Mark Douma on 5/20/2014.
//  Copyright (c) 2014 Mark Douma. All rights reserved.
//

#import "VSSourceAddonInstallOperation.h"
#import <SteamKit/VSSourceAddon.h>
#import "VSPrivateInterfaces.h"
#import <CoreServices/CoreServices.h>



#define VS_DEBUG 0



@implementation VSSourceAddonInstallOperation

@synthesize sourceAddon;
@synthesize installMethod;


- (id)init {
	return [self initWithSourceAddon:nil installMethod:VSSourceAddonInstallByCopying];
}


- (id)initWithSourceAddon:(VSSourceAddon *)aSourceAddon installMethod:(VSSourceAddonInstallMethod)anInstallMethod {
#if VS_DEBUG
	NSLog(@"[%@ %@]   %@  ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), aSourceAddon.fileName);
#endif
	NSParameterAssert(aSourceAddon != nil);
	if ((self = [super init])) {
		sourceAddon = [aSourceAddon retain];
		installMethod = anInstallMethod;
	}
	return self;
}


- (void)dealloc {
#if VS_DEBUG
	NSLog(@"[%@ %@]   %@  ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sourceAddon.fileName);
#endif
	[sourceAddon release];
	[super dealloc];
}


- (void)main {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
#if VS_DEBUG
	NSLog(@"[%@ %@]   %@  ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sourceAddon.fileName);
#endif
	
	[[VSSteamManager defaultManager] performSelectorOnMainThread:@selector(beginProcessingSourceAddonInstallOperationOnMainThread:) withObject:self waitUntilDone:NO];
	
	@try {
		
		if (sourceAddon.sourceAddonStatus == VSSourceAddonValidAddon) {
			
			/*
			 NSFileManager's -replaceItemAtURL:withItemAtURL:backupItemName:options:resultingItemURL:error: works
			 beautifully for this with minimal race conditions, in that if a source addon file already existed at the target path, it would replace
			 it, yet if it didn't exist, it would simply copy it without issuing an error. Unfortunately, it's OS X 10.6+ only.
			 
			 OS X 10.5 has FSPathReplaceObject(), but since it appears to use FSRefs internally, it only works with files or items that
			 actually exist (since FSRefs can't refer to objects that don't exist). This means I can only use FSPathReplaceObject() when
			 an existing source addon exists at the destination path. If the file exists, we can use FSPathReplaceObject(), otherwise we 
			 just move the file from the temp location to the destination path. Checking for the existence of that file kind of defeats
			 the purpose of trying to eliminate race conditions, but oh well.... 
			 */
			
			NSURL *originalSourceAddonURL = [[[sourceAddon URL] retain] autorelease];
			
			VSGame *game = sourceAddon.game;
			
			NSURL *sourceAddonsFolderURL = game.sourceAddonsFolderURL;
			
			NSString *targetSourceAddonPath = [sourceAddonsFolderURL.path stringByAppendingPathComponent:sourceAddon.URL.path.lastPathComponent];
			
			/* FSPathGetTemporaryDirectoryForReplaceObject() only works with items that actually exist, so instead
			 of passing in the targetSourceAddonPath (which may not exist), we pass in the path to the source addons folder itself. */
			
			char tempDirPathC[PATH_MAX + 1];
			
			OSStatus status = FSPathGetTemporaryDirectoryForReplaceObject([sourceAddonsFolderURL.path fileSystemRepresentation], tempDirPathC, sizeof(tempDirPathC), 0);
			
			if (status) {
				NSLog(@"[%@ %@]   %@   FSPathGetTemporaryDirectoryForReplaceObject() returned == %ld", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sourceAddon.fileName, (long)status);
				
				[[VSSteamManager defaultManager] performSelectorOnMainThread:@selector(finishProcessingSourceAddonInstallOperationOnMainThread:) withObject:self waitUntilDone:NO];
				
				[pool release];
			}
			
			NSString *tempDirPath = [NSString stringWithUTF8String:tempDirPathC];
			
#if VS_DEBUG
			NSLog(@"[%@ %@]   %@   tempDirPath == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sourceAddon.fileName, tempDirPath);
#endif
			
			NSString *uniqueTempDirPattern = [tempDirPath stringByAppendingPathComponent:@".com.markdouma.SourceAddonInstallation.XXXXXXXXXX"];
			
			char *uniqueTempDirC = mkdtemp((char *)[uniqueTempDirPattern fileSystemRepresentation]);
			
			if (uniqueTempDirC == NULL) {
				NSLog(@"[%@ %@]   %@   mkdtemp() returned NULL; errno == %ld, error == %s", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sourceAddon.fileName, (long)errno, strerror(errno));
				[[VSSteamManager defaultManager] performSelectorOnMainThread:@selector(finishProcessingSourceAddonInstallOperationOnMainThread:) withObject:self waitUntilDone:NO];
				[pool release];
			}
			
			NSString *uniqueTempDirPath = [NSString stringWithUTF8String:uniqueTempDirC];
			
			NSString *tempSourceAddonPath = [uniqueTempDirPath stringByAppendingPathComponent:sourceAddon.URL.path.lastPathComponent];
			
			NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
			NSError *error = nil;
			
			if (![fileManager copyItemAtPath:sourceAddon.URL.path toPath:tempSourceAddonPath error:&error]) {
				NSLog(@"[%@ %@]   %@   ERROR: failed to copyItemAtPath:toPath:error:; error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sourceAddon.fileName, error);
				goto cleanup;
			}
			
			if ([fileManager fileExistsAtPath:targetSourceAddonPath]) {
				// replace it
				
				status = FSPathReplaceObject([targetSourceAddonPath fileSystemRepresentation], [tempSourceAddonPath fileSystemRepresentation], NULL, NULL, tempDirPathC, kFSReplaceObjectDefaultOptions);
				
				if (status) {
					NSLog(@"[%@ %@]   %@   FSPathReplaceObject() returned == %ld", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sourceAddon.fileName, (long)status);
					goto cleanup;
				}
				
			} else {
				// move it
				
				if (![fileManager moveItemAtPath:tempSourceAddonPath toPath:targetSourceAddonPath error:&error]) {
					NSLog(@"[%@ %@]   %@   ERROR: failed to move '%@' to '%@'; error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sourceAddon.fileName, tempSourceAddonPath, targetSourceAddonPath, error);
					goto cleanup;
				}
			}
			
			sourceAddon.URL = [NSURL fileURLWithPath:targetSourceAddonPath];
			sourceAddon.installed = YES;
			
			if (installMethod == VSSourceAddonInstallByMoving) {
				if (![fileManager removeItemAtPath:originalSourceAddonURL.path error:&error]) {
					NSLog(@"[%@ %@]   %@   ERROR: failed to removeItemAtURL:error:; error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sourceAddon.fileName, error);
				}
			}
			
		cleanup:
			
			if (![fileManager removeItemAtPath:uniqueTempDirPath error:&error]) {
				NSLog(@"[%@ %@]   %@   ERROR: failed to remove directory at '%@'; error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sourceAddon.fileName, uniqueTempDirPath, error);
			}
		}
		
	} @catch(...) {
		// Do not rethrow exceptions.
	}
	
	[[VSSteamManager defaultManager] performSelectorOnMainThread:@selector(finishProcessingSourceAddonInstallOperationOnMainThread:) withObject:self waitUntilDone:NO];
	
	[pool release];
}


@end

