//
//  CoreDataManager.m
//  ExpenseTracker
//
//  Created by XOO_Raven on 9/8/25.
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
        [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
            if (error != nil) {
                NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                abort();
            }
            [self insertDefaultBudget];
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

#pragma mark - Default Budget
- (void)insertDefaultBudget {
    NSManagedObjectContext *context = self.viewContext;
    NSError *fetchError = nil;

    if (fetchError) {
        NSLog(@"Error checking for existing transaction types: %@", fetchError);
        return;
    }

//    if (count > 0) {
//        // Default data already exists
//        NSLog(@"Default data already exists");
//        return;
//    }
    
    NSManagedObject *budget = [NSEntityDescription insertNewObjectForEntityForName:@"Budget" inManagedObjectContext:context];
    [budget setValue:@"Budget Test" forKey:@"name"];
    NSDate *now = [NSDate date];
    [budget setValue:now forKey:@"createdAt"];
    [budget setValue:now forKey:@"updatedAt"];
    
    // Create and connect categories
    createCategory(context, @"Salary", YES, budget);
    createCategory(context, @"Bonus", YES, budget);
    createCategory(context, @"Savings", YES, budget);

    createCategory(context, @"Groceries", NO, budget);
    createCategory(context, @"Electricity", NO, budget);
    createCategory(context, @"Housing", NO, budget);
    createCategory(context, @"Save", NO, budget);
    createCategory(context, @"Travel", NO, budget);


    // Save context
    NSError *saveError = nil;
    if (![context save:&saveError]) {
        NSLog(@"Failed to save default transaction types: %@", saveError);
    } else {
        NSLog(@"Default categories inserted.");
    }
}

NSManagedObject *createCategory(NSManagedObjectContext *context, NSString *name, BOOL isIncome, NSManagedObject *budget) {
    NSDate *now = [NSDate date];
    NSManagedObject *category = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:context];
    [category setValue:name forKey:@"name"];
    [category setValue:@(isIncome) forKey:@"isIncome"];
    [category setValue:now forKey:@"createdAt"];
    [category setValue:now forKey:@"updatedAt"];
    [category setValue:budget forKey:@"budget"];
    
    NSMutableSet *categories = [budget mutableSetValueForKey:@"category"];
    [categories addObject:category];
    
    return category;
}



@end

