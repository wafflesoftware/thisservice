//
//  TSCreateServiceViewController.m
//  ThisService
//
//  Created by Jesper on 2006-10-28.
//  Copyright 2006-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import "TSCreateServiceViewController.h"
#import "WFFilePicker.h"

#import "NDAlias.h"
#import "NDAlias+AliasFile.h"

#import "NSAppleScript+HandlerCalls.h"

#import "TSCheckedListDataSource.h"

#import "TSStubbornImageView.h"

#import "IconFamily.h"

#import "TSServiceInputRules.h"

#import "TSService.h"

#import "TSServiceAppFilter.h"

#import "TSExtraCollectionView.h"

#define	ThisServiceServiceVersion	@"2"


@implementation TSCreateServiceViewController

@synthesize pathToUpcomingService, upcomingService, takesInput, producesOutput;

- (IBAction)specifyInputRules:(id)sender {
	inputRulesWindowController = [[TSServiceInputRulesWindowController alloc] initWithWindowNibName:@"TSServiceInputRulesWindowController"];
	[inputRulesWindowController setEditor:self];
	[inputRulesWindowController setInitialInputRules:inputRules];
	
	[NSApp beginSheet:[inputRulesWindowController window] modalForWindow:[[self view] window] modalDelegate:self didEndSelector:@selector(inputRulesSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (IBAction)specifyAppFilter:(id)sender {
	appFilterWindowController = [[TSServiceAppFilterWindowController alloc] initWithWindowNibName:@"TSServiceAppFilterWindowController"];
	[appFilterWindowController setEditor:self];
	[appFilterWindowController setInitialAppFilter:appFilter];
	
	[NSApp beginSheet:[appFilterWindowController window] modalForWindow:[[self view] window] modalDelegate:self didEndSelector:@selector(appFilterSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (BOOL)inputRulesSet {
	return inputRules && ![inputRules isEmpty];
}

+ (NSSet *)keyPathsForValuesAffectingInputRulesSet {
    return [NSSet setWithObject:@"inputRules"];
}

- (void)setInputRules:(TSServiceInputRules *)newRules {
	if (inputRules == newRules) return;
	[self willChangeValueForKey:@"inputRules"];
	[inputRules release];
	inputRules = [newRules retain];
	[self didChangeValueForKey:@"inputRules"];
}

- (void)setAppFilter:(TSServiceAppFilter *)newFilter {
    if (appFilter == newFilter) return;
	[self willChangeValueForKey:@"appFilter"];
    [appFilter release];
    appFilter = [newFilter retain];
	[self didChangeValueForKey:@"appFilter"];
    
    NSInteger count = newFilter == nil ? 0 : [newFilter.applicationIdentifiers count];
    NSString *status = nil;
    if (count == 0) {
        status = @"Usable from any application.";
    } else if (count == 1) {
        status = @"Usable from one application.";
    } else {
        status = [NSString stringWithFormat:@"Usable from %d applications.", count];
    }
    
    appFilterStatusLabel.stringValue = status;
}

- (void)serviceAppFilterWindowController:(TSServiceAppFilterWindowController *)windowController savedChanges:(TSServiceAppFilter *)newFilter {
    [self setAppFilter:newFilter];
	
	[NSApp endSheet:[windowController window]];
    
    if (newFilter) {
        [self addExtra:extraAppFilter];
    } else {
        [self removeExtra:extraAppFilter];
    }
    
}
- (void)serviceAppFilterWindowControllerCancelled:(TSServiceAppFilterWindowController *)windowController {
	
	[NSApp endSheet:[windowController window]];
    
}

- (void)serviceInputRulesWindowController:(TSServiceInputRulesWindowController *)windowController savedChanges:(TSServiceInputRules *)newRules {
	[self setInputRules:newRules];
	
	[NSApp endSheet:[windowController window]];
    
    if (![newRules isEmpty]) {
        [self addExtra:extraInputRules];
    } else {
        [self removeExtra:extraInputRules];
    }
}

- (void)serviceInputRulesWindowControllerCancelled:(TSServiceInputRulesWindowController *)windowController {
	[NSApp endSheet:[windowController window]];	
}

- (void)stubbornImageView:(TSStubbornImageView *)imageView changedImage:(NSImage *)image isStubbornDefault:(BOOL)isDefault {
	if (isDefault) {
		[iconLabel setStringValue:NSLocalizedString(@"Default service icon chosen", @"Default service icon text in service icon label")];
		[iconLabel setTextColor:[[NSColor textColor] colorWithAlphaComponent:0.7]];
	} else {
		[iconLabel setStringValue:NSLocalizedString(@"Service icon chosen", @"Custom service icon text in service icon label")];
		[iconLabel setTextColor:[NSColor textColor]];
	}	
}

@synthesize timeoutInSeconds;

static NSString *extraAppFilter = @"appFilter";
static NSString *extraInputRules = @"inputRules";
static NSString *extraServiceIcon = @"serviceIcon";
static NSString *extraReferenceScript = @"referenceScript";
static NSString *extraTimeout = @"timeout";

- (void)awakeFromNib {
    
    self.producesOutput = YES;
    self.takesInput = YES;
    
    self.timeoutInSeconds = 30;
    
    if ([extrasScrollView respondsToSelector:@selector(setHorizontalScrollElasticity:)]) {
        [extrasScrollView setHorizontalScrollElasticity:NSScrollElasticityNone];
        [extrasScrollView setVerticalScrollElasticity:NSScrollElasticityNone];
    }
    
    baseSize = self.view.frame.size;
    extraIncrement = 28;
    [extrasCollectionView registerWhenRemovedTarget:self action:@selector(removedExtra:)];
    
    [extrasCollectionView registerView:appFilterCollectionItemView forIdentifier:extraAppFilter];
    [extrasCollectionView registerView:inputRulesCollectionItemView forIdentifier:extraInputRules];
    [extrasCollectionView registerView:serviceIconCollectionItemView forIdentifier:extraServiceIcon];
    [extrasCollectionView registerView:referenceServiceCollectionItemView forIdentifier:extraReferenceScript];
    [extrasCollectionView registerView:timeoutCollectionItemView forIdentifier:extraTimeout];
    
	referenceType = TSServiceScriptCopied;
	
	[self stubbornImageView:iconView changedImage:[iconView image] isStubbornDefault:YES];
	
//    [filePicker setAllowedFileTypes:[NSArray arrayWithObjects:(NSString *)kUTTypeText, @"com.apple.applescript.text", @"com.apple.applescript.script", nil]];
    // Not using this line --^ since unknown file types will not be recognized as conforming to text types.
    
	[filePicker bind:@"filePath" toObject:self withKeyPath:@"filePath" options:[NSDictionary dictionary]];
    
    appFilter = nil;
}


- (TSServiceType)serviceType {
//	NSLog(@"asked to return type");
    return (producesOutput ? (takesInput ? TSServiceFilterType : TSServiceOutputOnlyType) : (takesInput ? TSServiceInputOnlyType : TSServiceNoInputOutputType));
}

- (void)setServiceName:(NSString *)_sn {
	if (_sn == serviceName) return;
	[self willChangeValueForKey:@"serviceName"];
	[serviceName release];
	serviceName = _sn;
	[serviceName retain];
	[self didChangeValueForKey:@"serviceName"];
}

- (NSString *)serviceName {
	return serviceName;
}

+ (NSSet *)keyPathsForValuesAffectingNameIsGiven {
    return [NSSet setWithObject:@"serviceName"];
}

+ (NSSet *)keyPathsForValuesAffectingScriptIsGiven {
    return [NSSet setWithObject:@"filePath"];
}

+ (NSSet *)keyPathsForValuesAffectingReadyToCreate {
    return [NSSet setWithObjects:@"filePath", @"serviceName", nil];
}

- (void)setFilePath:(NSString *)path {
	[self willChangeValueForKey:@"scriptIsGiven"];
	[self didChangeValueForKey:@"scriptIsGiven"];
	
	if ([serviceName length] == 0) {
        NSString *presumptiveName = [[path lastPathComponent] stringByDeletingPathExtension];
        if ([presumptiveName rangeOfString:@" "].location != NSNotFound) {
            [self setServiceName:presumptiveName];
        } else {
            [self setServiceName:[presumptiveName capitalizedString]];
        }
	}
}

- (NSString *)filePath {
	return [filePicker filePath];
}

- (BOOL)scriptIsGiven {
	return (!([filePicker isEmpty]));
}

- (BOOL)nameIsGiven {
	NSString *name = [serviceName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	return ([name length] > 0);
}

- (BOOL)readyToCreate {
	return [self scriptIsGiven] && [self nameIsGiven];
}

- (void)inputRulesSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[sheet orderOut:nil];
    [inputRulesWindowController release];
    inputRulesWindowController = nil;
}

- (void)appFilterSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[sheet orderOut:nil];
    [appFilterWindowController release];
    appFilterWindowController = nil;
}

- (void)testServiceSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[sheet orderOut:nil];
    [testWindowController release];
    testWindowController = nil;
}

+ (NSString *)stringByCleansingString:(NSString *)string fromCharactersNotInSet:(NSCharacterSet *)set {
	NSScanner *cleanseScanner = [NSScanner scannerWithString:string];
	[cleanseScanner setCharactersToBeSkipped:[set invertedSet]];
	NSString *cleansedName = @"";
	NSString *cleansedChunk = nil;
	while (!([cleanseScanner isAtEnd])) {
		[cleanseScanner scanUpToCharactersFromSet:set intoString:NULL];
		[cleanseScanner scanCharactersFromSet:set intoString:&cleansedChunk];
		cleansedName = [cleansedName stringByAppendingString:cleansedChunk];
		cleansedChunk = nil;
	}	
	return cleansedName;
}

+ (NSString *)cleanseName:(NSString *)name {
	static NSMutableCharacterSet *mcs = nil;
    if (!mcs) {
        mcs = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
        [mcs addCharactersInString:@" "];
    }
	return [self camelCize:[self stringByCleansingString:name fromCharactersNotInSet:mcs]];	
}

+ (NSString *)sanitizeName:(NSString *)name {
	return [self camelCize:[self stringByCleansingString:name fromCharactersNotInSet:[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 "]]];
}

+ (NSString *)camelCize:(NSString *)name {
	NSString *orig = name;
	NSArray *comps = [orig componentsSeparatedByString:@" "];
	NSMutableString *cc = [[comps objectAtIndex:0] mutableCopy];
	if ([comps count] > 1) {
		int i = 1;
		for (i = 1; i < [comps count]; i++) [cc appendString:[[comps objectAtIndex:i] capitalizedString]];
	}
	return [cc autorelease];
}

-(NSOpenPanel *)filePicker:(WFFilePicker *)aFilePicker willShowOpenPanel:(NSOpenPanel *)openPanel {
    [openPanel setAllowsOtherFileTypes:YES];
    return openPanel;
}

- (IBAction)chooseImage:(id)sender {
	NSOpenPanel *op = [NSOpenPanel openPanel];
	
	NSArray *imageFileTypesIncludingHFSTypes = [NSImage imageFileTypes];
	NSMutableArray *imageFileTypes = [NSMutableArray array];
	for (NSString *fileType in imageFileTypesIncludingHFSTypes) {
		OSType ostype = NSHFSTypeCodeFromFileType(fileType);
		if (ostype != 0) continue;
		[imageFileTypes addObject:fileType];
	}
	
	[op setAllowedFileTypes:imageFileTypes];
	[op setCanChooseFiles:YES];
	[op setResolvesAliases:YES];
	[op setAllowsMultipleSelection:NO];
	[op setMessage:@"Choose an icon for the service."];
	[op setPrompt:NSLocalizedString(@"Choose", @"Choose button in image picker's file sheet")];
	NSString *dir = nil; NSString *fil = nil;
	[op beginSheetForDirectory:dir
						  file:fil
						 types:imageFileTypes
				modalForWindow:[[self view] window]
				 modalDelegate:self
				didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
				   contextInfo:nil];
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo {
	if (returnCode == NSOKButton) {
		NSImage *im = [[NSImage alloc] initWithContentsOfURL:[panel URL]];
		[iconView setImage:[im autorelease]];
        
        [self addExtra:extraServiceIcon];
	}
}

-(void)testing:(TSServiceTestWindowController *)aTestWindowController failedFatally:(NSError *)error {
	[NSApp endSheet:[testWindowController window]];
    [testWindowController release];
    testWindowController = nil;
}

-(void)testingCancelled:(TSServiceTestWindowController *)aTestWindowController {
	[NSApp endSheet:[testWindowController window]];
    [testWindowController release];
    testWindowController = nil;
}

-(void)testingDone:(TSServiceTestWindowController *)aTestWindowController {
	[NSApp endSheet:[testWindowController window]];
    [testWindowController release];
    testWindowController = nil;
    [self produceServiceAfterTesting];
}

- (void)produceServiceAfterTesting {
    NSString *pathToService = self.pathToUpcomingService;
    
    TSService *service = self.upcomingService;
    
    NSFileWrapper *fw = [service upgradedServiceFileWrapper];
    
    NSURL *urlToService = [NSURL fileURLWithPath:pathToService];
    
    [fw writeToFile:pathToService atomically:YES updateFilenames:YES];
    
    [service writeReferenceAliasForServiceAtURL:urlToService];
    [service installServiceAfterFileWrapperWrittenAtURL:urlToService];
    
    pathToLatestService = [pathToService retain];
    
    self.pathToUpcomingService = nil;
    self.upcomingService = nil;
    
    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"The service %@ has been created and installed.", @"Brief message shown when the service is created."), serviceName] defaultButton:NSLocalizedString(@"OK", @"OK button for 'service has been created' sheet") alternateButton:nil otherButton:NSLocalizedString(@"Reveal in Finder", @"Reveal in Finder button for 'service has been created' sheet") informativeTextWithFormat:NSLocalizedString(@"The service is placed in Library/Services inside your home folder. It can be used immediately from other applications.\n\nTo set a keyboard shortcut for the service, visit the Keyboard preference pane in System Preferences and find your service under the Keyboard Shortcuts tab, Services.", @"Informative text for 'service has been created' sheet")];
    [alert beginSheetModalForWindow:[[self view] window]
                      modalDelegate:self
                     didEndSelector:@selector(createdServiceAlertDidEnd:returnCode:contextInfo:)
                        contextInfo:nil];
}

- (void)finishProducingService:(TSService *)service pathToService:(NSString *)pathToService {
    
    self.pathToUpcomingService = pathToService;
    self.upcomingService = service;
    
    if (([NSEvent modifierFlags] & NSAlternateKeyMask) == NSAlternateKeyMask) {
        [self produceServiceAfterTesting];
        return;
    }
    
	
    NSFileWrapper *fw = [service upgradedServiceFileWrapper];
    
    NSString *uuid = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *tryoutPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"thisservice-tryout-%@", uuid]];
    NSURL *urlToTryout = [NSURL fileURLWithPath:tryoutPath];
    
    [fw writeToFile:tryoutPath atomically:YES updateFilenames:NO];
    
    [service writeReferenceAliasForServiceAtURL:urlToTryout];
    TSServiceTester *tester = [service testRunServiceAfterFileWrapperWrittenAtURL:urlToTryout];
    
    testWindowController = [[TSServiceTestWindowController alloc] initWithTester:tester];
    testWindowController.delegate = self;
    
    NSWindow *window = [testWindowController window];
    
    if (!testWindowController.doomed) {
        [NSApp beginSheet:window modalForWindow:[[self view] window] modalDelegate:self didEndSelector:@selector(testServiceSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
    }
}

- (NSNumber *)resolvedTimeout {
    return [self alreadyHasExtra:extraTimeout] ? [NSNumber numberWithInteger:timeoutInSeconds] : nil;
}

- (IBAction)produceService:(id)sender {
	if ([filePicker isEmpty]) return;
	NSString *pathToScript = [filePicker filePath];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:pathToScript]) {
        NSAlert *alert = [[NSAlert alertWithMessageText:@"The service script chosen does not exist any longer." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please choose a service script again."] retain];
        [alert beginSheetModalForWindow:[[self view] window]
                          modalDelegate:self
                         didEndSelector:@selector(scriptMissingAlertDidEnd:returnCode:contextInfo:)
                            contextInfo:nil];
        return;
    }
	
	IconFamily *iconFamily = [self resolvedIcon];
    TSServiceAppFilter *resolvedAppFilter = [self resolvedAppFilter];
    TSServiceInputRules *resolvedInputRules = [self resolvedInputRules];
    
    referenceType = [self resolvedReferenceType];
    
    TSServiceType serviceType = [self serviceType];
    
    NSNumber *timeout = [self resolvedTimeout];
	
	TSService *service = [TSService serviceWithServiceName:serviceName
                                               serviceType:serviceType
                                       scriptReferenceType:referenceType
                                                inputRules:(resolvedInputRules == nil ? nil : [NSArray arrayWithObject:resolvedInputRules])
                                          timeoutInSeconds:timeout
                                                scriptPath:pathToScript
                                               serviceIcon:iconFamily
                                            applicationIDs:(resolvedAppFilter == nil ? nil : [resolvedAppFilter applicationIdentifiers])];
	
	NSString *serviceFileName = [service serviceFileName];
	NSString *pathToService = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Services"] stringByAppendingPathComponent:serviceFileName];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:pathToService]) {
		NSAlert *alertExists = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Another service called %@ already exists. Do you want to keep the old service?", @"Brief message shown when the service is created and a service already exists."), serviceName] defaultButton:NSLocalizedString(@"Keep and Rename", @"Command to keep a service with the same name when creating the service.") alternateButton:NSLocalizedString(@"Cancel", @"Command to cancel creating service when a service with the same name exists when creating the service.") otherButton:NSLocalizedString(@"Move to Trash", @"Command to trash a service with the same name when creating the service.") informativeTextWithFormat:@"Keeping the service will rename it. This may have unintended consequences."];
		serviceBeingCreated = [[NSDictionary alloc] initWithObjectsAndKeys:service, @"service", pathToService, @"pathToService", nil];
		[alertExists beginSheetModalForWindow:[[self view] window]
						  modalDelegate:self
						 didEndSelector:@selector(resolveExistingServiceAlertDidEnd:returnCode:contextInfo:)
							contextInfo:nil];
		return;
	}
	
	[self finishProducingService:service pathToService:pathToService];
	
	
}


- (void)scriptMissingAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[[alert window] orderOut:self];
    [filePicker setEmpty];
    [alert autorelease];
}

- (void)errorAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[[alert window] orderOut:self];	
}

- (void)resolveExistingServiceAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	TSService *service = [[serviceBeingCreated objectForKey:@"service"] retain];
	NSString *pathToService = [[serviceBeingCreated objectForKey:@"pathToService"] retain];
	[serviceBeingCreated release];
	serviceBeingCreated = nil;
	[[alert window] orderOut:self];
	
	if (returnCode == NSAlertDefaultReturn) {
		NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
		[df setDateStyle:NSDateFormatterBehavior10_4];
		[df setDateFormat:@"yyyy-MM-dd HH-mm-ss"];
		
		NSString *renamed = [[[pathToService stringByDeletingPathExtension] stringByAppendingFormat:@" %@", [df stringFromDate:[NSDate date]]] stringByAppendingPathExtension:[pathToService pathExtension]];
		NSError *error = nil;
		if (![[NSFileManager defaultManager] moveItemAtPath:pathToService toPath:renamed error:&error] && error) {
			[[NSAlert alertWithError:error] beginSheetModalForWindow:[[self view] window]
													   modalDelegate:self
													  didEndSelector:@selector(errorAlertDidEnd:returnCode:contextInfo:)
														 contextInfo:nil];
		}
		
		[self finishProducingService:service pathToService:pathToService];
	} else if (returnCode == NSAlertOtherReturn) {
		int tag;
		[[NSWorkspace sharedWorkspace]
				performFileOperation:NSWorkspaceRecycleOperation
				source:[pathToService stringByDeletingLastPathComponent]
				destination:@""
				files:[NSArray arrayWithObject:[pathToService lastPathComponent]]
				tag:&tag];
		
		[self finishProducingService:service pathToService:pathToService];
	}
	
	[service autorelease];
	[pathToService autorelease];
}


- (void)createdServiceAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if (returnCode == NSAlertOtherReturn) {
		[[NSWorkspace sharedWorkspace] selectFile:pathToLatestService inFileViewerRootedAtPath:[pathToLatestService stringByDeletingLastPathComponent]];
		[pathToLatestService release];
	}
	[[alert window] orderOut:self];
}

