//
//  TKImageDocument.m
//  Source Finagler
//
//  Created by Mark Douma on 10/15/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//


#import "TKImageDocument.h"
#import "TKImageExportController.h"
#import "TKImageDocumentAccessoryViewController.h"
#import "TKBlueBackgroundView.h"
#import "TKImageRepAdditions.h"
#import "TKImageKitAdditions.h"
#import "MDAppKitAdditions.h"
#import "TKImageBrowserItem.h"

#import <Quartz/Quartz.h>


enum {
	TKFacesTag		= 1,
	TKFramesTag		= 2,
	TKMipmapsTag	= 3
};



NSString * const TKImageDocumentShowFaceBrowserViewKey		= @"TKImageDocumentShowFaceBrowserView";
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
        imageIOBundle = [[NSBundle bundleWithIdentifier:@"com.apple.ImageIO.framework"] retain];
    // Returns a localized version of the string designated by 'key' in table 'CGImageSource'.
	NSString *string = [imageIOBundle localizedStringForKey:key value:key table:@"CGImageSource"];
#if TK_DEBUG
//	NSLog(@"TKImageIOLocalizedString() key == %@, value == %@ ", key, string);
#endif
	return string;
}


@interface TKImageDocument (TKPrivate)

- (NSIndexSet *)selectedFaceIndexes;
- (void)setSelectedFaceIndexes:(NSIndexSet *)faceIndexes;

- (void)showFaceBrowserView;
- (void)hideFaceBrowserView;
- (void)showFrameBrowserView;
- (void)hideFrameBrowserView;
- (void)showMipmapBrowserView;
- (void)hideMipmapBrowserView;

@end


@implementation TKImageDocument

+ (void)initialize {
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:TKImageDocumentShowFaceBrowserViewKey];
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:TKImageDocumentShowFrameBrowserViewKey];
	[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:TKImageDocumentShowMipmapBrowserViewKey];
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:TKImageDocumentDoNotShowWarningAgainKey];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}


// Return the names of the types for which this class can be instantiated to play the 
// Editor or Viewer role.  
//
+ (NSArray *)readableTypes {
	static NSArray *readableTypes = nil;
	
	if (readableTypes == nil) {
		readableTypes = [(NSArray *)CGImageSourceCopyTypeIdentifiers() autorelease];
		readableTypes = [[readableTypes arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:TKVTFType, TKDDSType, TKSFTextureImageType, nil]] retain];
#if TK_DEBUG
//		NSLog(@"[%@ %@] readableTypes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), readableTypes);
#endif
	}
	return readableTypes;
}

// Return the names of the types which this class can save. Typically this includes all types 
// for which the application can play the Viewer role, plus types than can be merely exported by 
// the application.
//
+ (NSArray *)writableTypes {
	static NSArray *writableTypes = nil;
	
	if (writableTypes == nil) {
		writableTypes = [(NSArray *)CGImageDestinationCopyTypeIdentifiers() autorelease];
		writableTypes = [[writableTypes arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:TKVTFType, TKDDSType, TKSFTextureImageType, nil]] retain];
#if TK_DEBUG
//		NSLog(@"[%@ %@] writableTypes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), writableTypes);
#endif
	}
	return writableTypes;
}


// Return YES if instances of this class can be instantiated to play the Editor role.
+ (BOOL)isNativeType:(NSString *)type {
#if TK_DEBUG
//	NSLog(@"[%@ %@] type == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), type);
#endif
    return [[self writableTypes] containsObject:type];
}


@synthesize image;
@synthesize dimensions;
@synthesize shouldShowFaceBrowserView;
@synthesize shouldShowFrameBrowserView;
@synthesize shouldShowMipmapBrowserView;


- (id)init {
    if ((self = [super init])) {
		
		visibleFaceBrowserItems = [[NSMutableArray alloc] init];
		visibleFrameBrowserItems = [[NSMutableArray alloc] init];
		
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
	
	[visibleFaceBrowserItems release];
	[visibleFrameBrowserItems release];
	
	[visibleMipmapReps release];
	
	[imageExportController release];
	[accessoryViewController release];
	
	[super dealloc];
}


- (NSString *)windowNibName {
    return @"TKImageDocument";
}


- (BOOL)readFromURL:(NSURL *)absURL ofType:(NSString *)typeName error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@] URL.path == %@, typeName == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), absURL.path, typeName);
#endif
	
	// allow us to call this method to re-read in a newly "saved-as" file without leaking memory
	[image release];
	
	// take advantage of our creation methods that return by indirection an `NSError`
	image = [(TKImage *)[TKImage alloc] initWithContentsOfURL:absURL error:outError];
	
	if (image) [self setDimensions:[NSString stringWithFormat:@"%lu x %lu", (unsigned long)[image size].width, (unsigned long)[image size].height]];
	
