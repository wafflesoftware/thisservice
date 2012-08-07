//
//  TSService.m
//  ThisService
//
//  Created by Jesper on 2011-07-20.
//  Copyright 2011-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import "TSService.h"

#import "IconFamily.h"
#import "TSServiceInputRules.h"

#import "NDAlias.h"
#import "NDAlias+AliasFile.h"

#import "TSServiceTester.h"

#define	ThisServiceServiceVersion	@"2"

@implementation TSService

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

+ (NSString *)cleanseName:(NSString *)name {
	static NSCharacterSet *cleansingSet = nil;
	if (cleansingSet == nil) {
		NSMutableCharacterSet *mcs = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
		[mcs addCharactersInString:@" "];
		cleansingSet = [mcs copy];
		[mcs release];
	}
	
	return [self camelCize:[self stringByCleansingString:name fromCharactersNotInSet:cleansingSet]];	
}

- (NSTimeInterval)effectiveTimeout {
    return timeoutInSeconds ? [timeoutInSeconds doubleValue] : 30;
}

+ (NSString *)sanitizeName:(NSString *)name {
	static NSCharacterSet *sanitizedSet = nil;
	if (sanitizedSet == nil) {
		sanitizedSet = [[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 "] retain];
	}
	
	return [self camelCize:[self stringByCleansingString:name fromCharactersNotInSet:sanitizedSet]];
}

- (BOOL)supportsInput {
    return (serviceType == TSServiceInputOnlyType || serviceType == TSServiceFilterType);
}

- (BOOL)supportsOutput {
    return (serviceType == TSServiceOutputOnlyType || serviceType == TSServiceFilterType);
}



- (id)initWithServiceName:(NSString *)serviceName_
		  serviceFileName:(NSString *)serviceFileName_
		   executableName:(NSString *)executableName_
	  infoPlistDictionary:(NSDictionary *)infoPlistDictionary_
			  serviceIcon:(IconFamily *)serviceIcon_
			  serviceType:(TSServiceType)serviceType_
	  scriptReferenceType:(TSServiceScriptReferenceType)scriptReferenceType_
			allInputRules:(NSArray *)allInputRules_
                     timeoutInSeconds:(NSNumber *)timeoutInSeconds_
	   serviceFileWrapper:(NSFileWrapper *)serviceFileWrapper_
pathToScriptInFileWrapper:(NSString *)pathToScriptInFileWrapper_
pathToScriptOutsideService:(NSString *)pathToScriptOutsideService_
       existingServiceURL:(NSURL *)existingServiceURL_ {
	self = [super init];
	if (self != nil) {
		serviceName = [serviceName_ retain];
		serviceFileName = [serviceFileName_ retain];
		executableName = [executableName_ retain];
		infoPlistDictionary = [infoPlistDictionary_ retain];
		serviceIcon = [serviceIcon_ retain];
		serviceType = serviceType_;
		scriptReferenceType = scriptReferenceType_;
		allInputRules = [allInputRules_ retain];
         timeoutInSeconds = [timeoutInSeconds_ retain];
		serviceFileWrapper = [serviceFileWrapper_ retain];
		pathToScriptInFileWrapper = [pathToScriptInFileWrapper_ retain];
		pathToScriptOutsideService = [pathToScriptOutsideService_ retain];
        existingServiceURL = [existingServiceURL_ retain];
	}
	return self;
}



+ (TSService *)serviceAtURL:(NSURL *)serviceURL {
    if (![serviceURL isFileURL]) return nil;
    
    NSString *path = [serviceURL path];
    
    if (![[path pathExtension] isEqualToString:@"service"]) return nil;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *contentsPath = [path stringByAppendingPathComponent:@"Contents"];
    
    BOOL isDir;
    if (![fm fileExistsAtPath:contentsPath isDirectory:&isDir] || !isDir) return nil;
    
    NSString *infoPlistPath = [contentsPath stringByAppendingPathComponent:@"Info.plist"];
    if (![fm fileExistsAtPath:infoPlistPath isDirectory:&isDir] || isDir) return nil;
    
    NSString *macOSFolderPath = [contentsPath stringByAppendingPathComponent:@"MacOS"];
    if (![fm fileExistsAtPath:macOSFolderPath isDirectory:&isDir] || !isDir) return nil;
    
    NSString *resourcesFolderPath = [contentsPath stringByAppendingPathComponent:@"Resources"];
    if (![fm fileExistsAtPath:resourcesFolderPath isDirectory:&isDir] || !isDir) return nil;
    
    NSFileWrapper *serviceFileWrapper = [[[NSFileWrapper alloc] initWithPath:path] autorelease];
    if (!serviceFileWrapper || ![serviceFileWrapper isDirectory]) return nil;
    
    NSFileWrapper *contentsFileWrapper = (NSFileWrapper *)[[serviceFileWrapper fileWrappers] objectForKey:@"Contents"];
    if (!contentsFileWrapper || ![contentsFileWrapper isKindOfClass:[NSFileWrapper class]] || ![contentsFileWrapper isDirectory]) return nil;
    
    NSFileWrapper *macOSFileWrapper = (NSFileWrapper *)[[contentsFileWrapper fileWrappers] objectForKey:@"MacOS"];
    if (!macOSFileWrapper || ![macOSFileWrapper isKindOfClass:[NSFileWrapper class]] || ![macOSFileWrapper isDirectory]) return nil;
    
    NSFileWrapper *resourcesFileWrapper = (NSFileWrapper *)[[contentsFileWrapper fileWrappers] objectForKey:@"Resources"];
    if (!resourcesFileWrapper || ![resourcesFileWrapper isKindOfClass:[NSFileWrapper class]] || ![resourcesFileWrapper isDirectory]) return nil;
    
    NSFileWrapper *infoPlistFileWrapper = (NSFileWrapper *)[[contentsFileWrapper fileWrappers] objectForKey:@"Info.plist"];
    if (!infoPlistFileWrapper || ![infoPlistFileWrapper isKindOfClass:[NSFileWrapper class]] || ![infoPlistFileWrapper isRegularFile]) return nil;
    
    NSString *deserializeError = nil;
    id plist = [NSPropertyListSerialization propertyListFromData:[infoPlistFileWrapper regularFileContents] mutabilityOption:NSPropertyListMutableContainersAndLeaves format:NULL errorDescription:&deserializeError];
    if (deserializeError != nil) {
        [deserializeError release];
        return nil;
    }
    if (!plist || ![plist isKindOfClass:[NSMutableDictionary class]]) {
        return nil;
    }

    NSMutableDictionary *infoPlist = (NSMutableDictionary *)plist;
    
    NSArray *acceptableServiceVersions = [NSArray arrayWithObjects:@"1", @"2", nil];
    
    NSString *serviceVersion = [infoPlist objectForKey:@"ThisServiceServiceVersion"];
    if (!serviceVersion || ![serviceVersion isKindOfClass:[NSString class]]) return nil;
    if (![acceptableServiceVersions containsObject:serviceVersion]) return nil;
    
    NSArray *services = [infoPlist objectForKey:@"NSServices"];
    if (!services || ![services isKindOfClass:[NSArray class]] || [services count] != 1) return nil;
    NSMutableDictionary *firstService = [services objectAtIndex:0];
    if (!firstService || ![firstService isKindOfClass:[NSMutableDictionary class]]) return nil;
    
    NSArray *mustExistHaveStringsAndNotBeEmpty = [NSArray arrayWithObjects:@"NSMessage", @"NSPortName", @"NSUserData", nil];
    NSCharacterSet *white = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    for (NSString *mustExistKey in mustExistHaveStringsAndNotBeEmpty) {
        id object = [firstService objectForKey:mustExistKey];
        if (!object) return nil;
        if (![object isKindOfClass:[NSString class]]) return nil;
        NSString *str = object;
        if ([[str stringByTrimmingCharactersInSet:white] length] == 0) return nil;
    }
    
    NSDictionary *menuItemDict = [firstService objectForKey:@"NSMenuItem"];
    if (!menuItemDict || ![menuItemDict isKindOfClass:[NSDictionary class]]) return nil;
    NSString *menuItemDefault = [menuItemDict objectForKey:@"default"];
    if (!menuItemDefault || ![menuItemDefault isKindOfClass:[NSString class]] || [[menuItemDefault stringByTrimmingCharactersInSet:white] length] == 0) return nil;
    NSString *serviceName = menuItemDefault;
    
    NSString *singleRecognizedType = @"NSStringPboardType";
    NSArray *sendTypes = [firstService objectForKey:@"NSSendTypes"];
    NSArray *returnTypes = [firstService objectForKey:@"NSReturnTypes"];
//    if (!sendTypes && !returnTypes) return nil;
    BOOL acceptsInput = NO;
    BOOL producesOutput = NO;
    for (id typesArrayObj in [NSArray arrayWithObjects:(sendTypes == nil ? [NSNull null] : sendTypes), (returnTypes == nil ? [NSNull null] : returnTypes), nil]) {
        if ([typesArrayObj isEqual:[NSNull null]]) continue;
        if (![typesArrayObj isKindOfClass:[NSArray class]]) return nil;
        NSArray *typesArray = (NSArray *)typesArrayObj;
        if ([typesArray count] != 1) return nil;
        id singleTypeObj = [typesArray objectAtIndex:0];
        if (![singleTypeObj isKindOfClass:[NSString class]]) return nil;
        NSString *singleType = singleTypeObj;
        if (![singleType isEqualToString:singleRecognizedType]) return nil;
        
        if (typesArray == sendTypes) {
            acceptsInput = YES;
        }
        if (typesArray == returnTypes) {
            producesOutput = YES;
        }
    }
    
    TSServiceType serviceType = (producesOutput ? (acceptsInput ? TSServiceFilterType : TSServiceOutputOnlyType) : (acceptsInput ? TSServiceInputOnlyType : TSServiceNoInputOutputType));
    
	NSString *origExec = [infoPlist objectForKey:@"CFBundleExecutable"];
    if (!origExec || ![origExec isKindOfClass:[NSString class]]) return nil;
    
    NSFileWrapper *origExecWrapper = [[macOSFileWrapper fileWrappers] objectForKey:origExec];
    if (!origExecWrapper || ![origExecWrapper isKindOfClass:[NSFileWrapper class]] || ![origExecWrapper isRegularFile]) return nil;
    
    [macOSFileWrapper removeFileWrapper:origExecWrapper];
    [macOSFileWrapper addRegularFileWithContents:[NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"ServiceSkeleton" ofType:nil]] preferredFilename:origExec];
    
	NSString *refType = [infoPlist objectForKey:@"ServiceSkeletonReferenceType"];
    
    if (refType != nil && [refType isEqualToString:@"ref"]) {
		NSTask *task = [[NSTask alloc] init];
		[task setLaunchPath:[[[path stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"MacOS"] stringByAppendingPathComponent:origExec]];
		[task setArguments:[NSArray arrayWithObject:@"-THISSERVICE_PRINT_SCRIPT_URL_AND_QUIT"]];
		
		NSPipe *pstdout;
		pstdout = [NSPipe pipe];
		[task setStandardOutput:pstdout];
		NSFileHandle *fileout;
		fileout = [pstdout fileHandleForReading];
		[task launch];
		[task waitUntilExit];
		NSData *readdata;
		readdata = [fileout readDataToEndOfFile];
		[task terminate];
		[task release];
		
		NSString *urlstr;
		urlstr = [[[[NSString alloc] initWithData:readdata encoding:NSUTF8StringEncoding] autorelease] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        //		NSLog(@"urlstr: %@", urlstr);
		NSURL *url = [NSURL URLWithString:urlstr];
		NSString *pathToScript = [url path];
        //		NSLog(@"path to script: %@", pathToScript);
		if (![pathToScript hasSuffix:[[path stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Resources"]]) {
			[resourcesFileWrapper removeFileWrapper:[[resourcesFileWrapper fileWrappers] objectForKey:@"Alias Reference"]];
			[resourcesFileWrapper addFileWrapper:[[[NSFileWrapper alloc] initWithPath:pathToScript] autorelease]];
			[infoPlist setObject:@"copy" forKey:@"ServiceSkeletonReferenceType"];
			[infoPlist removeObjectForKey:@"ServiceSkeletonOriginalScriptPath"];
		}
	}
    
//	BOOL nulledKeys = NO;
	
	if ([firstService objectForKey:@"NSKeyEquivalent"] != nil) {
		[firstService removeObjectForKey:@"NSKeyEquivalent"];
//		nulledKeys = YES;
	}
    
    id timeout = [infoPlist objectForKey:@"NSTimeout"];
    NSNumber *timeoutNumberInSeconds = nil;
    if ([timeout isKindOfClass:[NSString class]]) { // yes, this is a string
        NSString *timeoutAsString = timeout;
        NSInteger timeoutInMilliseconds = [timeoutAsString doubleValue];
        timeoutNumberInSeconds = [NSNumber numberWithDouble:timeoutInMilliseconds/1000.0];
    }
    
    [plist setObject:ThisServiceServiceVersion forKey:@"ThisServiceServiceVersion"];
    
    
    
    NSString *serializeError = nil;
    NSData *updatedPlist = [NSPropertyListSerialization dataFromPropertyList:plist format:NSPropertyListXMLFormat_v1_0 errorDescription:&serializeError];
    if (serializeError != nil) {
        [serializeError release];
        return nil;
    }
    
    [contentsFileWrapper removeFileWrapper:infoPlistFileWrapper];
    [contentsFileWrapper addRegularFileWithContents:updatedPlist preferredFilename:@"Info.plist"];
    
    NSString *serviceFileName = [[path lastPathComponent] stringByDeletingPathExtension];
    
	return [[[self alloc] initWithServiceName:serviceName
							  serviceFileName:serviceFileName
							   executableName:origExec
						  infoPlistDictionary:plist
								  serviceIcon:nil
								  serviceType:serviceType
				 		  scriptReferenceType:TSServiceScriptCopied
				 			    allInputRules:nil
                             timeoutInSeconds:timeoutNumberInSeconds
				 		   serviceFileWrapper:serviceFileWrapper
				    pathToScriptInFileWrapper:nil
				   pathToScriptOutsideService:nil
                           existingServiceURL:serviceURL] autorelease];
}

- (NSString *)serviceName {
    return serviceName;
}

- (BOOL)renameService:(NSString *)newServiceName {
    if ([newServiceName isEqualToString:serviceName]) return YES;
    NSFileWrapper *contentsFileWrapper = [[serviceFileWrapper fileWrappers] objectForKey:@"Contents"];
    NSFileWrapper *infoPlistFileWrapper = [[contentsFileWrapper fileWrappers] objectForKey:@"Info.plist"];
    NSData *infoPlistData = [infoPlistFileWrapper regularFileContents];
    
    NSString *errorDescription = nil;
    NSPropertyListFormat format;
    
    NSMutableDictionary *fullInfoPlist = [NSPropertyListSerialization propertyListFromData:infoPlistData mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&format errorDescription:&errorDescription];
    if (errorDescription) {
        [errorDescription release];
        return NO;
    }
    
    [serviceName release];
    serviceName = [newServiceName copy];
    
    
    
    
    NSString *cl = [TSService cleanseName:newServiceName];
	NSString *san = [TSService sanitizeName:newServiceName];
	
    [serviceFileName release];
	serviceFileName = [[cl stringByAppendingPathExtension:@"service"] retain];
	
	NSString *newExec = [NSString stringWithFormat:@"%@ThisService", san];
	
	[fullInfoPlist setObject:san forKey:@"ServiceSkeletonSuitableExecutableName"];
	NSString *origExec = [[fullInfoPlist objectForKey:@"CFBundleExecutable"] retain];
	[fullInfoPlist setObject:newExec forKey:@"CFBundleExecutable"];
	[fullInfoPlist setObject:[NSString stringWithFormat:@"net.wafflesoftware.ThisService.generated-service.%@", cl] forKey:@"CFBundleIdentifier"];
	[fullInfoPlist setObject:[NSString stringWithFormat:@"ThisServiceGeneratedService%@", cl] forKey:@"ServiceSkeletonPortName"];
    
    [infoPlistDictionary release];
    infoPlistDictionary = [fullInfoPlist retain];

    NSData *infoPlistDataAgain = [NSPropertyListSerialization
                                  dataFromPropertyList:fullInfoPlist
                                  format:format
                                  errorDescription:&errorDescription];
    
    
    NSFileWrapper *binFW = [[contentsFileWrapper fileWrappers] objectForKey:@"MacOS"];
	NSFileWrapper *execFW = [[binFW fileWrappers] objectForKey:origExec];
    [origExec release];
	NSFileWrapper *execNewFW = [[NSFileWrapper alloc] initRegularFileWithContents:[execFW regularFileContents]];
	[execNewFW setIcon:[execFW icon]];
	[execNewFW setFileAttributes:[execFW fileAttributes]];
	[execNewFW setFilename:newExec];
	[execNewFW setPreferredFilename:newExec];
	[binFW removeFileWrapper:execFW];
	[binFW addFileWrapper:[execNewFW autorelease]];
    
	[contentsFileWrapper removeFileWrapper:infoPlistFileWrapper];
	[contentsFileWrapper addRegularFileWithContents:infoPlistDataAgain preferredFilename:@"Info.plist"];
    
    return YES;
}


+ (TSService *)serviceWithServiceName:(NSString *)serviceName
						  serviceType:(TSServiceType)serviceType
				  scriptReferenceType:(TSServiceScriptReferenceType)scriptReferenceType
						   inputRules:(NSArray *)allInputRules
                     timeoutInSeconds:(NSNumber *)timeoutInSeconds
						   scriptPath:(NSString *)pathToScript
						  serviceIcon:(IconFamily *)iconFamily
                       applicationIDs:(NSSet *)applicationIDs {
	
	NSString *scriptName = [pathToScript lastPathComponent];
	
	NSString *cleansedName = [self cleanseName:serviceName];
	NSString *sanitaryName = [self sanitizeName:serviceName];
	//	NSLog(@"cleansedName: %@; sanitaryName: %@", cleansedName, sanitaryName);
	NSFileWrapper *scriptfw = [[NSFileWrapper alloc] initRegularFileWithContents:[NSData dataWithContentsOfFile:pathToScript]];
	
	NSString *executableName = [NSString stringWithFormat:@"%@ThisService", sanitaryName];
	
	NSMutableDictionary *service = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									[NSDictionary dictionaryWithObjectsAndKeys:
									 serviceName, @"default", nil], @"NSMenuItem",
									@"doServiceWork", @"NSMessage",
									@"ServiceSkeletonMagic", @"NSPortName",
									@"", @"NSServiceDescription",
									scriptName, @"NSUserData",
									nil];
	
	id rulesObj = nil;
	
	if ([allInputRules count] == 1) {
		NSMutableDictionary *ctxDict = [[[allInputRules objectAtIndex:0] infoPlistRequiredContextDictionary] mutableCopy];
        if ([applicationIDs count] > 0) {
            [ctxDict setObject:[applicationIDs allObjects] forKey:@"NSApplicationIdentifier"];
        }
        rulesObj = [ctxDict autorelease];
	} else if ([allInputRules count] > 1) {
		NSMutableArray *manyRules = [NSMutableArray array];
		for (TSServiceInputRules *rules in allInputRules) {
            NSMutableDictionary *ctxDict = [[[rules infoPlistRequiredContextDictionary] mutableCopy] autorelease];
            if ([applicationIDs count] > 0) {
                [ctxDict setObject:[applicationIDs allObjects] forKey:@"NSApplicationIdentifier"];
            }
			[manyRules addObject:ctxDict];
		}
		rulesObj = manyRules;
	}
	
	if (rulesObj) {
		[service setObject:rulesObj forKey:@"NSRequiredContext"];
	} else {
        id ctxObj = [NSArray array];
        if ([applicationIDs count] > 0) {
            ctxObj = [NSDictionary dictionaryWithObject:[applicationIDs allObjects] forKey:@"NSApplicationIdentifier"];
        }
        
		[service setObject:ctxObj forKey:@"NSRequiredContext"];
	}
	
	if (serviceType == TSServiceInputOnlyType || serviceType == TSServiceFilterType) {
		[service setObject:[NSArray arrayWithObject:@"NSStringPboardType"]
					forKey:@"NSSendTypes"];
	}
	if (serviceType == TSServiceOutputOnlyType || serviceType == TSServiceFilterType) {
		[service setObject:[NSArray arrayWithObject:@"NSStringPboardType"]
					forKey:@"NSReturnTypes"];
	}
    
    if (timeoutInSeconds) {
        NSTimeInterval ti = [timeoutInSeconds integerValue] * 1000;
        if (ti >= 1) {
            [service setObject:[NSString stringWithFormat:@"%llu", (unsigned long long)ti] forKey:@"NSTimeout"];
        } else {
            timeoutInSeconds = nil;
        }
    }
	
	BOOL isRefService = scriptReferenceType == TSServiceScriptReferenced;
	NSString *refType = (isRefService ? @"ref" : @"copy");
	
	NSMutableDictionary *infoplist = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									  @"English", @"CFBundleDevelopmentRegion",
									  executableName, @"CFBundleExecutable",
//									  serviceName, @"CFBundleDisplayName", doesn't actually do anything
									  [NSString stringWithFormat:@"net.wafflesoftware.ThisService.generated-service.%@", cleansedName], @"CFBundleIdentifier",
									  [NSString stringWithFormat:@"ThisServiceGeneratedService%@", cleansedName], @"ServiceSkeletonPortName",
									  sanitaryName, @"ServiceSkeletonSuitableExecutableName",
									  refType, @"ServiceSkeletonReferenceType",
									  ThisServiceServiceVersion, @"ThisServiceServiceVersion", 
									  @"6.0", @"CFBundleInfoDictionaryVersion",
									  @"APPL", @"CFBundlePackageType",
									  @"", @"CFBundleSignature",
									  @"1.0", @"CFBundleVersion",
									  @"1", @"NSBGOnly",
									  @"NSApplication", @"NSPrincipalClass",
									  [NSArray arrayWithObject:service], @"NSServices",
									  nil];
	if (isRefService)
		[infoplist setObject:pathToScript forKey:@"ServiceSkeletonOriginalScriptPath"];
	
	BOOL hasIcon = (iconFamily != nil);
	NSString *iconFileName = nil;
	
	if (hasIcon) {
		iconFileName = [[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingPathExtension:@"icns"];
		[infoplist setObject:iconFileName forKey:@"CFBundleIconFile"];
	}
	
	NSString *failure = nil;
	NSFileWrapper *infoplistfw = [[NSFileWrapper alloc] initRegularFileWithContents:
								  [NSPropertyListSerialization dataFromPropertyList:infoplist format:NSPropertyListXMLFormat_v1_0 errorDescription:&failure]];
	if (failure) [failure release];
	
	NSFileWrapper *serviceSkeletonfw = [[NSFileWrapper alloc] initRegularFileWithContents:[NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"ServiceSkeleton" ofType:nil]]];
	
	NSFileWrapper *macosfw = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:[NSDictionary dictionaryWithObject:[serviceSkeletonfw autorelease] forKey:executableName]];
	NSFileWrapper *resourcefw = nil;
	NSString *pathToScriptInFileWrapper = nil;
	if (isRefService) {
		resourcefw = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:[NSDictionary dictionary]];
	} else {
		resourcefw = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:[NSDictionary dictionaryWithObject:scriptfw forKey:scriptName]];
		pathToScriptInFileWrapper = [[@"Contents" stringByAppendingPathComponent:@"Resources"] stringByAppendingPathComponent:scriptName];
	}
	[scriptfw release];
	NSDictionary *contentsFileWrappers = [NSDictionary dictionaryWithObjectsAndKeys:
										  infoplistfw, @"Info.plist",
										  resourcefw, @"Resources",
										  macosfw, @"MacOS",
										  nil];
	[infoplistfw release];
	[resourcefw release];
	[macosfw release];
	
	if (hasIcon) {
		NSData *icns = [iconFamily data];
		[resourcefw addRegularFileWithContents:icns preferredFilename:iconFileName];
	}
	
	NSFileWrapper *contentsfw = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:contentsFileWrappers];
	NSFileWrapper *fw = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:[NSDictionary dictionaryWithObject:[contentsfw autorelease] forKey:@"Contents"]];
	
	NSString *serviceFileName = [cleansedName stringByAppendingPathExtension:@"service"];
	
	return [[[self alloc] initWithServiceName:serviceName
							  serviceFileName:serviceFileName
							   executableName:executableName
						  infoPlistDictionary:infoplist
								  serviceIcon:iconFamily
								  serviceType:serviceType
				 		  scriptReferenceType:scriptReferenceType
				 			    allInputRules:allInputRules
                                  timeoutInSeconds:timeoutInSeconds
				 		   serviceFileWrapper:[fw autorelease]
				    pathToScriptInFileWrapper:pathToScriptInFileWrapper
				   pathToScriptOutsideService:pathToScript
                           existingServiceURL:nil] autorelease];
}