- (BOOL)shouldOpenFileAtPath:(NSString *)filePath {
	[filePicker setFilePath:filePath];
	return YES;
}

- (IBAction)help:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"createhelp" inBook:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleHelpBookName"]];
}

-(BOOL)collectionView:(NSCollectionView *)collectionView canDragItemsAtIndexes:(NSIndexSet *)indexes withEvent:(NSEvent *)event {
    return NO;
}

- (void)resizeForExtraList {
    NSSize newSize = baseSize;
    newSize.height += ([[extrasCollectionView content] count] * extraIncrement);
    [self.container resizeViewController:self toNewContentSize:newSize animate:YES];
}

- (void)removedExtra:(id)sender {
    [self resizeForExtraList];
    [extrasDropDown setEnabled:YES];
}



NSInteger sortedExtrasCompare(id a, id b, void *unusedCtx) {
    static NSArray *sortedExtras = nil;
    if (!sortedExtras) {
        sortedExtras = [[NSArray arrayWithObjects:extraServiceIcon,
                         extraTimeout, extraAppFilter, extraInputRules, extraReferenceScript, nil] retain];
    }
    return [[NSNumber numberWithInteger:[sortedExtras indexOfObject:a]] compare:[NSNumber numberWithInteger:[sortedExtras indexOfObject:b]]];
}