#if TK_DEBUG
	NSLog(@"[%@ %@] image == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), image);
#endif
	
	if (image == nil) {
#if TK_DEBUG
		NSLog(@"[%@ %@] ERROR: failed to open file at \"%@\"; error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), absURL.path, (outError ? *outError : @""));
#endif
		
	}
	
	return (image != nil);
}


- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@] URL.path == %@, typeName == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), absoluteURL.path, typeName);
#endif
	
	NSString *imageUTType = accessoryViewController.imageUTType;
	
	if ([imageUTType isEqualToString:TKDDSType] || [imageUTType isEqualToString:TKVTFType]) {
		
		if ([imageUTType isEqualToString:TKDDSType]) {
			
			NSData *fileData = [image DDSRepresentationUsingFormat:(accessoryViewController.ddsContainer == TKDDSContainerDX10 ? accessoryViewController.dds10Format : accessoryViewController.dds9Format)
														   quality:accessoryViewController.compressionQuality
														 container:accessoryViewController.ddsContainer
														   options:accessoryViewController.options
															 error:outError];
			
			if (fileData) {
				return [fileData writeToURL:absoluteURL options:NSDataWritingAtomic error:outError];
			}
			
		} else if ([imageUTType isEqualToString:TKVTFType]) {
			
			NSData *fileData = [image VTFRepresentationUsingFormat:accessoryViewController.vtfFormat
														   quality:accessoryViewController.compressionQuality
														   options:accessoryViewController.options
															 error:outError];
			if (fileData) {
				return [fileData writeToURL:absoluteURL options:NSDataWritingAtomic error:outError];
			}
		}
		
	} else if ([imageUTType isEqualToString:TKSFTextureImageType]) {
		NSData *archiveData = [NSKeyedArchiver archivedDataWithRootObject:image];
		if (archiveData) {
			return [archiveData writeToURL:absoluteURL options:NSDataWritingAtomic error:outError];
		}
		
	} else {
		// ImageIO
		NSData *fileData = [image representationUsingImageType:imageUTType properties:accessoryViewController.imageProperties];
		if (fileData) {
			return [fileData writeToURL:absoluteURL options:NSDataWritingAtomic error:outError];
		}
	}
	return NO;
}


- (void)awakeFromNib {
#if TK_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	// NOTE: called multiple times as other nib files are loaded
}

static CALayer *MDBlueBackgroundLayerWithFrame(NSRect frame) {
	CALayer *layer = [CALayer layer];
	CGColorRef cRef = CGColorCreateGenericRGB(229.0/255.0, 235.0/255.0, 245.0/255.0, 1.0);
	layer.backgroundColor = cRef;
	CGColorRelease(cRef);
	layer.bounds = CGRectMake(0.0, 0.0, NSWidth(frame), NSHeight(frame));
	layer.autoresizingMask = kCALayerHeightSizable | kCALayerWidthSizable | kCALayerMinXMargin | kCALayerMinYMargin | kCALayerMaxXMargin | kCALayerMaxYMargin;
	return layer;
}


- (void)windowControllerDidLoadNib:(NSWindowController *)windowController {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super windowControllerDidLoadNib:windowController];
	
	
	if ([faceBrowserView respondsToSelector:@selector(setBackgroundLayer:)]) {
		[faceBrowserView setBackgroundLayer:MDBlueBackgroundLayerWithFrame([faceBrowserView frame])];
	}
	
	if ([mipmapBrowserView respondsToSelector:@selector(setBackgroundLayer:)]) {
		[mipmapBrowserView setBackgroundLayer:MDBlueBackgroundLayerWithFrame([mipmapBrowserView frame])];
	}
	
	if ([frameBrowserView respondsToSelector:@selector(setBackgroundLayer:)]) {
		[frameBrowserView setBackgroundLayer:MDBlueBackgroundLayerWithFrame([frameBrowserView frame])];
	}
	
