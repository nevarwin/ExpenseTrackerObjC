//
//  TransactionsViewController.h
//  ExpenseTracker
//
//  Created by XOO_Raven on 6/27/25.
//

#ifndef TransactionsViewController_h
#define TransactionsViewController_h

#import <UIKit/UIKit.h>
#import "Transaction.h"


@interface TransactionsViewController : UIViewController

@property (nonatomic, assign) BOOL isEditMode;
@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) Transaction *existingTransaction;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIBarButtonItem *leftButton;
@property (nonatomic, strong) UIBarButtonItem *rightButton;
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) UIDatePicker *timePicker;
@property (nonatomic, strong) UITextField *amountTextField;
@property (nonatomic, strong) UIPickerView *categoryPicker;
@property (nonatomic, strong) UIPickerView *budgetPicker;
@property (nonatomic, strong) NSArray *categoryValues;
@property (nonatomic, strong) NSDictionary *expenseAttributes;
@property (nonatomic, strong) NSDictionary *incomeAttributes;

@property (nonatomic, assign) NSInteger selectedTypeIndex;
@property (nonatomic, strong) NSArray *typeValues;
@property (nonatomic, strong) UIPickerView *typePicker;

@end

#endif /* TransactionsViewController_h */
