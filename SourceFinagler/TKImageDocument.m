//
//  TKImageDocument.m
//  Texture Kit
//
//  Created by Mark Douma on 10/15/2010.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//


#import "TKImageDocument.h"
#import "TKImageExportController.h"
#import "TKImageDocumentAccessoryViewController.h"
#import "TKImageExportPreset.h"
#import "TKImageBrowserItem.h"
#import "TKBlueBackgroundView.h"
#import "TKGrayscaleFilter.h"
#import "TKImageKitAdditions.h"


#import "MDAppController.h"
#import "MDAppKitAdditions.h"


#import <Quartz/Quartz.h>

enum {
	TKFacesTag		= 1,
	TKFramesTag		= 2,
	TKMipmapsTag	= 3
};



enum {
	TKImageContentSlicesMask		= 1 << 0,
	TKImageContentFacesMask			= 1 << 1,
	TKImageContentFramesMask		= 1 << 2,
	TKImageContentMipmapsMask		= 1 << 3
};
typedef NSUInteger TKImageContentMask;


static inline TKImageContentMask TKImageContentMaskForImage(TKImage *anImage) {
	TKImageContentMask imageContentMask = 0;
	if ([anImage isDepthTexture]) imageContentMask |= TKImageContentSlicesMask;
	if ([anImage isCubemap] || [anImage isSpheremap]) imageContentMask |= TKImageContentFacesMask;
	if ([anImage isAnimated]) imageContentMask |= TKImageContentFramesMask;
	if ([anImage hasMipmaps]) imageContentMask |= TKImageContentMipmapsMask;
	return imageContentMask;
}


enum {
	TKImageDocumentViewModeShowSlicesBrowserMask			= 1 << 0,
	TKImageDocumentViewModeShowFacesBrowserMask				= 1 << 1,
	TKImageDocumentViewModeShowFramesBrowserMask			= 1 << 2,
	TKImageDocumentViewModeShowMipmapsBrowserMask			= 1 << 3
};



NSString * const TKImageDocumentViewModeMaskFormatKey					= @"TKImageDocumentViewModeMaskFormat %lu";


NSString * const TKImageDocumentShowFaceBrowserViewKey		= @"TKImageDocumentShowFaceBrowserView";
NSString * const TKImageDocumentShowFrameBrowserViewKey		= @"TKImageDocumentShowFrameBrowserView";
NSString * const TKImageDocumentShowMipmapBrowserViewKey	= @"TKImageDocumentShowMipmapBrowserView";

NSString * const TKImageDocumentPboardType					= @"TKImageDocumentPboardType";

NSString * const TKImageDocumentDoNotShowWarningAgainKey		= @"TKImageDocumentDoNotShowWarningAgain";

NSString * const TKShouldShowImageInspectorKey				= @"TKShouldShowImageInspector";

NSString * const TKShouldShowImageInspectorDidChangeNotification	= @"TKShouldShowImageInspectorDidChange";


// for the dictionary for adding draggedFilenames 
static NSString * const TKSliceIndexesKey = @"TKSliceIndexes";
static NSString * const TKFaceIndexesKey = @"TKFaceIndexes";
static NSString * const TKFrameIndexesKey = @"TKFrameIndexes";
//static NSString * const TKMipmapIndexesKey = @"TKMipmapIndexes";
static NSString * const TKDraggedFilenamesKey = @"TKDraggedFilenames";
static NSString * const TKImageRepsKey		 = @"TKImageReps";


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


@interface TKImageDocument (TKPrivate)

- (void)displayAlert;

- (NSIndexSet *)selectedFaceIndexes;
- (void)setSelectedFaceIndexes:(NSIndexSet *)faceIndexes;


- (void)showFaceBrowserView;
- (void)hideFaceBrowserView;
- (void)showFrameBrowserView;
- (void)hideFrameBrowserView;
- (void)showMipmapBrowserView;
- (void)hideMipmapBrowserView;


- (void)reloadData;

- (TKImageRep *)selectedImageRep;

- (NSArray *)selectedImageReps;


- (NSUInteger)writeImageReps:(NSArray *)imageReps toPasteboard:(NSPasteboard *)pboard forTypes:(NSArray *)types;


- (BOOL)generateMipmapsUsingFilter:(TKMipmapGenerationType)aFilter;
- (BOOL)removeGeneratedMipmapsUsingFilter:(TKMipmapGenerationType)aFilter;


/* for static, non-animated texture images */
- (BOOL)insertRepresentations:(NSArray *)representations atMipmapIndexes:(NSIndexSet *)mipmapIndexes;
- (BOOL)removeRepresentations:(NSArray *)representations atMipmapIndexes:(NSIndexSet *)mipmapIndexes;
- (BOOL)moveRepresentations:(NSArray *)representations fromMipmapIndexes:(NSIndexSet *)fromMipmapIndexes toMipmapIndexes:(NSIndexSet *)toMipmapIndexes;



/* for animated (multi-frame) texture images */
- (BOOL)insertRepresentations:(NSArray *)representations atFrameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes;
- (BOOL)removeRepresentations:(NSArray *)representations atFrameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes;
- (BOOL)moveRepresentations:(NSArray *)representations fromFrameIndexes:(NSIndexSet *)fromFrameIndexes mipmapIndexes:(NSIndexSet *)fromMipmapIndexes toFrameIndexes:(NSIndexSet *)toFrameIndexes mipmapIndexes:(NSIndexSet *)toMipmapIndexes;



/* for multi-sided texture images */
- (BOOL)insertRepresentations:(NSArray *)representations atFaceIndexes:(NSIndexSet *)faceIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes;
- (BOOL)removeRepresentations:(NSArray *)representations atFaceIndexes:(NSIndexSet *)faceIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes;
- (BOOL)moveRepresentations:(NSArray *)representations fromFaceIndexes:(NSIndexSet *)fromFaceIndexes mipmapIndexes:(NSIndexSet *)fromMipmapIndexes toFaceIndexes:(NSIndexSet *)toFaceIndexes mipmapIndexes:(NSIndexSet *)toMipmapIndexes;



/* for animated (multi-frame), multi-sided texture images */
- (BOOL)insertRepresentations:(NSArray *)representations atFaceIndexes:(NSIndexSet *)faceIndexes frameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes;
- (BOOL)removeRepresentations:(NSArray *)representations atFaceIndexes:(NSIndexSet *)faceIndexes frameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes;
- (BOOL)moveRepresentations:(NSArray *)representations fromFaceIndexes:(NSIndexSet *)fromFaceIndexes frameIndexes:(NSIndexSet *)fromFrameIndexes mipmapIndexes:(NSIndexSet *)fromMipmapIndexes toFaceIndexes:(NSIndexSet *)toFaceIndexes frameIndexes:(NSIndexSet *)toFrameIndexes mipmapIndexes:(NSIndexSet *)toMipmapIndexes;

- (void)applyChannelMasks;

- (void)performLoadOfImageFilesInBackgroundThread:(id)sender;

- (void)finishLoadOfImageRepsOnMainThread:(id)sender;


@end


@implementation TKImageDocument


@synthesize draggedFilenames;

@synthesize image, dimensions, shouldShowFrameBrowserView, shouldShowMipmapBrowserView;
@synthesize shouldShowFaceBrowserView;

@synthesize exportPreset;

@synthesize redScale;
@synthesize greenScale;
@synthesize blueScale;
@synthesize alphaScale;

@synthesize small;
@synthesize medium;
@synthesize big;
@synthesize large;

@synthesize normalMapWrapMode;

@synthesize normalizeMipmaps;

@synthesize imageInspectorController;

@synthesize grayscaleFilter;

@synthesize currentMenuBrowserView;


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
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
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
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
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
+ (BOOL)isNativeType:(NSString *)aType {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
    return [[self writableTypes] containsObject:aType];
}