-(NSURL *)existingServiceURL {
    return existingServiceURL;
}

- (void)writeReferenceAliasForServiceAtURL:(NSURL *)serviceURL {
	if (scriptReferenceType != TSServiceScriptReferenced) return;
	
	NSString *pathToService = [serviceURL path];
	NSString *pathToScript = pathToScriptOutsideService;
	
	NSString *pathToAlias = [[[pathToService stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Resources"] stringByAppendingPathComponent:@"Alias Reference"];

	NDAlias *alias = [NDAlias aliasWithURL:[NSURL fileURLWithPath:pathToScript]];
	[alias writeToFile:pathToAlias];
}

- (NSString *)pathToScriptOutsideService {
    return pathToScriptOutsideService;
}

- (BOOL)freshenScriptInFileWrapperWrittenAtURL:(NSURL *)serviceURL {
    if (!pathToScriptInFileWrapper) return YES; // reference script is always fresh
    if (!pathToScriptOutsideService) return YES;
    
    NSString *pathToService = [serviceURL path];
    NSString *pathToScriptDestination = [pathToService stringByAppendingPathComponent:pathToScriptInFileWrapper];
    
    NSString *pathToScriptOrigin = pathToScriptOutsideService;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSError *copyingError = nil;
    if (![pathToScriptDestination hasPrefix:pathToService]) {
        NSLog(@"destination script is not in service bundle, wtf? dest: %@, service: %@", pathToScriptDestination, pathToService);
        return NO;
    }
    
    [fm removeItemAtPath:pathToScriptDestination error:NULL];
    
    if (![fm copyItemAtPath:pathToScriptOrigin toPath:pathToScriptDestination error:&copyingError]) {
        NSLog(@"Could not freshen script! %@", copyingError);
        return NO;
    }
    
    NSArray *pathComponents = [pathToScriptInFileWrapper componentsSeparatedByString:@"/"];
    NSFileWrapper *currentFileWrapper = serviceFileWrapper;
    NSFileWrapper *prevFileWrapper = nil;
    for (NSString *pathComponent in pathComponents) {
        NSFileWrapper *subWrapper = [[currentFileWrapper fileWrappers] objectForKey:pathComponent];
        
        prevFileWrapper = currentFileWrapper;
        currentFileWrapper = subWrapper;
    }
    
    NSLog(@"prev file wrapper %@", prevFileWrapper);
    NSLog(@"current file wrapper %@", currentFileWrapper);
    
    NSString *preferredFilename = [currentFileWrapper preferredFilename];
    [prevFileWrapper removeFileWrapper:currentFileWrapper];
    [prevFileWrapper addRegularFileWithContents:[NSData dataWithContentsOfFile:pathToScriptOrigin] preferredFilename:preferredFilename];
    
    return YES;
}

- (void)installServiceAfterFileWrapperWrittenAtURL:(NSURL *)serviceURL {
	
	NSString *pathToService = [serviceURL path];
    
    NSDictionary *fileAttributesToSet = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:0775] forKey:NSFilePosixPermissions];
    
    NSString *pathToExecutable = [[[pathToService stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"MacOS"] stringByAppendingPathComponent:executableName];
	
	[[NSFileManager defaultManager] setAttributes:fileAttributesToSet ofItemAtPath:pathToExecutable error:NULL];
	
	NSTask *quicklyOpen = [[NSTask alloc] init];
	[quicklyOpen setLaunchPath:[[[pathToService stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"MacOS"] stringByAppendingPathComponent:executableName]];
	[quicklyOpen setArguments:[NSArray arrayWithObject:@"-THISSERVICE_REGISTER_SERVICE"]];
	[quicklyOpen launch];
	[quicklyOpen waitUntilExit]; // it'll exit on its own
	//	[quicklyOpen terminate];
	[quicklyOpen release];
	
}

- (TSServiceTester *)testRunServiceAfterFileWrapperWrittenAtURL:(NSURL *)serviceURL {
	
	NSString *pathToService = [serviceURL path];
    
    NSDictionary *fileAttributesToSet = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:0775] forKey:NSFilePosixPermissions];
    
    NSString *pathToExecutable = [[[pathToService stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"MacOS"] stringByAppendingPathComponent:executableName];
	
	[[NSFileManager defaultManager] setAttributes:fileAttributesToSet ofItemAtPath:pathToExecutable error:NULL];
    
    NSString *launchPath =[[[pathToService stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"MacOS"] stringByAppendingPathComponent:executableName];
    
    TSServiceTester *tester = [[TSServiceTester alloc] initWithServiceLaunchPath:launchPath service:self testServiceURL:serviceURL];
    
    return [tester autorelease];
}

- (NSString *)serviceFileName {
	return serviceFileName;
}


- (NSFileWrapper *)upgradedServiceFileWrapper {
	return serviceFileWrapper;
}

- (void) dealloc
{
	[serviceName release];
	[serviceFileName release];
	[executableName release];
	[infoPlistDictionary release];
	[serviceIcon release];
	[allInputRules release];
	[serviceFileWrapper release];
	[pathToScriptInFileWrapper release];
	[pathToScriptOutsideService release];
	
	[super dealloc];
}


// key is NSString * (local file name), value is TSService *.
+ (NSDictionary *)allServicesInUserBoundary {
    @try {
        NSString *pathToServicesFolder = [@"~/Library/Services" stringByExpandingTildeInPath];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *folderenum = [fm contentsOfDirectoryAtPath:pathToServicesFolder error:NULL];

        
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        
        for (NSString *filename in folderenum) {
            if (![[filename pathExtension] isEqualToString:@"service"]) continue;
            NSString *fullPath = [pathToServicesFolder stringByAppendingPathComponent:filename];
            BOOL isDir;
            if (![fm fileExistsAtPath:fullPath isDirectory:&isDir] || !isDir) continue;
            
//            NSLog(@"found service %@", fullPath);
            TSService *service = [TSService serviceAtURL:[NSURL fileURLWithPath:fullPath]];
            if (!service) {
//                NSLog(@" - not eligible");
                continue;
            } else {
//                NSLog(@" + eligible");
            }
            [d setObject:service forKey:filename];
        }
        
        return [[d copy] autorelease];
    }
    @catch (NSException *exception) {
        NSLog(@"encountered error finding out services in user boundary: %@", exception);
        return [NSDictionary dictionary];
    }

}

@end
