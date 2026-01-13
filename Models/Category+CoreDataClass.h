//
//  Category+CoreDataClass.h
//  ExpenseTracker
//
//  Created by raven on 1/6/26.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Budget, Transaction;

NS_ASSUME_NONNULL_BEGIN

@interface Category : NSManagedObject

- (BOOL)isValidForDate:(NSDate *)date;

@end

NS_ASSUME_NONNULL_END

#import "Category+CoreDataProperties.h"
