//
//  CategoryAlert.m
//  ExpenseTracker
//
//  Created by raven on 10/13/25.
//

#import <Foundation/Foundation.h>
#import "CategoryViewController.h"

@interface CategoryViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@end

@implementation CategoryViewController

#pragma mark - viewDidLoad
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupTableViews];
    
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    self.categoryTextField.delegate = self;
    self.monthsTextField.delegate = self;
    self.monthlyTextField.delegate = self;
    
    self.title = @"Category";
    NSString *rightButtonTitle = self.isEditMode ? @"Update" : @"Add";
    self.leftButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(leftButtonTapped)];
    self.rightButton = [[UIBarButtonItem alloc] initWithTitle:rightButtonTitle style:UIBarButtonItemStyleDone target:self action:@selector(rightButtonTapped)];
    self.navigationItem.leftBarButtonItem = self.leftButton;
    self.navigationItem.rightBarButtonItem = self.rightButton;
    
}

# pragma mark - Actions
- (void)leftButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)rightButtonTapped {
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
    if (self.installmentEnabled) {
        return 6;
    } else {
        return 3;
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
        case 0: {
            cell.textLabel.text = @"Pay in Installments";
            if (!self.installmentSwitch) {
                self.installmentSwitch = [[UISwitch alloc] init];
                [self.installmentSwitch addTarget:self action:@selector(toggleInstallment:) forControlEvents:UIControlEventValueChanged];
            }
            cell.accessoryView = self.installmentSwitch;
            break;
        }
        case 1:
            // TODO: add limit to text field
            cell.textLabel.text = @"Category Name";
            if (!self.categoryTextField) {
                self.categoryTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
                self.categoryTextField.placeholder = @"e.g. Needs";
                self.categoryTextField.textAlignment = NSTextAlignmentRight;
            }
            cell.accessoryView = self.categoryTextField;
            break;
        case 2:
            cell.textLabel.text = _installmentEnabled ? @"Total Amount" : @"Allocated Amount";
            if (!self.amountTextField) {
                self.amountTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
                self.amountTextField.placeholder = @"₱0.00";
                self.amountTextField.textAlignment = NSTextAlignmentRight;
            }
            cell.accessoryView = self.amountTextField;
            break;
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
            }
            cell.accessoryView = self.monthlyTextField;
            break;
    }
    return cell;
}

@end
