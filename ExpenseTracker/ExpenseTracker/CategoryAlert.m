//
//  CategoryAlert.m
//  ExpenseTracker
//
//  Created by raven on 10/13/25.
//

#import <Foundation/Foundation.h>
#import "CategoryAlert.h"

@interface CategoryAlert () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@end

@implementation CategoryAlert

#pragma mark - View Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self setupTableViews];
}

#pragma mark - Setup UI
- (void)setupUI {
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"Add Category";
    
    // Create main stack view
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.spacing = 10;
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [stackView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
        [stackView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [stackView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [stackView.bottomAnchor constraintLessThanOrEqualToAnchor:self.view.bottomAnchor constant:-20],
    ]];
    
    // Category Info Table
    [stackView addArrangedSubview:self.categoryInfoTableView];
    [self.categoryInfoTableView.heightAnchor constraintEqualToConstant:160].active = YES;
    
    // Installment Info Table
    [stackView addArrangedSubview:self.installmentInfoTableView];
    [self.installmentInfoTableView.heightAnchor constraintEqualToConstant:200].active = YES;
    
    // Hide installment section initially
    self.installmentInfoTableView.hidden = YES;
}

#pragma mark - Setup Tables
- (void)setupTableViews {
    // Category Info
    self.categoryInfoTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.categoryInfoTableView.delegate = self;
    self.categoryInfoTableView.dataSource = self;
    self.categoryInfoTableView.scrollEnabled = NO;
    self.categoryInfoTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.categoryInfoTableView.layer.cornerRadius = 12;
    
    // Installment Info
    self.installmentInfoTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.installmentInfoTableView.delegate = self;
    self.installmentInfoTableView.dataSource = self;
    self.installmentInfoTableView.scrollEnabled = NO;
    self.installmentInfoTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.installmentInfoTableView.layer.cornerRadius = 12;
}

#pragma mark - Toggle Installment
- (void)toggleInstallment:(UISwitch *)sender {
    self.installmentInfoTableView.hidden = !sender.isOn;
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.categoryInfoTableView) return 3;
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.categoryInfoTableView) {
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
                cell.textLabel.text = @"Category Name";
                if (!self.categoryTextField) {
                    self.categoryTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
                    self.categoryTextField.placeholder = @"e.g. Needs";
                    self.categoryTextField.textAlignment = NSTextAlignmentRight;
                }
                cell.accessoryView = self.categoryTextField;
                break;
            case 2:
                cell.textLabel.text = @"Amount";
                if (!self.totalLabel) {
                    self.totalLabel = [[UILabel alloc] init];
                    self.totalLabel.text = @"₱0.00";
                }
                cell.accessoryView = self.totalLabel;
                break;
        }
        return cell;
    }
    
    // Installment Info
    static NSString *installCellId = @"InstallmentCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:installCellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:installCellId];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Start Date";
            if (!self.startDatePicker) {
                self.startDatePicker = [[UIDatePicker alloc] init];
                self.startDatePicker.preferredDatePickerStyle = UIDatePickerStyleCompact;
            }
            cell.accessoryView = self.startDatePicker;
            break;
        case 1:
            cell.textLabel.text = @"Months";
            if (!self.monthsTextField) {
                self.monthsTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
                self.monthsTextField.keyboardType = UIKeyboardTypeNumberPad;
                self.monthsTextField.placeholder = @"e.g. 6";
                self.monthsTextField.textAlignment = NSTextAlignmentRight;
            }
            cell.accessoryView = self.monthsTextField;
            break;
        case 2:
            cell.textLabel.text = @"Monthly Payment";
            if (!self.monthlyLabel) {
                self.monthlyLabel = [[UILabel alloc] init];
                self.monthlyLabel.text = @"₱0.00";
            }
            cell.accessoryView = self.monthlyLabel;
            break;
    }
    
    return cell;
}

@end
