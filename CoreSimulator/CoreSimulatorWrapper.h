//
//  CoreSimulatorHelper.h
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 18/09/15.
//  Copyright © 2015 Daniel Cerutti. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreSimulator.h"

@interface CoreSimulatorHelper : NSObject

+ (BOOL)loadAllPlatformsReturningError:(NSError **)error;

@end

//@class SimDevice;


@interface SimServiceContextWrapper : NSObject

+ (SimServiceContext *)sharedServiceContextForDeveloperDir:(NSString *)developerDir simServiceContextClass:(Class)serviceClass error:(NSError **)error;


@end


@interface SimDeviceWrapper : NSObject

+ (instancetype)simDeviceWrapper:(id)simDevice;

//@property(retain, nonatomic) NSDistantObject<SimBridge> *simBridgeDistantObject;
//@property(retain, nonatomic) NSMachPort *simBridgePort;
//@property(retain, nonatomic) NSMachPort *hostSupportPort;
//@property(retain) NSMachPort *deathTriggerPort;
//@property(retain) NSObject<OS_dispatch_queue> *stateVariableQueue;
//@property(retain) NSMutableDictionary *registeredServices;
//@property(retain) NSObject<OS_dispatch_queue> *bootstrapQueue;
//@property(retain) SimDeviceNotificationManager *notificationManager;
//@property(copy) NSString *setPath;
//@property(retain) SimServiceConnectionManager *connectionManager;
//@property(readonly) SimDeviceSet *deviceSet;
//@property(copy) NSUUID *UDID;
//@property(retain) SimRuntime *runtime;
//@property(retain) SimDeviceType *deviceType;
//
//- (BOOL)isAvailableWithError:(NSError **)error;
@property(readonly) BOOL available;
//- (BOOL)triggerCloudSyncWithError:(NSError **)error;
//- (void)triggerCloudSyncWithCompletionHandler:(CDUnknownBlockType)arg1;
//- (BOOL)postDarwinNotification:(id)arg1 error:(id *)arg2;
//
//- (pid_t)launchApplicationWithID:(NSString *)appId options:(NSDictionary *)options error:(NSError **)error;
//- (void)launchApplicationAsyncWithID:(NSString *)appId options:(NSDictionary *)options completionHandler:(CDUnknownBlockType)arg3;
- (NSDictionary *)installedAppsWithError:(NSError **)error;
//- (BOOL)applicationIsInstalled:(NSString *)appId type:(id *)arg2 error:(NSError **)error;
- (BOOL)uninstallApplication:(NSString *)appId withOptions:(id)arg2 error:(NSError **)error;
- (BOOL)installApplication:(NSURL *)appUrl withOptions:(NSDictionary *)options error:(NSError **)error;
//
//- (BOOL)setKeyboardLanguage:(NSString *)lang error:(NSError **)error;
//- (BOOL)addPhoto:(NSURL *)url error:(NSError **)error;
//- (BOOL)openURL:(NSURL *)url error:(NSError **)error;
//
//- (void)simBridgeSync:(CDUnknownBlockType)arg1;
//- (void)simBridgeAsync:(CDUnknownBlockType)arg1;
//- (void)simBridgeCommon:(CDUnknownBlockType)arg1;
//- (long long)compare:(id)arg1;
//- (id)newDeviceNotification;
//- (id)createXPCNotification:(const char *)arg1;
//- (id)createXPCRequest:(const char *)arg1;
//- (void)handleXPCRequestSpawn:(id)arg1 peer:(id)arg2;
//- (void)handleXPCRequestGetenv:(id)arg1 peer:(id)arg2;
//- (void)handleXPCRequestLookup:(id)arg1 peer:(id)arg2;
//- (void)handleXPCRequestRegister:(id)arg1 peer:(id)arg2;
//- (void)handleXPCRequestRestore:(id)arg1 peer:(id)arg2;
//- (void)handleXPCRequestUpdateUIWindow:(id)arg1 peer:(id)arg2;
//- (void)handleXPCRequestErase:(id)arg1 peer:(id)arg2;
//- (void)handleXPCRequestUpgrade:(id)arg1 peer:(id)arg2;
//- (void)handleXPCRequestShutdown:(id)arg1 peer:(id)arg2;
//- (void)handleXPCRequestBoot:(id)arg1 peer:(id)arg2;
//- (void)handleXPCRequestRename:(id)arg1 peer:(id)arg2;
//- (void)handleXPCRequest:(id)arg1 peer:(id)arg2;
//- (void)handleXPCNotificationDeviceUIWindowPropertiesChanged:(id)arg1;
//- (void)handleXPCNotificationDeviceRenamed:(id)arg1;
//- (void)handleXPCNotificationDeviceStateChanged:(id)arg1;
//- (void)handleXPCNotification:(id)arg1;

