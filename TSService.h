//
//  TSService.h
//  ThisService
//
//  Created by Jesper on 2011-07-20.
//  Copyright 2011-2012 waffle software. All rights reserved.
//  BSD licensed - see license.txt for more information.
//

#import <Cocoa/Cocoa.h>

@class IconFamily;

typedef enum {
	TSServiceInputOnlyType,
	TSServiceOutputOnlyType,
	TSServiceFilterType,
    TSServiceNoInputOutputType
} TSServiceType;

typedef enum {
	TSServiceScriptCopied,
	TSServiceScriptReferenced
} TSServiceScriptReferenceType;

@class TSServiceTester;

@interface TSService : NSObject {
	NSString *serviceName;
	NSString *serviceFileName;
	NSString *executableName;
	NSDictionary *infoPlistDictionary;
	IconFamily *serviceIcon;
	TSServiceType serviceType;
	TSServiceScriptReferenceType scriptReferenceType;
	NSArray *allInputRules;
    NSSet *applicationIDs;
	NSFileWrapper *serviceFileWrapper;
	NSString *pathToScriptInFileWrapper;
	NSString *pathToScriptOutsideService;
    NSURL *existingServiceURL;
    NSNumber *timeoutInSeconds;
}
+ (TSService *)serviceWithServiceName:(NSString *)name
                          serviceType:(TSServiceType)serviceType
                  scriptReferenceType:(TSServiceScriptReferenceType)scriptReferenceType
                           inputRules:(NSArray *)allInputRules
                     timeoutInSeconds:(NSNumber *)timeoutInSeconds
                           scriptPath:(NSString *)path
                          serviceIcon:(IconFamily *)image
                       applicationIDs:(NSSet *)applicationIDs;

// returns nil if the service is not a ThisService service
+ (TSService *)serviceAtURL:(NSURL *)serviceURL;

+ (NSString *)cleanseName:(NSString *)name;
+ (NSString *)camelCize:(NSString *)name;

- (BOOL)renameService:(NSString *)newServiceName;

- (NSString *)serviceName;
- (NSString *)serviceFileName;
- (NSURL *)existingServiceURL;

// returns an NSFileWrapper to a reconstructed, upgraded service with the info plist rebuilt and the latest ServiceSkeleton
- (NSFileWrapper *)upgradedServiceFileWrapper;

// for a referenced-script-style-service, instates the reference alias (which can only be done to a path/URL and not to a file wrapper)
// for a copy-style-service, does nothing
- (void)writeReferenceAliasForServiceAtURL:(NSURL *)serviceURL;

// chmods the script skeleton and runs the service once with a specific parameter that tells it to register itself and quit
- (void)installServiceAfterFileWrapperWrittenAtURL:(NSURL *)serviceURL;

- (TSServiceTester *)testRunServiceAfterFileWrapperWrittenAtURL:(NSURL *)serviceURL;
- (BOOL)freshenScriptInFileWrapperWrittenAtURL:(NSURL *)serviceURL;

// key is NSURL *, value is TSService *.
+ (NSDictionary *)allServicesInUserBoundary;

- (NSString *)pathToScriptOutsideService;

@property (readonly) BOOL supportsOutput;
@property (readonly) BOOL supportsInput;

- (NSTimeInterval)effectiveTimeout;

@end
