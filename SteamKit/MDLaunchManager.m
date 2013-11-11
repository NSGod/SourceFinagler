//
//  MDLaunchManager.m
//  Steam Example
//
//  Created by Mark Douma on 7/16/2010.
//  Copyright (c) 2010 Mark Douma LLC. All rights reserved.
//

#import "MDLaunchManager.h"
#import "MDFolderManager.h"
#import <ServiceManagement/ServiceManagement.h>


#define MD_DEBUG 0

@interface MDLaunchManager (MDPrivate)
- (BOOL)loadJobWithPath:(NSString *)path inDomain:(MDLaunchDomain)domain error:(NSError **)outError;
- (BOOL)unloadJobWithLabel:(NSString *)label inDomain:(MDLaunchDomain)domain error:(NSError **)outError;
@end

enum {
	MDUndeterminedVersion	= -1,
	MDCheetah				= 0x1000,
	MDPuma					= 0x1010,
	MDJaguar				= 0x1020,
	MDPanther				= 0x1030,
	MDTiger					= 0x1040,
	MDLeopard				= 0x1050,
	MDSnowLeopard			= 0x1060,
	MDLion					= 0x1070,
	MDMountainLion			= 0x1080,
	MDUnknownKitty			= 0x1090,
	MDUnknownVersion		= 0x1100
};

static SInt32 MDSystemVersion = MDUnknownVersion;
static SInt32 MDFullSystemVersion = 0;

static BOOL useServiceManagement = NO;

static BOOL agentIsUnloadingSelf = NO;



// Creating a Singleton Instance
//
// http://developer.apple.com/mac/library/documentation/Cocoa/Conceptual/CocoaFundamentals/CocoaObjects/CocoaObjects.html#//apple_ref/doc/uid/TP40002974-CH4-SW32
//

static MDLaunchManager *sharedManager = nil;

@implementation MDLaunchManager

@synthesize agentLaunchDate;

+ (MDLaunchManager *)defaultManager {
	if (sharedManager == nil) {
		sharedManager = [[super allocWithZone:NULL] init];
	}
	return sharedManager;
}

+ (id)allocWithZone:(NSZone *)zone {
	return [[self defaultManager] retain];
}

- (id)copyWithZone:(NSZone *)zone {
	return self;
}

- (id)init {
	if ((self = [super init])) {
		Gestalt(gestaltSystemVersion, &MDFullSystemVersion);
		MDSystemVersion = MDFullSystemVersion & 0xfffffff0;
		
		useServiceManagement = (MDSystemVersion >= MDSnowLeopard);
	}
	return self;
}

- (id)retain {
	return self;
}

- (NSUInteger)retainCount {
	return NSUIntegerMax; //denotes an object that cannot be released
}

- (oneway void)release {
	// do nothing
}

- (id)autorelease {
	return self;
}