- (id)init {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
    if ((self = [super init])) {
		
		redScale = 1.0/3.0;
		greenScale = 1.0/3.0;
		blueScale = 1.0/3.0;
		alphaScale = 0.0;
		
		small = 1.0;
		medium = 0.5;
		big = 0.25;
		large = 0.125;
		
		normalizeMipmaps = YES;

		
		visibleFaceBrowserItems = [[NSMutableArray alloc] init];
		visibleFrameBrowserItems = [[NSMutableArray alloc] init];
		
		visibleMipmapReps = [[NSMutableArray alloc] init];
		
		shouldShowFaceBrowserView = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentShowFaceBrowserViewKey] boolValue];
		shouldShowFrameBrowserView = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentShowFrameBrowserViewKey] boolValue];
		shouldShowMipmapBrowserView = [[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentShowMipmapBrowserViewKey] boolValue];
		
//		imageChannels = [[NSMutableArray alloc] init];
		
		imageChannelMask = TKImageChannelRGBAMask;
    }
    return self;
}


- (void)dealloc {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[imageView setDelegate:nil];
	
	[image release];
	[metadata release];
	[dimensions release];
	[saveOptions release];
	
	[visibleFaceBrowserItems release];
	[visibleFrameBrowserItems release];
	
	[visibleMipmapReps release];
	
	[imageExportController release];
	
	[accessoryViewController release];
	
	[exportPreset release];
	
	[grayscaleFilter release];
	
	[imageChannelNamesAndFilters release];
	[imageChannels release];
	
	[draggedFilenames release];
	
	[super dealloc];
}


- (NSString *)windowNibName {
	if (MDGetSystemVersion() >= MDLion) {
		return @"TKImageDocumentLion";
	}
    return @"TKImageDocument";
}


- (id)initWithType:(NSString *)typeName error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@] typeName == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), typeName);
#endif
	if ((self = [super initWithType:typeName error:outError])) {
		image = [[TKImage alloc] initWithSize:NSMakeSize(512.0, 512.0)];
		
	}
	return self;
}



- (BOOL)readFromURL:(NSURL *)absURL ofType:(NSString *)typeName error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@] typeName == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), typeName);
#endif
	
	NSData *imageData = [NSData dataWithContentsOfURL:absURL];
	if (imageData) image = [[TKImage alloc] initWithData:imageData];
	
	if (image) [self setDimensions:[NSString stringWithFormat:@"%lu x %lu", (unsigned long)[image size].width, (unsigned long)[image size].height]];
	
#if TK_DEBUG
	NSLog(@"[%@ %@] image == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), image);
#endif
	
	return (image != nil);
}



- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@] typeName == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), typeName);
#endif
	
	BOOL success = NO;
	
	if ([[accessoryViewController imageUTType] isEqualToString:TKDDSType]) {
		NSData *fileData = [image DDSRepresentationUsingFormat:[accessoryViewController ddsFormat] quality:[TKImageRep defaultDXTCompressionQuality] options:nil];
		if (fileData) {
			success = [fileData writeToURL:absoluteURL options:NSDataWritingAtomic error:outError];
		}
	} else if ([[accessoryViewController imageUTType] isEqualToString:TKVTFType]) {
		NSData *fileData = [image VTFRepresentationUsingFormat:[accessoryViewController vtfFormat] quality:[TKImageRep defaultDXTCompressionQuality] options:nil];
		if (fileData) {
			success = [fileData writeToURL:absoluteURL options:NSDataWritingAtomic error:outError];
		}
		
	} else if ([[accessoryViewController imageUTType] isEqualToString:TKSFTextureImageType]) {
		NSData *archiveData = [NSKeyedArchiver archivedDataWithRootObject:image];
		if (archiveData) {
			success = [archiveData writeToURL:absoluteURL options:NSDataWritingAtomic error:outError];
		}
		
	} else {
		// ImageIO
		NSData *fileData = [image dataForType:[accessoryViewController imageUTType] properties:[accessoryViewController imageProperties]];
		if (fileData) {
			success = [fileData writeToURL:absoluteURL options:NSDataWritingAtomic error:outError];
		}
	}
	
//	[[NSUserDefaults standardUserDefaults] setObject:[accessoryController imageUTType] forKey:TKImageDocumentLastSavedFormatTypeKey];
	
	return success;
}



- (void)awakeFromNib {
//	[self addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
//	[self bind:(NSString *)binding toObject:imageView withKeyPath:@"zoomFactor" options:(NSDictionary *)options
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
	
#if TK_DEBUG
	NSLog(@"[%@ %@] image == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), image);
#endif
	
	
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
	
	
	if ([image faceCount]) {
		[faceBrowserView setSelectionIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	}
	
//	[frameBrowserView reloadData];
	
	NSLog(@"[%@ %@] reloaded frameBrowserView, setting selection", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
//	if ([image faceCount] > 0) {
//		[faceBrowserView setSelectionIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
//	}
	
	if ([image frameCount]) {
		[frameBrowserView setSelectionIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	}
	
	if ([image mipmapCount]) {
		[mipmapBrowserView setSelectionIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	}
	
	
	
	if (togglePlaySegmentedControl && ([image frameCount] < 1)) {
		[togglePlaySegmentedControl setEnabled:NO forSegment:0];
	}
	
	if ([[[NSUserDefaults standardUserDefaults] objectForKey:TKImageDocumentDoNotShowWarningAgainKey] boolValue] == NO) {
		[self performSelector:@selector(displayAlert) withObject:nil afterDelay:0.0];
	}
	
	[mipmapBrowserView setAllowsReordering:NO];
	
	[frameBrowserView setDraggingDestinationDelegate:self];
	
}


- (void)displayAlert {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
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
		[imageExportController cleanup];
		[imageExportController release];
		imageExportController = nil;
		
		[accessoryViewController cleanup];
		[accessoryViewController release];
		accessoryViewController = nil;
		
		if (imageInspectorController) {
			[imageInspectorController setDataSource:nil];
			[imageInspectorController reloadData];
			imageInspectorController = nil;
		}
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


- (IBAction)importImageSequence:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowedFileTypes:[NSArray arrayWithObjects:(id)kUTTypeImage, nil]];
	[openPanel setAllowsMultipleSelection:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setCanChooseFiles:YES];
	
	[openPanel beginSheetModalForWindow:imageWindow completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			NSArray *URLs = [openPanel URLs];
			
			NSMutableArray *filePaths = [NSMutableArray array];
			
			for (NSURL *URL in URLs) {
				NSString *filePath = [URL path];
				if (filePath) [filePaths addObject:filePath];
			}
			
			[filePaths sortUsingSelector:@selector(caseInsensitiveNumericalCompare:)];
			
			NSMutableArray *imageReps = [NSMutableArray array];
			
			for (NSString *filePath in filePaths) {
				TKImageRep *anImageRep = [TKImageRep imageRepWithContentsOfFile:filePath];
				if (anImageRep) [imageReps addObject:anImageRep];
			}
			
			if (![self insertRepresentations:imageReps atFrameIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [imageReps count])] mipmapIndexes:[NSIndexSet indexSetWithIndex:0]]) {
				
				
			}
		}
		
	
	}];
	
//	[self reloadData];
	
}




