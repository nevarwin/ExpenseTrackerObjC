//
//  BudgetDisplayViewController.h
//  ExpenseTracker
//
//  Created by raven on 8/26/25.
//

#import <UIKit/UIKit.h>
#import "Budget+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface BudgetDisplayViewController : UIViewController

@property (nonatomic, strong) UIView *headerContainer;
@property (nonatomic, strong) Budget *budget;
@property (nonatomic, strong) UITextField *headerLabelTextField;
@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, strong) UITableView *budgetDisplayTableView;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) NSDictionary<NSString *, NSAttributeDescription *> *expenseAttributes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDecimalNumber *> *expenseValues;

@property (nonatomic, strong) NSDictionary<NSString *, NSAttributeDescription *> *incomeAttributes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDecimalNumber *> *incomeValues;
@end

NS_ASSUME_NONNULL_END
