//
//  ServiceSkeletonMagic.m
//  ThisService
//
//  Created by Jesper on 2006-10-28.
//  Copyright 2006-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import "ServiceSkeletonMagic.h"
#import "NSAppleScript+HandlerCalls.h"
#include <sys/types.h>
#include <sys/stat.h>

#import "../NDAlias.h"
#import "../NDAlias+AliasFile.h"

@interface ServiceSkeletonMagic (DeepInternalVoodoo)
- (NSURL *)URLToCorrectScript:(NSString *)filename;
@end

static NSString *ServiceSkeletonErrorDomain = @"net.wafflesoftware.ThisService.ServiceSkeleton.ErrorDomain";

@implementation ServiceSkeletonMagic

static BOOL shouldKeepRunning = YES;
+ (BOOL)shouldKeepRunning {
    return shouldKeepRunning;
}

static BOOL logging = NO;
+ (void)setLogging:(BOOL)nl {
    logging = nl;
}

@synthesize producer=_producer, connection=_connection, connectionName=_connectionName;

- (id)init {
	self = [super init];
	if (self != nil) {
		outputsForFileHandles = [[NSMutableDictionary alloc] init];
        _connectionName = [[NSString stringWithFormat:@"thisservice-skeleton-%@", [[NSProcessInfo processInfo] globallyUniqueString]] retain];
	}
	return self;
}

-(BOOL)vendSkeleton {
    NSConnection *theConnection = [NSConnection serviceConnectionWithName:_connectionName rootObject:self];
    self.connection = theConnection;
    
    return (theConnection != nil);
}

- (void)setUpServiceTesting:(NSString *)testingServiceConnectionName {
    if (![self vendSkeleton]) {
        SLog(@"Could not register NSConnection name %@", self.connectionName);
        exit(-1);
    }
    
    SLog(@"Producer connection name: %@", testingServiceConnectionName);
    
    id proxyOfProducer = [NSConnection rootProxyForConnectionWithRegisteredName:testingServiceConnectionName host:nil];
    [proxyOfProducer setProtocolForProxy:@protocol(TSServiceTestingProducer)];
    NSConnection *conn = [proxyOfProducer connectionForProxy];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionDied:) name:NSConnectionDidDieNotification object:conn];
    
    SLog(@"Connected to producer: %@", proxyOfProducer);
    
    [self registerProducer:proxyOfProducer];

}

- (void)connectionDied:(NSNotification *)not {
    SLog(@"Connection died; give up!");
    shouldKeepRunning = NO;
}

-(NSString *)connectionName {
    return  _connectionName;
}

- (void)registerProducer:(id<TSServiceTestingProducer>)p {
    _producer = [p retain];
    
    SLog(@"Registered producer: %@", p);
    
    [_producer registerNewSkeletonNamed:_connectionName];
    SLog(@"Called registerNewSkeletonNamed: %@", _connectionName);
}


-(oneway void)invokeServiceWithPasteboard:(NSString *)pasteboardName {
    [self performSelectorOnMainThread:@selector(doInvokeServiceWithPasteboard:) withObject:pasteboardName waitUntilDone:NO];
}

- (void)tearDown {
//    NSLog(@"told to tear down; shouldKeepRunning is %d; connection: %@", shouldKeepRunning, self.connection);
    [self.connection invalidate];
}

- (oneway void)testingDone {
    shouldKeepRunning = NO;
//    NSLog(@"TS# testing done! shut down; set shouldKeepRunning to %d", shouldKeepRunning);
    [self performSelectorOnMainThread:@selector(tearDown) withObject:nil waitUntilDone:NO];
}


- (NSDictionary *)serviceInfo {
	NSDictionary *infoPlist = [[NSBundle bundleForClass:[self class]] infoDictionary];
	NSArray *servicesArray = (NSArray *)[infoPlist objectForKey:@"NSServices"];
	NSDictionary *ourService = [[servicesArray objectAtIndex:0] copy];
	return [ourService autorelease];
}


- (void)doInvokeServiceWithPasteboard:(NSString *)pasteboardName {
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:pasteboardName];
    
    [_producer testRunForSkeletonStarted:_connectionName];
    
    NSDictionary *ourService = [self serviceInfo];
	NSString *script = [ourService objectForKey:@"NSUserData"];
    
    NSString *error = nil;
    
    [self doServiceWork:pboard userData:script error:&error];
    
    [_producer testRunForSkeleton:_connectionName ended:error];
    
