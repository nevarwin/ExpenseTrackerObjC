//
//  TransactionsViewController.h
//  ExpenseTracker
//
//  Created by raven on 6/27/25.
//

#ifndef TransactionsViewController_h
#define TransactionsViewController_h

#import "Transaction+CoreDataClass.h"
#import "TransactionService.h"
#import <UIKit/UIKit.h>

@interface TransactionsViewController : UIViewController

@property (nonatomic, strong) TransactionService *service;
@property (nonatomic, assign) BOOL isEditMode;
@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) Transaction *existingTransaction;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIBarButtonItem *leftButton;
@property (nonatomic, strong) UIBarButtonItem *rightButton;
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) UITextField *amountTextField;
@property (nonatomic, strong) UITextField *descriptionTextField;

@property (nonatomic, assign) NSManagedObjectID* selectedBudgetIndex;
@property (nonatomic, strong) NSArray *budgetValues;
@property (nonatomic, strong) UIPickerView *budgetPicker;

@property (nonatomic, assign) NSManagedObjectID* selectedCategoryIndex;
@property (nonatomic, strong) NSArray *categoryValues;
@property (nonatomic, strong) UIPickerView *categoryPicker;

@property (nonatomic, assign) NSInteger selectedTypeIndex;
@property (nonatomic, strong) NSArray *typeValues;
@property (nonatomic, strong) UIPickerView *typePicker;

@property (nonatomic, assign) NSInteger currentPickerMode;

@property (nonatomic, strong) NSArray<Budget *> *budgets;
@property (nonatomic, strong) NSArray<Category *> *category;

@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;

@end

#endif /* TransactionsViewController_h */