- (BOOL)prepareSavePanel:(NSSavePanel *)aSavePanel {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (accessoryViewController == nil) accessoryViewController = [[TKImageDocumentAccessoryViewController alloc] initWithImageDocument:self];

	return [accessoryViewController prepareSavePanel:aSavePanel];
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
		NSString *initialFilename = nil;
		
		if ([self fileURL] == nil) {
			initialFilename = [@"Untitled" stringByAppendingPathExtension:fileType];
		} else {
			initialFilename = [[[[[self fileURL] path] lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:fileType];
		}
		
		NSLog(@"[%@ %@] initialFilename == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), initialFilename);

		[savePanel setAllowedFileTypes:[NSArray arrayWithObjects:[[exportPreset fileType] lowercaseString], nil]];
		NSLog(@"[%@ %@] allowedFileTypes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [savePanel allowedFileTypes]);
		
		[savePanel setNameFieldStringValue:initialFilename];
		
		[savePanel beginSheetModalForWindow:imageWindow completionHandler:^(NSInteger result) {
			if (result == NSFileHandlingPanelOKButton) {
				NSURL *URL = [savePanel URL];
				
				NSData *imageData = nil;
				
				if ([[[exportPreset fileType] lowercaseString] isEqualToString:TKVTFFileType]) {
					
					imageData = [TKVTFImageRep VTFRepresentationOfImageRepsInArray:[image representations] usingPreset:exportPreset];
					
				} else if ([[[exportPreset fileType] lowercaseString] isEqualToString:TKDDSFileType]) {
					
					imageData = [TKDDSImageRep DDSRepresentationOfImageRepsInArray:[image representations] usingPreset:exportPreset];
				}
				
				if (imageData) {
					NSError *outError = nil;
					if (![imageData writeToURL:URL options:NSDataWritingAtomic error:&outError]) {
						NSLog(@"[%@ %@] failed to write imageData to URL, error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), outError);
						
					}
				}
			}
		}];
	}
	
}


//- (void)exportSavePanelDidEnd:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	
//	if (returnCode == NSOKButton) {
//		NSURL *URL = [sheet URL];
//		
//		NSData *imageData = nil;
//		
//		if ([[[exportPreset fileType] lowercaseString] isEqualToString:TKVTFFileType]) {
//			
//			imageData = [TKVTFImageRep VTFRepresentationOfImageRepsInArray:[image representations] usingPreset:exportPreset];
//			
//		} else if ([[[exportPreset fileType] lowercaseString] isEqualToString:TKDDSFileType]) {
//			
//			imageData = [TKDDSImageRep DDSRepresentationOfImageRepsInArray:[image representations] usingPreset:exportPreset];
//		}
//		
//		if (imageData) {
//			NSError *outError = nil;
//			if (![imageData writeToURL:URL options:NSDataWritingAtomic error:&outError]) {
//				NSLog(@"[%@ %@] failed to write imageData to URL, error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), outError);
//	
//			}
//		}
//		
//	}
//	
//	[sheet orderOut:self];
//}


- (IBAction)grayscale:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[grayscalePanel makeKeyAndOrderFront:nil];
}


- (IBAction)previewGrayscale:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (grayscaleFilter == nil) grayscaleFilter = [[TKGrayscaleFilter alloc] init];

	TKImageRep *selectedImageRep = [self selectedImageRep];
	if (selectedImageRep == nil) return;
	
//	if (imageView.imageKitLayer.filters == nil) 
//		imageView.imageKitLayer.filters = [NSArray arrayWithObjects:grayscaleFilter, nil];
//	
//	[imageView.imageKitLayer setValue:[NSNumber numberWithDouble:redScale] forKeyPath:@"filters.grayscaleFilter.redScale"];
//	[imageView.imageKitLayer setValue:[NSNumber numberWithDouble:greenScale] forKeyPath:@"filters.grayscaleFilter.greenScale"];
//	[imageView.imageKitLayer setValue:[NSNumber numberWithDouble:blueScale] forKeyPath:@"filters.grayscaleFilter.blueScale"];
//	[imageView.imageKitLayer setValue:[NSNumber numberWithDouble:alphaScale] forKeyPath:@"filters.grayscaleFilter.alphaScale"];
	
}


- (IBAction)applyGrayscale:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
//	imageView.imageKitLayer.filters = nil;
}



- (IBAction)normalMap:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[normalMapPanel makeKeyAndOrderFront:nil];
	
}


- (IBAction)previewNormalMap:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	TKImageRep *sourceImageRep = [image representationForMipmapIndex:0];
	
	CIVector *heightFactors = [CIVector vectorWithX:redScale Y:greenScale Z:blueScale W:alphaScale];
	CIVector *filterFactor = [CIVector vectorWithX:small Y:medium Z:big W:large];
	
	
	NSArray *normalMapImageReps = [sourceImageRep imageRepsByApplyingNormalMapFilterWithHeightEvaluationWeights:heightFactors
																								  filterWeights:filterFactor
																									   wrapMode:normalMapWrapMode
																							   normalizeMipmaps:normalizeMipmaps
																							   normalMapLibrary:TKNormalMapLibraryUseNVIDIATextureTools];
	
	if (normalMapImageReps && [normalMapImageReps count]) {
		TKImageRep *normalMapImageRep = [normalMapImageReps objectAtIndex:0];
		
		[imageView setPreviewImageRep:normalMapImageRep];
	}
}



- (IBAction)applyNormalMap:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	
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
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSRect frame = [faceBrowserViewView frame];
	NSRect newFrame = NSMakeRect(frame.origin.x, frame.origin.y, faceBrowserWidth, NSHeight(frame));
	NSLog(@"[%@ %@] [faceBrowserViewView frame] == %@, faceBrowserWidth == %.3f, newFrame == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRect(frame), faceBrowserWidth, NSStringFromRect(newFrame));
	
	[faceBrowserViewView setFrame:newFrame];
}