//    shouldKeepRunning = NO;
    
}
- (NSURL *)urlToScript {
	NSDictionary *ourService = [self serviceInfo];
	NSString *script = [ourService objectForKey:@"NSPortName"];
	return [self URLToCorrectScript:script];
}

- (void)doServiceWork:(NSPasteboard *)pboard
			  userData:(NSString *)userData
				 error:(NSString **)error {
    
    isRunning = YES;
	
    NSString *pboardString;
    NSArray *types;
	
	BOOL expectingInput = NO;
	BOOL expectingOutput = NO;
	
	NSString *script = nil;
	
	NSDictionary *ourService = [self serviceInfo];
	if ([ourService objectForKey:@"NSSendTypes"]) {
		expectingInput = YES;
	}
	if ([ourService objectForKey:@"NSReturnTypes"]) {
		expectingOutput = YES;
	}
	
	script = userData;
	
	SLog(@"Service %@ expects input? %@ output? %@", [[ourService objectForKey:@"NSMenuItem"] objectForKey:@"default"],  (expectingInput ? @"yep" : @"nope"), (expectingOutput ? @"yep" : @"nope"));
	
	NSData *inputData = [NSData data];
	
	if (expectingInput) {
		types = [pboard types];
		if (![types containsObject:NSStringPboardType]) {
			*error = NSLocalizedString(@"Error: couldn't extract string data from pboard.",
									   @"couldn't extract string data from pboard.");
            isRunning = NO;
			return;
		}
//		NSLog(@"has string pboard type!");
		pboardString = [pboard stringForType:NSStringPboardType];
		if (!pboardString) {
			*error = NSLocalizedString(@"Error: couldn't construct UTF-8 text from input data.",
									   @"pboard couldn't construct UTF-8 text from input data.");
            isRunning = NO;
			return;
		}
//		NSLog(@"has non-empty string!");
		inputData = [pboardString dataUsingEncoding:NSUTF8StringEncoding];
	}

    NSError *scriptRunningError = nil;
	NSData *outputData = [self callThroughToScript:script withData:inputData expectingOutput:expectingOutput error:&scriptRunningError];
    if (scriptRunningError) {
        *error = [@"There was an error running or initializing the script:\n" stringByAppendingString:[scriptRunningError description]];
    } else if (expectingOutput) {
		if (!outputData) return;
		NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
		
		if (!outputString) {
			*error = NSLocalizedString(@"Error: couldn't construct UTF-8 text from output data.",
									   @"self couldn't construct UTF-8 text from output data.");
            isRunning = NO;
			return;
		}

		
		// the following is used to debug "the Mail issue" where they pass along the clipboard instead, the bozos.
#if 0
		//NSLog(@"pboard info: '%@' (%@); %@", [pboard name], [pboard types], pboard);
		//NSLog(@"clipboard info: '%@' (%@); %@", [[NSPasteboard pasteboardWithName:NSGeneralPboard] name], [[NSPasteboard pasteboardWithName:NSGeneralPboard] types], [NSPasteboard pasteboardWithName:NSGeneralPboard]);
		[self logPasteboard:pboard];
		[self logPasteboard:[NSPasteboard generalPasteboard]];
		if ([pboard isEqualTo:[NSPasteboard generalPasteboard]]) {
			NSLog(@"pboard is equal to clipboard! danger!");
		}
#endif
		
//		NSLog(@"has return value! %@", outputData);
		types = [NSArray arrayWithObject:NSStringPboardType];
		[pboard declareTypes:types owner:nil];
		[pboard setString:outputString forType:NSStringPboardType];
		
		[outputString release];
	}
    
    isRunning = NO;
    [self bumpBailingTimer];
    
    return;
	
}

- (void)bumpBailingTimer {
    if (!self.connection) {
        #define ThisServiceBailAfterInteractivityInterval   (NSTimeInterval)120
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(bailAfterInactivity) object:nil];
        [self performSelector:@selector(bailAfterInactivity) withObject:nil afterDelay:ThisServiceBailAfterInteractivityInterval];
    }
}

- (void)bailAfterInactivity {
    if (isRunning) {
        [self bumpBailingTimer];
        return;
    }
    shouldKeepRunning = NO;
}

