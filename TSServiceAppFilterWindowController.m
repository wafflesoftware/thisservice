//
//  TSServiceAppFilterWindowController.m
//  ThisService
//
//  Created by Jesper on 2012-07-01.
//  Copyright 2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//
//

#import "TSServiceAppFilterWindowController.h"

#import "TSServiceAppFilter.h"

#import "NSWorkspace+SmallIcon.h"

@interface TSServiceAppFilterEntry : NSObject {
    NSString *_appID;
    NSString *_name;
    NSImage *_appIcon;
}
@property (retain) NSString *appID;
@property (retain) NSString *name;
@property (retain) NSImage *appIcon;
+ (TSServiceAppFilterEntry *)entryWithAppID:(NSString *)appID;
+ (TSServiceAppFilterEntry *)entryWithAppAtURL:(NSURL *)appURL;
- (TSServiceAppFilterEntry *)initWithAppID:(NSString *)appID name:(NSString *)name appIcon:(NSImage *)appIcon;
- (NSComparisonResult)compareEntry:(TSServiceAppFilterEntry *)other;
@end

@implementation TSServiceAppFilterEntry

@synthesize appID=_appID, name=_name, appIcon=_appIcon;

- (NSComparisonResult)compareEntry:(TSServiceAppFilterEntry *)other {
    SEL maybeAvailableCompareSelector = @selector(localizedStandardCompare:);
    NSComparisonResult nameComparison;
    if ([NSString instancesRespondToSelector:maybeAvailableCompareSelector]) {
        nameComparison = [self.name localizedStandardCompare:other.name];
    } else {
        nameComparison = [self.name localizedCaseInsensitiveCompare:other.name];
    }
    
    if (nameComparison != NSOrderedSame) return nameComparison;
    
    return [self.appID compare:other.appID options:NSCaseInsensitiveSearch];
}

- (TSServiceAppFilterEntry *)initWithAppID:(NSString *)appID name:(NSString *)name appIcon:(NSImage *)appIcon
{
    self = [super init];
    if (self) {
        _appID = [appID retain];
        _name = [name retain];
        _appIcon = [appIcon retain];
    }
    return self;
}


+ (TSServiceAppFilterEntry *)entryWithAppID:(NSString *)appID url:(NSURL *)url {
    if (!appID) return nil;
    
    if (url) {
        NSString *path = [url path];
        
        NSImage *icon = [[NSWorkspace sharedWorkspace] smallIconForFileAtPath:path];
        NSString *name = [[NSFileManager defaultManager] displayNameAtPath:path];
        
        return [[[self alloc] initWithAppID:appID name:name appIcon:icon] autorelease];
    } else {
        return [[[self alloc] initWithAppID:appID name:nil appIcon:nil] autorelease];
    }
    
}

+ (TSServiceAppFilterEntry *)entryWithAppID:(NSString *)appID {
    NSURL *url = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:appID];
    return [self entryWithAppID:appID url:url];
}

+ (TSServiceAppFilterEntry *)entryWithAppAtURL:(NSURL *)appURL {
    NSString *extension = [[appURL path] pathExtension];
    if (![extension isEqualToString:@"app"]) return nil;
    NSBundle *bundle = [NSBundle bundleWithURL:appURL];
    if (bundle) {
        NSString *identifier = [bundle bundleIdentifier];
        if (identifier) {
            return [self entryWithAppID:identifier];
        }
    }
    
    return nil;
}

@end

@interface TSServiceAppFilterWindowController ()

@end

@implementation TSServiceAppFilterWindowController
@synthesize applicationDropDown;
@synthesize okButton;
@synthesize tableView;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)setInitialAppFilter:(TSServiceAppFilter *)anInitialAppFilter {
	initialAppFilter = [anInitialAppFilter retain];
}

- (void)setEditor:(id<TSServiceAppFilterWindowControllerDelegate>)newEditor {
	editor = newEditor;
}

- (void)setApps:(NSMutableArray *)newApps {
    [apps autorelease];
    apps = [newApps retain];
    NSMutableSet *newAppIDsInUse = [NSMutableSet set];
    for (TSServiceAppFilterEntry *entry in apps) {
        [newAppIDsInUse addObject:entry.appID];
    }
//    [okButton setEnabled:enabled];
    [appIDsInUse autorelease];
    appIDsInUse = [newAppIDsInUse retain];
}