- (void)hideFaceBrowserView {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSRect frame = [faceBrowserViewView frame];
	faceBrowserWidth = NSWidth(frame);
	
	
	[faceBrowserViewView setFrame:NSMakeRect(frame.origin.x, frame.origin.y, 1.0, NSHeight(frame))];
	
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
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (aBrowser == faceBrowserView) {
#if TK_DEBUG
		NSLog(@"[%@ %@] faceBrowserView", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		
		if ([image faceCount]) {
			[visibleFaceBrowserItems setArray:[TKImageBrowserItem faceBrowserItemsWithImageRepsInArray:[image representationsForFaceIndexes:[image allFaceIndexes]
																															  mipmapIndexes:[image firstMipmapIndexSet]]]];
		} else {
			[visibleFaceBrowserItems setArray:[NSArray array]];
		}
		
		return [visibleFaceBrowserItems count];
		
	} else if (aBrowser == frameBrowserView) {
#if TK_DEBUG
		NSLog(@"[%@ %@] frameBrowserView", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		
		if ([image faceCount] && [image frameCount]) {
			[visibleFrameBrowserItems setArray:[TKImageBrowserItem frameBrowserItemsWithImageRepsInArray:[image representationsForFaceIndexes:[self selectedFaceIndexes]
																																 frameIndexes:[image allFrameIndexes]
																																mipmapIndexes:[image firstMipmapIndexSet]]]];
			
		} else if ([image faceCount]) {
			
			[visibleFrameBrowserItems setArray:[NSArray array]];
			
		} else if ([image frameCount]) {
			
			[visibleFrameBrowserItems setArray:[TKImageBrowserItem frameBrowserItemsWithImageRepsInArray:[image representationsForFrameIndexes:[image allFrameIndexes]
																																 mipmapIndexes:[image firstMipmapIndexSet]]]];
		} else {
			[visibleFrameBrowserItems setArray:[NSArray array]];

		}
		
		return [visibleFrameBrowserItems count];

	} else if (aBrowser == mipmapBrowserView) {
#if TK_DEBUG
		NSLog(@"[%@ %@] mipmapBrowserView", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		
		if ([image faceCount] && [image frameCount]) {
			
			[visibleMipmapReps setArray:[image representationsForFaceIndexes:[self selectedFaceIndexes]
																frameIndexes:[frameBrowserView selectionIndexes]
															   mipmapIndexes:[image allMipmapIndexes]]];
			
		} else if ([image faceCount]) {
			
			[visibleMipmapReps setArray:[image representationsForFaceIndexes:[self selectedFaceIndexes]
															   mipmapIndexes:[image allMipmapIndexes]]];
			
		} else if ([image frameCount]) {
			
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
	NSLog(@"[%@ %@] imageBrowser == %@, index == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (aBrowser == faceBrowserView ? @"faceBrowserView" : aBrowser == frameBrowserView ? @"frameBrowserView" : @"mipmapBrowserView"), (unsigned long)anIndex);
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
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
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


/*! 
  @method imageBrowser:removeItemsAtIndexes:
  @abstract Invoked by the image browser after it has been determined that a remove operation should be applied (optional)
  @discussion The data source should update itself (usually by removing this indexes).  
*/
- (void)imageBrowser:(IKImageBrowserView *)aBrowser removeItemsAtIndexes:(NSIndexSet *)indexes {
#if TK_DEBUG
	NSLog(@"[%@ %@] imageBrowser == %@, indexes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (aBrowser == faceBrowserView ? @"faceBrowserView" : aBrowser == frameBrowserView ? @"frameBrowserView" : @"mipmapBrowserView"), indexes);
#endif
	
	if (aBrowser == faceBrowserView) {
		NSMutableArray *faceBrowserImageReps = [NSMutableArray array];
		
		for (TKImageBrowserItem *faceBrowserItem in visibleFaceBrowserItems) {
			TKImageRep *tkImageRep = [faceBrowserItem imageRep];
			if (tkImageRep) [faceBrowserImageReps addObject:tkImageRep];
		}
		
		
		
	} else if (aBrowser == frameBrowserView) {
		NSMutableArray *frameBrowserImageReps = [NSMutableArray array];
		
		for (TKImageBrowserItem *frameBrowserItem in visibleFrameBrowserItems) {
			TKImageRep *tkImageRep = [frameBrowserItem imageRep];
			if (tkImageRep) [frameBrowserImageReps addObject:tkImageRep];
		}
		
		NSArray *allFrameBrowserImageReps = nil;
		
		if ([image faceCount] && [image frameCount]) {
			allFrameBrowserImageReps = [image representationsForFaceIndexes:[self selectedFaceIndexes]
															   frameIndexes:indexes
															  mipmapIndexes:[image allMipmapIndexes]];
		} else if ([image frameCount]) {
			allFrameBrowserImageReps = [image representationsForFrameIndexes:indexes
															   mipmapIndexes:[image allMipmapIndexes]];
		}
		
		
		
#if TK_DEBUG
		NSLog(@"[%@ %@] frameBrowserImageReps == %@, allFrameBrowserImageReps == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), frameBrowserImageReps, allFrameBrowserImageReps);
#endif
		
		if ([image faceCount] && [image frameCount]) {
			if (![self removeRepresentations:allFrameBrowserImageReps
							   atFaceIndexes:[self selectedFaceIndexes]
								frameIndexes:indexes
							   mipmapIndexes:[image allMipmapIndexes]]) {
				
				NSLog(@"[%@ %@] failed to remove reps!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
				
			}
			
		} else if ([image frameCount]) {
			if (![self removeRepresentations:allFrameBrowserImageReps atFrameIndexes:indexes mipmapIndexes:[image allMipmapIndexes]]) {
				NSLog(@"[%@ %@] failed to remove reps!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
				
			}
		}
		
		
//		if (![self removeRepresentations:frameBrowserImageReps atFrameIndexes:indexes mipmapIndexes:[image allMipmapIndexes]]) {
//			NSLog(@"[%@ %@] failed to remove reps!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//		}
		
	} else if (aBrowser == mipmapBrowserView) {
		
		if ([image faceCount] && [image frameCount]) {
			if (![self removeRepresentations:[visibleMipmapReps objectsAtIndexes:indexes]
							   atFaceIndexes:[self selectedFaceIndexes]
								frameIndexes:[frameBrowserView selectionIndexes]
							   mipmapIndexes:indexes]) {
				
				NSLog(@"[%@ %@] failed to remove reps!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			}
			
		} else if ([image faceCount]) {
			if (![self removeRepresentations:[visibleMipmapReps objectsAtIndexes:indexes]
							   atFaceIndexes:[self selectedFaceIndexes]
							   mipmapIndexes:indexes]) {
				
				NSLog(@"[%@ %@] failed to remove reps!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			}
			
		} else if ([image frameCount]) {
			if (![self removeRepresentations:[visibleMipmapReps objectsAtIndexes:indexes]
							  atFrameIndexes:[frameBrowserView selectionIndexes]
							   mipmapIndexes:indexes]) {
				
				NSLog(@"[%@ %@] failed to remove reps!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			}
			
		} else {
			
			if (![self removeRepresentations:[visibleMipmapReps objectsAtIndexes:indexes]
							 atMipmapIndexes:indexes]) {
				
				NSLog(@"[%@ %@] failed to remove reps!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			}
			
		}
		
		
		
	}
	
	
}


/*! 
  @method imageBrowser:moveItemsAtIndexes:toIndex:
  @abstract Invoked by the image browser after it has been determined that a reordering operation should be applied (optional).
  @discussion The data source should update itself (usually by reordering its elements).  
*/
- (BOOL)imageBrowser:(IKImageBrowserView *)aBrowser moveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)destinationIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@] imageBrowser == %@, indexes == %@, destinationIndex == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (aBrowser == faceBrowserView ? @"faceBrowserView" : aBrowser == frameBrowserView ? @"frameBrowserView" : @"mipmapBrowserView"), indexes, (unsigned long)destinationIndex);
#endif
	
	if (aBrowser == faceBrowserView) {
		
	} else if (aBrowser == frameBrowserView) {
		
		if ([image faceCount] && [image frameCount]) {
			NSArray *allFrameBrowserImageReps = [image representationsForFaceIndexes:[self selectedFaceIndexes] frameIndexes:indexes mipmapIndexes:[image allMipmapIndexes]];
			
			return [self moveRepresentations:allFrameBrowserImageReps fromFaceIndexes:[self selectedFaceIndexes] frameIndexes:indexes mipmapIndexes:[image allMipmapIndexes]
																		toFaceIndexes:[self selectedFaceIndexes] frameIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(destinationIndex, [indexes count])] mipmapIndexes:[image allMipmapIndexes]];
			
			
		} else if ([image frameCount]) {
			NSArray *allFrameBrowserImageReps = [image representationsForFrameIndexes:indexes mipmapIndexes:[image allMipmapIndexes]];
			
			return [self moveRepresentations:allFrameBrowserImageReps fromFrameIndexes:indexes mipmapIndexes:[image allMipmapIndexes]
																		toFrameIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(destinationIndex, [indexes count])] mipmapIndexes:[image allMipmapIndexes]];
			
		}
		
	} else if (aBrowser == mipmapBrowserView) {
		
		
		
		
	}
	return NO;
}




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
	
	self.currentMenuBrowserView = aBrowser;

	if (aBrowser == faceBrowserView) {
		
		if ([image faceCount] && [image frameCount]) {
			[visibleFrameBrowserItems setArray:[TKImageBrowserItem frameBrowserItemsWithImageRepsInArray:[image representationsForFaceIndexes:[self selectedFaceIndexes]
																																 frameIndexes:[image allFrameIndexes]
																																mipmapIndexes:[image firstMipmapIndexSet]]]];
			
		} else if ([image faceCount]) {
			
			[visibleFrameBrowserItems setArray:[NSArray array]];
			
		} else if ([image frameCount]) {
			
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
		
		if ([image faceCount] && [image frameCount]) {
			
			[visibleMipmapReps setArray:[image representationsForFaceIndexes:[self selectedFaceIndexes]
																frameIndexes:[frameBrowserView selectionIndexes]
															   mipmapIndexes:[image allMipmapIndexes]]];
			
		} else if ([image faceCount]) {
			
			[visibleMipmapReps setArray:[image representationsForFaceIndexes:[self selectedFaceIndexes]
															   mipmapIndexes:[image allMipmapIndexes]]];
			
		} else if ([image frameCount]) {
			
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
			
			if (imageInspectorController) {
				if (imageChannels == nil) {
					imageChannels = [[NSMutableArray alloc] init];
					[imageChannels setArray:[TKImageChannel imageChannelsWithImageRep:imageRep]];
					
				} else {
					
					[imageChannels makeObjectsPerformSelector:@selector(updateWithImageRep:) withObject:imageRep];
					
				}
				
				[imageInspectorController reloadData];
			}
			
			
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
	self.currentMenuBrowserView = aBrowser;
}


- (void)imageBrowser:(IKImageBrowserView *)aBrowser backgroundWasRightClickedWithEvent:(NSEvent *)event {
#if TK_DEBUG
	NSLog(@"[%@ %@] event == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), event);
#endif
	self.currentMenuBrowserView = aBrowser;
}



- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@] draggingInfo == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sender);
#endif
	NSPasteboard *pboard = [sender draggingPasteboard];
	NSArray *droppedFilenames = [pboard propertyListForType:NSFilenamesPboardType];
	
	if (droppedFilenames == nil) return NSDragOperationNone;
	
	for (NSString *filePath in droppedFilenames) {
		NSString *utiType = [[NSWorkspace sharedWorkspace] typeOfFile:filePath error:NULL];
		if (utiType) {
			if (![[NSWorkspace sharedWorkspace] type:utiType conformsToType:(NSString *)kUTTypeImage]) {
				NSLog(@"[%@ %@] file at path == %@ doesn't conform to kUTTypeImage!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), filePath);
				return NSDragOperationNone;
			}
		}
	}
	
	self.draggedFilenames = droppedFilenames;
	
	return NSDragOperationEvery;
}


- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@] draggingInfo == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sender);
#endif
	return NSDragOperationEvery;
}


- (void)draggingExited:(id <NSDraggingInfo>)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@] draggingInfo == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sender);
#endif
	self.draggedFilenames = nil;
}


- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@] draggingInfo == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sender);
#endif
	return YES;
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@] draggingInfo == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sender);
#endif
	
	NSUInteger indexAtLocationOfDroppedItem = [frameBrowserView indexAtLocationOfDroppedItem];
	
#if TK_DEBUG
	NSLog(@"[%@ %@] indexAtLocationOfDroppedItem == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)indexAtLocationOfDroppedItem);
#endif
	
	NSArray *copiedFilenames = [[draggedFilenames copy] autorelease];
	
	NSMutableDictionary *dragDict = [NSMutableDictionary dictionary];
	
	[dragDict setObject:copiedFilenames forKey:TKDraggedFilenamesKey];
	
	if ([image faceCount] && [image frameCount]) {
		[dragDict setObject:[self selectedFaceIndexes] forKey:TKFaceIndexesKey];
		[dragDict setObject:[NSIndexSet indexSetWithIndex:indexAtLocationOfDroppedItem] forKey:TKFrameIndexesKey];
		
		
	} else if ([image faceCount]) {
		
		[dragDict setObject:[self selectedFaceIndexes] forKey:TKFaceIndexesKey];
		[dragDict setObject:[NSIndexSet indexSetWithIndex:indexAtLocationOfDroppedItem] forKey:TKFrameIndexesKey];

	} else if ([image frameCount]) {
		
		[dragDict setObject:[NSIndexSet indexSetWithIndex:indexAtLocationOfDroppedItem] forKey:TKFrameIndexesKey];
		
	} else {
		[dragDict setObject:[NSIndexSet indexSetWithIndex:indexAtLocationOfDroppedItem] forKey:TKFrameIndexesKey];

	}
	
	
	[NSThread detachNewThreadSelector:@selector(performLoadOfImageFilesInBackgroundThread:) toTarget:self withObject:dragDict];
	
	return YES;
}


- (void)performLoadOfImageFilesInBackgroundThread:(id)sender {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	static NSUInteger imageImportThreadCounter = 0;
	
	imageImportThreadCounter++;
	
	NSThread *currentThread = [NSThread currentThread];
	[currentThread setName:[NSString stringWithFormat:@"imageImportThread %lu", (unsigned long)imageImportThreadCounter]];
	
#if TK_DEBUG
	NSLog(@"[%@ %@] - %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [currentThread name]);
#endif
	
	NSMutableDictionary *dragDict = (NSMutableDictionary *)sender;
	
	NSArray *filePaths = [dragDict objectForKey:TKDraggedFilenamesKey];
	
	NSMutableArray *theImageReps = [NSMutableArray array];
	
	NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
	BOOL isDir;
	
	for (NSString *filePath in filePaths) {
		if ([fileManager fileExistsAtPath:filePath isDirectory:&isDir] && !isDir) {
			TKImageRep *tkImageRep = [TKImageRep imageRepWithContentsOfFile:filePath];
			if (tkImageRep) [theImageReps addObject:tkImageRep];
		}
	}
	
	NSIndexSet *targetIndexSet = [dragDict objectForKey:TKFrameIndexesKey];
	
	NSMutableIndexSet *frameIndexes = nil;
	
	if (targetIndexSet) {
		frameIndexes = [[[NSMutableIndexSet alloc] initWithIndexSet:targetIndexSet] autorelease];
		NSUInteger firstIndex = [targetIndexSet firstIndex];
		
		[frameIndexes addIndexesInRange:NSMakeRange(firstIndex, [theImageReps count])];
		
		
	} else {
		frameIndexes = [NSMutableIndexSet indexSet];
		[frameIndexes addIndexesInRange:NSMakeRange(0, [theImageReps count])];
		
	}
	
	[dragDict setObject:frameIndexes forKey:TKFrameIndexesKey];
	[dragDict setObject:theImageReps forKey:TKImageRepsKey];
	
	[self performSelectorOnMainThread:@selector(finishLoadOfImageRepsOnMainThread:) withObject:dragDict waitUntilDone:NO];
	
	[pool release];
}


- (void)finishLoadOfImageRepsOnMainThread:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSMutableDictionary *dragDict = (NSMutableDictionary *)sender;
	
	NSIndexSet *sliceIndexes = [dragDict objectForKey:TKSliceIndexesKey];
	NSIndexSet *faceIndexes = [dragDict objectForKey:TKFaceIndexesKey];
	NSIndexSet *frameIndexes = [dragDict objectForKey:TKFrameIndexesKey];
//	NSIndexSet *mipmapIndexes = [dragDict objectForKey:TKMipmapIndexesKey];
	
	NSArray *theImageReps = [dragDict objectForKey:TKImageRepsKey];
	
	if (sliceIndexes) {
		
	} else if (faceIndexes && frameIndexes) {
		if (![self insertRepresentations:theImageReps atFaceIndexes:(faceIndexes ? faceIndexes : [self selectedFaceIndexes]) frameIndexes:frameIndexes mipmapIndexes:[NSIndexSet indexSetWithIndex:0]]) {
			
		}
		
	} else if (faceIndexes) {
		if (![self insertRepresentations:theImageReps atFaceIndexes:(faceIndexes ? faceIndexes : [self selectedFaceIndexes]) mipmapIndexes:[NSIndexSet indexSetWithIndex:0]]) {
			
		}
		
	} else if (frameIndexes) {
		if (![self insertRepresentations:theImageReps atFrameIndexes:frameIndexes mipmapIndexes:[NSIndexSet indexSetWithIndex:0]]) {
			
		}
		
		
	} else {
		
		
	}
	
//	[self reloadData];
	
}


#pragma mark <IKImageBrowserDelegate> END 
#pragma mark -
#pragma mark <TKImageInspectorDataSource>


- (BOOL)acceptsImageInspectorControl:(TKImageInspectorController *)controller {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return YES;
}


- (void)beginImageInspectorControl:(TKImageInspectorController *)controller {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	self.imageInspectorController = controller;
	imageInspectorController.dataSource = self;
	
	if (imageChannels == nil) {
		TKImageRep *selectedImageRep = [self selectedImageRep];
		if (selectedImageRep == nil) {
			NSArray *reps = [image representations];
			if ([reps count]) {
				selectedImageRep = [TKImageRep largestRepresentationInArray:reps];
			}
		}
		imageChannels = [[NSMutableArray alloc] init];
		[imageChannels setArray:[TKImageChannel imageChannelsWithImageRep:selectedImageRep]];
	}
	
	[controller reloadData];
}


- (void)endImageInspectorControl:(TKImageInspectorController *)controller {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	imageInspectorController.dataSource = nil;
	self.imageInspectorController = nil;
	
	[controller reloadData];
}


- (NSUInteger)numberOfImageChannelsInImageInspector:(TKImageInspectorController *)inspector {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [imageChannels count];
}


- (TKImageChannel *)imageChannelAtIndex:(NSUInteger)anIndex {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [imageChannels objectAtIndex:anIndex];
}


- (void)imageInspectorController:(TKImageInspectorController *)inspectorController didEnableImageChannel:(TKImageChannel *)aChannel {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	imageChannelMask |= [aChannel channelMask];
	[self applyChannelMasks];
}


- (void)imageInspectorController:(TKImageInspectorController *)inspectorController didDisableImageChannel:(TKImageChannel *)aChannel {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	imageChannelMask &= ~[aChannel channelMask];
	[self applyChannelMasks];
}

#pragma mark <TKImageInspectorDataSource> END 
#pragma mark -


- (void)setupImageChannelMasksIfNecessary {
	if (imageChannelNamesAndFilters == nil) {
		imageChannelNamesAndFilters = [[NSMutableDictionary alloc] init];
		
//		TKImageRep *selectedImageRep = [self selectedImageRep];
		
		CIFilter *redChannelFilter = [CIFilter filterForChannelMask:TKImageChannelRedMask];
		redChannelFilter.name = @"redChannelFilter";
		CIFilter *greenChannelFilter = [CIFilter filterForChannelMask:TKImageChannelGreenMask];
		greenChannelFilter.name = @"greenChannelFilter";
		CIFilter *blueChannelFilter = [CIFilter filterForChannelMask:TKImageChannelBlueMask];
		blueChannelFilter.name = @"blueChannelFilter";
		CIFilter *alphaChannelFilter = [CIFilter filterForChannelMask:TKImageChannelAlphaMask];
		alphaChannelFilter.name = @"alphaChannelFilter";
		
//		[redChannelFilter setValue:[CIImage imageWithCGImage:[selectedImageRep CGImage]] forKey:kCIInputImageKey];
//		
//		[greenChannelFilter setValue:[redChannelFilter valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
//		[blueChannelFilter setValue:[greenChannelFilter valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
//		[alphaChannelFilter setValue:[blueChannelFilter valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
		
		CIFilter *multiChannelFilter = [CIFilter filterForChannelMask:TKImageChannelRGBAMask];
		multiChannelFilter.name = @"multiChannelFilter";
//		[multiChannelFilter setValue:[alphaChannelFilter valueForKey:kCIOutputImageKey] forKey:kCIInputImageKey];
		
		[imageChannelNamesAndFilters setObject:redChannelFilter forKey:redChannelFilter.name];
		[imageChannelNamesAndFilters setObject:greenChannelFilter forKey:greenChannelFilter.name];
		[imageChannelNamesAndFilters setObject:blueChannelFilter forKey:blueChannelFilter.name];
		[imageChannelNamesAndFilters setObject:alphaChannelFilter forKey:alphaChannelFilter.name];
		[imageChannelNamesAndFilters setObject:multiChannelFilter forKey:multiChannelFilter.name];
		
//		imageView.imageKitLayer.filters = [NSArray arrayWithArray:[imageChannelNamesAndFilters allValues]];
		
	}
}




- (void)applyChannelMasks {
	[self setupImageChannelMasksIfNecessary];
	
	if (imageChannelMask == TKImageChannelRedMask ||
		imageChannelMask == TKImageChannelGreenMask ||
		imageChannelMask == TKImageChannelBlueMask ||
		imageChannelMask == TKImageChannelAlphaMask) {
		// single-channel preview
		
//		[imageView.imageKitLayer setValue:[NSNumber numberWithBool:(imageChannelMask == TKImageChannelRedMask)]	forKeyPath:@"filters.redChannelFilter.enabled"];
//		[imageView.imageKitLayer setValue:[NSNumber numberWithBool:(imageChannelMask == TKImageChannelGreenMask)] forKeyPath:@"filters.greenChannelFilter.enabled"];
//		[imageView.imageKitLayer setValue:[NSNumber numberWithBool:(imageChannelMask == TKImageChannelBlueMask)] forKeyPath:@"filters.blueChannelFilter.enabled"];
//		[imageView.imageKitLayer setValue:[NSNumber numberWithBool:(imageChannelMask == TKImageChannelAlphaMask)] forKeyPath:@"filters.alphaChannelFilter.enabled"];
//		
//		[imageView.imageKitLayer setValue:[NSNumber numberWithBool:NO] forKeyPath:@"filters.multiChannelFilter.enabled"];
		
		
	} else {
		// multi-channel preview
		
//		[imageView.imageKitLayer setValue:[NSNumber numberWithBool:NO] forKeyPath:@"filters.redChannelFilter.enabled"];
//		[imageView.imageKitLayer setValue:[NSNumber numberWithBool:NO] forKeyPath:@"filters.greenChannelFilter.enabled"];
//		[imageView.imageKitLayer setValue:[NSNumber numberWithBool:NO] forKeyPath:@"filters.blueChannelFilter.enabled"];
//		[imageView.imageKitLayer setValue:[NSNumber numberWithBool:NO] forKeyPath:@"filters.alphaChannelFilter.enabled"];
//		
//		[imageView.imageKitLayer setValue:[CIVector vectorWithString:(imageChannelMask & TKImageChannelRedMask) ? @"[1.0 0.0 0.0 0.0]" : @"[0.0 0.0 0.0 0.0]"] forKeyPath:@"filters.multiChannelFilter.inputRVector"];
//		[imageView.imageKitLayer setValue:[CIVector vectorWithString:(imageChannelMask & TKImageChannelGreenMask) ? @"[1.0 0.0 0.0 0.0]" : @"[0.0 0.0 0.0 0.0]"] forKeyPath:@"filters.multiChannelFilter.inputGVector"];
//		[imageView.imageKitLayer setValue:[CIVector vectorWithString:(imageChannelMask & TKImageChannelBlueMask) ? @"[1.0 0.0 0.0 0.0]" : @"[0.0 0.0 0.0 0.0]"] forKeyPath:@"filters.multiChannelFilter.inputBVector"];
//		[imageView.imageKitLayer setValue:[CIVector vectorWithString:(imageChannelMask & TKImageChannelAlphaMask) ? @"[1.0 0.0 0.0 0.0]" : @"[0.0 0.0 0.0 0.0]"] forKeyPath:@"filters.multiChannelFilter.inputAVector"];
//
//		[imageView.imageKitLayer setValue:[NSNumber numberWithBool:YES] forKeyPath:@"filters.multiChannelFilter.enabled"];

	}
}


- (IBAction)changeToolMode:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@] sender == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sender);
#endif
	
	NSInteger tag = 0;
	
	if ([sender isKindOfClass:[NSSegmentedControl class]]) {
		NSSegmentedCell *cell = [(NSSegmentedControl *)sender cell];
		tag = [cell tagForSegment:[cell selectedSegment]];
		
	} else if ([sender isKindOfClass:[NSMenuItem class]]) {
		
		tag = [(NSMenuItem *)sender tag];
		
		[toolModeControl selectSegmentWithTag:tag];
	}
	
	if (tag == 1) {
		[imageView setCurrentToolMode:IKToolModeMove];
	} else if (tag == 2) {
		[imageView setCurrentToolMode:IKToolModeSelect];
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


- (IBAction)generateMipmaps:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSInteger tag = [(NSMenuItem *)sender tag];
	if (![self generateMipmapsUsingFilter:tag]) {
		NSLog(@"[%@ %@] failed to generate mipmaps!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	}
}


- (IBAction)removeMipmaps:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (![self removeGeneratedMipmapsUsingFilter:TKMipmapGenerationUsingBoxFilter]) {
		NSLog(@"[%@ %@] failed to remove mipmaps!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		
	}
}



- (void)copy:(id)sender {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSArray *selectedImageReps = [self selectedImageReps];
	[self writeImageReps:selectedImageReps toPasteboard:[NSPasteboard generalPasteboard] forTypes:[NSArray arrayWithObjects:TKImageDocumentPboardType, NSTIFFPboardType, nil]];
}



#pragma mark -
#pragma mark (internal) modification of image

- (BOOL)generateMipmapsUsingFilter:(TKMipmapGenerationType)aFilter {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if ([image isDepthTexture]) return NO;
	
	[image generateMipmapsUsingFilter:aFilter];
	
#if TK_DEBUG
//	NSLog(@"[%@ %@] image == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), image);
#endif
	
	
	[[[self undoManager] prepareWithInvocationTarget:self] removeGeneratedMipmapsUsingFilter:aFilter];
	
	if (![[self undoManager] isUndoing]) {
		[[self undoManager] setActionName:NSLocalizedString(@"Generate Mipmaps", @"")];
	}
	
	[self reloadData];
	
#if TK_DEBUG
//	NSLog(@"[%@ %@] image == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), image);
#endif
	
	
	return YES;
}


- (BOOL)removeGeneratedMipmapsUsingFilter:(TKMipmapGenerationType)aFilter {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if ([image isDepthTexture]) return NO;
	
	[image removeMipmaps];
	
#if TK_DEBUG
	NSLog(@"[%@ %@] image == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), image);
#endif
	
	
	[(TKImageDocument *)[[self undoManager] prepareWithInvocationTarget:self] generateMipmapsUsingFilter:aFilter];
	
	if (![[self undoManager] isUndoing]) {
		[[self undoManager] setActionName:NSLocalizedString(@"Remove Mipmaps", @"")];
	}
	
	[self reloadData];
	
	return NO;
}


/* for static, non-animated texture images */
- (BOOL)insertRepresentations:(NSArray *)representations atMipmapIndexes:(NSIndexSet *)mipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSSize largestSize = NSZeroSize;
	
	if ([[image representations] count] == 0) {
		TKImageRep *largestImageRep = [TKImageRep largestRepresentationInArray:representations];
		largestSize = [largestImageRep size];
	}
	
	[image setRepresentations:representations forMipmapIndexes:mipmapIndexes];
	
	if (!NSEqualSizes(largestSize, NSZeroSize)) {
		[image setSize:largestSize];
	}
	
	[[[self undoManager] prepareWithInvocationTarget:self] removeRepresentations:representations atMipmapIndexes:mipmapIndexes];
	
	if (![[self undoManager] isUndoing]) {
		[[self undoManager] setActionName:NSLocalizedString(@"Add Images", @"")];
	}
	
	[self reloadData];
	
	return YES;
}


- (BOOL)removeRepresentations:(NSArray *)representations atMipmapIndexes:(NSIndexSet *)mipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[[representations retain] autorelease];
	
	[image removeRepresentationsForMipmapIndexes:mipmapIndexes];
	
	[[[self undoManager] prepareWithInvocationTarget:self] insertRepresentations:representations atMipmapIndexes:mipmapIndexes];
	
	if (![[self undoManager] isUndoing]) {
		[[self undoManager] setActionName:NSLocalizedString(@"Remove Images", @"")];
	}
	
	[self reloadData];
	
	return YES;
}


- (BOOL)moveRepresentations:(NSArray *)representations fromMipmapIndexes:(NSIndexSet *)fromMipmapIndexes toMipmapIndexes:(NSIndexSet *)toMipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSArray *removedReps = [[image representationsForMipmapIndexes:fromMipmapIndexes] retain];
	
	NSArray *replacedReps = [[image representationsForMipmapIndexes:toMipmapIndexes] retain];
	
	[image removeRepresentationsForMipmapIndexes:fromMipmapIndexes];
	
	[image removeRepresentationsForMipmapIndexes:toMipmapIndexes];
	
	[image setRepresentations:removedReps forMipmapIndexes:toMipmapIndexes];
	
	[image setRepresentations:replacedReps forMipmapIndexes:fromMipmapIndexes];
	
	[removedReps release];
	
	[replacedReps release];
	
	[[[self undoManager] prepareWithInvocationTarget:self] moveRepresentations:representations fromMipmapIndexes:toMipmapIndexes toMipmapIndexes:fromMipmapIndexes];
	
	if (![[self undoManager] isUndoing]) {
		[[self undoManager] setActionName:NSLocalizedString(@"Move Images", @"")];
	}
	
	[self reloadData];
	
	return YES;
}




/* for animated (multi-frame) texture images */
- (BOOL)insertRepresentations:(NSArray *)representations atFrameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSSize largestSize = NSZeroSize;
	
	if ([[image representations] count] == 0) {
		TKImageRep *largestImageRep = [TKImageRep largestRepresentationInArray:representations];
		largestSize = [largestImageRep size];
	}
	
	[image setRepresentations:representations forFrameIndexes:frameIndexes mipmapIndexes:mipmapIndexes];
	
	if (!NSEqualSizes(largestSize, NSZeroSize)) {
		[image setSize:largestSize];
	}
	
	[[[self undoManager] prepareWithInvocationTarget:self] removeRepresentations:representations atFrameIndexes:frameIndexes mipmapIndexes:mipmapIndexes];
	
	if (![[self undoManager] isUndoing]) {
		[[self undoManager] setActionName:NSLocalizedString(@"Add Images", @"")];
	}
	
	[self reloadData];
	
	return YES;
}



- (BOOL)removeRepresentations:(NSArray *)representations atFrameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[[representations retain] autorelease];

	[image removeRepresentationsForFrameIndexes:frameIndexes mipmapIndexes:mipmapIndexes];
	
	[[[self undoManager] prepareWithInvocationTarget:self] insertRepresentations:representations atFrameIndexes:frameIndexes mipmapIndexes:mipmapIndexes];
	
	if (![[self undoManager] isUndoing]) {
		[[self undoManager] setActionName:NSLocalizedString(@"Remove Images", @"")];
	}
	
	[self reloadData];
	
	return YES;
}



