//
//  TKImageDocument.m
//  Texture Kit
//
//  Created by Mark Douma on 10/15/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//


#import "TKImageDocument.h"
#import "TKImageExportController.h"
#import "TKImageDocumentAccessoryViewController.h"
#import "TKImageExportPreset.h"

#import "MDAppKitAdditions.h"

#import <Quartz/Quartz.h>



NSString * const TKImageDocumentShowFrameBrowserViewKey		= @"TKImageDocumentShowFrameBrowserView";
NSString * const TKImageDocumentShowMipmapBrowserViewKey	= @"TKImageDocumentShowMipmapBrowserView";

NSString * const TKImageDocumentPboardType					= @"TKImageDocumentPboardType";

NSString * const TKImageDocumentDoNotShowWarningAgainKey		= @"TKImageDocumentDoNotShowWarningAgain";


#define TK_DEBUG 1

/* 
 Typically, an application that uses NSDocumentController can only
 support a static list of file formats enumerated in its Info.plist file.
 
 This subclass of NSDocumentController is provided so that this
 application can dynamically support all the file formats supported 
 by ImageIO.
 */

NSString *TKImageIOLocalizedString(NSString *key) {
	
    static NSBundle *imageIOBundle = nil;
    if (imageIOBundle == nil)
        imageIOBundle = [NSBundle bundleWithIdentifier:@"com.apple.ImageIO.framework"];
    // Returns a localized version of the string designated by 'key' in table 'CGImageSource'.
	NSString *string = [imageIOBundle localizedStringForKey:key value:key table:@"CGImageSource"];
#if TK_DEBUG
	NSLog(@"TKImageIOLocalizedString() key == %@, value == %@ ", key, string);
#endif
	return string;
}


@interface TKImageDocument (Private)
- (void)showFrameBrowserView;
- (void)hideFrameBrowserView;
- (void)showMipmapBrowserView;
- (void)hideMipmapBrowserView;

@end


@implementation TKImageDocument

+ (void)initialize {
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	[defaultValues setObject:TKVTFType forKey:TKImageDocumentLastSavedFormatTypeKey];
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:TKImageDocumentShowFrameBrowserViewKey];
	[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:TKImageDocumentShowMipmapBrowserViewKey];
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:TKImageDocumentDoNotShowWarningAgainKey];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}


// Return the names of the types for which this class can be instantiated to play the 
// Editor or Viewer role.  
//
+ (NSArray *)readableTypes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	static NSArray *readableTypes = nil;
	if (readableTypes == nil) {
		readableTypes = [(NSArray *)CGImageSourceCopyTypeIdentifiers() autorelease];
		readableTypes = [[readableTypes arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:TKVTFType, TKDDSType, TKSFTextureImageType, nil]] retain];
	}
//	NSLog(@"[%@ %@] readableTypes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), readableTypes);
	return readableTypes;
}

// Return the names of the types which this class can save. Typically this includes all types 
// for which the application can play the Viewer role, plus types than can be merely exported by 
// the application.
//
+ (NSArray *)writableTypes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	static NSArray *writableTypes = nil;
	if (writableTypes == nil) {
		writableTypes = [(NSArray *)CGImageDestinationCopyTypeIdentifiers() autorelease];
		writableTypes = [[writableTypes arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:TKVTFType, TKDDSType, TKSFTextureImageType, nil]] retain];
	}
//	NSLog(@"[%@ %@] writableTypes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), writableTypes);
	return writableTypes;
}


// Return YES if instances of this class can be instantiated to play the Editor role.
//
+ (BOOL)isNativeType:(NSString *)type {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
    return [[self writableTypes] containsObject:type];
}


@synthesize image, dimensions, shouldShowFrameBrowserView, shouldShowMipmapBrowserView;

@synthesize exportPreset;


- (id)init {
    if ((self = [super init])) {
		
		visibleMipmapReps = [[NSMutableArray alloc] init];
		
		shouldShowFrameBrowserView = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentShowFrameBrowserViewKey] boolValue];
		shouldShowMipmapBrowserView = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentShowMipmapBrowserViewKey] boolValue];

    }
    return self;
}


- (void)dealloc {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[image release];
	[metadata release];
	[dimensions release];
	[saveOptions release];
	[visibleMipmapReps release];
	
	[imageExportController release];
	[accessoryController release];
	
	[exportPreset release];
	
	[super dealloc];
}


- (NSString *)windowNibName {
    return @"TKImageDocument";
}


