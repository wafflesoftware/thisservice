//
//  TSZip.m
//  ThisService
//
//  Created by Jesper on 2007-04-23.
//  Copyright 2007-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import "TSZip.h"

@implementation TSZip
/*
 
 When you want to save your document as a Zip file.
 using
 cocoadev.com
 http://www.cocoadev.com/index.pl?UsingZipFilesExamples
 
*/

static BOOL logging = NO;
#define TSZLog(...)    do { if (logging) { NSLog(__VA_ARGS__); } } while (0)

+ (void)cleanseFileWrapperOfIcons:(NSFileWrapper *)fw {
	if (nil != [fw icon]) [fw setIcon:nil];
	if (nil != [fw fileWrappers] || [[fw fileWrappers] count] == 0) return;
	NSDictionary *wrappers = [fw fileWrappers];
	NSEnumerator *fwEnumerator = [wrappers keyEnumerator];
	NSString *fwN;
	while (fwN = [fwEnumerator nextObject]) {
		NSFileWrapper *innerFW = [[fw fileWrappers] objectForKey:fwN];
		[self cleanseFileWrapperOfIcons:innerFW];
	} 
}

+ (NSData *)zip:(id)raw //raw must be NSData or NSFileWrapper
{
	TSZLog(@"ThisService zipping...");	
	CFUUIDRef uuidcf = CFUUIDCreate(NULL);
    NSString *uuid = (NSString *)CFUUIDCreateString(NULL, uuidcf);
    CFRelease(uuidcf);
	NSString *scratchFolder = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"thisservice-zip-%@", uuid]];
	[uuid release];

	TSZLog(@"scratch folder: %@", scratchFolder);
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSError *err;
    if (![fm createDirectoryAtPath:scratchFolder withIntermediateDirectories:NO attributes:nil error:&err]) {
        TSZLog(@"could not create scratch folder at %@ because of %@", scratchFolder, err);
        return nil;
    }
	
	TSZLog(@"created scratch folder");
	
	NSString *sourceFilename = @"data";
	NSString *targetFilename = @"zipped data";
	
	NSString *sourcePath = [scratchFolder stringByAppendingPathComponent:sourceFilename];
	NSString *targetPath = [scratchFolder stringByAppendingPathComponent:targetFilename];
	
	TSZLog(@"source path: %@, target path: %@", sourcePath, targetPath);
	
	BOOL flag = NO;
	if([raw isKindOfClass:[NSData class]]) {
		TSZLog(@"is data");
		flag = [raw writeToFile:sourcePath atomically:YES];
	}
	else if([raw isKindOfClass:[NSFileWrapper class]]) {
		TSZLog(@"is filewrapper");
		NSFileWrapper *fw = raw;
		//NSLog(@"fileWrappers: %@", [fw fileWrappers]);
		NSArray *files = [[fw fileWrappers] allKeys];
		TSZLog(@"files: %@", files);
		[self cleanseFileWrapperOfIcons:fw];
		//NSLog(@"cleansed: %@", fw);
		flag = [raw writeToFile:sourcePath atomically:YES updateFilenames:YES];
		TSZLog(@"wrote to file");
		NSEnumerator *fileEnumerator = [files objectEnumerator];
		NSString *file;
		while (file = [fileEnumerator nextObject]) {
			NSString *pathToGeneratedSuperfluosIcon = [[sourcePath stringByAppendingPathComponent:file] stringByAppendingPathExtension:@"tiff"];
			if ([fm fileExistsAtPath:pathToGeneratedSuperfluosIcon]) {
				TSZLog(@"horrible NSFileWrapper-generated icon exists for %@, let's remove it", file);
                [fm removeItemAtPath:pathToGeneratedSuperfluosIcon error:NULL];
			}
		} 
	}
	
	if(flag == NO) {
		TSZLog(@"could not write file when zipping");
		return nil;
	}
	
	/* Assumes sourcePath and targetPath are both
		valid, standardized paths. */
	
	//----------------
	// Create the zip task
	
	TSZLog(@"starting zip task");
	
	NSTask * backupTask = [[NSTask alloc] init];
	[backupTask setLaunchPath:@"/usr/bin/ditto"];
	[backupTask setArguments:
		[NSArray arrayWithObjects:@"-c", @"-k", @"-X", @"--sequesterRsrc",
			sourcePath, targetPath, nil]];

	TSZLog(@"launching");
	
	// Launch it and wait for execution
	[backupTask launch];
	TSZLog(@"launched");
	[backupTask waitUntilExit];
	
	int terminationStatus = [backupTask terminationStatus];
	
	[backupTask release];	
	
	TSZLog(@"exited, termstatus: %d", terminationStatus);
	
	// Handle the task's termination status
	if (terminationStatus != 0) {
		TSZLog(@"Sorry, didn't work.");
		return nil;
	}
	
	NSData *convertedData = [[NSData alloc] initWithContentsOfFile:targetPath];

	TSZLog(@"created converted data");
	
	//delete scratch

	TSZLog(@"deleting scratch folders");
    
	
    NSError *removeScratchFolderError = nil;
    TSZLog(@"scratch folder: %@", scratchFolder);
    [[NSFileManager defaultManager] removeItemAtPath:scratchFolder error:&removeScratchFolderError];
	TSZLog(@"remove scratch folder: %@ error %@", scratchFolder, removeScratchFolderError);
	
	return [convertedData autorelease];
}
@end