- (BOOL)moveRepresentations:(NSArray *)representations fromFrameIndexes:(NSIndexSet *)fromFrameIndexes mipmapIndexes:(NSIndexSet *)fromMipmapIndexes toFrameIndexes:(NSIndexSet *)toFrameIndexes mipmapIndexes:(NSIndexSet *)toMipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSArray *removedReps = [[image representationsForFrameIndexes:fromFrameIndexes mipmapIndexes:fromMipmapIndexes] retain];
	
	NSArray *replacedReps = [[image representationsForFrameIndexes:toFrameIndexes mipmapIndexes:toMipmapIndexes] retain];
	
	[image removeRepresentationsForFrameIndexes:fromFrameIndexes mipmapIndexes:fromMipmapIndexes];
	
	[image removeRepresentationsForFrameIndexes:toFrameIndexes mipmapIndexes:toMipmapIndexes];
	
	[image setRepresentations:removedReps forFrameIndexes:toFrameIndexes mipmapIndexes:toMipmapIndexes];
	
	[image setRepresentations:replacedReps forFrameIndexes:fromFrameIndexes mipmapIndexes:fromMipmapIndexes];
	
	[removedReps release];
	
	[replacedReps release];
	
	[[[self undoManager] prepareWithInvocationTarget:self] moveRepresentations:representations fromFrameIndexes:toFrameIndexes mipmapIndexes:toMipmapIndexes toFrameIndexes:fromFrameIndexes mipmapIndexes:fromMipmapIndexes];
	
	if (![[self undoManager] isUndoing]) {
		[[self undoManager] setActionName:NSLocalizedString(@"Move Images", @"")];
	}
	
	[self reloadData];
	
	return YES;
}