- (BOOL)readFromURL:(NSURL *)absURL ofType:(NSString *)typeName error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@] typeName == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), typeName);
#endif
	
    BOOL status = NO;
	
	if ([typeName isEqualToString:TKDDSType] ||
		[typeName isEqualToString:TKVTFType]) {
		
		NSData *data = [NSData dataWithContentsOfURL:absURL];
		if (data) image = [[TKImage alloc] initWithData:data];
		
		return (image != nil);
		
	} else if ([typeName isEqualToString:TKSFTextureImageType]) {
		NSData *archiveData = [NSData dataWithContentsOfURL:absURL];
		if (archiveData) {
			image = [[NSKeyedUnarchiver unarchiveObjectWithData:archiveData] retain];
			if (image) {
				[self setDimensions:[NSString stringWithFormat:@"%lu x %lu", [image size].width, [image size].height]];
			}
			return (image != nil);
		}
		
	} else {
		image = [[TKImage alloc] initWithContentsOfURL:absURL];
		
		[self setDimensions:[NSString stringWithFormat:@"%lu x %lu", [image size].width, [image size].height]];
		
		if (image != nil) status = YES;
		
		if (status == NO && outError) *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:nil];
	}
#if TK_DEBUG
	NSLog(@"[%@ %@] image == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), image);
#endif
	
    return status;
}



- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@] typeName == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), typeName);
#endif
	
	BOOL success = NO;
	
	if ([[accessoryController imageUTType] isEqualToString:TKDDSType]) {
		NSData *fileData = [image DDSRepresentationUsingFormat:[accessoryController ddsFormat] quality:[TKImageRep defaultDXTCompressionQuality] createMipmaps:YES];
		if (fileData) {
			success = [fileData writeToURL:absoluteURL options:NSDataWritingAtomic error:outError];
		}
	} else if ([[accessoryController imageUTType] isEqualToString:TKVTFType]) {
		NSData *fileData = [image VTFRepresentationUsingFormat:[accessoryController vtfFormat] quality:[TKImageRep defaultDXTCompressionQuality] createMipmaps:YES];
		if (fileData) {
			success = [fileData writeToURL:absoluteURL options:NSDataWritingAtomic error:outError];
		}
		
	} else if ([[accessoryController imageUTType] isEqualToString:TKSFTextureImageType]) {
		NSData *archiveData = [NSKeyedArchiver archivedDataWithRootObject:image];
		if (archiveData) {
			success = [archiveData writeToURL:absoluteURL options:NSDataWritingAtomic error:outError];
		}
		
	} else {
		// ImageIO
		NSData *fileData = [image dataForType:[accessoryController imageUTType] properties:[accessoryController imageProperties]];
		if (fileData) {
			success = [fileData writeToURL:absoluteURL options:NSDataWritingAtomic error:outError];
		}
	}
	
	return success;
}



- (void)awakeFromNib {
//	[self addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
//	[self bind:(NSString *)binding toObject:imageView withKeyPath:@"zoomFactor" options:(NSDictionary *)options
}



