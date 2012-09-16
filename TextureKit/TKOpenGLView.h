//
//  TKOpenGLView.h
//  Texture Kit
//
//  Created by Mark Douma on 12/1/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//


#import <AppKit/NSOpenGLView.h>
#import <CoreVideo/CVDisplayLink.h>


@class TKOpenGLRenderer;


@interface TKOpenGLView : NSOpenGLView {
	TKOpenGLRenderer		*renderer;
	CVDisplayLinkRef		displayLink;
	
	NSPoint					lastMousePoint;
	
	float					pitch;
	float					zoomFactor;
	
	BOOL					mouseIsDown;
	BOOL					rightMouseIsDown;
	BOOL					middleMouseIsDown;
	
	
}

@property (retain) TKOpenGLRenderer *renderer;


@end


