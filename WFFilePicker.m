//
//  WFFilePicker.m
//
//  Created by Jesper on 2006-04-13.
//  Copyright 2006-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import "WFFilePicker.h"
#import "SRCommon.h"

#import "NSWorkspace+SmallIcon.h"

#define WFFilePickerIconSize	16.0
#define WFLabelTextColorDimmedUnselected	[[NSColor textColor] colorWithAlphaComponent:0.7]
#define WFLabelTextColorOrdinary	[NSColor textColor]

@interface NSMenu (PopUpRegularMenuAdditions)
+ (void)popUpMenu:(NSMenu *)menu forView:(NSView *)view pullsDown:(BOOL)pullsDown;
@end

@implementation NSMenu (PopUpRegularMenuAdditions)
+ (void)popUpMenu:(NSMenu *)menu forView:(NSView *)view pullsDown:(BOOL)pullsDown {
	NSRect frame = [view frame];
	frame.origin.x = 0.0;
	frame.origin.y = 0.0;
	
	if (pullsDown) [menu insertItemWithTitle:@"" action:NULL keyEquivalent:@"" atIndex:0];
	
	NSPopUpButtonCell *popUpButtonCell = [[NSPopUpButtonCell alloc] initTextCell:@"" pullsDown:pullsDown];
	[popUpButtonCell setMenu:menu];
	if (!pullsDown) [popUpButtonCell selectItem:nil];
	[popUpButtonCell performClickWithFrame:frame inView:view];
	
	[popUpButtonCell autorelease];
}
@end

@interface WFFilePicker (Private)
- (void)setDroppingFlag:(BOOL)isDr;
- (NSDragOperation)setDroppingFlag:(BOOL)isDr operation:(NSDragOperation)op;

- (BOOL)cmdFileMenuIsAvailable;

- (BOOL)isNewURLValidChoice:(NSURL *)u;
- (NSURL *)resolveAlias:(NSURL *)url;

- (void)revealPathOfMenuItem:(id)sender;
- (void)showCmdMenuForFileUsingEvent:(NSEvent *)mouseDownEvent;
@end

@interface WFFilePickerLabelView : NSTextField {
	WFFilePicker *filePicker;
}
- (void)setFilePicker:(WFFilePicker *)fp;
@end

@implementation WFFilePickerLabelView

- (BOOL)isEditable { return NO; }

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		; //
	}
	return self;
}

- (void)setFilePicker:(WFFilePicker *)fp {
	if (fp == filePicker) return;
	[filePicker release];
	filePicker = fp;
	[filePicker retain];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	if (![filePicker cmdFileMenuIsAvailable]) { [super mouseDown:theEvent]; return; }
	if ([theEvent modifierFlags] & NSCommandKeyMask) {
		[filePicker showCmdMenuForFileUsingEvent:theEvent];
		return;
	}
	[super mouseDown:theEvent];
}

-(void) rightMouseDown:(NSEvent *)theEvent {
	if (![filePicker cmdFileMenuIsAvailable]) { [super rightMouseDown:theEvent]; return; }
	if (([theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask) == 0) {
		[filePicker showCmdMenuForFileUsingEvent:theEvent];
		return;
	}
	[super rightMouseDown:theEvent];
}

@end

@interface WFFilePickerIconView : NSImageView {
	WFFilePicker *filePicker;
}
- (void)setFilePicker:(WFFilePicker *)fp;
@end

@implementation WFFilePickerIconView

- (BOOL)isEditable { return NO; }

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		; //
	}
	return self;
}

- (void)setFilePicker:(WFFilePicker *)fp {
	if (fp == filePicker) return;
	[filePicker release];
	filePicker = fp;
	[filePicker retain];
}