- (void)windowControllerDidLoadNib:(NSWindowController *)windowController {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[self changeViewMode:self];

	NSUInteger contentResizingMask = [frameBrowserView contentResizingMask];
	NSLog(@"[%@ %@] contentResizingMask == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)contentResizingMask);
	[frameBrowserView setContentResizingMask:NSViewWidthSizable];
	
	[frameBrowserView reloadData];
	NSLog(@"[%@ %@] reloaded frameBrowserView, setting selection", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	if ([image frameCount] > 0) {
		[frameBrowserView setSelectionIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	}
	
	if ([image mipmapCount] > 0) {
		[mipmapBrowserView setSelectionIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	}
	
	
	if ([mipmapBrowserView respondsToSelector:@selector(setBackgroundLayer:)]) {
		CALayer *layer = [CALayer layer];
		CGColorRef cRef = CGColorCreateGenericRGB(229.0/255.0, 235.0/255.0, 245.0/255.0, 1.0);
		layer.backgroundColor = cRef;
		CGColorRelease(cRef);
		NSRect frame = [mipmapBrowserView frame];
		
		layer.bounds = CGRectMake(0.0, 0.0, frame.size.width, frame.size.height);
		layer.autoresizingMask = kCALayerHeightSizable | kCALayerWidthSizable | kCALayerMinXMargin | kCALayerMinYMargin | kCALayerMaxXMargin | kCALayerMaxYMargin;
		[mipmapBrowserView setBackgroundLayer:layer];
	}
	if ([frameBrowserView respondsToSelector:@selector(setBackgroundLayer:)]) {
		CALayer *layer = [CALayer layer];
		CGColorRef cRef = CGColorCreateGenericRGB(229.0/255.0, 235.0/255.0, 245.0/255.0, 1.0);
		layer.backgroundColor = cRef;
		CGColorRelease(cRef);
		NSRect frame = [frameBrowserView frame];
		
		layer.bounds = CGRectMake(0.0, 0.0, frame.size.width, frame.size.height);
		layer.autoresizingMask = kCALayerHeightSizable | kCALayerWidthSizable | kCALayerMinXMargin | kCALayerMinYMargin | kCALayerMaxXMargin | kCALayerMaxYMargin;
		[frameBrowserView setBackgroundLayer:layer];
	}
	
	if (togglePlaySegmentedControl && ([image frameCount] <= 1)) {
		[togglePlaySegmentedControl setEnabled:NO forSegment:0];
	}
	
	if ([[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentDoNotShowWarningAgainKey] boolValue] == NO) {
		NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"The image-creation and manipulation feature is still a work in progress.", @"")
									   informativeText:NSLocalizedString(@"Many operations do not work properly yet.", @"")
										   firstButton:NSLocalizedString(@"OK", @"")
										  secondButton:nil
										   thirdButton:nil];
		
		[alert setShowsSuppressionButton:YES];
		
		[alert beginSheetModalForWindow:imageWindow modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	}
	
	
}


- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([[alert suppressionButton] state] == NSOnState) {
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:TKImageDocumentDoNotShowWarningAgainKey];
	}
}


- (void)windowWillClose:(NSNotification *)notification {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}


- (BOOL)prepareSavePanel:(NSSavePanel *)aSavePanel {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (accessoryController == nil) {
		accessoryController = [[TKImageDocumentAccessoryViewController alloc] initWithImageDocument:self];
	}
	return [accessoryController prepareSavePanel:aSavePanel];
}


- (IBAction)saveDocumentTo:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (imageExportController == nil) imageExportController = [[TKImageExportController alloc] initWithImageDocument:self];
	
	[imageExportController setImage:image];
	
	[NSApp beginSheet:[imageExportController window]
	   modalForWindow:imageWindow
		modalDelegate:self
	   didEndSelector:@selector(exportSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	
}

- (IBAction)cancel:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self setExportPreset:nil];
	[NSApp endSheet:[imageExportController window]];
}


- (IBAction)exportWithPreset:(TKImageExportPreset *)preset {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self setExportPreset:preset];
	[NSApp endSheet:[imageExportController window]];
}


