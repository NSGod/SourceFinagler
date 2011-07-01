//
//  MDCopyOperationSeparatorView.m
//  Source Finagler
//
//  Created by Mark Douma on 6/12/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import "MDCopyOperationSeparatorView.h"
#import "MDCopyOperationView.h"


#define MD_DEBUG 0

#define MD_COPY_OPERATION_SEPARATOR_VIEW_HEIGHT 1.0


static NSColor *separatorColor = nil;

@implementation MDCopyOperationSeparatorView

+ (void)initialize {
	if (separatorColor == nil) separatorColor = [[NSColor colorWithCalibratedRed:184.0/255.0 green:184.0/255.0 blue:184.0/255.0 alpha:1.0] retain];
}



+ (id)separatorView {
	return [[self class] separatorViewPositionedAboveCopyOperationView:nil];
}


+ (id)separatorViewPositionedAboveCopyOperationView:(MDCopyOperationView *)copyOperationView {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSRect frame = NSMakeRect(0.0, 0.0, (copyOperationView ? [[copyOperationView class] copyOperationViewSize].width : [MDCopyOperationView copyOperationViewSize].width), 1.0);
	if (copyOperationView) frame.origin.y = [copyOperationView frame].origin.y + NSHeight([copyOperationView frame]);
	
	MDCopyOperationSeparatorView *separatorView = [[[[self class] alloc] initWithFrame:frame] autorelease];
	[copyOperationView setSeparatorView:separatorView];
	return separatorView;
}


- (id)initWithFrame:(NSRect)frame {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
    if ((self = [super initWithFrame:frame])) {
		
    }
    return self;
}

+ (CGFloat)separatorViewHeight {
	return MD_COPY_OPERATION_SEPARATOR_VIEW_HEIGHT;
}

- (void)drawRect:(NSRect)frame {
	[separatorColor set];
	[NSBezierPath fillRect:frame];
}

- (BOOL)isOpaque {
	return YES;
}



@end
