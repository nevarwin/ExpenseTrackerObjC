//
//  CategoryAlert.m
//  ExpenseTracker
//
//  Created by raven on 10/13/25.
//

#import <Foundation/Foundation.h>
#import "CategoryViewController.h"
#import "CoreDataManager.h"
#import "Category+CoreDataClass.h"
#import "BudgetAllocation+CoreDataClass.h"
#import "Budget+CoreDataClass.h"

@interface CategoryViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@end

@implementation CategoryViewController

#pragma mark - viewDidLoad
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupTableViews];
    
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    
    self.title = @"Category";
    NSString *rightButtonTitle = self.isEditMode ? @"Update" : @"Add";
    self.leftButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(leftButtonTapped)];
    self.rightButton = [[UIBarButtonItem alloc] initWithTitle:rightButtonTitle style:UIBarButtonItemStyleDone target:self action:@selector(rightButtonTapped)];
    self.navigationItem.leftBarButtonItem = self.leftButton;
    self.navigationItem.rightBarButtonItem = self.rightButton;
    
}

# pragma mark - Actions
- (void)computeMonthlyAmount {
    NSInteger months = [self.monthsTextField.text integerValue];
    double amount = [self.amountTextField.text doubleValue];
    
    double monthlyAmount = amount / months;
    
    self.monthlyTextField.text = [NSString stringWithFormat:@"%.2f", monthlyAmount];
}

- (void)leftButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)rightButtonTapped {
    NSManagedObjectContext *context = [[CoreDataManager sharedManager] viewContext];
    Category *newCategory = [NSEntityDescription insertNewObjectForEntityForName:@"Category"
                                                          inManagedObjectContext:context];
    
    
    BOOL isInstallment = _installmentSwitch.isOn;
    NSLog(@"isInstallment: %d", isInstallment);
    // Validate fields if installment is on
    if (isInstallment) {
        BOOL allFieldsFilled = (self.startDatePicker != nil &&
                                self.monthsTextField.text.length != 0 &&
                                self.monthlyTextField.text.length != 0);
        
        if (!allFieldsFilled) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Missing Fields"
                                                                           message:@"Please fill in all installment fields."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                         style:UIAlertActionStyleDefault
                                                       handler:nil];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
    }
    
    newCategory.isIncome = self.isIncome;
    newCategory.isInstallment = isInstallment;
    newCategory.name = self.categoryTextField.text;
    
    if (isInstallment) {
        newCategory.installmentStartDate = self.startDatePicker.date;
        newCategory.installmentMonths = (int16_t)[self.monthsTextField.text integerValue];
        NSLog(@"self.monthlyTextField.text: %@", self.monthlyTextField.text);
        newCategory.monthlyPayment = [NSDecimalNumber decimalNumberWithString:self.monthlyTextField.text];
    }
    
    if (self.onCategoryAdded) {
        NSDecimalNumber *amountDecimalValue = [NSDecimalNumber decimalNumberWithString:self.amountTextField.text];
        self.onCategoryAdded(newCategory, amountDecimalValue);
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)toggleInstallment:(UISwitch *)sender {
    self.installmentEnabled = sender.isOn;
    [self.categoryInfoTableView reloadData];
}


