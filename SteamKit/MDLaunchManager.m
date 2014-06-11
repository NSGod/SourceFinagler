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
	MDUndeterminedVersion	= 0,
	MDCheetah				= 0x1000,
	MDPuma					= 0x1010,
	MDJaguar				= 0x1020,
	MDPanther				= 0x1030,
	MDTiger					= 0x1040,
	MDLeopard				= 0x1050,
	MDSnowLeopard			= 0x1060,
	MDLion					= 0x1070,
	MDMountainLion			= 0x1080,
	MDMavericks				= 0x1090,
	MDUnknownVersion		= 0x1100
};

static SInt32 MDSystemVersion = MDUndeterminedVersion;


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
		SInt32 MDFullSystemVersion = 0;
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
	if (pid <= 0 || domain != MDLaunchUserDomain) return nil;
	
	if (useServiceManagement) {
		NSArray *jobs = [(NSArray *)SMCopyAllJobDictionaries((domain == MDLaunchUserDomain ? kSMDomainUserLaunchd : kSMDomainSystemLaunchd)) autorelease];
		if (jobs == nil) return nil;
		
		for (NSDictionary *aJob in jobs) {
			if ([[aJob objectForKey:NSStringFromLaunchJobKey(LAUNCH_JOBKEY_PID)] intValue] == pid) return aJob;
		}
		return nil;
		
	} else {
		
		NSTask *task = [[[NSTask alloc] init] autorelease];
		[task setLaunchPath:@"/bin/launchctl"];
		[task setArguments:[NSArray arrayWithObject:@"list"]];
		[task setStandardOutput:[NSPipe pipe]];
		[task setStandardError:[NSPipe pipe]];
		[task launch];
		[task waitUntilExit];
		
		NSData *standardOutputData = [[[task standardOutput] fileHandleForReading] availableData];
		if (standardOutputData && standardOutputData.length) {
			NSString *standardOutputString = [[[NSString alloc] initWithData:standardOutputData encoding:NSUTF8StringEncoding] autorelease];
			
			NSString *pidString = [NSString stringWithFormat:@"%d", pid];
			
			NSArray *lines = [standardOutputString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
			
			for (NSString *line in lines) {
				if ([line hasPrefix:pidString]) {
					NSArray *items = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
					if (items.count == 3) return [self jobWithLabel:[items lastObject] inDomain:domain];
				}
			}
		}
		
		NSData *standardErrorData = [[[task standardError] fileHandleForReading] availableData];
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
	return nil;
}

- (NSDictionary *)jobWithLabel:(NSString *)label inDomain:(MDLaunchDomain)domain {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSParameterAssert(label != nil);
	
	if (domain != MDLaunchUserDomain) return nil;
	
	if (useServiceManagement) {
		return [(NSDictionary *)SMJobCopyDictionary((domain == MDLaunchUserDomain ? kSMDomainUserLaunchd : kSMDomainSystemLaunchd), (CFStringRef)label) autorelease];
	} else {
		
		NSTask *task = [[[NSTask alloc] init] autorelease];
		[task setLaunchPath:@"/bin/launchctl"];
		[task setArguments:[NSArray arrayWithObjects:@"list", label, nil]];
		[task setStandardOutput:[NSPipe pipe]];
		[task setStandardError:[NSPipe pipe]];
		[task launch];
		[task waitUntilExit];
		
		NSData *standardOutputData = [[[task standardOutput] fileHandleForReading] availableData];
		if (standardOutputData && standardOutputData.length) {
			NSString *standardOutputString = [[[NSString alloc] initWithData:standardOutputData encoding:NSUTF8StringEncoding] autorelease];
#if MD_DEBUG
			NSLog(@"[%@ %@] standardOutputString == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), standardOutputString);
#endif
			if ([standardOutputString rangeOfString:label].location != NSNotFound) {
				return [NSDictionary dictionaryWithObjectsAndKeys:label, NSStringFromLaunchJobKey(LAUNCH_JOBKEY_LABEL), nil];
			}
			return nil;
		}
	}
	return nil;
}
		

- (NSArray *)jobsWithLabels:(NSArray *)labels inDomain:(MDLaunchDomain)domain {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSParameterAssert(labels != nil);
	
	if (domain != MDLaunchUserDomain) return nil;
	
	NSMutableArray *jobs = [NSMutableArray array];
	
	for (NSString *label in labels) {
		NSDictionary *job = [self jobWithLabel:label inDomain:domain];
		if (job) [jobs addObject:job];
	}
	return [[jobs copy] autorelease];
}



- (BOOL)submitJobWithDictionary:(NSDictionary *)launchAgentPlist inDomain:(MDLaunchDomain)domain error:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSParameterAssert(launchAgentPlist != nil);
	
	// in case we haven't fully implemented NSError reporting at all levels yet:
	if (outError) *outError = nil;
	
	if (domain != MDLaunchUserDomain) return NO;
	
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
	NSParameterAssert(label != nil);
	
	// in case we haven't fully implemented NSError reporting at all levels yet:
	if (outError) *outError = nil;
	
	if (domain != MDLaunchUserDomain) return NO;
	
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
	NSParameterAssert(oldJob != nil && newJob != nil);
	
	// in case we haven't fully implemented NSError reporting at all levels yet:
	if (outError) *outError = nil;
	
	if (domain != MDLaunchUserDomain) return NO;
	
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
	NSParameterAssert(path != nil);
	
	// in case we haven't fully implemented NSError reporting at all levels yet:
	if (outError) *outError = nil;
	
	if (domain != MDLaunchUserDomain) return NO;
	
	@synchronized(self) {
		
		if (useServiceManagement) {
			NSDictionary *job = [NSDictionary dictionaryWithContentsOfFile:path];
			if (job) return (BOOL)SMJobSubmit(kSMDomainUserLaunchd, (CFDictionaryRef)job, NULL, (CFErrorRef *)outError);
			return NO;
			
		} else {
			
			NSTask *task = [[[NSTask alloc] init] autorelease];
			[task setLaunchPath:@"/bin/launchctl"];
			[task setArguments:[NSArray arrayWithObjects:@"load", @"-w", path, nil]];
			[task setStandardOutput:[NSPipe pipe]];
			[task setStandardError:[NSPipe pipe]];
			[task launch];
			[task waitUntilExit];
			
			NSData *standardOutputData = [[[task standardOutput] fileHandleForReading] availableData];
			if (standardOutputData && [standardOutputData length]) {
				NSString *standardOutputString = [[[NSString alloc] initWithData:standardOutputData encoding:NSUTF8StringEncoding] autorelease];
				NSLog(@"[%@ %@] standardOutputString == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), standardOutputString);
			}
			NSData *standardErrorData = [[[task standardError] fileHandleForReading] availableData];
			if (standardErrorData && [standardErrorData length]) {
				NSString *standardErrorString = [[[NSString alloc] initWithData:standardErrorData encoding:NSUTF8StringEncoding] autorelease];
				NSLog(@"[%@ %@] standardErrorString == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), standardErrorString);
			}
			
			if (![task isRunning]) {
				if ([task terminationStatus] != 0) {
					NSLog(@"[%@ %@] \"/bin/launchctl load -w %@\" returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), path, [task terminationStatus]);
					if (outError) *outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:[task terminationStatus] userInfo:nil];
					return NO;
				} else {
					return YES;
				}
			}
		}
	}
	return NO;
}



- (BOOL)unloadJobWithLabel:(NSString *)label inDomain:(MDLaunchDomain)domain error:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSParameterAssert(label != nil);
	
	// in case we haven't fully implemented NSError reporting at all levels yet:
	if (outError) *outError = nil;
	
	if (domain != MDLaunchUserDomain) return NO;
	
	@synchronized(self) {
		
		if (agentIsUnloadingSelf && agentLaunchDate) {
#if MD_DEBUG
			NSTimeInterval totalElapsedTime = fabs([agentLaunchDate timeIntervalSinceNow]);
#endif
			[agentLaunchDate release];
			agentLaunchDate = nil;
			
#if MD_DEBUG
			NSLog(@"[%@ %@] ***** TOTAL ELAPSED TIME == %.7f sec (%.4f ms) *****", NSStringFromClass([self class]), NSStringFromSelector(_cmd), totalElapsedTime, totalElapsedTime * 1000.0);
#endif
		}
		
		if (useServiceManagement) {
			return (BOOL)SMJobRemove(kSMDomainUserLaunchd, (CFStringRef)label, NULL, NO, (CFErrorRef *)outError);
			
		} else {
			
			NSTask *task = [[[NSTask alloc] init] autorelease];
			[task setLaunchPath:@"/bin/launchctl"];
			[task setArguments:[NSArray arrayWithObjects:@"remove", label, nil]];
			[task setStandardOutput:[NSPipe pipe]];
			[task setStandardError:[NSPipe pipe]];
			[task launch];
			[task waitUntilExit];
			
			NSData *standardOutputData = [[[task standardOutput] fileHandleForReading] availableData];
			if (standardOutputData && [standardOutputData length]) {
				NSString *standardOutputString = [[[NSString alloc] initWithData:standardOutputData encoding:NSUTF8StringEncoding] autorelease];
				NSLog(@"[%@ %@] standardOutputString == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), standardOutputString);
			}
			NSData *standardErrorData = [[[task standardError] fileHandleForReading] availableData];
			if (standardErrorData && [standardErrorData length]) {
				NSString *standardErrorString = [[[NSString alloc] initWithData:standardErrorData encoding:NSUTF8StringEncoding] autorelease];
				NSLog(@"[%@ %@] standardErrorString == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), standardErrorString);
			}
			
			if (![task isRunning]) {
				if ([task terminationStatus] != 0) {
					NSLog(@"[%@ %@] \"/bin/launchctl remove %@\" returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), label, [task terminationStatus]);
					if (outError) *outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:[task terminationStatus] userInfo:nil];
					return NO;
				} else {
					return YES;
				}
			}
		}
	}
	return NO;
}

@end

