//
//  CoreDataManager.h
//  ExpenseTracker
//
//  Created by XOO_Raven on 9/8/25.
//

#ifndef CoreDataManager_h
#define CoreDataManager_h

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CoreDataManager : NSObject

@property (readonly, strong) NSPersistentContainer *persistentContainer;

+ (instancetype)sharedManager;
- (NSManagedObjectContext *)viewContext;
- (void)saveContext;

@end

#endif /* CoreDataManager_h */