#pragma mark - Setup Table
- (void)setupTableViews {
    self.categoryInfoTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.categoryInfoTableView.delegate = self;
    self.categoryInfoTableView.dataSource = self;
    self.categoryInfoTableView.scrollEnabled = NO;
    self.categoryInfoTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.categoryInfoTableView.layer.cornerRadius = 12;
    
    [self.view addSubview:self.categoryInfoTableView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.categoryInfoTableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.categoryInfoTableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.categoryInfoTableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.categoryInfoTableView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-40]
    ]];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.isIncome){
        if (self.installmentEnabled) {
            return 6;
        } else {
            return 3;
        }
    } else {
        return 2;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"CREATE CATEGORY";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *categoryCellId = @"CategoryInfoCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:categoryCellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:categoryCellId];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Category Name";
            if (!self.categoryTextField) {
                self.categoryTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
                self.categoryTextField.placeholder = @"e.g. Needs";
                self.categoryTextField.textAlignment = NSTextAlignmentRight;
                self.categoryTextField.delegate = self;
            }
            cell.accessoryView = self.categoryTextField;
            break;
        case 1:
            cell.textLabel.text = _installmentEnabled ? @"Total Amount" : @"Allocated Amount";
            if (!self.amountTextField) {
                self.amountTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
                self.amountTextField.keyboardType = UIKeyboardTypeNumberPad;
                self.amountTextField.placeholder = @"₱0.00";
                self.amountTextField.textAlignment = NSTextAlignmentRight;
                self.amountTextField.delegate = self;
                [self.amountTextField addTarget:self
                                                 action:@selector(textFieldDidChange:)
                                       forControlEvents:UIControlEventEditingChanged];
            }
            cell.accessoryView = self.amountTextField;
            break;
        case 2: {
            cell.textLabel.text = @"Pay in Installments";
            if (!self.installmentSwitch) {
                self.installmentSwitch = [[UISwitch alloc] init];
                [self.installmentSwitch addTarget:self action:@selector(toggleInstallment:) forControlEvents:UIControlEventValueChanged];
            }
            cell.accessoryView = self.installmentSwitch;
            break;
        }
        case 3:
            cell.textLabel.text = @"Start Date";
            if (!self.startDatePicker) {
                self.startDatePicker = [[UIDatePicker alloc] init];
                self.startDatePicker.preferredDatePickerStyle = UIDatePickerStyleAutomatic;
            }
            cell.accessoryView = self.startDatePicker;
            break;
        case 4:
            cell.textLabel.text = @"Months";
            if (!self.monthsTextField) {
                self.monthsTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
                self.monthsTextField.keyboardType = UIKeyboardTypeNumberPad;
                self.monthsTextField.placeholder = @"e.g. 6";
                self.monthsTextField.textAlignment = NSTextAlignmentRight;
                self.monthsTextField.delegate = self;
                
                [self.monthsTextField addTarget:self
                                                 action:@selector(textFieldDidChange:)
                                       forControlEvents:UIControlEventEditingChanged];
            }
            cell.accessoryView = self.monthsTextField;
            break;
        case 5:
            cell.textLabel.text = @"Monthly Payment";
            if (!self.monthlyTextField) {
                self.monthlyTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
                self.monthlyTextField.keyboardType = UIKeyboardTypeNumberPad;
                self.monthlyTextField.placeholder = @"₱0.00";
                self.monthlyTextField.textAlignment = NSTextAlignmentRight;
                self.monthlyTextField.delegate = self;
                self.monthlyTextField.userInteractionEnabled = NO;
            }
            cell.accessoryView = self.monthlyTextField;
            break;
    }
    return cell;
}

# pragma mark - UITextFieldDelegate
- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.amountTextField || textField == self.monthlyTextField) {
        [self computeMonthlyAmount];
    }
}

- (void)textFieldDidChange:(UITextField *)textField {
    [self computeMonthlyAmount];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.categoryTextField) {
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        
        if (newString.length > 16 && self.presentedViewController == nil) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Limit Reached"
                                                                           message:@"You can only enter up to 16 characters."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleDefault
                                                             handler:nil];
            [alert addAction:okAction];
            
            [self presentViewController:alert animated:YES completion:nil];
            
            return NO;
        }
    }
    
    if (textField == self.monthsTextField){
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSInteger value = [newString integerValue];
        
        if (string.length == 0) {
            return YES;
        }
        
        if (newString.length == 0) {
            return YES;
        }
        
        if (value <= 0) {
            textField.text = @"1";
            return NO;
        } else if (value > 12) {
            textField.text = @"12";
            return NO;
        }
    }
    
    if (textField == self.amountTextField || textField == self.monthlyTextField) {
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        
        if (newString.length > 8 && self.presentedViewController == nil) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Limit Reached"
                                                                           message:@"You can only enter up to 8 digits."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleDefault
                                                             handler:nil];
            [alert addAction:okAction];
            
            [self presentViewController:alert animated:YES completion:nil];
            
            return NO;
        }
    }
    return YES;
}

@end