#if TK_DEBUG
	NSLog(@"[%@ %@] ******* facesBrowserCellSize == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromSize([faceBrowserView cellSize]));
#endif
	if ([faceBrowserView respondsToSelector:@selector(setIntercellSpacing:)]) {
		[faceBrowserView setIntercellSpacing:NSMakeSize(1.0, 1.0)];
	}
	
	
	[self changeViewMode:self];

//	NSUInteger contentResizingMask = [frameBrowserView contentResizingMask];
//	NSLog(@"[%@ %@] contentResizingMask == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)contentResizingMask);
	
	
	[faceBrowserView setContentResizingMask:NSViewHeightSizable]; // ?
	
	[frameBrowserView setContentResizingMask:NSViewWidthSizable];
	
	[mipmapBrowserView setContentResizingMask:NSViewHeightSizable];
	
	
	[faceBrowserView reloadData];
	[frameBrowserView reloadData];
	[mipmapBrowserView reloadData];
	
	
	if (image.faceCount) {
		[faceBrowserView setSelectionIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	}
	
#if TK_DEBUG
	NSLog(@"[%@ %@] reloaded frameBrowserView, setting selection", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
//	if (image.faceCount > 0) {
//		[faceBrowserView setSelectionIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
//	}
	
	if (image.frameCount) {
		[frameBrowserView setSelectionIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	}
	
	if (image.mipmapCount) {
		[mipmapBrowserView setSelectionIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	}
	
	
	if (togglePlaySegmentedControl && !image.isAnimated) {
		[togglePlaySegmentedControl setEnabled:NO forSegment:0];
	}
	
	
	[mipmapBrowserView setAllowsReordering:NO];
	
	[frameBrowserView setDraggingDestinationDelegate:self];
	
	
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


#pragma mark - <NSWindowDelegate>


- (void)windowWillClose:(NSNotification *)notification {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([notification object] == imageWindow) {
//		[imageExportController cleanup];
//		[imageExportController release];
//		imageExportController = nil;
		
		[accessoryViewController cleanup];
		[accessoryViewController release];
		accessoryViewController = nil;
		
	}
}


#pragma mark END <NSWindowDelegate>
#pragma mark -


- (void)reloadData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSIndexSet *faceSelectionIndexes = [self selectedFaceIndexes];
	NSIndexSet *frameSelectionIndexes = [frameBrowserView selectionIndexes];
	NSIndexSet *mipmapSelectionIndexes = [mipmapBrowserView selectionIndexes];
	
#if TK_DEBUG
	
	
	NSLog(@"[%@ %@] (BEFORE) faceSelectionIndexes == %@, frameSelectionIndexes == %@, mipmapSelectionIndexes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), faceSelectionIndexes, frameSelectionIndexes, mipmapSelectionIndexes);
#endif
	
	[faceBrowserView reloadData];
	[frameBrowserView reloadData];
	[mipmapBrowserView reloadData];
	
	
	[togglePlaySegmentedControl setEnabled:[image isAnimated] forSegment:0];
	
	
#if TK_DEBUG
	NSLog(@"[%@ %@] reloaded data", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSIndexSet *revisedFaceSelectionIndexes = nil;
	NSIndexSet *revisedFrameSelectionIndexes = nil;
	NSIndexSet *revisedMipmapSelectionIndexes = nil;
	
	
//	NSMutableIndexSet *revisedFaceSelectionIndexes = nil;
//	NSMutableIndexSet *revisedFrameSelectionIndexes = nil;
//	NSMutableIndexSet *revisedMipmapSelectionIndexes = nil;
	
//	NSMutableIndexSet *revisedFaceSelectionIndexes = [[[NSMutableIndexSet alloc] initWithIndexSet:faceSelectionIndexes] autorelease];
//	NSMutableIndexSet *revisedFrameSelectionIndexes = [[[NSMutableIndexSet alloc] initWithIndexSet:frameSelectionIndexes] autorelease];
//	NSMutableIndexSet *revisedMipmapSelectionIndexes = [[[NSMutableIndexSet alloc] initWithIndexSet:mipmapSelectionIndexes] autorelease];
	
	if ([faceSelectionIndexes count]) {
		NSIndexSet *allFaceIndexes = [image allFaceIndexes];
		
		if (![allFaceIndexes containsIndexes:faceSelectionIndexes]) {
			// previous selection is no longer valid, adjust accordingly
			
			NSIndexSet *intersectingIndexSet = [allFaceIndexes indexesIntersectingIndexes:faceSelectionIndexes];
			
			if ([intersectingIndexSet count]) {
				revisedFaceSelectionIndexes = intersectingIndexSet;
			} else {
				revisedFaceSelectionIndexes = [NSIndexSet indexSetWithIndex:[allFaceIndexes firstIndex]];
			}
			
		} else {
			revisedFaceSelectionIndexes = faceSelectionIndexes;
		}
	}
	
	
	if ([frameSelectionIndexes count]) {
		NSIndexSet *allFrameIndexes = [image allFrameIndexes];
		
		if (![allFrameIndexes containsIndexes:frameSelectionIndexes]) {
			// previous selection is no longer valid, adjust accordingly
			
			NSIndexSet *intersectingIndexSet = [allFrameIndexes indexesIntersectingIndexes:frameSelectionIndexes];
			
			if ([intersectingIndexSet count]) {
				revisedFrameSelectionIndexes = intersectingIndexSet;
			} else {
				revisedFrameSelectionIndexes = [NSIndexSet indexSetWithIndex:[allFrameIndexes firstIndex]];
			}
		} else {
			revisedFrameSelectionIndexes = frameSelectionIndexes;
		}
	}
	
	
	if ([mipmapSelectionIndexes count]) {
		
		NSIndexSet *allMipmapIndexes = [image allMipmapIndexes];
		
		if (![allMipmapIndexes containsIndexes:mipmapSelectionIndexes]) {
			// previous selection is no longer valid, adjust accordingly
			
			NSIndexSet *intersectingIndexSet = [allMipmapIndexes indexesIntersectingIndexes:mipmapSelectionIndexes];
			
			if ([intersectingIndexSet count]) {
				revisedMipmapSelectionIndexes = intersectingIndexSet;
			} else {
				revisedMipmapSelectionIndexes = [NSIndexSet indexSetWithIndex:[allMipmapIndexes firstIndex]];
			}
		} else {
			revisedMipmapSelectionIndexes = mipmapSelectionIndexes;
		}
	}
	
	if (revisedFaceSelectionIndexes) [self setSelectedFaceIndexes:revisedFaceSelectionIndexes];
	
	if (revisedFrameSelectionIndexes) [frameBrowserView setSelectionIndexes:revisedFrameSelectionIndexes byExtendingSelection:NO];
	
	if (revisedMipmapSelectionIndexes) [mipmapBrowserView setSelectionIndexes:revisedMipmapSelectionIndexes byExtendingSelection:NO];
	
	
	
#if TK_DEBUG
	
	faceSelectionIndexes = [self selectedFaceIndexes];
	frameSelectionIndexes = [frameBrowserView selectionIndexes];
	mipmapSelectionIndexes = [mipmapBrowserView selectionIndexes];
	
	NSLog(@"[%@ %@] (AFTER) faceSelectionIndexes == %@, frameSelectionIndexes == %@, mipmapSelectionIndexes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), faceSelectionIndexes, frameSelectionIndexes, mipmapSelectionIndexes);
#endif
	
}


- (void)reloadImage {
#if TK_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}



- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@] typeName == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), typeName);
#endif

	NSFileWrapper *fileWrapper = [super fileWrapperOfType:typeName error:outError];
	
#if TK_DEBUG
	NSLog(@"[%@ %@] fileWrapper == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), fileWrapper);
#endif
	return fileWrapper;
}


- (void)saveDocumentWithDelegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo {
#if TK_DEBUG
	NSLog(@"[%@ %@] delegate == %@, didSaveSelector == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), delegate, NSStringFromSelector(didSaveSelector));
#endif
	[super saveDocumentWithDelegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
}


- (void)saveToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo {
#if TK_DEBUG
	NSLog(@"[%@ %@] url == %@, typeName == %@, saveOperation == %lu, delegate == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), url, typeName, (unsigned long)saveOperation, delegate);
#endif
	[super saveToURL:url ofType:typeName forSaveOperation:saveOperation delegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
}


- (void)presentError:(NSError *)error modalForWindow:(NSWindow *)window delegate:(id)delegate didPresentSelector:(SEL)didPresentSelector contextInfo:(void *)contextInfo {
#if TK_DEBUG
	NSLog(@"[%@ %@] error == %@, window == %@, delegate == %@, didPresentSelector == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error, window, delegate, NSStringFromSelector(didPresentSelector));
#endif
	[super presentError:error modalForWindow:window delegate:delegate didPresentSelector:didPresentSelector contextInfo:contextInfo];
}


- (BOOL)presentError:(NSError *)error {
#if TK_DEBUG
	NSLog(@"[%@ %@] error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
#endif
	return [super presentError:error];
}


- (NSError *)willPresentError:(NSError *)error {
#if TK_DEBUG
	NSLog(@"[%@ %@] error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
#endif
	NSError *supersError = [super willPresentError:error];
#if TK_DEBUG
	NSLog(@"[%@ %@] supersError == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
#endif
	return supersError;
	
//	return [super willPresentError:error];
}



- (void)setFileType:(NSString *)typeName {
#if TK_DEBUG
//	NSLog(@"[%@ %@] typeName == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), typeName);
#endif
	[super setFileType:typeName];
}


- (NSString *)fileType {
	NSString *fileType = [super fileType];
#if TK_DEBUG
//	NSLog(@"[%@ %@] fileType == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), fileType);
#endif
	return fileType;
}


- (void)setFileURL:(NSURL *)url {
#if TK_DEBUG
//	NSLog(@"[%@ %@] URL == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), url);
#endif
	[super setFileURL:url];
}


- (NSURL *)fileURL {
	NSURL *fileURL = [super fileURL];
#if TK_DEBUG
//	NSLog(@"[%@ %@] fileURL == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), fileURL);
#endif
	return fileURL;
}



- (IBAction)saveDocumentAs:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super saveDocumentAs:sender];
}


- (void)runModalSavePanelForSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo {
#if TK_DEBUG
	NSLog(@"[%@ %@] saveOperation == %lu, delegate == %@, didSaveSelector == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)saveOperation, delegate, NSStringFromSelector(didSaveSelector));
#endif
	if (saveOperation == NSSaveAsOperation) {
		return [super runModalSavePanelForSaveOperation:saveOperation delegate:self didSaveSelector:@selector(document:didSave:contextInfo:) contextInfo:NULL];
	} else {
		[super runModalSavePanelForSaveOperation:saveOperation delegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
	}
}


- (BOOL)prepareSavePanel:(NSSavePanel *)aSavePanel {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (accessoryViewController == nil) {
		accessoryViewController = [[TKImageDocumentAccessoryViewController alloc] initWithImageDocument:self];
	}
	return [accessoryViewController prepareSavePanel:aSavePanel];
}


- (BOOL)saveToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@]  URL.path == %@, typeName == %@, saveOperation == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), url.path, typeName, (unsigned long)saveOperation);
#endif
	BOOL success = [super saveToURL:url ofType:typeName forSaveOperation:saveOperation error:outError];
	
	
#if TK_DEBUG
	NSLog(@"[%@ %@]  self.fileURL.path == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.fileURL.path);
#endif
	
	return success;
}


- (void)document:(NSDocument *)document didSave:(BOOL)didSaveSuccessfully contextInfo:(void *)contextInfo {
#if TK_DEBUG
	NSLog(@"[%@ %@] didSave == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (didSaveSuccessfully ? @"YES" : @"NO"));
#endif
	// force save of defaults
	[accessoryViewController saveDefaults];
}


// disabled in Source Finagler 2.0.3; enabled in 2.5
- (IBAction)saveDocumentTo:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (imageExportController == nil) {
		imageExportController = [[TKImageExportController alloc] initWithImageDocument:self];
	}
	
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
	[NSApp endSheet:[imageExportController window]];
}


- (IBAction)export:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[NSApp endSheet:[imageExportController window]];
}


- (void)exportSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[sheet orderOut:self];
}



- (IBAction)changeViewMode:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@] sender == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sender);
#endif
	
	if (sender == self) {
		
		faceBrowserWidth = NSWidth([faceBrowserViewView frame]);
		frameBrowserHeight = NSHeight([frameBrowserViewView frame]);
		mipmapBrowserWidth = NSWidth([mipmapBrowserViewView frame]);
		
		[viewControl setSelected:shouldShowFaceBrowserView forSegment:0];
		[viewControl setSelected:shouldShowFrameBrowserView forSegment:1];
		[viewControl setSelected:shouldShowMipmapBrowserView forSegment:2];
		
		shouldShowFaceBrowserView ? [self showFaceBrowserView] : [self hideFaceBrowserView];
		
		if (shouldShowFrameBrowserView) [self showFrameBrowserView];
		
		if (!shouldShowMipmapBrowserView) [self hideMipmapBrowserView];
		
	} else {
		
		BOOL newShouldShowFaceBrowserView = shouldShowFaceBrowserView;
		BOOL newShouldShowFrameBrowserView = shouldShowFrameBrowserView;
		BOOL newShouldShowMipmapBrowserView = shouldShowMipmapBrowserView;
		
		if ([sender isKindOfClass:[NSSegmentedControl class]]) {
			
			newShouldShowFaceBrowserView = [(NSSegmentedControl *)sender isSelectedForSegment:0];
			newShouldShowFrameBrowserView = [(NSSegmentedControl *)sender isSelectedForSegment:1];
			newShouldShowMipmapBrowserView = [(NSSegmentedControl *)sender isSelectedForSegment:2];
			
		} else if ([sender isKindOfClass:[NSMenuItem class]]) {
			
			NSInteger tag = [(NSMenuItem *)sender tag];
			
//			BOOL newShouldShowFaceBrowserView = shouldShowFaceBrowserView;
//			BOOL newShouldShowFrameBrowserView = shouldShowFrameBrowserView;
//			BOOL newShouldShowMipmapBrowserView = shouldShowMipmapBrowserView;
			
			if (tag == TKFacesTag) {
				newShouldShowFaceBrowserView = !newShouldShowFaceBrowserView;
			} else if (tag == TKFramesTag) {
				newShouldShowFrameBrowserView = !newShouldShowFrameBrowserView;
			} else if (tag == TKMipmapsTag) {
				newShouldShowMipmapBrowserView = !newShouldShowMipmapBrowserView;
			}
		}
		
		if (newShouldShowFaceBrowserView != shouldShowFaceBrowserView) {
			shouldShowFaceBrowserView = newShouldShowFaceBrowserView;
			(shouldShowFaceBrowserView ? [self showFaceBrowserView] : [self hideFaceBrowserView]);
		}
		
		if (newShouldShowFrameBrowserView != shouldShowFrameBrowserView) {
			shouldShowFrameBrowserView = newShouldShowFrameBrowserView;
			(shouldShowFrameBrowserView ? [self showFrameBrowserView] : [self hideFrameBrowserView]);
		}
		
		if (newShouldShowMipmapBrowserView != shouldShowMipmapBrowserView) {
			shouldShowMipmapBrowserView = newShouldShowMipmapBrowserView;
			(shouldShowMipmapBrowserView ? [self showMipmapBrowserView] : [self hideMipmapBrowserView]);
		}
		
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:shouldShowFaceBrowserView] forKey:TKImageDocumentShowFaceBrowserViewKey];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:shouldShowFrameBrowserView] forKey:TKImageDocumentShowFrameBrowserViewKey];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:shouldShowMipmapBrowserView] forKey:TKImageDocumentShowMipmapBrowserViewKey];
	}
}
	