- (BOOL)addExtra:(NSString *)extra {
    NSArray *co = [extrasCollectionView content];
    if (!co) {
        co = [NSArray array];
    }
    if ([co containsObject:extra]) return NO;
    NSArray *newContent = [co arrayByAddingObject:extra];
    if ([newContent count] == 5) {
        [extrasDropDown setEnabled:NO];
    }
    NSArray *sortedNewContent = [newContent sortedArrayUsingFunction:sortedExtrasCompare context:NULL];
    
    [extrasCollectionView setContent:sortedNewContent];
//    NSLog(@"set cv items from %@ to %@", co, sortedNewContent);
    [self resizeForExtraList];
    return YES;
}

- (BOOL)removeExtra:(NSString *)extra {
    NSArray *co = [extrasCollectionView content];
    if (!co) {
        co = [NSArray array];
    }
    if (![co containsObject:extra]) return NO;
    NSMutableArray *newContent = [[co mutableCopy] autorelease];
    [newContent removeObject:extra];
    
    [extrasCollectionView setContent:newContent];
//    NSLog(@"set cv items from %@ to %@", co, newContent);
    [self resizeForExtraList];
    [extrasDropDown setEnabled:YES];
    return YES;
}

- (BOOL)alreadyHasExtra:(NSString *)extra {
    NSArray *co = [extrasCollectionView content];
    if (!co) {
        return NO;
    }
    return [co containsObject:extra];
}