//@property(copy) NSDictionary *uiWindowProperties;
//- (void)setName:(NSString *)name;
@property(readonly, copy) NSString *name;
//- (void)setState:(SimDeviceState)state;
@property(readonly) SimDeviceState state;
- (NSString*)stateString;

//- (void)simulateMemoryWarning;
//- (id)memoryWarningFilePath;
//@property(readonly, copy) NSString *logPath;
//- (NSString *)dataPath;
//- (NSString *)devicePath;
//- (NSDictionary *)environment;

//- (int)_spawnFromSelfWithPath:(id)arg1 options:(id)arg2 terminationHandler:(CDUnknownBlockType)arg3 error:(id *)arg4;
//- (int)_spawnFromLaunchdWithPath:(id)arg1 options:(id)arg2 terminationHandler:(CDUnknownBlockType)arg3 error:(id *)arg4;
//- (int)spawnWithPath:(id)arg1 options:(id)arg2 terminationHandler:(CDUnknownBlockType)arg3 error:(id *)arg4;
//- (void)spawnAsyncWithPath:(id)arg1 options:(id)arg2 terminationHandler:(CDUnknownBlockType)arg3 completionHandler:(CDUnknownBlockType)arg4;
//- (BOOL)registerPort:(unsigned int)arg1 service:(id)arg2 error:(id *)arg3;
//- (unsigned int)lookup:(id)arg1 error:(id *)arg2;
//- (unsigned int)_lookup:(id)arg1 error:(id *)arg2;

//- (id)getenv:(id)arg1 error:(id *)arg2;

//- (BOOL)restoreContentsAndSettingsFromDevice:(id)arg1 error:(id *)arg2;
//- (void)restoreContentsAndSettingsAsyncFromDevice:(id)arg1 completionHandler:(CDUnknownBlockType)arg2;

//- (BOOL)updateUIWindowProperties:(id)arg1 error:(id *)arg2;
//- (void)updateAsyncUIWindowProperties:(id)arg1 completionHandler:(CDUnknownBlockType)arg2;
//- (void)_sendUIWindowPropertiesToDevice;

//- (BOOL)eraseContentsAndSettingsWithError:(id *)arg1;
//- (void)eraseContentsAndSettingsAsyncWithCompletionHandler:(CDUnknownBlockType)arg1;

//- (BOOL)upgradeToRuntime:(id)arg1 error:(id *)arg2;
//- (void)upgradeAsyncToRuntime:(id)arg1 completionHandler:(CDUnknownBlockType)arg2;

//- (BOOL)rename:(id)arg1 error:(id *)arg2;
//- (void)renameAsync:(id)arg1 completionHandler:(CDUnknownBlockType)arg2;

//- (BOOL)shutdownWithError:(NSError **)error;
//- (BOOL)_shutdownWithError:(id *)arg1;
- (void)shutdownAsyncWithCompletionHandler:(void (^)(NSError *error))completionBlock;

//- (BOOL)bootWithOptions:(NSDictionary *)options error:(NSError **)error;
- (void)bootAsyncWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSError *error))completionBlock;

//- (void)launchdDeathHandlerWithDeathPort:(id)arg1;
//- (BOOL)startLaunchdWithDeathPort:(id)arg1 deathHandler:(CDUnknownBlockType)arg2 error:(id *)arg3;
//- (void)registerPortsWithLaunchd;
//@property(readonly) NSArray *launchDaemonsPaths;
//- (BOOL)removeLaunchdJobWithError:(id *)arg1;
//- (BOOL)createLaunchdJobWithError:(id *)arg1 extraEnvironment:(id)arg2 disabledJobs:(id)arg3;
//- (BOOL)clearTmpWithError:(id *)arg1;
//- (BOOL)ensureLogPathsWithError:(id *)arg1;
//- (BOOL)supportsFeature:(id)arg1;
//@property(readonly, copy) NSString *launchdJobName;
//- (void)saveToDisk;
//- (id)saveStateDict;
//- (void)validateAndFixState;
//@property(readonly, copy) NSString *descriptiveName;
//- (NSString *)description;

//- (id)initDevice:(NSString *)name
//            UDID:(NSUUID *)udid
//      deviceType:(SimDeviceType *)deviceType
//         runtime:(SimRuntime *)runtime
//           state:(unsigned long long)state
//connectionManager:(SimServiceConnectionManager *)connectionManager
//         setPath:(NSString *)path;

@end
