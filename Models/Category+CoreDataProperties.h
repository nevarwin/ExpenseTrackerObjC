//
//  Category+CoreDataProperties.h
//  ExpenseTracker
//
//  Created by raven on 1/6/26.
//
//

#import "Category+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Category (CoreDataProperties)

+ (NSFetchRequest<Category *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property (nullable, nonatomic, copy) NSDecimalNumber *allocatedAmount;
@property (nullable, nonatomic, copy) NSDate *createdAt;
@property (nullable, nonatomic, copy) NSDate *installmentEndDate;
@property (nonatomic) int16_t installmentMonths;
@property (nullable, nonatomic, copy) NSDate *installmentStartDate;
@property (nonatomic) BOOL isActive;
@property (nonatomic) BOOL isIncome;
@property (nonatomic) BOOL isInstallment;
@property (nullable, nonatomic, copy) NSDecimalNumber *monthlyPayment;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSDecimalNumber *totalInstallmentAmount;
@property (nullable, nonatomic, copy) NSDate *updatedAt;
@property (nullable, nonatomic, copy) NSDecimalNumber *usedAmount;
@property (nullable, nonatomic, retain) Budget *budget;
@property (nullable, nonatomic, retain) NSSet<Transaction *> *transactions;

@end

@interface Category (CoreDataGeneratedAccessors)

- (void)addTransactionsObject:(Transaction *)value;
- (void)removeTransactionsObject:(Transaction *)value;
- (void)addTransactions:(NSSet<Transaction *> *)values;
- (void)removeTransactions:(NSSet<Transaction *> *)values;

@end

NS_ASSUME_NONNULL_END