-(void)awakeFromNib {
//    [okButton setEnabled:NO];
    
    NSSet *appIDs = (initialAppFilter == nil ? [NSSet set] : initialAppFilter.applicationIdentifiers);
    
    NSMutableArray *appsByName = [NSMutableArray array];
    
    for (NSString *appID in appIDs) {
        TSServiceAppFilterEntry *entry = [TSServiceAppFilterEntry entryWithAppID:appID];
        if (entry) {
            [appsByName addObject:entry];
        }
    }
    [appsByName sortUsingSelector:@selector(compareEntry:)];
    
    [self setApps:appsByName];
    
    [tableView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, NSURLPboardType, nil]];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSArray *candidates = [NSArray arrayWithObjects:@"/Applications", @"/Applications/Utilities", [@"~/Applications" stringByExpandingTildeInPath], nil];
    NSMutableArray *entries = [NSMutableArray array];
    for (NSString *path in candidates) {
        NSArray *folderenum = [fm contentsOfDirectoryAtPath:path error:NULL];
        if (!folderenum) continue;
        
        for (NSString *filename in folderenum) {
            if (![[filename pathExtension] isEqualToString:@"app"]) continue;
            NSString *fullPath = [path stringByAppendingPathComponent:filename];
            BOOL isDir;
            if (![fm fileExistsAtPath:fullPath isDirectory:&isDir] || !isDir) continue;
            
            NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
            TSServiceAppFilterEntry *entry = [TSServiceAppFilterEntry entryWithAppAtURL:fileURL];
            if (!entry) continue;
            [entries addObject:entry];
        }
    }
    
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    
    NSURL *urlToFinder = [workspace URLForApplicationWithBundleIdentifier:@"com.apple.Finder"];
    if (urlToFinder) {
        TSServiceAppFilterEntry *entryToFinder = [TSServiceAppFilterEntry entryWithAppAtURL:urlToFinder];
        [entries addObject:entryToFinder];
    }
    
    [entries sortUsingSelector:@selector(compareEntry:)];
    NSMenu *menu = [applicationDropDown menu];
    NSInteger numberOfItems = [menu numberOfItems];
    for (NSInteger menuIndex = 1; menuIndex < numberOfItems; menuIndex++) {
        NSInteger yesLiterallyTheIndexOne = 1;
        [menu removeItemAtIndex:yesLiterallyTheIndexOne];
    }
    for (TSServiceAppFilterEntry *entry in entries) {
        NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:entry.name action:@selector(addApplication:) keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:entry];
        [menuItem setImage:[workspace smallIconForFileAtPath:[[workspace URLForApplicationWithBundleIdentifier:entry.appID] path]]];
        [menu addItem:menuItem];
    }
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if (menuItem.action == @selector(addApplication:)) {
        TSServiceAppFilterEntry *entry = menuItem.representedObject;
        return !([appIDsInUse containsObject:entry.appID]);
    }
    return [super validateMenuItem:menuItem];
}

- (void)addApplication:(id)sender {
    NSMenuItem *item = sender;
    TSServiceAppFilterEntry *newEntry = [item representedObject];
    
    
    NSMutableArray *allCurrentApps = [[apps mutableCopy] autorelease];
    
    BOOL added = NO;
    
        for (TSServiceAppFilterEntry *existingEntry in allCurrentApps) {
            if ([existingEntry.appID isEqualToString:newEntry.appID]) {
                newEntry = nil;
                break;
            }
        }
        if (newEntry) {
            [allCurrentApps addObject:newEntry];
            added = YES;
        }
    
    if (!added) return;
    
    [allCurrentApps sortUsingSelector:@selector(compareEntry:)];
    [self setApps:allCurrentApps];
    [tableView reloadData];
    [tableView deselectAll:nil];
    
    [self willChangeValueForKey:@"canDelete"];
    [self didChangeValueForKey:@"canDelete"];
    
    return;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    [self willChangeValueForKey:@"canDelete"];
    [self didChangeValueForKey:@"canDelete"];
}

+ (NSSet *)keyPathsForValuesAffectingCanDelete {
    return [NSSet setWithObject:@"tableView.selectedRow"];
}

- (BOOL)canDelete {
    if (!apps) return NO;
    NSInteger appCount = [apps count];
    if (appCount == 0) return NO;
    return [[tableView selectedRowIndexes] count] > 0;
}


- (void)deleteSelectedRows {
    NSIndexSet *selectedRows = [tableView selectedRowIndexes];
    if (selectedRows && [selectedRows count]) {
        NSMutableArray *newApps = [apps mutableCopy];
        [newApps removeObjectsAtIndexes:selectedRows];
        [self setApps:[newApps autorelease]];
        [tableView reloadData];
        if ([[tableView selectedRowIndexes] count] > 1) {
            [tableView deselectAll:nil];
        }
        if ([apps count] == 0) {
            [tableView deselectAll:nil];
        }
    }
    [self willChangeValueForKey:@"canDelete"];
    [self didChangeValueForKey:@"canDelete"];
}