- (void)showFaceBrowserView {
	NSRect frame = [faceBrowserViewView frame];
	NSRect newFrame = NSMakeRect(frame.origin.x, frame.origin.y, faceBrowserWidth, NSHeight(frame));
	
#if TK_DEBUG
	NSLog(@"[%@ %@] [faceBrowserViewView frame] == %@, faceBrowserWidth == %.3f, newFrame == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(frame), faceBrowserWidth, NSStringFromRect(newFrame));
#endif
	
	[faceBrowserViewView setFrame:newFrame];
}


- (void)hideFaceBrowserView {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSRect frame = [faceBrowserViewView frame];
	faceBrowserWidth = NSWidth(frame);
	
#if TK_DEBUG
	NSLog(@"[%@ %@] [faceBrowserViewView frame] == %@, faceBrowserWidth == %.3f", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(frame), frameBrowserHeight);
#endif
	
	[faceBrowserViewView setFrame:NSMakeRect(frame.origin.x, frame.origin.y, 1.0, NSHeight(frame))];
	
}


- (void)showFrameBrowserView {
	NSRect frame = [frameBrowserViewView frame];
	NSRect newFrame = NSMakeRect(frame.origin.x, frame.origin.y, NSWidth(frame), frameBrowserHeight);
	
#if TK_DEBUG
	NSLog(@"[%@ %@] [frameBrowserViewView frame] == %@, frameBrowserHeight == %.3f, newFrame == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(frame), frameBrowserHeight, NSStringFromRect(newFrame));
#endif
	
	[frameBrowserViewView setFrame:newFrame];
//	[frameBrowserViewView setFrame:NSMakeRect(frame.origin.x, frame.origin.y, NSWidth(frame), frameBrowserHeight)];
}


- (void)hideFrameBrowserView {
	NSRect frame = [frameBrowserViewView frame];
	frameBrowserHeight = NSHeight(frame);
	
#if TK_DEBUG
	NSLog(@"[%@ %@] [frameBrowserViewView frame] == %@, frameBrowserHeight == %.3f", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(frame), frameBrowserHeight);
#endif
	
	[frameBrowserViewView setFrame:NSMakeRect(frame.origin.x, frame.origin.y, NSWidth(frame), 1.0)];
}


- (void)showMipmapBrowserView {
	NSRect frame = [mipmapBrowserViewView frame];
	NSRect newFrame = NSMakeRect(frame.origin.x, frame.origin.y, mipmapBrowserWidth, NSHeight(frame));
	
#if TK_DEBUG
 	NSLog(@"[%@ %@] [mipmapBrowserViewView frame] == %@, mipmapBrowserWidth == %.3f, newFrame == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(frame), mipmapBrowserWidth, NSStringFromRect(newFrame));
#endif
	
	[mipmapBrowserViewView setFrame:newFrame];
//	[mipmapBrowserViewView setFrame:NSMakeRect(frame.origin.x, frame.origin.y, mipmapBrowserWidth, NSHeight(frame))];
}


- (void)hideMipmapBrowserView {
	NSRect frame = [mipmapBrowserViewView frame];
	
	mipmapBrowserWidth = NSWidth(frame);
	
#if TK_DEBUG
	NSLog(@"[%@ %@] [mipmapBrowserViewView frame] == %@, mipmapBrowserWidth == %.3f", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(frame), mipmapBrowserWidth);
#endif
	
	[mipmapBrowserViewView setFrame:NSMakeRect(frame.origin.x, frame.origin.y, 1.0, NSHeight(frame))];
}



- (NSIndexSet *)selectedFaceIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSIndexSet *selectedFaceIndexes = [faceBrowserView selectionIndexes];
#if TK_DEBUG
	NSLog(@"[%@ %@] selectedFaceIndexes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), selectedFaceIndexes);
#endif
	NSMutableIndexSet *translatedFaceIndexes = [NSMutableIndexSet indexSet];
	if ([selectedFaceIndexes containsIndex:1]) [translatedFaceIndexes addIndex:TKFaceBack];
	if ([selectedFaceIndexes containsIndex:4]) [translatedFaceIndexes addIndex:TKFaceLeft];
	if ([selectedFaceIndexes containsIndex:5]) [translatedFaceIndexes addIndex:TKFaceUp];
	if ([selectedFaceIndexes containsIndex:6]) [translatedFaceIndexes addIndex:TKFaceRight];
	if ([selectedFaceIndexes containsIndex:7]) [translatedFaceIndexes addIndex:TKFaceDown];
	if ([selectedFaceIndexes containsIndex:9]) [translatedFaceIndexes addIndex:TKFaceFront];

	return translatedFaceIndexes;
}



- (void)setSelectedFaceIndexes:(NSIndexSet *)selectedFaceIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSMutableIndexSet *translatedFaceIndexes = [NSMutableIndexSet indexSet];
	
	if ([selectedFaceIndexes containsIndex:TKFaceBack]) [translatedFaceIndexes addIndex:1];
	if ([selectedFaceIndexes containsIndex:TKFaceLeft]) [translatedFaceIndexes addIndex:4];
	if ([selectedFaceIndexes containsIndex:TKFaceUp]) [translatedFaceIndexes addIndex:5];
	if ([selectedFaceIndexes containsIndex:TKFaceRight]) [translatedFaceIndexes addIndex:6];
	if ([selectedFaceIndexes containsIndex:TKFaceDown]) [translatedFaceIndexes addIndex:7];
	if ([selectedFaceIndexes containsIndex:TKFaceFront]) [translatedFaceIndexes addIndex:9];
	
	[faceBrowserView setSelectionIndexes:translatedFaceIndexes byExtendingSelection:NO];
}



- (TKImageRep *)selectedImageRep {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([visibleMipmapReps count]) {
		NSIndexSet *selectedMipmapIndexes = [mipmapBrowserView selectionIndexes];
		NSArray *selectedImageReps = [visibleMipmapReps objectsAtIndexes:selectedMipmapIndexes];
		return [TKImageRep largestRepresentationInArray:selectedImageReps];
	}
	return nil;
}


- (NSArray *)selectedImageReps {
	return [[visibleMipmapReps copy] autorelease];
}


- (NSUInteger)writeImageReps:(NSArray *)imageReps toPasteboard:(NSPasteboard *)pboard forTypes:(NSArray *)types {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSParameterAssert(imageReps != nil);
	
	[pboard declareTypes:types owner:self];
	
	if ([types containsObject:TKImageDocumentPboardType]) {
		NSData *imageRepData = [NSKeyedArchiver archivedDataWithRootObject:imageReps];
		if (imageRepData) [pboard setData:imageRepData forType:TKImageDocumentPboardType];
	}
	
	if ([types containsObject:NSTIFFPboardType]) {
		TKImageRep *firstImageRep = [imageReps objectAtIndex:0];
		NSData *TIFFRepresentation = [firstImageRep TIFFRepresentationUsingCompression:NSTIFFCompressionNone factor:0];
		if (TIFFRepresentation) [pboard setData:TIFFRepresentation forType:NSTIFFPboardType];
	}
	
	return [imageReps count];
}



#pragma mark -
#pragma mark <NSSplitViewDelegate>


- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSRect subviewBounds = [view bounds];
	
	if (splitView == mainSplitView) {
		if (view == facesMipmapsSplitView) {
			
		} else if (view == frameBrowserViewView) {
			
		}
		
	} else if (splitView == facesMipmapsSplitView) {
		
		if (view == faceBrowserViewView) {
			
			CGFloat idealWidth = [faceBrowserView idealViewWidth];
			
#if TK_DEBUG
//			NSLog(@"[%@ %@] subviewBounds == %@, idealWidth == %f", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(subviewBounds), idealWidth);
#endif
			if (NSWidth(subviewBounds) > idealWidth) {
				return YES;
			} else if (NSWidth(subviewBounds) <= idealWidth) {
				return NO;
			}
			
			
		} else if (view == mipmapBrowserViewView) {
			
			CGFloat idealWidth = [mipmapBrowserView idealViewWidth];
			
#if TK_DEBUG
//			NSLog(@"[%@ %@] subviewBounds == %@, idealWidth == %f", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(subviewBounds), idealWidth);
#endif
			if (NSWidth(subviewBounds) > idealWidth) {
				return YES;
			} else if (NSWidth(subviewBounds) <= idealWidth) {
				return NO;
			}
			
			
		}
		
		return YES;
		
		
	}
	return YES;
}



- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (splitView == mainSplitView) {
		if (subview == frameBrowserViewView) return YES;
		return NO;
		
	} else if (splitView == facesMipmapsSplitView) {
		if (subview == faceBrowserViewView || subview == mipmapBrowserViewView) return YES;
		return NO;
		
	}

	return YES;
}


//- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	
//	
//}
//
//
//- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	
//	
//}



#pragma mark <NSSplitViewDelegate> END 
#pragma mark -
#pragma mark <IKImageBrowserDataSource>

- (NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)aBrowser {
	
	if (aBrowser == faceBrowserView) {
#if TK_DEBUG
//		NSLog(@"[%@ %@] faceBrowserView", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		
		if (image.faceCount) {
			[visibleFaceBrowserItems setArray:[TKImageBrowserItem faceBrowserItemsWithImageRepsInArray:[image representationsForFaceIndexes:[image allFaceIndexes]
																															  mipmapIndexes:[image firstMipmapIndexSet]]]];
		} else {
			[visibleFaceBrowserItems setArray:[NSArray array]];
		}
		
		return [visibleFaceBrowserItems count];
		
	} else if (aBrowser == frameBrowserView) {
#if TK_DEBUG
//		NSLog(@"[%@ %@] frameBrowserView", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		
		if (image.faceCount && image.frameCount) {
			[visibleFrameBrowserItems setArray:[TKImageBrowserItem frameBrowserItemsWithImageRepsInArray:[image representationsForFaceIndexes:[self selectedFaceIndexes]
																																 frameIndexes:[image allFrameIndexes]
																																mipmapIndexes:[image firstMipmapIndexSet]]]];
			
		} else if (image.faceCount) {
			
			[visibleFrameBrowserItems setArray:[NSArray array]];
			
		} else if (image.frameCount) {
			
			[visibleFrameBrowserItems setArray:[TKImageBrowserItem frameBrowserItemsWithImageRepsInArray:[image representationsForFrameIndexes:[image allFrameIndexes]
																																 mipmapIndexes:[image firstMipmapIndexSet]]]];
		} else {
			[visibleFrameBrowserItems setArray:[NSArray array]];

		}
		
		return [visibleFrameBrowserItems count];

	} else if (aBrowser == mipmapBrowserView) {
#if TK_DEBUG
//		NSLog(@"[%@ %@] mipmapBrowserView", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		
		if (image.faceCount && image.frameCount) {
			
			[visibleMipmapReps setArray:[image representationsForFaceIndexes:[self selectedFaceIndexes]
																frameIndexes:[frameBrowserView selectionIndexes]
															   mipmapIndexes:[image allMipmapIndexes]]];
			
		} else if (image.faceCount) {
			
			[visibleMipmapReps setArray:[image representationsForFaceIndexes:[self selectedFaceIndexes]
															   mipmapIndexes:[image allMipmapIndexes]]];
			
		} else if (image.frameCount) {
			
			[visibleMipmapReps setArray:[image representationsForFrameIndexes:[frameBrowserView selectionIndexes]
																mipmapIndexes:[image allMipmapIndexes]]];
			
		} else {
			[visibleMipmapReps setArray:[image representationsForMipmapIndexes:[image allMipmapIndexes]]];
		}
		
		return [visibleMipmapReps count];
	}
	return 0;
}


