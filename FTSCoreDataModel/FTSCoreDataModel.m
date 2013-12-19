//
//  FTSCoreDataModel.m
//  iHomeschool
//
//  Created by Josh on 11/26/13.
//  Copyright (c) 2013 Fat Toad Software, Inc. All rights reserved.
//

#import "FTSCoreDataModel.h"

@interface FTSCoreDataModel ()
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readwrite) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readwrite) NSString *modelName;
@end

static NSString const * kFTSManagedObjectContextKey = @"FTS_NSManagedObjectContextForThreadKey";

@implementation FTSCoreDataModel

+ (instancetype)sharedDataModel {
    static FTSCoreDataModel *model = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        model = [[FTSCoreDataModel alloc] init];
    });
    
    return model;
}

+ (instancetype)initializeWithModelName:(NSString *)modelName {
    FTSCoreDataModel *model = [FTSCoreDataModel sharedDataModel];
    model.modelName = modelName;
    return model;
}

- (BOOL)saveContext {
    BOOL result;
    NSError *error = nil;
    NSManagedObjectContext *context = [self contextForCurrentThread];
    
    if ([context hasChanges]) {
        result = [context save:&error];
        
        if (error) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        }
        
        return result;
    }
    
    return YES;
}

# pragma mark - Threading methods

- (NSManagedObjectContext *)defaultContext {
    return self.managedObjectContext;
}

- (NSManagedObjectContext *)contextForCurrentThread {
    if ([NSThread isMainThread]) {
		return [self defaultContext];
	} else {
		NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
		NSManagedObjectContext *threadContext = [threadDict objectForKey:kFTSManagedObjectContextKey];
        
		if (threadContext == nil) {
			threadContext = [self contextWithParent:[self defaultContext]];
			[threadDict setObject:threadContext forKey:kFTSManagedObjectContextKey];
		}
        
		return threadContext;
	}}

- (NSManagedObjectContext *)contextWithParent:(NSManagedObjectContext *)parentContext {
    NSManagedObjectContext *context = [self contextWithoutParent];
    context.persistentStoreCoordinator = parentContext.persistentStoreCoordinator;
    
    [[NSNotificationCenter defaultCenter] addObserver:context
                                             selector:@selector(contextWillSave:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:context];
    return context;
}

- (NSManagedObjectContext *)contextWithoutParent {
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [context setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    return context;
}

- (void)contextWillSave:(NSNotification *)notification {
    void (^mergeChanges) (void) = ^{
        [[self defaultContext] mergeChangesFromContextDidSaveNotification:notification];
    };
    
    if ([NSThread isMainThread]) {
        mergeChanges();
    } else {
        dispatch_async(dispatch_get_main_queue(), mergeChanges);
    }
}

# pragma mark - Core Data Stack
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:self.modelName withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }

    NSString *pathComponent = [NSString stringWithFormat:@"%@.sqlite", self.modelName];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:pathComponent];
    NSLog(@"DB is at %@", storeURL);
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:@{NSMigratePersistentStoresAutomaticallyOption: @YES,
                                                                   NSInferMappingModelAutomaticallyOption: @YES}
                                                           error:&error]) {

        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