/* for multi-sided texture images */
- (BOOL)insertRepresentations:(NSArray *)representations atFaceIndexes:(NSIndexSet *)faceIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSSize largestSize = NSZeroSize;
	
	if ([[image representations] count] == 0) {
		TKImageRep *largestImageRep = [TKImageRep largestRepresentationInArray:representations];
		largestSize = [largestImageRep size];
	}
	
	[image setRepresentations:representations forFaceIndexes:faceIndexes mipmapIndexes:mipmapIndexes];
	
	if (!NSEqualSizes(largestSize, NSZeroSize)) {
		[image setSize:largestSize];
	}
	
	[[[self undoManager] prepareWithInvocationTarget:self] removeRepresentations:representations atFaceIndexes:faceIndexes mipmapIndexes:mipmapIndexes];
	
	if (![[self undoManager] isUndoing]) {
		[[self undoManager] setActionName:NSLocalizedString(@"Add Images", @"")];
	}
	
	[self reloadData];
	
	return YES;
}


- (BOOL)removeRepresentations:(NSArray *)representations atFaceIndexes:(NSIndexSet *)faceIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[[representations retain] autorelease];
	
	[image removeRepresentationsForFaceIndexes:faceIndexes mipmapIndexes:mipmapIndexes];
	
	[[[self undoManager] prepareWithInvocationTarget:self] insertRepresentations:representations atFaceIndexes:faceIndexes mipmapIndexes:mipmapIndexes];
	
	if (![[self undoManager] isUndoing]) {
		[[self undoManager] setActionName:NSLocalizedString(@"Remove Images", @"")];
	}
	
	[self reloadData];
	
	return YES;
}


