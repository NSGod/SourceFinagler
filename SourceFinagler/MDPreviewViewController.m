//
//  MDPreviewViewController.m
//  Source Finagler
//
//  Created by Mark Douma on 9/30/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDPreviewViewController.h"
#import <WebKit/WebKit.h>
#import <QTKit/QTKit.h>
#import "MDTransparentView.h"
#import "MDHLDocument.h"
#import <HLKit/HLKit.h>
#import "MDFileSizeFormatter.h"
#import "MDInspectorView.h"



#define MD_DEBUG 0


@implementation MDPreviewViewController

@synthesize sound;
@synthesize soundStatus;
@synthesize isQuickLookPanel;


- (id)init {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self initWithNibName:@"MDHLColumnPreviewView" bundle:nil];
}


- (void)dealloc {
	[sound setDelegate:nil];
	[sound stop];
	[sound release];
	[super dealloc];
}


- (void)awakeFromNib {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[inspectorView setInitiallyShown:YES];
	[textView setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];
	
	MDFileSizeFormatter *formatter = [[[MDFileSizeFormatter alloc] initWithUnitsType:MDFileSizeFormatterAutomaticUnitsType
																			   style:MDFileSizeFormatterPhysicalStyle] autorelease];
	[sizeField setFormatter:formatter];
}



- (void)setRepresentedObject:(id)representedObject {
#if MD_DEBUG
	NSLog(@"[%@ %@] representedObject == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), representedObject);
#endif
	MDSoundStatus ourStatus = self.soundStatus;
	if (ourStatus == MDSoundPaused || ourStatus == MDSoundPlaying) {
		[sound stop];
		self.sound = nil;
		self.soundStatus = MDSoundNone;
		[soundButton setImage:[NSImage imageNamed:@"play"]];
	}
	
	// representedObject can be:
	//		nil
	//		an MDHLDocument
	//		an HKFile or HKFolder
	
	if (representedObject == nil || [representedObject isKindOfClass:[MDHLDocument class]]) {
		[box setContentView:imageViewView];
		[super setRepresentedObject:representedObject];
		return;
	}
	
	if ([representedObject isKindOfClass:[HKItem class]] && [representedObject respondsToSelector:@selector(fileType)]) {
		HKFileType fileType = HKFileTypeNone;
		fileType = [(HKFile *)representedObject fileType];
		
		if (isQuickLookPanel) {
			
			// if we are the Quick Look panel, then we can show more kinds
			
			switch (fileType) {
				case HKFileTypeHTML :
					[[webView mainFrame] loadHTMLString:[(HKFile *)representedObject stringValue] baseURL:nil];
					[box setContentView:webViewView];
					break;
					
				case HKFileTypeText :
					[textView setString:[(HKFile *)representedObject stringValue]];
					[box setContentView:textViewView];
					break;
					
				case HKFileTypeImage :
				case HKFileTypeOther :
					[box setContentView:imageViewView];
					break;
					
				case HKFileTypeSound :
					[box setContentView:soundViewView];
					[self setSound:[(HKFile *)representedObject sound]];
					[sound setName:[(HKFile *)representedObject name]];
					[sound setDelegate:self];
					break;
					
				case HKFileTypeMovie :
					[box setContentView:movieViewView];
					break;
					
				default:
					break;
			}
			
		} else {
			
			switch (fileType) {
				case HKFileTypeHTML :
				case HKFileTypeText :
				case HKFileTypeOther :
				case HKFileTypeImage :
					[box setContentView:imageViewView];
					break;
					
				case HKFileTypeSound :
					[box setContentView:soundViewView];
					[self setSound:[(HKFile *)representedObject sound]];
					[sound setName:[(HKFile *)representedObject name]];
					[sound setDelegate:self];
					break;
					
				case HKFileTypeMovie :
					[box setContentView:movieViewView];
					break;
					
				default:
					break;
			}
		}
	}
	[super setRepresentedObject:representedObject];
}



- (void)sound:(NSSound *)aSound didFinishPlaying:(BOOL)didFinishPlaying {
#if MD_DEBUG
	NSLog(@"[%@ %@] sound == %@, sound.name == %@, didFinishPlaying == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), aSound, aSound.name, (didFinishPlaying ? @"YES" : @"NO"));
#endif
	self.soundStatus = MDSoundNone;
	[soundButton setImage:[NSImage imageNamed:@"play"]];
}



- (IBAction)togglePlaySound:(id)sender {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	MDSoundStatus ourStatus = self.soundStatus;
	
	if (ourStatus == MDSoundNone) {
		self.soundStatus = MDSoundPlaying;
		[soundButton setImage:[NSImage imageNamed:@"pause"]];
		[sound play];
		
	} else if (ourStatus == MDSoundPaused) {
		self.soundStatus = MDSoundPlaying;
		[soundButton setImage:[NSImage imageNamed:@"play"]];
		[sound resume];
		
	} else if (ourStatus == MDSoundPlaying) {
		self.soundStatus = MDSoundPaused;
		[soundButton setImage:[NSImage imageNamed:@"pause"]];
		[sound pause];
		
	}
}


@end