- (NSDictionary *)jobWithProcessIdentifier:(pid_t)pid inDomain:(MDLaunchDomain)domain {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSDictionary *job = nil;
	if (pid > 0 && domain == MDLaunchUserDomain) {
		
		if (useServiceManagement) {
			NSArray *jobs = [(NSArray *)SMCopyAllJobDictionaries((domain == MDLaunchUserDomain ? kSMDomainUserLaunchd : kSMDomainSystemLaunchd)) autorelease];
			if (jobs) {
				for (NSDictionary *aJob in jobs) {
					if ([[aJob objectForKey:NSStringFromLaunchJobKey(LAUNCH_JOBKEY_PID)] intValue] == pid) {
						job = aJob;
						break;
					}
				}
			}
		} else {
			NSData *standardOutputData = nil;
			NSData *standardErrorData = nil;
			
			NSTask *task = [[[NSTask alloc] init] autorelease];
			[task setLaunchPath:@"/bin/launchctl"];
			[task setArguments:[NSArray arrayWithObject:@"list"]];
			[task setStandardOutput:[NSPipe pipe]];
			[task setStandardError:[NSPipe pipe]];
			[task launch];
			[task waitUntilExit];
			
			standardOutputData = [[[task standardOutput] fileHandleForReading] availableData];
			if (standardOutputData && [standardOutputData length]) {
				NSString *standardOutputString = [[[NSString alloc] initWithData:standardOutputData encoding:NSUTF8StringEncoding] autorelease];
//				NSLog(@"[%@ %@] standardOutputString == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), standardOutputString);
				
				NSString *pidString = [NSString stringWithFormat:@"%d", pid];
				
				NSString *targetLine = nil;
				NSArray *lines = [standardOutputString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
				if (lines && [lines count]) {
					for (NSString *line in lines) {
						if ([line hasPrefix:pidString]) {
							targetLine = line;
							break;
						}
					}
					if (targetLine) {
#if MD_DEBUG
						NSLog(@"[%@ %@] targetLine == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), targetLine);
#endif
						NSArray *items = [targetLine componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
						if (items && [items count] == 3) {
							NSString *label = [items lastObject];
							if (label) {
								job = [self jobWithLabel:label inDomain:domain];
							}
						}
					}
				}
			}
			
			standardErrorData = [[[task standardError] fileHandleForReading] availableData];
			if (standardErrorData && [standardErrorData length]) {
				NSString *standardErrorString = [[[NSString alloc] initWithData:standardErrorData encoding:NSUTF8StringEncoding] autorelease];
				NSLog(@"[%@ %@] standardErrorString ==  %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), standardErrorString);
			}
			
			if (![task isRunning]) {
				if ([task terminationStatus] != 0) {
					NSLog(@"[%@ %@] \"/bin/launchctl list\" returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [task terminationStatus]);
				}
			}
		}
	}
	return job;
}

- (NSDictionary *)jobWithLabel:(NSString *)label inDomain:(MDLaunchDomain)domain {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSDictionary *job = nil;
	
	if (label && domain == MDLaunchUserDomain) {
			if (useServiceManagement) {
				job = [(NSDictionary *)SMJobCopyDictionary((domain == MDLaunchUserDomain ? kSMDomainUserLaunchd : kSMDomainSystemLaunchd), (CFStringRef)label) autorelease];
			} else {
				NSData *standardOutputData = nil;
				NSData *standardErrorData = nil;
				
				NSTask *task = [[[NSTask alloc] init] autorelease];
				[task setLaunchPath:@"/bin/launchctl"];
				[task setArguments:[NSArray arrayWithObjects:@"list", label, nil]];
				[task setStandardOutput:[NSPipe pipe]];
				[task setStandardError:[NSPipe pipe]];
				[task launch];
				[task waitUntilExit];
				
				standardOutputData = [[[task standardOutput] fileHandleForReading] availableData];
				if (standardOutputData && [standardOutputData length]) {
					NSString *standardOutputString = [[[NSString alloc] initWithData:standardOutputData encoding:NSUTF8StringEncoding] autorelease];
					NSLog(@"[%@ %@] standardOutputString == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), standardOutputString);
					
					if (!NSEqualRanges([standardOutputString rangeOfString:label], NSMakeRange(NSNotFound, 0))) {
						job = [NSDictionary dictionaryWithObjectsAndKeys:label, NSStringFromLaunchJobKey(LAUNCH_JOBKEY_LABEL), nil];
					}
				}
				standardErrorData = [[[task standardError] fileHandleForReading] availableData];
				if (standardErrorData && [standardErrorData length]) {
					NSString *standardErrorString = [[[NSString alloc] initWithData:standardErrorData encoding:NSUTF8StringEncoding] autorelease];
					NSLog(@"[%@ %@] standardErrorString ==  %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), standardErrorString);
				}
				
				if (![task isRunning]) {
					if ([task terminationStatus] != 0) {
						NSLog(@"[%@ %@] \"/bin/launchctl list %@\" returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), label, [task terminationStatus]);
					}
				}
			}
	}
	return job;
}
		

- (NSArray *)jobsWithLabels:(NSArray *)labels inDomain:(MDLaunchDomain)domain {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSMutableArray *jobs = [NSMutableArray array];
	
	if (labels && [labels count] && domain == MDLaunchUserDomain) {
		for (NSString *label in labels) {
			NSDictionary *job = [self jobWithLabel:label inDomain:domain];
			if (job) [jobs addObject:job];
	}
}
	return [[jobs copy] autorelease];
}



- (BOOL)submitJobWithDictionary:(NSDictionary *)launchAgentPlist inDomain:(MDLaunchDomain)domain error:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (launchAgentPlist == nil || domain != MDLaunchUserDomain) return NO;
	if (outError) *outError = nil;
	
	@synchronized(self) {
		
		MDFolderManager *folderManager = [MDFolderManager defaultManager];
		NSString *launchAgentDirectoryPath = [folderManager pathForDirectoryWithName:@"LaunchAgents" inDirectory:MDLibraryDirectory inDomain:MDUserDomain error:outError];
		if (launchAgentDirectoryPath == nil) return NO;
		
		NSString *label = [launchAgentPlist objectForKey:NSStringFromLaunchJobKey(LAUNCH_JOBKEY_LABEL)];
		NSString *jobPath = [launchAgentDirectoryPath stringByAppendingPathComponent:[label stringByAppendingPathExtension:@"plist"]];
		
		if (![launchAgentPlist writeToFile:jobPath atomically:NO]) return NO;
		
		return [self loadJobWithPath:jobPath inDomain:MDLaunchUserDomain error:outError];
	}
	return NO;
}


- (BOOL)removeJobWithLabel:(NSString *)label inDomain:(MDLaunchDomain)domain error:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (label == nil || domain != MDLaunchUserDomain) return NO;
	
	if (outError) *outError = nil;
	
	@synchronized(self) {
		
		MDFolderManager *folderManager = [MDFolderManager defaultManager];
		NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
		
		NSString *launchAgentDirectoryPath = [folderManager pathForDirectoryWithName:@"LaunchAgents" inDirectory:MDLibraryDirectory inDomain:MDUserDomain error:outError];
		if (launchAgentDirectoryPath == nil) return NO;
		
		NSString *jobPath = [launchAgentDirectoryPath stringByAppendingPathComponent:[label stringByAppendingPathExtension:@"plist"]];
		if ([fileManager fileExistsAtPath:jobPath]) [fileManager removeItemAtPath:jobPath error:outError];
		return [self unloadJobWithLabel:label inDomain:domain error:outError];
	}
	return NO;
}


- (BOOL)replaceJob:(NSDictionary *)oldJob withJob:(NSDictionary *)newJob loadNewJobBeforeUnloadingOld:(BOOL)loadNewJobBeforeUnloadingOld inDomain:(MDLaunchDomain)domain error:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (oldJob == nil || newJob == nil || domain != MDLaunchUserDomain) return NO;
	if (outError) *outError = nil;
	
	@synchronized(self) {
		
#if MD_DEBUG
		NSLog(@"[%@ %@] newJob == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), newJob);
#endif
		
		NSString *oldJobLabel = [oldJob objectForKey:NSStringFromLaunchJobKey(LAUNCH_JOBKEY_LABEL)];
		if (oldJobLabel == nil) {
			NSLog(@"[%@ %@] failed to get oldJobLabel", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return NO;
		}
		
		if (loadNewJobBeforeUnloadingOld) {
			agentIsUnloadingSelf = YES;
			if (![self submitJobWithDictionary:newJob inDomain:domain error:outError]) {
				return NO;
			}
			
			if (![self removeJobWithLabel:oldJobLabel inDomain:domain error:outError]) {
				return NO;
			}
			
		} else {
			if (![self removeJobWithLabel:oldJobLabel inDomain:domain error:outError]) {
				return NO;
			}
			if (![self submitJobWithDictionary:newJob inDomain:domain error:outError]) {
				return NO;
			}
		}
	}
	return YES;
}

@end


@implementation MDLaunchManager (MDPrivate)

- (BOOL)loadJobWithPath:(NSString *)path inDomain:(MDLaunchDomain)domain error:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	BOOL success = NO;
	if (outError) *outError = nil;
	if (path && domain == MDLaunchUserDomain) {
		
		@synchronized(self) {
			
			if (useServiceManagement) {
				NSDictionary *job = [NSDictionary dictionaryWithContentsOfFile:path];
				if (job) success = (BOOL)SMJobSubmit(kSMDomainUserLaunchd, (CFDictionaryRef)job, NULL, (CFErrorRef *)outError);
			} else {
				success = YES;
				
				NSData *standardOutputData = nil;
				NSData *standardErrorData = nil;
				
				NSTask *task = [[[NSTask alloc] init] autorelease];
				[task setLaunchPath:@"/bin/launchctl"];
				[task setArguments:[NSArray arrayWithObjects:@"load", @"-w", path, nil]];
				[task setStandardOutput:[NSPipe pipe]];
				[task setStandardError:[NSPipe pipe]];
				[task launch];
				[task waitUntilExit];
				
				standardOutputData = [[[task standardOutput] fileHandleForReading] availableData];
				if (standardOutputData && [standardOutputData length]) {
					NSString *standardOutputString = [[[NSString alloc] initWithData:standardOutputData encoding:NSUTF8StringEncoding] autorelease];
					NSLog(@"[%@ %@] standardOutputString == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), standardOutputString);
				}
				standardErrorData = [[[task standardError] fileHandleForReading] availableData];
				if (standardErrorData && [standardErrorData length]) {
					NSString *standardErrorString = [[[NSString alloc] initWithData:standardErrorData encoding:NSUTF8StringEncoding] autorelease];
					NSLog(@"[%@ %@] standardErrorString == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), standardErrorString);
				}
				
				if (![task isRunning]) {
					if ([task terminationStatus] != 0) {
						NSLog(@"[%@ %@] \"/bin/launchctl load -w %@\" returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), path, [task terminationStatus]);
						if (outError) *outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:[task terminationStatus] userInfo:nil];
						success = NO;
					}
				}
			}
		}
	}
	return success;
}



- (BOOL)unloadJobWithLabel:(NSString *)label inDomain:(MDLaunchDomain)domain error:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	BOOL success = NO;
	if (outError) *outError = nil;
	if (label && domain == MDLaunchUserDomain) {
		
		@synchronized(self) {
			
			if (useServiceManagement) {
				if (agentIsUnloadingSelf && agentLaunchDate) {
					NSTimeInterval totalElapsedTime = fabs([agentLaunchDate timeIntervalSinceNow]);
					[agentLaunchDate release];
					agentLaunchDate = nil;
					
#if MD_DEBUG
					NSLog(@"[%@ %@] ***** TOTAL ELAPSED TIME == %.7f sec (%.4f ms) *****", NSStringFromClass([self class]), NSStringFromSelector(_cmd), totalElapsedTime, totalElapsedTime * 1000.0);
#endif
				}
				
					success = (BOOL)SMJobRemove(kSMDomainUserLaunchd, (CFStringRef)label, NULL, NO, (CFErrorRef *)outError);
			} else {
				if (agentIsUnloadingSelf && agentLaunchDate) {
					NSTimeInterval totalElapsedTime = fabs([agentLaunchDate timeIntervalSinceNow]);
					[agentLaunchDate release];
					agentLaunchDate = nil;
					
#if MD_DEBUG
					NSLog(@"[%@ %@] ***** TOTAL ELAPSED TIME == %.7f sec (%.4f ms) *****", NSStringFromClass([self class]), NSStringFromSelector(_cmd), totalElapsedTime, totalElapsedTime * 1000.0);
#endif
				}
				success = YES;
				NSData *standardOutputData = nil;
				NSData *standardErrorData = nil;
				
				NSTask *task = [[[NSTask alloc] init] autorelease];
				[task setLaunchPath:@"/bin/launchctl"];
					[task setArguments:[NSArray arrayWithObjects:@"remove", label, nil]];
				[task setStandardOutput:[NSPipe pipe]];
				[task setStandardError:[NSPipe pipe]];
				[task launch];
				[task waitUntilExit];
				
				standardOutputData = [[[task standardOutput] fileHandleForReading] availableData];
				if (standardOutputData && [standardOutputData length]) {
					NSString *standardOutputString = [[[NSString alloc] initWithData:standardOutputData encoding:NSUTF8StringEncoding] autorelease];
					NSLog(@"[%@ %@] standardOutputString == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), standardOutputString);
				}
				standardErrorData = [[[task standardError] fileHandleForReading] availableData];
				if (standardErrorData && [standardErrorData length]) {
					NSString *standardErrorString = [[[NSString alloc] initWithData:standardErrorData encoding:NSUTF8StringEncoding] autorelease];
					NSLog(@"[%@ %@] standardErrorString == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), standardErrorString);
				}
				
				if (![task isRunning]) {
					if ([task terminationStatus] != 0) {
						NSLog(@"[%@ %@] \"/bin/launchctl remove %@\" returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), label, [task terminationStatus]);
						if (outError) *outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:[task terminationStatus] userInfo:nil];
						success = NO;
					}
				}
			}
		}
	}
	return success;
}

@end