- (TSServiceScriptReferenceType)resolvedReferenceType {
    return [self alreadyHasExtra:extraReferenceScript] ? TSServiceScriptReferenced : TSServiceScriptCopied;
}

- (TSServiceInputRules *)resolvedInputRules {
    return [self alreadyHasExtra:extraInputRules] ? inputRules : nil;
}

- (IconFamily *)resolvedIcon {
    BOOL hasIcon = (![iconView isStubbornDefault]);
	IconFamily *iconFamily = nil;
	
	if (hasIcon) {
		iconFamily = [IconFamily iconFamilyWithThumbnailsOfImage:[iconView image]];
	}
    return [self alreadyHasExtra:extraServiceIcon] ? iconFamily : nil;
}

- (TSServiceAppFilter *)resolvedAppFilter {
    return [self alreadyHasExtra:extraAppFilter] ? appFilter : nil;
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    NSString *extra = nil;
    SEL action = [menuItem action];
    if (action == @selector(addAppFilterExtra:)) {
        extra = extraAppFilter;
    } else if (action == @selector(addInputRulesExtra:)) {
        extra = extraInputRules;
    } else if (action == @selector(addServiceIconExtra:)) {
        extra = extraServiceIcon;
    } else if (action == @selector(addReferenceServiceExtra:)) {
        extra = extraReferenceScript;
    } else if (action == @selector(addTimeoutExtra:)) {
        extra = extraTimeout;
    }
    if (extra) return ![self alreadyHasExtra:extra];
    
    return NO;
}

- (IBAction)addAppFilterExtra:(id)sender {
//    [self addExtra:extraAppFilter];
    [self specifyAppFilter:sender];
}
- (IBAction)addInputRulesExtra:(id)sender {
//    [self addExtra:extraInputRules];
    [self specifyInputRules:sender];
}
- (IBAction)addServiceIconExtra:(id)sender {
//    [self addExtra:extraServiceIcon];
    [self chooseImage:sender];
}
- (IBAction)addReferenceServiceExtra:(id)sender {
    [self addExtra:extraReferenceScript];
}

- (IBAction)addTimeoutExtra:(id)sender {
    [self addExtra:extraTimeout];
}
@end