- (BOOL)moveRepresentations:(NSArray *)representations fromFaceIndexes:(NSIndexSet *)fromFaceIndexes mipmapIndexes:(NSIndexSet *)fromMipmapIndexes toFaceIndexes:(NSIndexSet *)toFaceIndexes mipmapIndexes:(NSIndexSet *)toMipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSArray *removedReps = [[image representationsForFaceIndexes:fromFaceIndexes mipmapIndexes:fromMipmapIndexes] retain];
	
	NSArray *replacedReps = [[image representationsForFaceIndexes:toFaceIndexes mipmapIndexes:toMipmapIndexes] retain];
	
	[image removeRepresentationsForFaceIndexes:fromFaceIndexes mipmapIndexes:fromMipmapIndexes];
	
	[image removeRepresentationsForFaceIndexes:toFaceIndexes mipmapIndexes:toMipmapIndexes];
	
	[image setRepresentations:removedReps forFaceIndexes:toFaceIndexes mipmapIndexes:toMipmapIndexes];
	
	[image setRepresentations:replacedReps forFaceIndexes:fromFaceIndexes mipmapIndexes:fromMipmapIndexes];
	
	[removedReps release];
	
	[replacedReps release];
	
	[[[self undoManager] prepareWithInvocationTarget:self] moveRepresentations:representations fromFaceIndexes:toFaceIndexes mipmapIndexes:toMipmapIndexes toFaceIndexes:fromFaceIndexes mipmapIndexes:fromMipmapIndexes];
	
	if (![[self undoManager] isUndoing]) {
		[[self undoManager] setActionName:NSLocalizedString(@"Move Images", @"")];
	}
	
	[self reloadData];
	
	return YES;
}




