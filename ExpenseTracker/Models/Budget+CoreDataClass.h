//
//  Budget+CoreDataClass.h
//  ExpenseTracker
//
//  Created by raven on 9/15/25.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BudgetAllocation, Category, Transaction;

NS_ASSUME_NONNULL_BEGIN

@interface Budget : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "Budget+CoreDataProperties.h"
