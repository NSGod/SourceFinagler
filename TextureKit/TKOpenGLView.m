//
//  TKOpenGLView.m
//  Texture Kit
//
//  Created by Mark Douma on 12/1/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//


#import <TextureKit/TKOpenGLView.h>
#import <TextureKit/TKOpenGLRenderer.h>
#import <TextureKit/TKOpenGLBase.h>
#import "TKOpenGLPrivateInterfaces.h"



#define TK_DEBUG 1

@interface TKOpenGLView (TKPrivate)

- (void)initGL;
- (void)drawView;


//- (void)startDisplayLink;
//- (void)stopDisplayLink;


@end


@implementation TKOpenGLView

@synthesize renderer;


- (CVReturn)drawFrameForTime:(const CVTimeStamp *)outputTime {
	// There is no autorelease pool when this method is called 
	// because it will be called from a background thread
	// It's important to create one or you will leak objects
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self drawView];
	
	[pool release];
	return kCVReturnSuccess;
}


// This is the renderer output callback function
static CVReturn TKDisplayLinkCallback(CVDisplayLinkRef displayLink,
									  const CVTimeStamp *now,
									  const CVTimeStamp *outputTime,
									  CVOptionFlags flagsIn,
									  CVOptionFlags *flagsOut,
									  void *displayLinkContext) {
	
    CVReturn result = [(TKOpenGLView *)displayLinkContext drawFrameForTime:outputTime];
    return result;
}



- (id)initWithFrame:(NSRect)frameRect {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif

	NSOpenGLPixelFormatAttribute attrs[] = {
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 24,
		// Must specify the 3.2 Core Profile to use OpenGL 3.2
#if TK_ENABLE_OPENGL3 
		NSOpenGLPFAOpenGLProfile,
		NSOpenGLProfileVersion3_2Core,
#endif
		0
	};
	
	NSOpenGLPixelFormat *pf = [[[NSOpenGLPixelFormat alloc] initWithAttributes:attrs] autorelease];
	
	if (!pf) {
		NSLog(@"No OpenGL pixel format");
	}
	
	if ((self = [super initWithFrame:frameRect pixelFormat:pf])) {
		
	}
	
	return self;
}


- (void)dealloc {
	[renderer release];
	// Release the display link
	CVDisplayLinkRelease(displayLink);
	[super dealloc];
}



- (void)prepareOpenGL {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super prepareOpenGL];
	
	// Make all the OpenGL calls to setup rendering  
	//  and build the necessary rendering objects
	[self initGL];
	
	// Create a display link capable of being used with all active displays
	CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
	
	// Set the renderer output callback function
	CVDisplayLinkSetOutputCallback(displayLink, &TKDisplayLinkCallback, self);
	
	// Set the display link for the current renderer
	CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
	CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
	CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
	
//	// Activate the display link
//	CVDisplayLinkStart(displayLink);
}


- (void)initGL {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	// Make this openGL context current to the thread
	// (i.e. all openGL on this thread calls will go to this context)
	[[self openGLContext] makeCurrentContext];
	
	// Synchronize buffer swaps with vertical refresh rate
	GLint swapInt = 1;
	[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
	
	// Init our renderer.  Use 0 for the defaultFBO which is appropriate for MacOS (but not iOS)
	renderer = [[TKOpenGLRenderer alloc] initWithView:self defaultFrameBufferObjectName:0];
}



- (void)startDisplayLink {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (displayLink == NULL) {
		NSLog(@"[%@ %@] WARNING: displayLink == NULL!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return;
	}
	
	if (CVDisplayLinkIsRunning(displayLink)) {
		NSLog(@"[%@ %@] WARNING: displayLink is already running!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return;
	}
	
	// Activate the display link
	CVDisplayLinkStart(displayLink);
	
}



- (void)stopDisplayLink {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (displayLink == NULL) {
		NSLog(@"[%@ %@] WARNING: displayLink == NULL!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return;
	}
	
	if (!CVDisplayLinkIsRunning(displayLink)) {
		NSLog(@"[%@ %@] WARNING: displayLink isn't running!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return;
	}
	
	// Activate the display link
	CVDisplayLinkStop(displayLink);
	
}




- (void)reshape {
	[super reshape];
	
	// We draw on a secondary thread through the display link
	// When resizing the view, -reshape is called automatically on the main thread
	// Add a mutex around to avoid the threads accessing the context simultaneously when resizing
	CGLLockContext([[self openGLContext] CGLContextObj]);
	
	[renderer setSize:[self bounds].size];
	
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}


- (void)drawView {
	[[self openGLContext] makeCurrentContext];

	// We draw on a secondary thread through the display link
	// When resizing the view, -reshape is called automatically on the main thread
	// Add a mutex around to avoid the threads accessing the context simultaneously	when resizing
	CGLLockContext([[self openGLContext] CGLContextObj]);
	
	[renderer render];
	
	CGLFlushDrawable([[self openGLContext] CGLContextObj]);
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}



- (void)drawRect:(NSRect)frame {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super drawRect:frame];
}


- (void)setNeedsDisplay:(BOOL)flag {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super setNeedsDisplay:flag];
}


- (void)mouseDown:(NSEvent *)event {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	lastMousePoint = [self convertPoint:[event locationInWindow] fromView:nil];
	mouseIsDown = YES;
}

- (void)mouseUp:(NSEvent *)event {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	mouseIsDown = NO;
}


- (void)rightMouseDown:(NSEvent *)event {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	lastMousePoint = [self convertPoint:[event locationInWindow] fromView:nil];
	rightMouseIsDown = YES;
}

- (void)rightMouseUp:(NSEvent *)event {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	rightMouseIsDown = NO;
}


- (void)otherMouseDown:(NSEvent *)event {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	lastMousePoint = [self convertPoint:[event locationInWindow] fromView:nil];
	middleMouseIsDown = YES;
}

- (void)otherMouseUp:(NSEvent *)event {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	middleMouseIsDown = NO;
}


- (void)mouseDragged:(NSEvent *)event {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSUInteger modifierFlags = [event modifierFlags];
	NSLog(@"[%@ %@] modifierFlags == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)modifierFlags);
	
	if (modifierFlags & NSControlKeyMask) {
		[self rightMouseDragged:event];
	} else {
		NSPoint mouse = [self convertPoint:[event locationInWindow] fromView:nil];
		
		pitch += lastMousePoint.y - mouse.y;
		
		lastMousePoint = mouse;
		
		[renderer setPitch:pitch];
		
//		[self setNeedsDisplay:YES];
	}
	
	
}



- (void)rightMouseDragged:(NSEvent *)event {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSPoint mouse = [self convertPoint:[event locationInWindow] fromView:nil];
	
	zoomFactor += 0.01f * (lastMousePoint.y - mouse.y);
	if (zoomFactor < 0.05f) {
		zoomFactor = 0.05f;
	} else if (zoomFactor > 2.0f) {
		zoomFactor = 2.0f;
	}
	lastMousePoint = mouse;
	
	[renderer setZoomFactor:zoomFactor];
	
//	[self setNeedsDisplay:YES];
	
}


- (void)otherMouseDragged:(NSEvent *)event {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	
}


- (void)scrollWheel:(NSEvent *)event {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super scrollWheel:event];
}




@end