- (id /*IKImageBrowserItem*/)imageBrowser:(IKImageBrowserView *)aBrowser itemAtIndex:(NSUInteger)anIndex {
#if TK_DEBUG
//	NSLog(@"[%@ %@] imageBrowser == %@, index == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (aBrowser == faceBrowserView ? @"faceBrowserView" : aBrowser == frameBrowserView ? @"frameBrowserView" : @"mipmapBrowserView"), (unsigned long)anIndex);
#endif
	
	if (aBrowser == faceBrowserView) {
		
		return [visibleFaceBrowserItems objectAtIndex:anIndex];
		
	} else if (aBrowser == frameBrowserView) {
		
		return [visibleFrameBrowserItems objectAtIndex:anIndex];
		
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
		return [self writeImageReps:images toPasteboard:pboard forTypes:[NSArray arrayWithObjects:TKImageDocumentPboardType, NSTIFFPboardType, nil]];
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



/*!
	@method numberOfGroupsInImageBrowser:
	@abstract Returns the number of groups
	@discussion this method is optional
*/
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
	NSString *browserName = @"<unknown>";
	
	if (aBrowser == faceBrowserView) {
		browserName = @"faceBrowserView";
	} else if (aBrowser == frameBrowserView) {
		browserName = @"frameBrowserView";
	} else if (aBrowser == mipmapBrowserView) {
		browserName = @"mipmapBrowserView";
	}
	NSLog(@"[%@ %@] aBrowser == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), browserName);
#endif
	
	if (aBrowser == faceBrowserView) {
		
		if (image.faceCount && image.frameCount) {
			[visibleFrameBrowserItems setArray:[TKImageBrowserItem frameBrowserItemsWithImageRepsInArray:[image representationsForFaceIndexes:[self selectedFaceIndexes]
																																 frameIndexes:[image allFrameIndexes]
																																mipmapIndexes:[image firstMipmapIndexSet]]]];
			
		} else if (image.faceCount) {
			
			[visibleFrameBrowserItems setArray:[NSArray array]];
			
		} else if (image.frameCount) {
			
			[visibleFrameBrowserItems setArray:[TKImageBrowserItem frameBrowserItemsWithImageRepsInArray:[image representationsForFrameIndexes:[image allFrameIndexes]
																																 mipmapIndexes:[image firstMipmapIndexSet]]]];
			
		} else {
			[visibleFrameBrowserItems setArray:[NSArray array]];
			
		}
		
		[frameBrowserView reloadData];
		[mipmapBrowserView reloadData];
		
		if ([visibleFrameBrowserItems count] && [[frameBrowserView selectionIndexes] count] == 0) {
			[frameBrowserView setSelectionIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
		}
		
	} else if (aBrowser == frameBrowserView) {
		
		if (image.faceCount && image.frameCount) {
			
			[visibleMipmapReps setArray:[image representationsForFaceIndexes:[self selectedFaceIndexes]
																frameIndexes:[frameBrowserView selectionIndexes]
															   mipmapIndexes:[image allMipmapIndexes]]];
			
		} else if (image.faceCount) {
			
			[visibleMipmapReps setArray:[image representationsForFaceIndexes:[self selectedFaceIndexes]
															   mipmapIndexes:[image allMipmapIndexes]]];
			
		} else if (image.frameCount) {
			
			[visibleMipmapReps setArray:[image representationsForFrameIndexes:[frameBrowserView selectionIndexes]
																mipmapIndexes:[image allMipmapIndexes]]];
			
		} else {
			[visibleMipmapReps setArray:[image representationsForMipmapIndexes:[image allMipmapIndexes]]];
		}
		
		[mipmapBrowserView reloadData];
		
		if ([visibleMipmapReps count]) {
			[mipmapBrowserView setSelectionIndexes:[NSIndexSet indexSetWithIndex:0]	byExtendingSelection:NO];
		}
		
		
	} else if (aBrowser == mipmapBrowserView) {
		NSIndexSet *selectionIndexes = [aBrowser selectionIndexes];
		
		if ([selectionIndexes count] == 1) {
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



/* implement/override these methods here so we can be considered a valid "First Responder"
 to them, so that our `validateMenuItem:` will be called where we can disable them  */

- (IBAction)toggleShowInspector:(id)sender {}


- (IBAction)toggleShowViewOptions:(id)sender {}


- (IBAction)toggleShowQuickLook:(id)sender {}


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
	
	BOOL isAnimating = [imageView isAnimating];
	
	if ([sender isKindOfClass:[NSSegmentedControl class]]) {
		[(NSSegmentedControl *)sender setImage:[NSImage imageNamed:(isAnimating ? @"overlayPlay" : @"overlayStop")] forSegment:0];
		[[(NSSegmentedControl *)sender cell] setToolTip:(isAnimating ? NSLocalizedString(@"Play the animated image", @"") : NSLocalizedString(@"Stop playing the animated image", @"")) forSegment:0];
	}
	[togglePlayToolbarItem setLabel:(isAnimating ? NSLocalizedString(@"Play", @"") : NSLocalizedString(@"Stop", @""))];
	
	if (isAnimating) {
		imageView.animationImageReps = nil;
	} else {
		
		imageView.animationImageReps = [image representationsForFrameIndexes:[image allFrameIndexes] mipmapIndexes:[image firstMipmapIndexSet]];
	}
	
	(isAnimating ? [imageView stopAnimating] : [imageView startAnimating]);
}



- (IBAction)toggleAutomaticallyResize:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
}


- (void)copy:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSArray *selectedImageReps = [self selectedImageReps];
	[self writeImageReps:selectedImageReps toPasteboard:[NSPasteboard generalPasteboard] forTypes:[NSArray arrayWithObjects:TKImageDocumentPboardType, NSTIFFPboardType, nil]];
}



#pragma mark - <NSMenuDelegate>

- (void)menuNeedsUpdate:(NSMenu *)menu {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	
}


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
#if TK_DEBUG
//	NSLog(@"[%@ %@] menuItem == %@, action == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), menuItem, NSStringFromSelector([menuItem action]));
#endif
	SEL action = [menuItem action];
	NSInteger tag = [menuItem tag];
	
	if (action == @selector(revealInFinder:) ||
		action == @selector(saveDocument:) ||
		action == @selector(toggleShowInspector:) ||
		action == @selector(toggleShowViewOptions:) ||
		action == @selector(toggleShowQuickLook:)) {
		return NO;
		
//	} else if (action == @selector(switchViewMode:)) {
//		// disable MDHLDocument stuff
//		return NO;
//		
	} else if (action == @selector(changeViewMode:)) {
		if (tag == TKFacesTag) {
			[menuItem setTitle:(shouldShowFaceBrowserView ? NSLocalizedString(@"Hide Faces", @"") : NSLocalizedString(@"Show Faces", @""))];
			
		} else if (tag == TKFramesTag) {
			[menuItem setTitle:(shouldShowFrameBrowserView ? NSLocalizedString(@"Hide Frames", @"") : NSLocalizedString(@"Show Frames", @""))];
			
		} else if (tag == TKMipmapsTag) {
			[menuItem setTitle:(shouldShowMipmapBrowserView ? NSLocalizedString(@"Hide Mipmaps", @"") : NSLocalizedString(@"Show Mipmaps", @""))];
			
		}
	}
	
	return YES;
}


@end




