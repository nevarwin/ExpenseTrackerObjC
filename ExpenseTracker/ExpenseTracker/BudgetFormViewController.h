//
//  BudgetFormViewController.h
//  ExpenseTracker
//
//  Created by raven on 8/6/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BudgetFormViewController : UIViewController

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) UIDatePicker *timePicker;
@property (nonatomic, strong) NSString *budgetName;
@property (nonatomic, strong) NSDate *selectedDate;

// Income
@property (nonatomic, strong) NSDecimalNumber *salary;
@property (nonatomic, strong) NSDecimalNumber *bonus;
@property (nonatomic, strong) NSDecimalNumber *savings;

// Expenses
@property (nonatomic, strong) NSDecimalNumber *groceries;
@property (nonatomic, strong) NSDecimalNumber *gifts;
@property (nonatomic, strong) NSDecimalNumber *healthMedical;
@property (nonatomic, strong) NSDecimalNumber *electricity;
@property (nonatomic, strong) NSDecimalNumber *foodMoney;
@property (nonatomic, strong) NSDecimalNumber *personalWallet;
@property (nonatomic, strong) NSDecimalNumber *transpoPerWeek;
@property (nonatomic, strong) NSDecimalNumber *lrt;
@property (nonatomic, strong) NSDecimalNumber *travel;
@property (nonatomic, strong) NSDecimalNumber *debt;


@property (nonatomic, assign) BOOL isEditMode;
@property (nonatomic, weak) id delegate;

@property (strong, nonatomic) UIBarButtonItem *rightButton;
@property (strong, nonatomic) UIBarButtonItem *leftButton;

@end

NS_ASSUME_NONNULL_END
