//
//  FTSCoreDataModel.h
//  iHomeschool
//
//  Created by Josh on 11/26/13.
//  Copyright (c) 2013 Fat Toad Software, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface FTSCoreDataModel : NSObject

@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly) NSString *modelName;

+ (instancetype)sharedDataModel;
+ (instancetype)initializeWithModelName:(NSString *)modelName;
- (BOOL)saveContext;
- (NSManagedObjectContext *)contextForCurrentThread;
@end