/* for animated (multi-frame), multi-sided texture images */
- (BOOL)insertRepresentations:(NSArray *)representations atFaceIndexes:(NSIndexSet *)faceIndexes frameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSSize largestSize = NSZeroSize;
	
	if ([[image representations] count] == 0) {
		TKImageRep *largestImageRep = [TKImageRep largestRepresentationInArray:representations];
		largestSize = [largestImageRep size];
	}
	
	[image setRepresentations:representations forFaceIndexes:faceIndexes frameIndexes:frameIndexes mipmapIndexes:mipmapIndexes];
	
	[[[self undoManager] prepareWithInvocationTarget:self] removeRepresentations:representations atFaceIndexes:faceIndexes frameIndexes:frameIndexes mipmapIndexes:mipmapIndexes];
	
	if (!NSEqualSizes(largestSize, NSZeroSize)) {
		[image setSize:largestSize];
	}
	
	if (![[self undoManager] isUndoing]) {
		[[self undoManager] setActionName:NSLocalizedString(@"Add Images", @"")];
	}
	
	[self reloadData];
	
	return YES;
}


- (BOOL)removeRepresentations:(NSArray *)representations atFaceIndexes:(NSIndexSet *)faceIndexes frameIndexes:(NSIndexSet *)frameIndexes mipmapIndexes:(NSIndexSet *)mipmapIndexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[[representations retain] autorelease];
	
	[image removeRepresentationsForFaceIndexes:faceIndexes frameIndexes:frameIndexes mipmapIndexes:mipmapIndexes];
	
	[[[self undoManager] prepareWithInvocationTarget:self] insertRepresentations:representations atFaceIndexes:faceIndexes frameIndexes:frameIndexes mipmapIndexes:mipmapIndexes];
	
	if (![[self undoManager] isUndoing]) {
		[[self undoManager] setActionName:NSLocalizedString(@"Remove Images", @"")];
	}
	
	[self reloadData];
	
	return YES;
}


- (BOOL)moveRepresentations:(NSArray *)representations fromFaceIndexes:(NSIndexSet *)fromFaceIndexes frameIndexes:(NSIndexSet *)fromFrameIndexes mipmapIndexes:(NSIndexSet *)fromMipmapIndexes toFaceIndexes:(NSIndexSet *)toFaceIndexes frameIndexes:(NSIndexSet *)toFrameIndexes mipmapIndexes:(NSIndexSet *)toMipmapIndexes {
	
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSArray *removedReps = [[image representationsForFaceIndexes:fromFaceIndexes frameIndexes:fromFrameIndexes mipmapIndexes:fromMipmapIndexes] retain];
	
	NSArray *replacedReps = [[image representationsForFaceIndexes:toFaceIndexes frameIndexes:toFrameIndexes mipmapIndexes:toMipmapIndexes] retain];
	
	[image removeRepresentationsForFaceIndexes:fromFaceIndexes frameIndexes:fromFrameIndexes mipmapIndexes:fromMipmapIndexes];
	
	[image removeRepresentationsForFaceIndexes:toFaceIndexes frameIndexes:toFrameIndexes mipmapIndexes:toMipmapIndexes];
	
	[image setRepresentations:removedReps forFaceIndexes:toFaceIndexes frameIndexes:toFrameIndexes mipmapIndexes:toMipmapIndexes];
	
	[image setRepresentations:replacedReps forFaceIndexes:fromFaceIndexes frameIndexes:fromFrameIndexes mipmapIndexes:fromMipmapIndexes];
	
	[removedReps release];
	
	[replacedReps release];
	
	[[[self undoManager] prepareWithInvocationTarget:self] moveRepresentations:representations fromFaceIndexes:toFaceIndexes frameIndexes:toFrameIndexes mipmapIndexes:toMipmapIndexes toFaceIndexes:fromFaceIndexes frameIndexes:fromFrameIndexes mipmapIndexes:fromMipmapIndexes];

	if (![[self undoManager] isUndoing]) {
		[[self undoManager] setActionName:NSLocalizedString(@"Move Images", @"")];
	}
	
	[self reloadData];
	
	return YES;
}

#pragma mark (internal) modification of image (END)
#pragma mark -



- (void)menuNeedsUpdate:(NSMenu *)menu {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	

}



- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	SEL action = [menuItem action];
	NSInteger tag = [menuItem tag];
	
	if (action == @selector(copy:)) {
		
	} else if (action == @selector(paste:)) {
		
	} else if (action == @selector(switchViewMode:)) {
		// disable MDHLDocument stuff
		return NO;
		
	} else if (action == @selector(changeToolMode:)) {
		NSString *currentToolMode = [imageView currentToolMode];
		
		if (tag == 1) {
			[menuItem setState:[currentToolMode isEqual:IKToolModeMove]];
		} else if (tag == 2) {
			[menuItem setState:[currentToolMode isEqual:IKToolModeSelect]];
		}
	} else if (action == @selector(changeViewMode:)) {
		if (tag == TKFacesTag) {
			[menuItem setTitle:(shouldShowFaceBrowserView ? NSLocalizedString(@"Hide Faces", @"") : NSLocalizedString(@"Show Faces", @""))];
			
		} else if (tag == TKFramesTag) {
			[menuItem setTitle:(shouldShowFrameBrowserView ? NSLocalizedString(@"Hide Frames", @"") : NSLocalizedString(@"Show Frames", @""))];

		} else if (tag == TKMipmapsTag) {
			[menuItem setTitle:(shouldShowMipmapBrowserView ? NSLocalizedString(@"Hide Mipmaps", @"") : NSLocalizedString(@"Show Mipmaps", @""))];

		}
	} else if (action == @selector(generateMipmaps:)) {
		return [image imageType] != TKEmptyImageType;
		
//		if (currentMenuBrowserView == faceBrowserView) {
//			return [[self selectedFaceIndexes] count] > 0;
//		} else if (currentMenuBrowserView == frameBrowserView) {
//			return [[frameBrowserView selectionIndexes] count] > 0;
//		} else if (currentMenuBrowserView == mipmapBrowserView) {
//			return [[mipmapBrowserView selectionIndexes] count] > 0;
//		}
	} else if (action == @selector(removeMipmaps:)) {
		return [image hasMipmaps];
	}
	return YES;
}


- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	SEL action = [theItem action];
	
	if (action == @selector(togglePlayAnimation:)) {
		if ([imageView isAnimating]) {
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




