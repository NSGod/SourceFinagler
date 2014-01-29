//
//  MDAboutWindowController.m
//  Source Finagler
//
//  Created by Mark Douma on 6/28/2005.
//  Copyright © 2005 Mark Douma. All rights reserved.
//


#import "MDAboutWindowController.h"
#import "MDAppKitAdditions.h"


#define MD_DEBUG 0


@implementation MDAboutWindowController

- (id)init {
	if ((self = [super initWithWindowNibName:@"MDAboutWindow"])) {
		
	} else {
		[NSBundle runFailedNibLoadAlert:@"MDAboutWindow"];
	}
	return self;
}


- (void)awakeFromNib {
	[nameField setStringValue:[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey]];
	[versionField setStringValue:[NSString stringWithFormat:@"%@ %@ (%@)",
								  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"],
								  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
								  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]]];
	
	[copyrightField setStringValue:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSHumanReadableCopyright"]];
}



- (IBAction)showWindow:(id)sender {
	if (![[self window] isVisible]) {
		[[self window] center];
	}
	[[self window] makeKeyAndOrderFront:nil];
}


- (IBAction)showAcknowledgements:(id)sender {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSString *rtfPath = [[NSBundle mainBundle] pathForResource:@"Acknowledgments" ofType:@"rtf"];
	if (rtfPath) {
		[[NSWorkspace sharedWorkspace] openFile:rtfPath];
	}
}


@end

