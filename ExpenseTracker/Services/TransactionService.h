
#import <Foundation/Foundation.h>
@class Budget;
@class Category;
@class Transaction;

NS_ASSUME_NONNULL_BEGIN

@interface TransactionService : NSObject

+ (instancetype)sharedService;

- (NSArray<Budget *> *)fetchBudgetsWithError:(NSError **)error;

- (NSArray<Category *> *)fetchCategoriesWithError:(NSError **)error 
                                             isIncome:(NSInteger)isIncome 
                                        transactionDate:(NSDate *)date 
                                            budgetID:(Budget *)budgetID
                             excludedTransactionID:(nullable Budget *)excludedTransactionID;

- (void)saveTransactionWithAmount:(NSDecimalNumber *)amount
                             desc:(NSString *)desc
                             date:(NSDate *)date
                           budget:(Budget *)budget
                         category:(Category *)category
                         isIncome:(BOOL)isIncome
               existingTransaction:(nullable Transaction *)existingTransaction
                       completion:(void (^)(BOOL success, NSError * _Nullable error, BOOL amountOverflow))completion;

@end

NS_ASSUME_NONNULL_END
