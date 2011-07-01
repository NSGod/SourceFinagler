//
//  MDTableView.m
//  Source Finagler
//
//  Created by Mark Douma on 6/26/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//
//#if TARGET_CPU_X86 || TARGET_CPU_X86_64

#import "MDTableView.h"
#import "MDOtherAppsHelperController.h"


@implementation MDTableView


- (void)rightMouseDown:(NSEvent *)event {
#if MD_DEBUG
		NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSInteger rowIndex = [self rowAtPoint:[self convertPoint:[event locationInWindow] fromView:nil]];
	
	NSIndexSet *selectedRowIndexes = [self selectedRowIndexes];
	if (rowIndex >= 0) {
		if ([selectedRowIndexes containsIndex:rowIndex]) {
			return [super rightMouseDown:event];
		} else {
			[self selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
			return [super rightMouseDown:event];
		}
	} else {
		if ([selectedRowIndexes count]) {
			[self deselectAll:self];
			return [super rightMouseDown:event];
		}
	}
	return [super rightMouseDown:event];
}


- (void)mouseDown:(NSEvent *)event {
#if MD_DEBUG
		NSLog(@" \"%@\" [%@ %@]", [[[[self window] windowController] document] displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSUInteger modifierFlags = [event modifierFlags];
	if (modifierFlags & NSAlternateKeyMask || modifierFlags & NSCommandKeyMask) {
		return [super mouseDown:event];
	} else if (modifierFlags & NSControlKeyMask) {
		NSInteger rowIndex = [self rowAtPoint:[self convertPoint:[event locationInWindow] fromView:nil]];
		NSIndexSet *selectedRowIndexes = [self selectedRowIndexes];
		if (rowIndex >= 0) {
			if ([selectedRowIndexes containsIndex:rowIndex]) {
				return [super mouseDown:event];
			} else {
				[self selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
				return [super mouseDown:event];
			}
		} else {
			if ([selectedRowIndexes count]) {
				[self deselectAll:self];
				return [super mouseDown:event];
			}
		}
	}
	return [super mouseDown:event];
}


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	SEL action = [menuItem action];
	if (action == @selector(revealInFinder:)) {
		return [[self delegate] respondsToSelector:@selector(revealInFinder:)] ||
				[[self dataSource] respondsToSelector:@selector(revealInFinder:)];
	}
	return YES;
}


- (IBAction)revealInFinder:(id)sender {
	if ([[self delegate] respondsToSelector:@selector(revealInFinder:)]) {
		[(MDOtherAppsHelperController *) [self delegate] revealInFinder:self];
	} else if ([[self dataSource] respondsToSelector:@selector(revealInFinder:)]) {
		[(MDOtherAppsHelperController *) [self dataSource] revealInFinder:self];
	}
}


@end
//#endif
