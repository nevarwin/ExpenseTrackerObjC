//
//  Transaction+CoreDataProperties.h
//  ExpenseTracker
//
//  Created by raven on 9/15/25.
//
//

#import "Transaction+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Transaction (CoreDataProperties)

+ (NSFetchRequest<Transaction *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property (nullable, nonatomic, copy) NSDecimalNumber *amount;
@property (nullable, nonatomic, copy) NSDate *createdAt;
@property (nullable, nonatomic, copy) NSDate *date;
@property (nonatomic) BOOL isActive;
@property (nullable, nonatomic, copy) NSDate *updatedAt;
@property (nullable, nonatomic, retain) Budget *budget;
@property (nullable, nonatomic, retain) Category *category;

@end

NS_ASSUME_NONNULL_END
