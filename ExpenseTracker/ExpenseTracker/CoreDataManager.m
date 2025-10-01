//
//  CoreDataManager.m
//  ExpenseTracker
//
//  Created by raven on 9/8/25.
//

#import <Foundation/Foundation.h>
#import "CoreDataManager.h"

@implementation CoreDataManager

#pragma mark - Singleton
+ (instancetype)sharedManager {
    static CoreDataManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CoreDataManager alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Core Data Stack
@synthesize persistentContainer = _persistentContainer;

- (NSPersistentContainer *)persistentContainer {
    if (_persistentContainer == nil) {
        _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"Transaction"];
        
        NSPersistentStoreDescription *storeDescription = _persistentContainer.persistentStoreDescriptions.firstObject;
        storeDescription.shouldMigrateStoreAutomatically = YES;
        storeDescription.shouldInferMappingModelAutomatically = YES;
        
        [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
            if (error != nil) {
                NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                abort();
            }
        }];
    }
    return _persistentContainer;
}

- (NSManagedObjectContext *)viewContext {
    return self.persistentContainer.viewContext;
}

#pragma mark - Save Context
- (void)saveContext {
    NSManagedObjectContext *context = self.viewContext;
    if (context != nil && context.hasChanges) {
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Unresolved error saving context: %@, %@", error, error.userInfo);
        }
    }
}



@end

