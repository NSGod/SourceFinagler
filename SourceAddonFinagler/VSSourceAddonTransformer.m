//
//  VSSourceAddonTransformer.m
//  Source Finagler
//
//  Created by Mark Douma on 12/23/2013.
//  Copyright (c) 2013 Mark Douma. All rights reserved.
//

#import "VSSourceAddonTransformer.h"
#import <SteamKit/SteamKit.h>



#define VS_DEBUG 0



@implementation VSSourceAddonTransformer


+ (Class)transformedValueClass {
	return [NSString class];
}


+ (BOOL)allowsReverseTransformation {
	return NO;
}


- (id)transformedValue:(id)value {
	if (value == nil) return nil;
	
#if VS_DEBUG
	NSLog(@"[%@ %@] value == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), value);
#endif
	
	if (![value isKindOfClass:[VSSourceAddon class]]) {
		[NSException raise:NSInternalInconsistencyException
					format:@"value (%@) is not of the %@ class.", NSStringFromClass([value class]), NSStringFromClass([VSSourceAddon class])];
	}
	
	VSSourceAddon *sourceAddon = (VSSourceAddon *)value;
	VSSourceAddonStatus sourceAddonStatus = [(VSSourceAddon *)value sourceAddonStatus];
	
	switch (sourceAddonStatus) {
		case VSSourceAddonStatusUnknown :
			return NSLocalizedString(@"Unknown error", @"");
			break;
			
		case VSSourceAddonNotAnAddonFile :
			return NSLocalizedString(@"Not a valid Source Addon file", @"");
			break;
			
		case VSSourceAddonNoAddonInfoFound :
			return NSLocalizedString(@"No \"addoninfo.txt\" file could be found inside the Source Addon file", @"");
			break;
			
		case VSSourceAddonAddonInfoUnreadable :
			return NSLocalizedString(@"Couldn't read the \"addoninfo.txt\" file inside the Source Addon file", @"");
			break;
			
		case VSSourceAddonNoGameIDFoundInAddonInfo :
			return NSLocalizedString(@"Didn't find a valid game ID in the \"addoninfo.txt\" file inside the Source Addon file", @"");
			break;
			
		case VSSourceAddonGameNotFound :
			return [NSString stringWithFormat:NSLocalizedString(@"Could not locate installed game for Steam Game ID #%lu", @""), (unsigned long)sourceAddon.sourceAddonGameID];
			break;
			
		default:
			return NSLocalizedString(@"Unknown error", @"");
			break;
	}
	return nil;
}


@end