- (void)exportSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[sheet orderOut:self];
	
	if (exportPreset) {
		NSSavePanel *savePanel = [NSSavePanel savePanel];
		NSString *fileType = [[exportPreset fileType] lowercaseString];
		NSLog(@"[%@ %@] fileType == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), fileType);
		NSString *initialFilename = [[[[[self fileURL] path] lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:fileType];
		
		NSLog(@"[%@ %@] initialFilename == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), initialFilename);

		[savePanel setAllowedFileTypes:[NSArray arrayWithObjects:[[exportPreset fileType] lowercaseString], nil]];
		NSLog(@"[%@ %@] allowedFileTypes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [savePanel allowedFileTypes]);
		
		if ([savePanel respondsToSelector:@selector(setNameFieldStringValue:)]) {
			[savePanel setNameFieldStringValue:initialFilename];
		}
		
		[savePanel beginSheetForDirectory:nil file:nil modalForWindow:imageWindow modalDelegate:self didEndSelector:@selector(exportSavePanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
		
	}
	
	
}


- (void)exportSavePanelDidEnd:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (returnCode == NSOKButton) {
		NSURL *URL = [sheet URL];
		
		NSData *imageData = nil;
		
		if ([[exportPreset fileType] isEqualToString:TKVTFFileType]) {
			
			imageData = [TKVTFImageRep VTFRepresentationOfImageRepsInArray:[image representations] usingPreset:exportPreset];
			
		} else if ([[exportPreset fileType] isEqualToString:TKDDSFileType]) {
			
			imageData = [TKDDSImageRep DDSRepresentationOfImageRepsInArray:[image representations] usingPreset:exportPreset];
		}
		
		if (imageData) {
			NSError *outError = nil;
			if (![imageData writeToURL:URL options:NSDataWritingAtomic error:&outError]) {
				NSLog(@"[%@ %@] failed to write imageData to URL, error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), outError);
	
			}
		}
		
	}
	
	[sheet orderOut:self];
}



- (IBAction)changeViewMode:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (sender == self) {
		
		frameBrowserHeight = NSHeight([frameBrowserViewView frame]);
		mipmapBrowserWidth = NSWidth([mipmapBrowserViewView frame]);
		
		[viewControl setSelected:shouldShowFrameBrowserView forSegment:0];
		[viewControl setSelected:shouldShowMipmapBrowserView forSegment:1];
		
		if (shouldShowFrameBrowserView) [self showFrameBrowserView];
		
		if (!shouldShowMipmapBrowserView) [self hideMipmapBrowserView];
		
	} else {
		
		BOOL newShouldShowFrameBrowserView = [(NSSegmentedControl *)sender isSelectedForSegment:0];
		BOOL newShouldShowMipmapBrowserView = [(NSSegmentedControl *)sender isSelectedForSegment:1];
		
		if (newShouldShowFrameBrowserView != shouldShowFrameBrowserView) {
			shouldShowFrameBrowserView = newShouldShowFrameBrowserView;
			(shouldShowFrameBrowserView ? [self showFrameBrowserView] : [self hideFrameBrowserView]);
		}
		
		if (newShouldShowMipmapBrowserView != shouldShowMipmapBrowserView) {
			shouldShowMipmapBrowserView = newShouldShowMipmapBrowserView;
			(shouldShowMipmapBrowserView ? [self showMipmapBrowserView] : [self hideMipmapBrowserView]);
		}
		
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:shouldShowFrameBrowserView] forKey:TKImageDocumentShowFrameBrowserViewKey];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:shouldShowMipmapBrowserView] forKey:TKImageDocumentShowMipmapBrowserViewKey];
		
	}
}
	

- (void)showFrameBrowserView {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSRect frame = [frameBrowserViewView frame];
	NSRect newFrame = NSMakeRect(frame.origin.x, frame.origin.y, NSWidth(frame), frameBrowserHeight);
	NSLog(@"[%@ %@] [frameBrowserViewView frame] == %@, frameBrowserHeight == %.3f, newFrame == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(frame), frameBrowserHeight, NSStringFromRect(newFrame));
	
	[frameBrowserViewView setFrame:newFrame];
//	[frameBrowserViewView setFrame:NSMakeRect(frame.origin.x, frame.origin.y, NSWidth(frame), frameBrowserHeight)];
}


- (void)hideFrameBrowserView {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSRect frame = [frameBrowserViewView frame];
//	NSLog(@"[%@ %@] [frameBrowserViewView frame] == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(frame));
	frameBrowserHeight = NSHeight(frame);
	NSLog(@"[%@ %@] [frameBrowserViewView frame] == %@, frameBrowserHeight == %.3f", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(frame), frameBrowserHeight);
	[frameBrowserViewView setFrame:NSMakeRect(frame.origin.x, frame.origin.y, NSWidth(frame), 1.0)];
}


- (void)showMipmapBrowserView {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSRect frame = [mipmapBrowserViewView frame];
	NSRect newFrame = NSMakeRect(frame.origin.x, frame.origin.y, mipmapBrowserWidth, NSHeight(frame));
	NSLog(@"[%@ %@] [mipmapBrowserViewView frame] == %@, mipmapBrowserWidth == %.3f, newFrame == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(frame), mipmapBrowserWidth, NSStringFromRect(newFrame));
	
	[mipmapBrowserViewView setFrame:newFrame];
//	[mipmapBrowserViewView setFrame:NSMakeRect(frame.origin.x, frame.origin.y, mipmapBrowserWidth, NSHeight(frame))];
	
}

- (void)hideMipmapBrowserView {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSRect frame = [mipmapBrowserViewView frame];
	
	mipmapBrowserWidth = NSWidth(frame);
	
	NSLog(@"[%@ %@] [mipmapBrowserViewView frame] == %@, mipmapBrowserWidth == %.3f", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(frame), mipmapBrowserWidth);
	[mipmapBrowserViewView setFrame:NSMakeRect(frame.origin.x, frame.origin.y, 1.0, NSHeight(frame))];
}




#pragma mark -
#pragma mark <TKImageViewAnimatedImageDataSource>

- (NSArray *)imageRepsForAnimationInImageView:(TKImageView *)anImageView {
	return [image representationsForFrameIndexes:[image allFrameIndexes] mipmapIndexes:[image firstMipmapIndexSet]];
}


#pragma mark <TKImageViewAnimatedImageDataSource> END 
#pragma mark -
#pragma mark <IKImageBrowserDataSource>

- (NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)aBrowser {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (aBrowser == frameBrowserView) {
		NSUInteger frameCount = [image frameCount];
//		return [theImage frameCount];
#if TK_DEBUG
	NSLog(@"[%@ %@] returning %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)frameCount);
#endif
		return frameCount;
	} else if (aBrowser == mipmapBrowserView) {
		return [visibleMipmapReps count];
	}
	return 0;
}

- (id /*IKImageBrowserItem*/)imageBrowser:(IKImageBrowserView *)aBrowser itemAtIndex:(NSUInteger)anIndex {
#if TK_DEBUG
//	NSLog(@"[%@ %@] imageBrowser == %@, index == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (aBrowser == frameBrowserView ? @"frameBrowserView" : @"mipmapBrowserView"), anIndex);
#endif
	
	if (aBrowser == frameBrowserView) {
		
		return [image representationForFrameIndex:anIndex mipmapIndex:0];
		
	} else if (aBrowser == mipmapBrowserView) {
		
		return [visibleMipmapReps objectAtIndex:anIndex];
		
	}
	
	return nil;
}


//	@method imageBrowser:writeItemsAtIndexes:toPasteboard:
//	@abstract This method is called after it has been determined that a drag should begin, but before the drag has been started. 'itemIndexes' contains the indexes that will be participating in the drag. Return the number of items effectively written to the pasteboard.
//	@discussion optional - drag and drop support

- (NSUInteger)imageBrowser:(IKImageBrowserView *)aBrowser writeItemsAtIndexes:(NSIndexSet *)itemIndexes toPasteboard:(NSPasteboard *)pboard {
#if TK_DEBUG
	NSLog(@"[%@ %@] ", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSArray *images = nil;
	
	if (aBrowser == frameBrowserView) {
		images = [image representationsForFrameIndexes:itemIndexes mipmapIndexes:[image allMipmapIndexes]];
		
	} else if (aBrowser == mipmapBrowserView) {
		images = [visibleMipmapReps objectsAtIndexes:itemIndexes];
		
	}
	
	if (images && [images count]) {
		[pboard declareTypes:[NSArray arrayWithObjects:TKImageDocumentPboardType, NSTIFFPboardType, nil] owner:self];
		NSData *imageData = [NSKeyedArchiver archivedDataWithRootObject:images];
		if (imageData) {
			[pboard setData:imageData forType:TKImageDocumentPboardType];
		}
		TKImageRep *firstImageRep = [images objectAtIndex:0];
		NSData *TIFFRepresentation = [firstImageRep TIFFRepresentationUsingCompression:NSTIFFCompressionNone factor:0];
		if (TIFFRepresentation) {
			[pboard setData:TIFFRepresentation forType:NSTIFFPboardType];
		}
		
		return [images count];
		
	}
	
	return 0;
	
}


///*! 
//  @method imageBrowser:removeItemsAtIndexes:
//  @abstract Invoked by the image browser after it has been determined that a remove operation should be applied (optional)
//  @discussion The data source should update itself (usually by removing this indexes).  
//*/
//- (void)imageBrowser:(IKImageBrowserView *)aBrowser removeItemsAtIndexes:(NSIndexSet *)indexes {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	
//}
//
///*! 
//  @method imageBrowser:moveItemsAtIndexes:toIndex:
//  @abstract Invoked by the image browser after it has been determined that a reordering operation should be applied (optional).
//  @discussion The data source should update itself (usually by reordering its elements).  
//*/
//- (BOOL)imageBrowser:(IKImageBrowserView *)aBrowser moveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)destinationIndex {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	
//}
//


//
///*!
//	@method numberOfGroupsInImageBrowser:
//	@abstract Returns the number of groups
//	@discussion this method is optional
//*/
//- (NSUInteger)numberOfGroupsInImageBrowser:(IKImageBrowserView *)aBrowser {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	
//}
//
///*!
//	@method imageBrowser:groupAtIndex:
//	@abstract Returns the group at index 'index'
//	@discussion A group is defined by a dictionay. Keys for this dictionary are defined below.
//*/
//- (NSDictionary *)imageBrowser:(IKImageBrowserView *)aBrowser groupAtIndex:(NSUInteger)index {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	
//}


#pragma mark <IKImageBrowserDataSource> END 
#pragma mark -
#pragma mark <IKImageBrowserDelegate>


- (void)imageBrowserSelectionDidChange:(IKImageBrowserView *)aBrowser {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (aBrowser == frameBrowserView) {
		[visibleMipmapReps setArray:[image representationsForFrameIndexes:[frameBrowserView selectionIndexes] mipmapIndexes:[image allMipmapIndexes]]];
		
		[mipmapBrowserView reloadData];
		
		if ([visibleMipmapReps count]) {
			[mipmapBrowserView setSelectionIndexes:[NSIndexSet indexSetWithIndex:0]	byExtendingSelection:NO];
		}
		
		
	} else if (aBrowser == mipmapBrowserView) {
		NSIndexSet *selectionIndexes = [aBrowser selectionIndexes];
		if ([selectionIndexes count] == 0 || [selectionIndexes count] >= 2) {
			
			
		} else if ([selectionIndexes count] == 1) {
			TKImageRep *imageRep = [visibleMipmapReps objectAtIndex:[selectionIndexes firstIndex]];
			[imageView setImage:[imageRep CGImage] imageProperties:([imageRep respondsToSelector:@selector(imageProperties)] ? [imageRep imageProperties] : nil)];
		}
	}

}

- (void)imageBrowser:(IKImageBrowserView *)aBrowser cellWasDoubleClickedAtIndex:(NSUInteger)anIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}


- (void)imageBrowser:(IKImageBrowserView *)aBrowser cellWasRightClickedAtIndex:(NSUInteger)anIndex withEvent:(NSEvent *)event {
#if TK_DEBUG
	NSLog(@"[%@ %@] event == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), event);
#endif
	[NSMenu popUpContextMenu:[aBrowser menu] withEvent:event forView:aBrowser];
}


- (void)imageBrowser:(IKImageBrowserView *)aBrowser backgroundWasRightClickedWithEvent:(NSEvent *)event {
#if TK_DEBUG
	NSLog(@"[%@ %@] event == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), event);
#endif
	[NSMenu popUpContextMenu:[aBrowser menu] withEvent:event forView:aBrowser];
	
}


#pragma mark <IKImageBrowserDelegate> END 
#pragma mark -



- (IBAction)changeToolMode:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([sender isKindOfClass:[NSSegmentedControl class]]) {
		
	}
}



- (IBAction)togglePlayAnimation:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@] sender == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sender);
#endif
	
	BOOL isPlaying = [imageView isPlaying];
	
	if ([sender isKindOfClass:[NSSegmentedControl class]]) {
		[(NSSegmentedControl *)sender setImage:[NSImage imageNamed:(isPlaying ? @"overlayPlay" : @"overlayStop")] forSegment:0];
		[[(NSSegmentedControl *)sender cell] setToolTip:(isPlaying ? NSLocalizedString(@"Play the animated image", @"") : NSLocalizedString(@"Stop playing the animated image", @"")) forSegment:0];
	}
	[togglePlayToolbarItem setLabel:(isPlaying ? NSLocalizedString(@"Play", @"") : NSLocalizedString(@"Stop", @""))];
	
	[imageView togglePlay:sender];
}



- (IBAction)toggleAutomaticallyResize:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}


- (IBAction)changeColumnCount:(id)sender  {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}

- (IBAction)changeBrowserSortOptions:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}


- (IBAction)openInNewWindow:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}

- (IBAction)saveCopyToFolder:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}


- (IBAction)sendImageTo:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}



- (void)menuNeedsUpdate:(NSMenu *)menu {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	

}

//- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	
//}


- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	SEL action = [theItem action];
	
	if (action == @selector(togglePlayAnimation:)) {
		if ([imageView isPlaying]) {
			[theItem setLabel:NSLocalizedString(@"Stop", @"")];
			[theItem setImage:[NSImage imageNamed:@"overlayStop"]];
			
		} else {
			[theItem setLabel:NSLocalizedString(@"Play", @"")];
			[theItem setImage:[NSImage imageNamed:@"overlayPlay"]];
		}
		
		if ([image frameCount] <= 1) return NO;
		
		return YES;
	} else if (action == @selector(changeViewMode:)) {
		
		
		return YES;
	}
	
	return YES;
}



//- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	return YES;
//}




@end