#if 0
- (void)logPasteboard:(NSPasteboard *)pboard {
	NSLog(@"pboard info: '%@' %@", [pboard name], [pboard types], pboard);
	NSEnumerator *typeEnumerator = [[pboard types] objectEnumerator];
	NSString *type;
	while (type = [typeEnumerator nextObject]) {
		NSLog(@" - type: '%@' (data: %@)", [pboard stringForType:type], [pboard dataForType:type]);
	}
}
#endif

- (NSURL *)URLToCorrectScript:(NSString *)filename {
	
	NSString *embeddedScriptAtPath = [[[[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:filename] stringByResolvingSymlinksInPath] stringByStandardizingPath];
	NSURL *embeddedPathURL = [NSURL fileURLWithPath:embeddedScriptAtPath];
	
	NSDictionary *infoPlist = [[NSBundle bundleForClass:[self class]] infoDictionary];
	if ((nil == [infoPlist objectForKey:@"ServiceSkeletonReferenceType"]) || ([[infoPlist objectForKey:@"ServiceSkeletonReferenceType"] isNotEqualTo:@"ref"])) {
		return embeddedPathURL;
	}
    
    NSFileManager *fm = [NSFileManager defaultManager];
	
	NSString *serviceName = [[[self serviceInfo] objectForKey:@"NSMenuItem"] objectForKey:@"default"];
	
	NDAlias *alias = [NDAlias aliasWithContentsOfFile:[[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"Alias Reference"]];
//	NSLog(@"alias: %@", alias);
	if (nil != alias) {
		NSString *scriptAtPath = [infoPlist objectForKey:@"ServiceSkeletonOriginalScriptPath"];
		NSURL *pathURL = [NSURL fileURLWithPath:scriptAtPath];
		NSString *scriptAtAlias = [[[alias path] stringByResolvingSymlinksInPath] stringByStandardizingPath];
		NSURL *aliasURL = [NSURL fileURLWithPath:scriptAtAlias];
		
		if ([scriptAtPath isEqualTo:scriptAtAlias])
			return pathURL;
		else { // Paths from file path and alias are different! Investigate. 
			
			// First, check whether they exist or not. If they turn out to be folders, act in the same way as if they didn't exist.
			BOOL aliasIsDir; BOOL pathIsDir; BOOL aliasExists; BOOL pathExists;
			aliasExists = [fm fileExistsAtPath:scriptAtAlias isDirectory:&aliasIsDir];
			pathExists = [fm fileExistsAtPath:scriptAtPath isDirectory:&pathIsDir];
			
			// If the path file does not exist or is a folder AND the alias file exists and is not a folder...
			if ((!pathExists || pathIsDir) && (aliasExists && !aliasIsDir)) {
				return aliasURL;
			}

			// Opposite.
			if ((!aliasExists || aliasIsDir) && (pathExists && !pathIsDir)) {
				return pathURL;
			}
			
			// None of the files exist! Nothing we can do.
			if (!pathExists && !aliasExists) {
				NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"The script on which the service %@ is based on no longer exists.", @"Service script can't be found; alert message text"), serviceName] defaultButton:NSLocalizedString(@"OK", @"Service script can't be found; alert OK button") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Please recreate this service from the original script.", @"Service script can't be found; alert informative text")];
				[alert runModal];
				return nil;
			}
            
            NSDictionary *attributesAtScriptPath = [fm attributesOfItemAtPath:scriptAtPath error:NULL];
            NSDictionary *attributesAtScriptAlias = [fm attributesOfItemAtPath:scriptAtAlias error:NULL];
			
            // Measuring sizes. If there was trouble getting these attributes in the first place, fileSize will be zero
            // through nil-messaging, which gets the same point across.
            
			unsigned long long sizePath = [attributesAtScriptPath fileSize];
			unsigned long long sizeAlias = [attributesAtScriptAlias fileSize];
			// The path file is empty and the alias file not.
			if ((sizePath == 0) && (sizeAlias > 0)) {
				return aliasURL;
			}
			// Opposite.
			if ((sizePath > 0) && (sizeAlias == 0)) {
				return pathURL;
			}
			
			// All other possibilities are exhausted - time to ask the user to pick.
			return [self askUserToPickScriptOne:pathURL orTwo:aliasURL];
			
		}
	}
	return embeddedPathURL;
}

static BOOL readDataFromFileHandle = NO;

