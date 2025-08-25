// ExpenseTracker/ExpenseTracker/TransactionsViewController.m

#import "TransactionsViewController.h"
#import "AppDelegate.h"

@interface TransactionsViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
@property (nonatomic, assign) BOOL isDatePickerVisible;
@end

@implementation TransactionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    
    self.title = @"Transaction";
    self.leftButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(leftButtonTapped)];
    self.rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStyleDone target:self action:@selector(rightButtonTapped)];
    self.navigationItem.leftBarButtonItem = self.leftButton;
    self.navigationItem.rightBarButtonItem = self.rightButton;
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDictionary *attributes = [appDelegate fetchAttributes];
    self.expenseAttributes = attributes[@"Expenses"];
    self.incomeAttributes = attributes[@"Income"];
    self.categoryValues = [self.expenseAttributes allKeys];
    
    [self setupTableView];
    [self setupPickers];
    [self setupTypePicker];
    [self selectEmptyScreen];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (void)setupPickers {
    self.datePicker = [[UIDatePicker alloc] init];
    self.datePicker.datePickerMode = UIDatePickerModeDate;
    self.timePicker = [[UIDatePicker alloc] init];
    self.timePicker.datePickerMode = UIDatePickerModeTime;
    self.categoryPicker = [[UIPickerView alloc] init];
    self.categoryPicker.delegate = self;
    self.categoryPicker.dataSource = self;
    self.amountTextField = [[UITextField alloc] init];
    self.amountTextField.placeholder = @"Enter amount";
    self.amountTextField.keyboardType = UIKeyboardTypeDecimalPad;
    self.amountTextField.delegate = self;
}

- (void)setupTypePicker {
    self.typeValues = @[@"Expense", @"Income"];
    self.selectedTypeIndex = 0;
    self.typePicker = [[UIPickerView alloc] init];
    self.typePicker.delegate = self;
    self.typePicker.dataSource = self;
}

- (void)selectEmptyScreen {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 6; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"FormCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellId];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    switch (indexPath.row) {
        case 0: // Date
            cell.textLabel.text = @"Date";
            [cell.contentView addSubview:self.datePicker];
            self.datePicker.translatesAutoresizingMaskIntoConstraints = NO;
            [NSLayoutConstraint activateConstraints:@[
                [self.datePicker.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
                [self.datePicker.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
                [self.datePicker.widthAnchor constraintEqualToConstant:140]
            ]];
            break;
        case 1: // Time
            cell.textLabel.text = @"Time";
            [cell.contentView addSubview:self.timePicker];
            self.timePicker.translatesAutoresizingMaskIntoConstraints = NO;
            [NSLayoutConstraint activateConstraints:@[
                [self.timePicker.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
                [self.timePicker.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
                [self.timePicker.widthAnchor constraintEqualToConstant:140]
            ]];
            break;
        case 2: // Amount
            cell.textLabel.text = @"Amount";
            [cell.contentView addSubview:self.amountTextField];
            self.amountTextField.translatesAutoresizingMaskIntoConstraints = NO;
            [NSLayoutConstraint activateConstraints:@[
                [self.amountTextField.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
                [self.amountTextField.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
                [self.amountTextField.widthAnchor constraintEqualToConstant:120]
            ]];
            break;
        case 3: // Budget
            cell.textLabel.text = @"Budget";
            break;
        case 4: // Type
            cell.textLabel.text = @"Type";
            cell.detailTextLabel.text = self.typeValues[self.selectedTypeIndex];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case 5: // Category
            cell.textLabel.text = @"Category";
            cell.detailTextLabel.text = self.categoryValues.count ? [self.categoryValues[0] capitalizedString] : @"";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) { // Date
        self.isDatePickerVisible = !self.isDatePickerVisible;
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if (indexPath.row == 1) { // Time
        UITextField *hiddenField = [[UITextField alloc] initWithFrame:CGRectZero];
        [self.view addSubview:hiddenField];
        hiddenField.inputView = self.timePicker;
        [hiddenField becomeFirstResponder];
    } else if (indexPath.row == 3) { // Category
        UITextField *hiddenField = [[UITextField alloc] initWithFrame:CGRectZero];
        [self.view addSubview:hiddenField];
        hiddenField.inputView = self.categoryPicker;
        [hiddenField becomeFirstResponder];
    }
}

#pragma mark - UIPickerViewDataSource/Delegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    if (pickerView == self.typePicker) return 1;
    return 1;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (pickerView == self.typePicker) return self.typeValues.count;
    return self.categoryValues.count;
}
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (pickerView == self.typePicker) return self.typeValues[row];
    return [self.categoryValues[row] capitalizedString];
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (pickerView == self.typePicker) {
        self.selectedTypeIndex = row;
        NSIndexPath *typeIndexPath = [NSIndexPath indexPathForRow:4 inSection:0];
        [self.tableView reloadRowsAtIndexPaths:@[typeIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}
#pragma mark - Actions

- (void)leftButtonTapped { [self dismissViewControllerAnimated:YES completion:nil]; }
- (void)rightButtonTapped {
    // Save logic here
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

@end