-(BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
    NSPasteboard *pboard = [info draggingPasteboard];
    
    NSMutableArray *candidateApps = [NSMutableArray array];
    
    if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        for (NSString *path in files) {
            if ([[path pathExtension] isEqualToString:@"app"]) {
                [candidateApps addObject:path];
            }
        }
    } else if ( [[pboard types] containsObject:NSURLPboardType] ) {
        NSURL *fileURL = [NSURL URLFromPasteboard:pboard];
        if ([[[fileURL path] pathExtension] isEqualToString:@"app"]) {
            [candidateApps addObject:[fileURL path]];
        }
    }
    
    
    
    NSMutableArray *allCurrentApps = [[apps mutableCopy] autorelease];
    
    BOOL added = NO;
    
    for (NSString *capp in candidateApps) {
        TSServiceAppFilterEntry *newEntry = [TSServiceAppFilterEntry entryWithAppAtURL:[NSURL fileURLWithPath:capp]];
        for (TSServiceAppFilterEntry *existingEntry in allCurrentApps) {
            if ([existingEntry.appID isEqualToString:newEntry.appID]) {
                newEntry = nil;
                break;
            }
        }
        if (newEntry) {
            [allCurrentApps addObject:newEntry];
            added = YES;
        }
    }
    
    if (!added) return NO;
            
    [allCurrentApps sortUsingSelector:@selector(compareEntry:)];
    [self setApps:allCurrentApps];
    [tableView reloadData];
    [tableView deselectAll:nil];
    
    [self willChangeValueForKey:@"canDelete"];
    [self didChangeValueForKey:@"canDelete"];
    
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
    NSPasteboard *pboard = [info draggingPasteboard];
    
    NSMutableArray *candidateApps = [NSMutableArray array];
    
    if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        for (NSString *path in files) {
            if ([[path pathExtension] isEqualToString:@"app"]) {
                [candidateApps addObject:path];
            }
        }
    } else if ( [[pboard types] containsObject:NSURLPboardType] ) {
        NSURL *fileURL = [NSURL URLFromPasteboard:pboard];
        if ([[[fileURL path] pathExtension] isEqualToString:@"app"]) {
            [candidateApps addObject:[fileURL path]];
        }
    }
    
    for (NSString *capp in candidateApps) {
        TSServiceAppFilterEntry *newEntry = [TSServiceAppFilterEntry entryWithAppAtURL:[NSURL fileURLWithPath:capp]];
        for (TSServiceAppFilterEntry *existingEntry in apps) {
            if ([existingEntry.appID isEqualToString:newEntry.appID]) {
                newEntry = nil;
                break;
            }
        }
        if (newEntry) {
            NSMutableArray *allCurrentApps = [[apps mutableCopy] autorelease];
            [allCurrentApps addObject:newEntry];
            [allCurrentApps sortUsingSelector:@selector(compareEntry:)];
            NSUInteger idxOfNew = [allCurrentApps indexOfObject:newEntry];
            if (idxOfNew != NSNotFound) {
                [tableView setDropRow:idxOfNew dropOperation:NSTableViewDropAbove];
                return NSDragOperationCopy;
            }
        }
    }
    
    return NSDragOperationNone;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    NSInteger appCount = [apps count];
    if (appCount == 0) return 1;
	return appCount;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSInteger appCount = [apps count];
    BOOL emptyRow = (appCount == 0);
    TSServiceAppFilterEntry *entry = (emptyRow ? nil : [apps objectAtIndex:row]);
    
	NSUInteger idxOfColumn = [[tableView tableColumns] indexOfObject:tableColumn];
	if (idxOfColumn == 0) {
        if (emptyRow) return nil;
        return entry.appIcon;
	} else if (idxOfColumn == 1) {
        if (emptyRow) return @"All applications";
        if (!entry.name) return @"?";
        return entry.name;
	} else if (idxOfColumn == 2) {
        if (emptyRow) return @"";
        return entry.appID;
    }
    return nil;
}

- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes {
    NSInteger appCount = [apps count];
    BOOL emptyRow = (appCount == 0);
    [self willChangeValueForKey:@"canDelete"];
    [self didChangeValueForKey:@"canDelete"];
    if (emptyRow) return [NSIndexSet indexSet];
    return proposedSelectionIndexes;
}
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if (tableColumn == nil) return;
    
    NSInteger appCount = [apps count];
    BOOL emptyRow = (appCount == 0);
    BOOL emptyRowOrNoName = emptyRow ? YES : ((TSServiceAppFilterEntry *)[apps objectAtIndex:row]).name == nil;
    
	NSUInteger idxOfColumn = [[tableView tableColumns] indexOfObject:tableColumn];
	if (idxOfColumn == 1) {
        NSColor *color = (emptyRowOrNoName ? [[NSColor textColor] colorWithAlphaComponent:0.6] : [NSColor textColor]);
        [aCell setTextColor:color];
	}
}


- (IBAction)done:(id)sender {
    
    NSSet *appIDs = [NSSet setWithArray:[apps valueForKey:@"appID"]];
    
    TSServiceAppFilter *appFilter = appIDs.count == 0 ? nil : [TSServiceAppFilter appFilterWithApplicationIdentifiers:appIDs];
    
    [editor serviceAppFilterWindowController:self savedChanges:appFilter];
}

- (IBAction)cancel:(id)sender {
	[editor serviceAppFilterWindowControllerCancelled:self];
}

- (IBAction)deleteSelectedRowsByButton:(id)sender {
    [self deleteSelectedRows];
}

- (void)dealloc {
    [apps release];
    [appIDsInUse release];
    [initialAppFilter release];
    
    [super dealloc];
}
@end