-(void) rightMouseDown:(NSEvent *)theEvent {
	if (![filePicker cmdFileMenuIsAvailable]) { [super rightMouseDown:theEvent]; return; }
	if (([theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask) == 0) {
		[filePicker showCmdMenuForFileUsingEvent:theEvent];
		return;
	}
	[super rightMouseDown:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	if ([filePicker isEmpty]) {
		if ([theEvent clickCount] > 1) {
			[filePicker beginChooseSheet:self];
		} else {
			[super mouseDown:theEvent];
		}
		return;
	}
	if (![filePicker isEnabled]) { [super mouseDown:theEvent]; return; }
	if ([theEvent modifierFlags] & NSCommandKeyMask) {
		[filePicker showCmdMenuForFileUsingEvent:theEvent];
		return;
	}
    [self dragFile:[[filePicker representedURL] path]
		  fromRect:[self frame]
		 slideBack:YES
			 event:theEvent];
}

@end

@implementation WFFilePicker (Private)

- (void)revealPathOfMenuItem:(id)sender {
//	NSLog(@"sender: %@ (%@)", sender, [sender className]);
	NSString *path = [sender representedObject];
	if (nil == path) return;
	[[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:[path stringByDeletingLastPathComponent]];
}

- (void)showCmdMenuForFileUsingEvent:(NSEvent *)mouseDownEvent {
	NSMenu *m = [[NSMenu alloc] initWithTitle:@""];
	NSMenuItem *mi;
	NSString *path = [[self representedURL] path];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	NSString *networkPrefix = @"/Network/";
	NSString *volPrefix = @"/Volumes/";
	NSString *rootPrefix = @"/";
	
	NSImage *icon;
	
	NSString *accPath = @"";
	
	NSMutableArray *targetPaths = [NSMutableArray array];
	
	if ([path hasPrefix:networkPrefix]) {
		mi = [[NSMenuItem alloc] initWithTitle:[fm displayNameAtPath:networkPrefix] action:@selector(revealPathOfMenuItem:) keyEquivalent:@""];
		icon = [ws smallIconForFileAtPath:networkPrefix];
		[mi setImage:icon];
		[mi setTarget:self];
		
		[targetPaths addObject:networkPrefix];
		
		[m insertItem:[mi autorelease] atIndex:0];
		path = [path substringFromIndex:[networkPrefix length]];
		accPath = networkPrefix;
	} else if ([path hasPrefix:volPrefix]) {
		path = [path substringFromIndex:[volPrefix length]];			
		accPath = volPrefix;
	} else {
		mi = [[NSMenuItem alloc] initWithTitle:[fm displayNameAtPath:rootPrefix] action:@selector(revealPathOfMenuItem:) keyEquivalent:@""];
		icon = [ws smallIconForFileAtPath:rootPrefix];
		[mi setImage:icon];
		[mi setTarget:self];
		
		[targetPaths addObject:rootPrefix];
		
		[m insertItem:[mi autorelease] atIndex:0];
		path = [path substringFromIndex:[rootPrefix length]];
		accPath = rootPrefix;
	}
	
	if ([path hasSuffix:@"/"]) path = [path substringToIndex:[path length]-2];
	
	NSArray *comps = [path componentsSeparatedByString:@"/"];
	NSEnumerator *compEnumerator = [comps objectEnumerator];
	NSString *comp;
	while (comp = [compEnumerator nextObject]) {
		NSString *thispath = [accPath stringByAppendingPathComponent:comp];
		
		NSString *displayName = [fm displayNameAtPath:thispath];
		
		NSDictionary *attrs = [fm attributesOfItemAtPath:thispath error:NULL];// fileAttributesAtPath:thispath traverseLink:NO];
		NSNumber *extensionHidden = [attrs objectForKey:NSFileExtensionHidden];
		if (nil != extensionHidden) {
			if ([extensionHidden boolValue]) {
				displayName = [displayName stringByDeletingPathExtension];
			}
		}
		
		mi = [[NSMenuItem alloc] initWithTitle:displayName action:@selector(revealPathOfMenuItem:) keyEquivalent:@""];
		
		icon = [ws smallIconForFileAtPath:thispath];
		
		[mi setImage:icon];
		[mi setTarget:self];
		
		[targetPaths addObject:thispath];
		
		[m insertItem:[mi autorelease] atIndex:0];
		
		accPath = [accPath stringByAppendingPathComponent:comp];
	}
	
	int i = 0; BOOL first = YES;
	int total = [m numberOfItems]-1;
	for (i = (total); i > -1; i--) {
		if (first) {
			[[m itemAtIndex:total-i] setRepresentedObject:nil];
			first = NO;
		} else {
			[[m itemAtIndex:total-i] setRepresentedObject:[targetPaths objectAtIndex:i+1]];
		}
	}
	
	[NSMenu popUpMenu:[m autorelease] forView:self pullsDown:NO];
}


- (BOOL)cmdFileMenuIsAvailable {
	return (![self isEmpty] && [self isEnabled]);
}

- (void)setDroppingFlag:(BOOL)isDr {
	isDropping = isDr;
//	NSLog(@"setDroppingFlag? %@", (isDr ? @"Y" : @"N"));
	[self setNeedsDisplay:YES];
}


- (NSDragOperation)setDroppingFlag:(BOOL)isDr operation:(NSDragOperation)op {
	[self setDroppingFlag:isDr];
	return op;
}

#define URLisBadChoiceWithReason(x,y)		{ /*NSLog(@"URL: %@ is bad choice; reason: %@", y, x);*/ return NO; }

- (BOOL)isNewURLValidChoice:(NSURL *)u {
	if (![u isFileURL]) URLisBadChoiceWithReason(@"isn't file URL",u);
	if (!canChooseDirectories && !canChooseFiles) URLisBadChoiceWithReason(@"can't choose dirs nor files",u); // what's left to choose?
	NSString *path = [u path];
	BOOL isDir;
	if (resolvesAliases) u = [self resolveAlias:u];
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) URLisBadChoiceWithReason(@"doesn't exist",u);
	if (!canChooseDirectories && canChooseFiles && isDir) URLisBadChoiceWithReason(@"file at URL is dir, can't choose dirs",u);
	if (canChooseDirectories && !canChooseFiles && !isDir) URLisBadChoiceWithReason(@"file at URL is file, can only choose dirs",u);
	if ((allowedFileTypes != nil) && ([allowedFileTypes count] > 0)) {
		if ((![allowedFileTypes containsObject:NSHFSTypeOfFile(path)]) && (![allowedFileTypes containsObject:[path pathExtension]]))
			URLisBadChoiceWithReason(@"isn't of specified type",u);
	}
	if (nil != delegate) {
		if ([delegate respondsToSelector:@selector(filePicker:validateURL:error:)]) {
			NSError *delValidateError;
			if (![delegate filePicker:self validateURL:u error:&delValidateError]) {
				NSString *errStr = [NSString stringWithFormat:@"delegate didn't like: (error: %@)", ((nil != delValidateError && [delValidateError isKindOfClass:[NSError class]]) ? (id)delValidateError : (id)@"no error")];
#pragma unused (errStr)
				URLisBadChoiceWithReason(errStr,u);
			}
		}
	}
	return YES;
}

- (NSURL *)resolveAlias:(NSURL *)url {
    FSRef fsRef;
    if (CFURLGetFSRef((CFURLRef)url, &fsRef))
    {
        Boolean targetIsFolder, wasAliased;
        if (FSResolveAliasFile (&fsRef, true /*resolveAliasChains*/, 
								&targetIsFolder, &wasAliased) == noErr && wasAliased)
        {
            CFURLRef resolvedUrl = CFURLCreateFromFSRef(NULL, &fsRef);
            if (resolvedUrl != NULL)
            {
                return [(NSURL *)resolvedUrl autorelease];
            }
        }
    }	
	return url;
}

@end

@implementation WFFilePicker

+ (void)initialize {
	[self exposeBinding:@"filePath"];
	[self exposeBinding:@"enabled"];
}



- (void)bind:(NSString *)binding
	toObject:(id)observableObject
 withKeyPath:(NSString *)keyPath
	 options:(NSDictionary *)options
{
	id vtinst;
	id vtname;
	if ([binding isEqualToString:@"filePath"]) {
		
		[observableObject addObserver:self
						   forKeyPath:keyPath
							  options:0
							  context:(void *)@"filePath"];
		
		filePathObserver = [observableObject retain];
		filePathObserverKeyPath = [keyPath retain];
		
		vtinst = [options objectForKey:NSValueTransformerBindingOption];
		vtname = [options objectForKey:NSValueTransformerNameBindingOption];
		if (vtname != nil) {
			filePathVT = [[NSValueTransformer valueTransformerForName:(NSString *)vtname] retain];
		}
		if (vtinst != nil) {
			filePathVT = [vtinst retain];	
		}
		
//		NSLog(@"added observer self for key path %@ on object %@", keyPath, observableObject);

	} else if ([binding isEqualToString:@"enabled"]) {
		
		
		[observableObject addObserver:self
						   forKeyPath:keyPath
							  options:0
							  context:(void *)@"enabled"];
		
		enabledObserver = [observableObject retain];
		enabledObserverKeyPath = [keyPath retain];
		
		vtinst = [options objectForKey:NSValueTransformerBindingOption];
		vtname = [options objectForKey:NSValueTransformerNameBindingOption];
		if (vtname != nil) {
			enabledVT = [[NSValueTransformer valueTransformerForName:(NSString *)vtname] retain];
		}
		if (vtinst != nil) {
			enabledVT = [vtinst retain];	
		}
		
//		NSLog(@"added observer self for key path %@ on object %@", keyPath, observableObject);
		
	}
		[super bind:binding toObject:observableObject withKeyPath:keyPath options:options];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
//	NSLog(@"observed value for keyPath: %@ of object: %@", keyPath, object);
	if (context == (void *)@"filePath") {
		
//		NSString *newFilePath = [object valueForKeyPath:keyPath];
//		NSLog(@"file path changed, new file path? %@", newFilePath);
		
	}
	if (context == (void *)@"enabled") {
//		NSLog(@"new enabled: %i", [(NSNumber *)[object valueForKeyPath:keyPath] boolValue]);
		NSNumber *val = (NSNumber *)[object valueForKeyPath:keyPath];
		if (enabledVT) val = [enabledVT transformedValue:val];
		BOOL newEnabled = [val boolValue];
		[self setEnabledWithoutKVO:newEnabled];
	}
}

- (void)setEnabled:(BOOL)en {
	[self setEnabledWithoutKVO:en];
//	NSLog(@"set enabled to %i", en);
	NSNumber *val = [NSNumber numberWithBool:enabled];
//	NSLog(@"enabledVT? %@", enabledVT);
//	NSLog(@"value: %@", val);
	if (enabledVT) val = [enabledVT transformedValue:val];
//	NSLog(@"value: %@", val);
	[enabledObserver setValue:val forKeyPath:enabledObserverKeyPath];
//	NSLog(@"set %@ of %@ to %i", enabledObserverKeyPath, enabledObserver, en);
}

- (NSImage *)disabledFileIcon {
	NSImage *dis = [[NSImage alloc] initWithSize:[currentFileIcon size]];
	[dis lockFocus];
	[currentFileIcon compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver fraction:0.7];
	[dis unlockFocus];
	return [dis autorelease];
}

- (void)setEnabledWithoutKVO:(BOOL)en {
	enabled = en;
	[chooseButton setEnabled:en];
	[iconView setEnabled:en];
	[nameView setEnabled:en];
	[nameView setTextColor:(en ? WFLabelTextColorOrdinary : WFLabelTextColorDimmedUnselected)];
	if (![self isEmpty]) [iconView setImage:(en ? currentFileIcon : [self disabledFileIcon])];
	[self setNeedsDisplay:YES];
}

- (BOOL)isEnabled {
	return enabled;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		
		frame.size.height = 20.0; // this looks the best.
		enabled = YES;
		
//		NSLog(@"own frame: %@", NSStringFromRect(frame));

		float iconWidth = WFFilePickerIconSize;
		
		resolvesAliases = YES;
		canChooseFiles = YES;
		canChooseDirectories = NO;
		allowedFileTypes = nil;
		
		[self registerForDraggedTypes:[NSArray arrayWithObjects:NSURLPboardType, NSFilenamesPboardType, nil]];
		
		NSRect iconFrame = NSMakeRect(0.0,0.0,iconWidth,NSHeight(frame));
//		NSLog(@"own icon: %@", NSStringFromRect(iconFrame));
        iconView = [[WFFilePickerIconView alloc] initWithFrame:iconFrame];
		[iconView setImageFrameStyle:NSImageFrameNone];
		[iconView setAutoresizingMask:(NSViewMaxXMargin | NSViewHeightSizable)];
		[iconView setImage:[NSImage imageNamed:@"NSApplicationIcon"]];
		[iconView setFilePicker:self];
		[self addSubview:iconView];

		float textXOffset = iconWidth+(iconWidth/6.0);
		float chooseWidth = 70.0;
		float chooseInset = 2.0;
		float textWidth = NSWidth(frame)-(chooseWidth+textXOffset+chooseInset);
		float textFontHeight = [NSFont systemFontSize];
		float textYOffset = (NSHeight(frame)-(textFontHeight*1.35))/2.0;
		float textHeight = NSHeight(frame)-(textYOffset*2.0);
		NSRect textFrame = NSMakeRect(textXOffset,textYOffset,textWidth,textHeight);
//		NSLog(@"own text: %@", NSStringFromRect(textFrame));
        nameView = [[WFFilePickerLabelView alloc] initWithFrame:textFrame];
		[nameView setBezeled:NO];
		[nameView setEditable:NO];
		[nameView setDrawsBackground:NO];
		[nameView setAutoresizingMask:(NSViewMaxXMargin | NSViewMaxYMargin | NSViewMinYMargin)];
		[nameView setStringValue:@"xyzzy.app"];
		[nameView setFilePicker:self];
		[[nameView cell] setLineBreakMode:NSLineBreakByTruncatingMiddle];
		[self addSubview:nameView];
		
		float chooseXOffset = textXOffset+textWidth;
		float chooseYOffset = 1.5;
		float chooseHeight = NSHeight(frame)-(chooseYOffset*2.0);
		NSRect chooseFrame = NSMakeRect(chooseXOffset,chooseYOffset,chooseWidth,chooseHeight);
//		NSLog(@"own choose: %@", NSStringFromRect(chooseFrame));
        chooseButton = [[NSButton alloc] initWithFrame:chooseFrame];

			[chooseButton setBezelStyle:12];


		[chooseButton setTitle:NSLocalizedString(@"Choose...", @"Label for Choose button in file picker")];
		[chooseButton sizeToFit];
		chooseFrame = [chooseButton frame];
		textFrame = [nameView frame];
		if ((chooseFrame.size.width + chooseFrame.origin.x) > frame.size.width) {
			float delta = (chooseFrame.size.width + chooseFrame.origin.x) - frame.size.width;
			chooseFrame.origin.x -= delta;
			textFrame.size.width -= delta;
		}
			chooseFrame.origin.y = floorf((frame.size.height - chooseFrame.size.height) / 2.0)+([chooseButton isFlipped] ? -1.0 : 1.0);
//			NSLog(@"own new choose: %@", NSStringFromRect(chooseFrame));
			[chooseButton setFrame:chooseFrame];
			[nameView setFrame:textFrame];
			chooseFrame = [chooseButton frame];
//		}
		[chooseButton setAutoresizingMask:(NSViewMinXMargin | NSViewMaxYMargin | NSViewMinYMargin)];
		[chooseButton setTarget:self];
		[chooseButton setAction:@selector(beginChooseSheet:)];
		[self addSubview:chooseButton];
		
		NSImage *emptyImage = SRResIndImage(@"SRRemoveShortcut");
		NSImage *emptyImagePressed = SRResIndImage(@"SRRemoveShortcutPressed");
		NSSize emptyImageSize = [emptyImage size];
		
		emptyButton = [[NSButton alloc] initWithFrame:NSMakeRect(0,NSMidY(chooseFrame)-(emptyImageSize.height/2.0),emptyImageSize.width,emptyImageSize.height)];
		[emptyButton setButtonType:NSMomentaryChangeButton];
//		[emptyButton setBezelStyle:NSShadowlessSquareBezelStyle];
		[emptyButton setBordered:NO];
		[emptyButton setImagePosition:NSImageOnly];
//		[[emptyButton cell] setShowsStateBy:NSContentsCellMask];
		[emptyButton setImage:emptyImage];
//		[emptyButton setImage:[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"SRRemoveShortcut" ofType:@"tif"]]];
		[emptyButton setAlternateImage:emptyImagePressed];
		[emptyButton setFrameSize:emptyImageSize];
		[emptyButton setHidden:YES];
		[emptyButton setAutoresizingMask:(NSViewMinXMargin | NSViewMaxYMargin | NSViewMinYMargin)];
		[emptyButton setTarget:self];
		[emptyButton setAction:@selector(doEmpty:)];
		[self addSubview:emptyButton];
		
		[self setEmpty];
		
    }
    return self;
}

- (BOOL)resolvesAliases {
//	NSLog(@"resolves aliases");
	return resolvesAliases;
}

- (void)setResolvesAliases:(BOOL)flag {
//	NSLog(@"set resolves aliases");
	resolvesAliases = flag;
}

- (BOOL)canChooseDirectories {
	return canChooseDirectories;
}

- (void)setCanChooseDirectories:(BOOL)flag {
	canChooseDirectories = flag;
}

- (BOOL)canChooseFiles {
	return canChooseFiles;
}

- (void)setCanChooseFiles:(BOOL)flag {
	canChooseFiles = flag;
}

- (NSArray *)allowedFileTypes {
	return allowedFileTypes;
}

- (void)setAllowedFileTypes:(NSArray *)types {
	if (types == allowedFileTypes) return;
	[allowedFileTypes release];
	allowedFileTypes = types;
	[allowedFileTypes retain];
}

- (IBAction)beginChooseSheet:(id)sender {
	[chooseButton setState:NSOnState];
	NSOpenPanel *op = [NSOpenPanel openPanel];
	if (nil != delegate) {
		if ([delegate respondsToSelector:@selector(filePicker:willShowOpenPanel:)]) {
			op = [delegate filePicker:self willShowOpenPanel:op];
			if (nil == op || ![op isKindOfClass:[NSOpenPanel class]]) op = [NSOpenPanel openPanel];
		}
	}
	[op setAllowedFileTypes:allowedFileTypes];
	[op setCanChooseDirectories:canChooseDirectories];
	[op setCanChooseFiles:canChooseFiles];
	[op setResolvesAliases:resolvesAliases];
	[op setAllowsMultipleSelection:NO];
	[op setPrompt:NSLocalizedString(@"Choose", @"Choose button in file picker's file sheet")];
	NSString *dir = nil; NSString *fil = nil;
	if ([self isNewURLValidChoice:representedURL]) {
		fil = [[representedURL path] lastPathComponent];
		dir = [[representedURL path] stringByDeletingLastPathComponent];
	}
	[op beginSheetForDirectory:dir
						  file:fil
						 types:allowedFileTypes
				modalForWindow:[self window]
				 modalDelegate:self
				didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
				   contextInfo:nil];
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo {
	if (returnCode == NSOKButton) {
		[self setRepresentedURL:[panel URL]];
	}
	[chooseButton setState:NSOffState];
	if (nil != delegate) {
		if ([delegate respondsToSelector:@selector(filePicker:openPanelDismissedWithReturnCode:)]) {
			[delegate filePicker:self openPanelDismissedWithReturnCode:returnCode];
		}
	}
}

- (void)setEmpty {
	currentFileIcon = nil;
	[iconView setImage:[[[NSImage alloc] initByReferencingFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/UnknownFSObjectIcon.icns"] autorelease]];
	[nameView setStringValue:NSLocalizedString(@"No file chosen", @"Grey label in file picker when no file is chosen")];
	[nameView setTextColor:WFLabelTextColorDimmedUnselected];
	[emptyButton setEnabled:NO];
	[representedURL release];
	representedURL = nil;
}

- (BOOL)isEmpty {
	return (nil == representedURL);
}

- (void)doEmpty:(id)sender {
	[self setEmpty];
	// foo
}

- (BOOL)showsEmptyButton {
	return showsEmptyButton;
}

- (void)reconfigureUI {
	NSRect chooseFrame = [chooseButton frame];
	NSRect textFrame = [nameView frame];
	NSRect emptyFrame = [emptyButton frame];
	
	if (showsEmptyButton) {
		double padding = 4.0;
		// Make way for the emptying button
		textFrame.size.width -= emptyFrame.size.width+padding;
		chooseFrame.origin.x -= emptyFrame.size.width+padding;
		emptyFrame.origin.x = NSMaxX(chooseFrame)+padding;
		emptyFrame.origin.y = (chooseFrame.origin.y)+NSMidY(chooseFrame)-(NSHeight(emptyFrame)/2.0)+1.0;
	} else {
		// Drop out the emptying button
		double delta = NSMaxX(emptyFrame)-NSMaxX(chooseFrame); // width + intercontrol padding
		textFrame.size.width += delta;
		chooseFrame.origin.x += delta;
		emptyFrame.origin.x += delta;
	}
	
	[nameView setFrame:textFrame];
	[chooseButton setFrame:chooseFrame];
	[emptyButton setFrame:emptyFrame];
	
	[emptyButton setHidden:!(showsEmptyButton)];
}

- (void)setShowsEmptyButton:(BOOL)set {
	if (set == showsEmptyButton) return;
	showsEmptyButton = set;
	
	[self reconfigureUI];
}

- (void)setFilePath:(NSString *)s { 
	NSURL *fu = [NSURL fileURLWithPath:s];
	if (nil == fu) return;
	[self setRepresentedURL:fu];
}

- (void)setRepresentedFSRef:(FSRef)r {
    CFURLRef cfurl = CFURLCreateFromFSRef(kCFAllocatorDefault,&r);
	[self setRepresentedURL:(NSURL *)cfurl];
    CFRelease(cfurl);
}

- (FSRef)representedFSRef {
	FSRef x;
	CFURLGetFSRef((CFURLRef)[self representedURL],&x);
	return x;
}

- (void)setRepresentedURL:(NSURL *)u {
	if (u == representedURL) return;
	if (![self isNewURLValidChoice:u]) return;
	[representedURL release];
	representedURL = u;
//	NSLog(@"set new represented URL: %@", representedURL);
	[emptyButton setEnabled:YES];
	[iconView setImage:[[NSWorkspace sharedWorkspace] iconForFile:[representedURL path]]];
	currentFileIcon = [[iconView image] copy];
	[nameView setStringValue:[[NSFileManager defaultManager] displayNameAtPath:[representedURL path]]];
	[nameView setTextColor:WFLabelTextColorOrdinary];
	[representedURL retain];

	[filePathObserver setValue:(filePathVT ? [filePathVT transformedValue:[self filePath]] : [self filePath]) forKeyPath:filePathObserverKeyPath];
}

- (NSString *)filePath { return [representedURL path]; }

- (NSURL *)representedURL { return representedURL; }

- (BOOL)representedFSRef:(FSRef *)ref {
	return (CFURLGetFSRef((CFURLRef)representedURL,ref));
}

- (void)drawRect:(NSRect)rect {
	if (isDropping) {
		if (!NSEqualSizes(rect.size,[self frame].size)) {
			[self setNeedsDisplay:YES];
			return;
		}
		[[NSColor selectedControlColor] setStroke];
	} else {
		[[NSColor clearColor] setStroke];
	}
	[NSBezierPath strokeRect:rect];
	[NSBezierPath strokeRect:NSInsetRect(rect,1.0,1.0)];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	NSPasteboard *pb = [sender draggingPasteboard];
	NSArray *pbtypes = [pb types];
	if ([pbtypes containsObject:NSURLPboardType]) {
		if ([self isNewURLValidChoice:[NSURL URLFromPasteboard:pb]])
			return [self setDroppingFlag:YES operation:NSDragOperationLink];
	} else if ([pbtypes containsObject:NSFilenamesPboardType]) {
		if ([self isNewURLValidChoice:[NSURL fileURLWithPath:[(NSArray *)[pb propertyListForType:NSFilenamesPboardType] objectAtIndex:0]]])
			return [self setDroppingFlag:YES operation:NSDragOperationLink];
	}
	return [self setDroppingFlag:NO operation:NSDragOperationNone];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
	[self setDroppingFlag:NO];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	NSPasteboard *pb = [sender draggingPasteboard];
	NSArray *pbtypes = [pb types];
	if ([pbtypes containsObject:NSURLPboardType]) {
		if ([self isNewURLValidChoice:[NSURL URLFromPasteboard:pb]])
			return YES;
	} else if ([pbtypes containsObject:NSFilenamesPboardType]) {
		if ([self isNewURLValidChoice:[NSURL fileURLWithPath:[(NSArray *)[pb propertyListForType:NSFilenamesPboardType] objectAtIndex:0]]])
			return YES;
	}
	return NO;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	NSPasteboard *pb = [sender draggingPasteboard];
	NSArray *pbtypes = [pb types];
	if ([pbtypes containsObject:NSURLPboardType]) {
		if ([self isNewURLValidChoice:[NSURL URLFromPasteboard:pb]]) {
			[self setRepresentedURL:(resolvesAliases ? [self resolveAlias:[NSURL URLFromPasteboard:pb]] : [NSURL URLFromPasteboard:pb])];
			return YES;
		}
	} else if ([pbtypes containsObject:NSFilenamesPboardType]) {
		if ([self isNewURLValidChoice:[NSURL fileURLWithPath:[(NSArray *)[pb propertyListForType:NSFilenamesPboardType] objectAtIndex:0]]]) {
			[self setRepresentedURL:(resolvesAliases ? [self resolveAlias:[NSURL fileURLWithPath:[(NSArray *)[pb propertyListForType:NSFilenamesPboardType] objectAtIndex:0]]] : [NSURL fileURLWithPath:[(NSArray *)[pb propertyListForType:NSFilenamesPboardType] objectAtIndex:0]])];
			return YES;
		}
	}
	return NO;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
	[self setDroppingFlag:NO];
}

-(void) rightMouseDown:(NSEvent *)theEvent {
	if (![self cmdFileMenuIsAvailable]) { [super rightMouseDown:theEvent]; return; }
	if (([theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask) == 0) {
		[self showCmdMenuForFileUsingEvent:theEvent];
		return;
	}
	[super rightMouseDown:theEvent];
}

- (void)mouseDown:(NSEvent *)ev {
	if (enabled && [ev clickCount] > 1) {
		[self beginChooseSheet:self];
	} else {
		if (![self isEnabled]) { [super mouseDown:ev]; return; }
		if (![self isEmpty] && ([ev modifierFlags] & NSCommandKeyMask)) {
			[self showCmdMenuForFileUsingEvent:ev];
			return;
		}
		[super mouseDown:ev];
	}
}

- (id)delegate {
	return delegate;
}

- (void)setDelegate:(id)del {
	if (del == delegate) return;
	[delegate release];
	delegate = del;
	[del retain];
}

- (void)dealloc {
	
	[currentFileIcon release];
	
	[chooseButton release];
	[iconView release];
	[nameView release];
	
	[representedURL release];
	
	[allowedFileTypes release];
	
	[super dealloc];
}

@end
