//
//  BudgetFormViewController.m
//  ExpenseTracker
//
//  Created by raven on 8/6/25.
//

#import "BudgetFormViewController.h"

@protocol BudgetFormViewControllerDelegate <NSObject>
- (void)budgetFormViewController:(BudgetFormViewController *)controller didSaveBudget:(id)budget;
- (void)budgetFormViewControllerDidCancel:(BudgetFormViewController *)controller;
@end

@interface BudgetFormViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation BudgetFormViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize properties
    self.selectedDate = [NSDate date];
    self.budgetName = @"";
    self.salary = [NSDecimalNumber zero];
    self.bonus = [NSDecimalNumber zero];
    self.savings = [NSDecimalNumber zero];
    
    // Setup UI
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.title = self.isEditMode ? @"Edit Budget" : @"Add Budget";
    
    // Navigation bar buttons
    self.leftButton = [[UIBarButtonItem alloc]
                       initWithTitle:@"Cancel"
                       style:UIBarButtonItemStylePlain
                       target:self
                       action:@selector(leftButtonTapped)];
    self.navigationItem.leftBarButtonItem = self.leftButton;
    
    self.rightButton = [[UIBarButtonItem alloc]
                        initWithTitle:@"Save"
                        style:UIBarButtonItemStyleDone
                        target:self
                        action:@selector(rightButtonTapped)];
    self.navigationItem.rightBarButtonItem = self.rightButton;
    
    // Disable save button initially until form is valid
    self.rightButton.enabled = NO;
    
    // Setup table view
    [self setupTableView];
    
    // Add tap gesture to dismiss keyboard
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(dismissKeyboard)];
    tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGesture];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero
                                                  style:UITableViewStyleInsetGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.view addSubview:self.tableView];
    
    // Register cell classes
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"TextFieldCell"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"DateCell"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"TimeCell"];
    
    // Setup constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
    
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: // Budget info
            return 1;
        case 1: // Date
            return 2;
        case 2: // Time
            return 2;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TextFieldCell" forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // Remove any existing text fields
        for (UIView *subview in cell.contentView.subviews) {
            [subview removeFromSuperview];
        }
        
        UITextField *textField = [[UITextField alloc] init];
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.tag = 100 + indexPath.row;
        [textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
        
        [cell.contentView addSubview:textField];
        
        [NSLayoutConstraint activateConstraints:@[
            [textField.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor],
            [textField.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:16],
            [textField.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
            [textField.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor]
        ]];
        
        textField.placeholder = @"Budget Name";
        textField.text = self.budgetName;
        
        return cell;
    } else if (indexPath.section == 1) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TextFieldCell" forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // Remove any existing text fields
        for (UIView *subview in cell.contentView.subviews) {
            [subview removeFromSuperview];
        }
        
        UITextField *textField = [[UITextField alloc] init];
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.tag = 100 + indexPath.row;
        [textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
        
        [cell.contentView addSubview:textField];
        
        [NSLayoutConstraint activateConstraints:@[
            [textField.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor],
            [textField.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:16],
            [textField.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
            [textField.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor]
        ]];
        
        
        if (indexPath.row == 0) {
            textField.placeholder = @"Paycheck";
            textField.text = self.budgetName;
            textField.keyboardType = UIKeyboardTypeDecimalPad;
            if (![self.salary isEqualToNumber:[NSDecimalNumber zero]]) {
                NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                formatter.numberStyle = NSNumberFormatterCurrencyStyle;
                textField.text = [formatter stringFromNumber:self.salary];
            }
        } else {
            textField.placeholder = @"Savings";
            textField.keyboardType = UIKeyboardTypeDecimalPad;
            if (![self.salary isEqualToNumber:[NSDecimalNumber zero]]) {
                NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                formatter.numberStyle = NSNumberFormatterCurrencyStyle;
                textField.text = [formatter stringFromNumber:self.salary];
            }
        }
        
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TextFieldCell" forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // Remove any existing text fields
        for (UIView *subview in cell.contentView.subviews) {
            [subview removeFromSuperview];
        }
        
        UITextField *textField = [[UITextField alloc] init];
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.tag = 100 + indexPath.row;
        [textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
        
        [cell.contentView addSubview:textField];
        
        [NSLayoutConstraint activateConstraints:@[
            [textField.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor],
            [textField.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:16],
            [textField.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
            [textField.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor]
        ]];
        
        
            textField.placeholder = @"Amount";
            textField.keyboardType = UIKeyboardTypeDecimalPad;
        if (![self.electricity isEqualToNumber:[NSDecimalNumber zero]]) {
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            formatter.numberStyle = NSNumberFormatterCurrencyStyle;
            textField.text = [formatter stringFromNumber:self.electricity];
        }
        
        return cell;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"BUDGET DETAILS";
        case 1:
            return @"EXPENSES";
        case 2:
            return @"INCOME";
        default:
            return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return @"Enter a name for your budget";
    }
    return nil;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}


#pragma mark - Event Handlers

- (void)textFieldChanged:(UITextField *)textField {
    if (textField.tag == 100) {
        self.budgetName = textField.text;
    } else if (textField.tag == 101) {
        NSString *cleanString = [[textField.text componentsSeparatedByCharactersInSet:
                                  [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                                 componentsJoinedByString:@""];
        
        double value = [cleanString doubleValue] / 100.0;
        self.salary = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.2f", value]];
        
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterCurrencyStyle;
        
        if (value > 0) {
            NSString *formattedString = [formatter stringFromNumber:self.salary];
            textField.text = formattedString;
        }
    }
    
    [self validateForm];
}

- (void)validateForm {
    BOOL isValid = self.budgetName.length > 0 &&
    ![self.salary isEqualToNumber:[NSDecimalNumber zero]];
    
    self.rightButton.enabled = isValid;
}

#pragma mark - Actions

- (void)rightButtonTapped {
    // Create budget object - replace with your actual Budget model
    NSDictionary *budgetData = @{
        @"name": self.budgetName,
        @"amount": self.salary,
        @"date": self.selectedDate
    };
    
    // Notify delegate
    if ([self.delegate respondsToSelector:@selector(budgetFormViewController:didSaveBudget:)]) {
        [self.delegate budgetFormViewController:self didSaveBudget:budgetData];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)leftButtonTapped {
    if ([self.delegate respondsToSelector:@selector(budgetFormViewControllerDidCancel:)]) {
        [self.delegate budgetFormViewControllerDidCancel:self];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

@end
