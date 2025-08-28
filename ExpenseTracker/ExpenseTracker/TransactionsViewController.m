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
    [self configureViewForMode];
    
    self.budgetValues = [NSMutableArray array];
    if(self.budgetValues.count == 0){
        self.budgetValues = @[@"None"];
    }
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
    self.datePicker.datePickerMode = UIDatePickerModeDateAndTime;
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
    self.typePicker = [[UIPickerView alloc] init];
    self.typePicker.delegate = self;
    self.typePicker.dataSource = self;
}

- (void)selectEmptyScreen {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

-(void)configureViewForMode{
    if(self.isEditMode){
        self.amountTextField.text = [NSString stringWithFormat:@"%ld", (long)self.existingTransaction.amount];
        
        NSLog(@"self.segmentControl.selectedSegmentIndex: %ld", (long)self.existingTransaction.type);
        
        // TODO: bug when in edit mode
        [self.datePicker setDate:self.existingTransaction.date];
        [self.budgetPicker selectRow:self.existingTransaction.budget inComponent:0 animated:NO];
        [self.categoryPicker selectRow:1 inComponent:0 animated:NO];
        
        NSString *typeTitle = _typeValues[self.existingTransaction.type];

    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 5; }

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
                [self.datePicker.widthAnchor constraintEqualToConstant:200]
            ]];
            break;
        case 1: // Amount
            cell.textLabel.text = @"Amount";
            [cell.contentView addSubview:self.amountTextField];
            self.amountTextField.translatesAutoresizingMaskIntoConstraints = NO;
            [NSLayoutConstraint activateConstraints:@[
                [self.amountTextField.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
                [self.amountTextField.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
                [self.amountTextField.widthAnchor constraintEqualToConstant:120]
            ]];
            break;
        case 2: // Budget
        {
            cell.textLabel.text = @"Budget";
            UIButton *typeButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [typeButton setTitle:@"Select Budget" forState:UIControlStateNormal];
            typeButton.translatesAutoresizingMaskIntoConstraints = NO;
            typeButton.tag = 0;
            [typeButton addTarget:self action:@selector(pickerButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:typeButton];
            
            [NSLayoutConstraint activateConstraints:@[
                [typeButton.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
                [typeButton.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor]
            ]];
            break;
        }
        case 3: // Type
        {
            cell.textLabel.text = @"Type";
            UIButton *typeButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [typeButton setTitle:@"Select Type" forState:UIControlStateNormal];
            typeButton.translatesAutoresizingMaskIntoConstraints = NO;
            typeButton.tag = 1;
            [typeButton addTarget:self action:@selector(pickerButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:typeButton];
            
            [NSLayoutConstraint activateConstraints:@[
                [typeButton.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
                [typeButton.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor]
            ]];
            break;
        }
        case 4: // Category
            cell.textLabel.text = @"Category";
            UIButton *typeButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [typeButton setTitle:@"Select Category" forState:UIControlStateNormal];
            typeButton.translatesAutoresizingMaskIntoConstraints = NO;
            typeButton.tag = 2;
            [typeButton addTarget:self action:@selector(pickerButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:typeButton];
            
            [NSLayoutConstraint activateConstraints:@[
                [typeButton.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-16],
                [typeButton.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor]
            ]];
            break;
    }
    return cell;
}

- (void)pickerButtonTapped:(UIButton *)sender {
    NSString *title = [sender titleForState:UIControlStateNormal];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:@"\n\n\n\n\n\n"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIPickerView *picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 40, alert.view.bounds.size.width - 20, 140)];
    picker.dataSource = self;
    picker.delegate = self;
    
    [alert.view addSubview:picker];
    self.currentPickerMode = sender.tag;
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
    NSDictionary *attributes = [appDelegate fetchAttributes];
    self.expenseAttributes = attributes[@"Expenses"];
    self.incomeAttributes = attributes[@"Income"];
    
    if(self.selectedTypeIndex == 0){
        self.categoryValues = [self.expenseAttributes allKeys];
    } else {
        self.categoryValues = [self.incomeAttributes allKeys];
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Budget"];
    fetchRequest.resultType = NSDictionaryResultType;
    fetchRequest.propertiesToFetch = @[@"name"];
    
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    
    if (!error && results.count != 0) {
        NSMutableArray *names = [NSMutableArray array];
        for (NSDictionary *dict in results) {
            NSString *name = dict[@"name"];
            if (name) {
                [names addObject:name];
            }
        }
        self.budgetValues = names;
    }
    
    
    UIAlertAction *done = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSInteger selectedRow;
        switch (sender.tag) {
            case 0:
                selectedRow = [picker selectedRowInComponent:0];
                self.selectedBudgetIndex = selectedRow;
                [sender setTitle:self.budgetValues[selectedRow] forState:UIControlStateNormal];
                break;
                
            case 1:
                selectedRow = [picker selectedRowInComponent:0];
                self.selectedTypeIndex = selectedRow;
                [sender setTitle:self.typeValues[selectedRow] forState:UIControlStateNormal];
                break;
                
            case 2:
                selectedRow = [picker selectedRowInComponent:0];
                self.selectedCategoryIndex = selectedRow;
                [sender setTitle:self.categoryValues[selectedRow] forState:UIControlStateNormal];
                break;
                
            default:
                break;
        }
        
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:done];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

#pragma mark - UIPickerViewDataSource/Delegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if(self.currentPickerMode == 0) return self.budgetValues.count;
    if(self.currentPickerMode == 1) return self.typeValues.count;
    if(self.currentPickerMode == 2) return self.categoryValues.count;
    return 0;
}
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if(self.currentPickerMode == 0) return self.budgetValues[row];
    if(self.currentPickerMode == 1) return self.typeValues[row];
    if(self.currentPickerMode == 2) return self.categoryValues[row];
    return 0;
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {

}
#pragma mark - Actions

- (void)leftButtonTapped { [self dismissViewControllerAnimated:YES completion:nil]; }
- (void)rightButtonTapped {
    NSInteger budget = self.selectedBudgetIndex;
    NSInteger type = self.selectedTypeIndex;
    NSString *category = self.categoryValues[self.selectedCategoryIndex];
    
    //Parse amount using NSNumberFormatter for safety
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *amountNumber = [formatter numberFromString:self.amountTextField.text];
    NSInteger amount = amountNumber.integerValue;
    
    NSDate *date = self.datePicker.date;
    
    if (amount == 0 || !date) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Invalid Input"
                                                                       message:@"Please fill all fields correctly."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:nil];
        
        [alert addAction:ok];
        
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    // Get Core Data Context
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
    
    Transaction *transaction;
    
    //Assign transaction values
    if (self.isEditMode && self.existingTransaction.transactionId) {
        transaction = self.existingTransaction;
        transaction.updatedAt = [NSDate date];
    } else {
        transaction = [NSEntityDescription insertNewObjectForEntityForName:@"Transaction" inManagedObjectContext:context];
        transaction.createdAt = [NSDate date];
        transaction.transactionId = [[NSUUID UUID] UUIDString];
    }
    
    transaction.amount = (int32_t)amount;
    transaction.category = category;
    transaction.date = date;
    transaction.type = type;
    transaction.budget = budget;
    
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Failed to save transaction: %@", error);
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

@end
