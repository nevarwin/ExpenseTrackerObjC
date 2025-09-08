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

//@property (nonatomic, strong) UIView *headerContainer;
@property (nonatomic, strong) Budget *budget;
@property (nonatomic, strong) UITextField *headerLabelTextField;
@property (nonatomic, strong) UITableView *budgetDisplayTableView;
@property (nonatomic, strong) UIView *headerContainer;
@property (strong, nonatomic) UIBarButtonItem *rightButton;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) NSMutableArray* income;
@property (nonatomic, strong) NSMutableArray* expenses;

@property (nonatomic, strong) NSMutableArray* incomeAmounts;
@property (nonatomic, strong) NSMutableArray* expensesAmounts;

@property (nonatomic) NSInteger incomeCount;
@property (nonatomic) NSInteger expenseCount;

@end

NS_ASSUME_NONNULL_END