- (NSURL *)askUserToPickScriptOne:(NSURL *)one orTwo:(NSURL *)two {
	
	selectedScript = nil;
	
	
	NSString *oneName = [[NSFileManager defaultManager] displayNameAtPath:[one path]];
	NSString *twoName = [[NSFileManager defaultManager] displayNameAtPath:[two path]];

	
	SInt32 errorCode = 0;
	
	/*
	 
	 The service ”Foobar“ can’t determine which script to use. Please select one.
	 
	 Since you've moved or duplicated the script since creating the service, the service cannot be sure which script to use.
	 
	 */
	const void* keys[] = {kCFUserNotificationAlertHeaderKey,
		kCFUserNotificationAlertMessageKey,
		kCFUserNotificationCheckBoxTitlesKey,
		kCFUserNotificationDefaultButtonTitleKey,
		kCFUserNotificationAlternateButtonTitleKey};
	const void* values[] = {(CFStringRef)[NSString stringWithFormat:NSLocalizedString(@"The service \"%@\" can't determine which script to use. Please select one.", @"Prompt for dialog asking which of two scripts to pick"), [[[self serviceInfo] objectForKey:@"NSMenuItem"] objectForKey:@"default"]],
		(CFStringRef)[NSString stringWithFormat:NSLocalizedString(@"Since you've moved or duplicated the script since creating the service, the service cannot be sure which script to use.\n\nScript A is located at:\n%@\nScript B is located at:\n%@", @"Informative text for dialog asking which of two scripts to pick"), [one path], [two path]],
		(CFArrayRef)[NSArray arrayWithObjects:oneName, twoName, nil],
		(CFStringRef)NSLocalizedString(@"Pick Script", @"'Pick Script' button for dialog asking which of two scripts to pick"),
		(CFStringRef)NSLocalizedString(@"Cancel", @"'Cancel' button for dialog asking which of two scripts to pick")};
	CFDictionaryRef parameters = CFDictionaryCreate(0, keys, values,
													sizeof(keys)/sizeof(*keys), &kCFTypeDictionaryKeyCallBacks,
													&kCFTypeDictionaryValueCallBacks);
	
	CFUserNotificationRef notif = CFUserNotificationCreate(kCFAllocatorDefault,
														   600,
														   (kCFUserNotificationUseRadioButtonsFlag|CFUserNotificationCheckBoxChecked(0)),
														   &errorCode,
														   parameters);
	
	CFOptionFlags responseOptions;
	SInt32 response = CFUserNotificationReceiveResponse(notif,600,&responseOptions);
#pragma unused (response)
	CFRelease(parameters);
	unsigned short button = responseOptions & 0x3;
	unsigned short which = responseOptions & CFUserNotificationCheckBoxChecked(0);
	CFRelease(notif);
	
	if (button == kCFUserNotificationDefaultResponse) {
		NSURL *correct = nil;
		if (which > 0) {
//			NSLog(@"one, %@", one);
			correct = one;
		} else {
//			NSLog(@"two, %@", two);
			correct = two;
		}
		
		// Update the housekeeping info to avoid asking next time.
		NDAlias *alias = [NDAlias aliasWithURL:correct];
		[alias writeToFile:[[[[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Resources"] stringByAppendingPathComponent:@"Alias Reference"]];
		NSURL *urlToInfoPlist = [NSURL fileURLWithPath:[[[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Info.plist"]];
		NSMutableDictionary *d = [[NSDictionary dictionaryWithContentsOfURL:urlToInfoPlist] mutableCopy];
		[d setObject:[correct path] forKey:@"ServiceSkeletonOriginalScriptPath"];
		[d writeToURL:urlToInfoPlist atomically:YES];
		[d release];
		return correct;
	} else {
		NSLog(@"cancel");
		return nil;
	}
	
	return selectedScript;
}

typedef enum _ServiceSkeletonErrors {
    TSCouldNotFindScript = 0,
    TSCouldNotExecuteScript = 1,
    TSAppleScriptConstructionError = 2,
    TSAppleScriptExecutedButDidNotReturnString = 3
} ServiceSkeletonErrors;

- (NSData *)callThroughToScript:(NSString *)filename withData:(NSData *)data expectingOutput:(BOOL)expOut error:(NSError **)error {
    *error = nil;
    
	BOOL needsWrite = (data != nil);
	//	NSLog(@"call through to script: %@ with data: %@ (needs write: %@)", filename, data, (needsWrite ? @"yep" : @"nope")); 
	
	
	NSURL *urlToScript = [self URLToCorrectScript:filename];
	//	NSString *fullPathToScript = [[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:filename];
	if (nil == urlToScript) { // Uh-oh. No script. Exit as painlessly as possible.
        *error = [NSError errorWithDomain:ServiceSkeletonErrorDomain
                                     code:TSCouldNotFindScript
                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                           @"The service script could not be found.", NSLocalizedDescriptionKey,
                                           nil]];
		if (expOut) {
			return nil;
		} else {
			return [NSData data];
		}
	}
    NSTask *task;
    task = [[NSTask alloc] init];
	
	OSType ostype = NSHFSTypeCodeFromFileType(NSHFSTypeOfFile(filename));
	NSString *lowercaseFilename = [filename lowercaseString];
	BOOL isOSA = NO;
	if (ostype == 'osas' || /* compiled script */
		[lowercaseFilename hasSuffix:@".scpt"] || /* extension is scpt */
		[lowercaseFilename hasSuffix:@".applescript"] || /* extension is applescript */
		[[[lowercaseFilename stringByDeletingPathExtension] pathExtension] isEqualToString:@"ts-osa"]) /* secondary extension is ts-osa, ie xxx.ts-osa.yy */ {
		isOSA = YES;
	}
	
	// Populate the context information
	
	// http://www.cocoadev.com/index.pl?DeterminingOSVersion
	SInt32 versionMajor, versionMinor, versionBugFix;
	NSMutableString *osxVersion = [[NSMutableString alloc] init];
	NSString *osxVersionFull;
	NSString *osxVersionMajorMinor;
	OSStatus err;
	if ((err = Gestalt(gestaltSystemVersionMajor, &versionMajor)) == noErr) {
		[osxVersion appendFormat:@"%ld", (signed long)versionMajor];
	} else {
		[osxVersion appendString:@"?"];
		versionMajor = -1;
	}
	[osxVersion appendString:@"."];
	if ((err = Gestalt(gestaltSystemVersionMinor, &versionMinor)) == noErr) {
		[osxVersion appendFormat:@"%ld", (signed long)versionMinor];
	} else {
		[osxVersion appendString:@"?"];
		versionMinor = -1;
	}
	[osxVersion appendString:@"."];	
	if ((err = Gestalt(gestaltSystemVersionBugFix, &versionBugFix)) == noErr) {
		[osxVersion appendFormat:@"%ld", (signed long)versionBugFix];
	} else {
		[osxVersion appendString:@"?"];
		versionBugFix = -1;
	}
	
	osxVersionMajorMinor = (versionMajor != -1 && versionMinor != -1) ?
	[[NSString alloc] initWithFormat:@"%ld.%ld", (signed long)versionMajor, (signed long)versionMinor] : @"?";
	osxVersionFull = (versionMajor != -1 && versionMinor != -1 && versionBugFix != -1) ?
	[osxVersion copy] : @"?";
	
	[osxVersion release];
	
	NSString *thisServiceOSplatform = @"Mac OS X";
	NSString *thisServiceSkeletonVersion = @"2";
	NSString *thisServiceImplementor = @"ThisService";
	
	/*<dl><dt>`«class TSsv»` (Service Skeleton Version)</dt>
	 <dt>`«class TSop»` (Service OS Platform)</dt>
	 <dt>`«class TSov»` (Service OS Version Major+Minor) and `«class TSoV»` (Service OS Version Full)</dt>
	 <dt>`«class TSiM»` (Service Implementor)</dt>
	 */
	
#define ThisServiceOSVersionMajorMinorAEKey       (AEKeyword)'TSov'
#define ThisServiceOSVersionFullAEKey             (AEKeyword)'TSoV'
#define ThisServiceOSPlatformAEKey                (AEKeyword)'TSop'
#define ThisServiceServiceSkeletonVersionAEKey    (AEKeyword)'TSsv'
#define ThisServiceImplementorAEKey               (AEKeyword)'TSiM'
	
	if (isOSA) {
		NSDictionary *applError = nil;
		NSAppleScript *appl = [[NSAppleScript alloc] initWithContentsOfURL:urlToScript error:&applError];
		if (!appl) {
            *error = [NSError errorWithDomain:ServiceSkeletonErrorDomain
                                         code:TSAppleScriptConstructionError
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                               @"The service AppleScript/OSA script could not be initialized.", NSLocalizedDescriptionKey,
                                               nil]];
            NSLog(@"AppleScript/OSA script initialization error: %@", applError);
			if (expOut) {
				return nil;
			} else {
				return [NSData data];
			}
		} else {
			NSDictionary *errorDict = nil;
			NSString *indatastring = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			NSAppleEventDescriptor *stdindescriptor = [NSAppleEventDescriptor listDescriptor];
			[stdindescriptor insertDescriptor:[NSAppleEventDescriptor descriptorWithString:[indatastring autorelease]] atIndex:1];
			
			NSAppleEventDescriptor *optsdescriptor = [NSAppleEventDescriptor recordDescriptor];
			[optsdescriptor setDescriptor:[NSAppleEventDescriptor descriptorWithString:osxVersionMajorMinor] forKeyword:ThisServiceOSVersionMajorMinorAEKey];
			[optsdescriptor setDescriptor:[NSAppleEventDescriptor descriptorWithString:osxVersionFull] forKeyword:ThisServiceOSVersionFullAEKey];
			[optsdescriptor setDescriptor:[NSAppleEventDescriptor descriptorWithString:thisServiceOSplatform] forKeyword:ThisServiceOSPlatformAEKey];
			[optsdescriptor setDescriptor:[NSAppleEventDescriptor descriptorWithString:thisServiceSkeletonVersion] forKeyword:ThisServiceServiceSkeletonVersionAEKey];
			[optsdescriptor setDescriptor:[NSAppleEventDescriptor descriptorWithString:thisServiceImplementor] forKeyword:ThisServiceImplementorAEKey];
			[stdindescriptor insertDescriptor:optsdescriptor atIndex:2];
			
			NSAppleEventDescriptor *descriptor = [appl callHandler:@"tsprocess"
													 withArguments:stdindescriptor
														 errorInfo:&errorDict];
			
			BOOL tryOldMethod = NO;
			if (nil != errorDict) {
				NSNumber *errorNumber = [errorDict objectForKey:NSAppleScriptErrorNumber];
#define AppleScriptCannotFindHandlerError	-1708
				if (nil != errorNumber && [errorNumber intValue] == AppleScriptCannotFindHandlerError) {
					// this is usually indicative that tsprocess doesn't exist; fall back to process
					tryOldMethod = YES;
					[stdindescriptor removeDescriptorAtIndex:2];
				}
			}
			if (tryOldMethod) {
				errorDict = nil;
				descriptor = [appl callHandler:@"process"
								 withArguments:stdindescriptor
									 errorInfo:&errorDict];
			}
			
			[appl autorelease];
			if (errorDict == nil) {
//				NSLog(@"AppleScript succeeded, descriptor: %@", descriptor);
				if (expOut) {
					if ([descriptor stringValue]) {
						return [[descriptor stringValue] dataUsingEncoding:NSUTF8StringEncoding];
					} else {
                        *error = [NSError errorWithDomain:ServiceSkeletonErrorDomain
                                                     code:TSAppleScriptExecutedButDidNotReturnString
                                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           @"The service AppleScript/OSA script executed, but did not return a string for the output.", NSLocalizedDescriptionKey,
                                                           nil]];
						return nil;
					}
				} else {
					return [NSData data];
				}
			} else {
                *error = [NSError errorWithDomain:ServiceSkeletonErrorDomain
                                             code:TSCouldNotExecuteScript
                                         userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                   @"The service AppleScript/OSA script could not be executed.", NSLocalizedDescriptionKey,
                                                   nil]];
				NSLog(@"The service AppleScript/OSA script could not be executed due to error: %@", errorDict);
			}			
		}
		return nil;
	} else {
		chmod([[urlToScript path] UTF8String],(S_IRWXU | S_IRWXG | S_IRWXO));
		[task setLaunchPath:[urlToScript path]];
		NSMutableDictionary *env = [[[NSProcessInfo processInfo] environment] mutableCopy];
		[env setObject:@"YES" forKey:@"ThisServiceMode"];
		
		[env setObject:[osxVersionMajorMinor autorelease] forKey:@"ThisServiceOSVersionMajorMinor"];
		[env setObject:[osxVersionFull autorelease] forKey:@"ThisServiceOSVersionFull"];
		
		[env setObject:thisServiceOSplatform forKey:@"ThisServiceOSPlatform"];
		
		[env setObject:thisServiceSkeletonVersion forKey:@"ThisServiceServiceSkeletonVersion"];
		[env setObject:thisServiceImplementor forKey:@"ThisServiceImplementor"];
		
		[task setCurrentDirectoryPath:[[NSBundle bundleForClass:[self class]] resourcePath]];
		[task setEnvironment:[env autorelease]];
		[task setArguments:[NSArray array]];
	}
	
	//	NSLog(@"task launch path: %@, arguments: %@", [task launchPath], [task arguments]);
	

	
    NSPipe *pstdout;
    pstdout = [NSPipe pipe];
    [task setStandardOutput:pstdout];
    NSFileHandle *fileout;
    fileout = [pstdout fileHandleForReading];
	
	NSFileHandle *filein;
	if (needsWrite) {
		NSPipe *pstdin;
		pstdin = [NSPipe pipe];
		[task setStandardInput:pstdin];
		filein = [pstdin fileHandleForWriting];
	}
	
    [task launch];
	
	SLog(@"TS# task launched: %@", task);
	
	
	NSValue *fileoutValue = [[NSValue valueWithPointer:(const void *)fileout] retain];
	[outputsForFileHandles setObject:[NSMutableData data] forKey:fileoutValue];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(readDataInBackground:) 
												 name:NSFileHandleReadCompletionNotification 
											   object:fileout];
	[fileout readInBackgroundAndNotify];
	
	SLog(@"TS# pulling data in the background");
	if (needsWrite) {
		SLog(@"TS#w# just about to write data (%llu bytes)", (unsigned long long)[data length]);

		@try {
			const NSUInteger stride = 50000;
			NSUInteger totalLength = [data length];
			NSUInteger offset = 0;
			SLog(@"TS#w# writing %llu bytes in batches", (unsigned long long)totalLength);
			for (offset = 0; offset < totalLength; offset += stride) {
				
				// allow for the asynchronous reads to happen in response to these writes
				// (have I told you that I love buffers?)
				[[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]]; 
				
				NSUInteger remaining = (totalLength - offset);
				NSUInteger numberBytes = (remaining > stride ? stride : remaining);
				NSRange range = NSMakeRange(offset, numberBytes);
				SLog(@"TS#w# writing %llu bytes starting from %llu (end index = %llu)",
					  (unsigned long long)range.length, (unsigned long long)range.location,
					  ((unsigned long long)range.length + (unsigned long long)range.location));
				[filein writeData:[data subdataWithRange:range]];
			}
			SLog(@"TS#w# finished writing data");
		} @catch (NSException *localException) {
			NSLog(@"TS#w# omg exception: %@", localException);
        }
		SLog(@"TS#w# task wrote data");
	}
	[filein closeFile];
	SLog(@"TS#w# closed write file handle");
	
	SLog(@"TS# waiting until exit");
	[task waitUntilExit];
	SLog(@"TS# exited!");
    
	// allow for the asynchronous reads to happen when the service is done
    do {
        SLog(@"TS#r-post# read asynchronously post-exit to grab all data");
        readDataFromFileHandle = NO;
        // if this causes a read, the flag will be set to YES and we'll go around another round
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];
    } while (readDataFromFileHandle);
    
    SLog(@"TS#r-post# done reading asynchronously");
	
	NSMutableData *outputBuffer = [outputsForFileHandles objectForKey:fileoutValue];
	[outputsForFileHandles removeObjectForKey:fileoutValue];
	[fileoutValue release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSFileHandleReadCompletionNotification
												  object:fileout];
	
	//	NSLog(@"read data");
	
	//    NSString *string;
	//    string = [[NSString alloc] initWithData:readdata encoding:NSUTF8StringEncoding];
	//    NSLog (@"got\n%@", string);
	[task release];
	return outputBuffer;
}


- (void)readDataInBackground:(NSNotification *)aNotification {
	NSFileHandle *fh = (NSFileHandle *)[aNotification object];

    NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	
	SLog(@"TS#r# new data or EOF available; %llu bytes", (unsigned long long)data.length);
	
	NSValue *fileoutValue = [NSValue valueWithPointer:(const void *)fh];
	NSMutableData *outputBuffer = [outputsForFileHandles objectForKey:fileoutValue];

    if ([data length]) {
		SLog(@"TS#r# new data appended: %llu bytes, total %llu bytes", (unsigned long long)[data length], ((unsigned long long)[data length] + (unsigned long long)[outputBuffer length]));
		[outputBuffer appendData:data];
		SLog(@"TS#r# appended");
        
        readDataFromFileHandle = YES;
		
		[fh readInBackgroundAndNotify];  
    } else {
        readDataFromFileHandle = NO;
    }
}


@end
