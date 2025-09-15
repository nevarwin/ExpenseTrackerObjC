//
//  Budget+CoreDataProperties.h
//  ExpenseTracker
//
//  Created by XOO_Raven on 9/15/25.
//
//

#import "Budget+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Budget (CoreDataProperties)

+ (NSFetchRequest<Budget *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property (nullable, nonatomic, copy) NSDate *createdAt;
@property (nonatomic) BOOL isActive;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSDecimalNumber *remainingAmount;
@property (nullable, nonatomic, copy) NSDecimalNumber *totalAmount;
@property (nullable, nonatomic, copy) NSDate *updatedAt;
@property (nullable, nonatomic, retain) NSSet<BudgetAllocation *> *allocations;
@property (nullable, nonatomic, retain) NSSet<Category *> *category;
@property (nullable, nonatomic, retain) NSSet<Transaction *> *transactions;

@end

@interface Budget (CoreDataGeneratedAccessors)

- (void)addAllocationsObject:(BudgetAllocation *)value;
- (void)removeAllocationsObject:(BudgetAllocation *)value;
- (void)addAllocations:(NSSet<BudgetAllocation *> *)values;
- (void)removeAllocations:(NSSet<BudgetAllocation *> *)values;

- (void)addCategoryObject:(Category *)value;
- (void)removeCategoryObject:(Category *)value;
- (void)addCategory:(NSSet<Category *> *)values;
- (void)removeCategory:(NSSet<Category *> *)values;

- (void)addTransactionsObject:(Transaction *)value;
- (void)removeTransactionsObject:(Transaction *)value;
- (void)addTransactions:(NSSet<Transaction *> *)values;
- (void)removeTransactions:(NSSet<Transaction *> *)values;

@end

NS_ASSUME_NONNULL_END
