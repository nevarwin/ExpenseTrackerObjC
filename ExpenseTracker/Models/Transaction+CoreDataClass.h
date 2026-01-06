//
//  Transaction+CoreDataClass.h
//  ExpenseTracker
//
//  Created by raven on 9/15/25.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Budget, Category;

NS_ASSUME_NONNULL_BEGIN

@interface Transaction : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "Transaction+CoreDataProperties.h"
