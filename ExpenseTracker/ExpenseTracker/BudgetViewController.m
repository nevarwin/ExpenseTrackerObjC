//
//  BudgetViewController.m
//
//  Created by raven on 8/4/25.
//

#import "BudgetViewController.h"
#import "BudgetFormViewController.h"
#import "AppDelegate.h"
#import "Budget+CoreDataClass.h"

@interface BudgetViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) NSArray *budgets;
@end

@implementation BudgetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set background color to match Health app
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    
    // Setup UI components
    [self setupHeaderView];
    [self setupTableView];
    [self fetchBudgets];
}

- (void)fetchBudgets {
    if (!self.managedObjectContext) {
        AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        self.managedObjectContext = delegate.persistentContainer.viewContext;
    }
    NSFetchRequest *request = [Budget fetchRequest];
    NSError *error = nil;
    self.budgets = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Error fetching budgets: %@", error);
        self.budgets = @[];
    }
    [self.budgetTableView reloadData];
}

- (void)setupHeaderView {
    // Create header container
    UIView *headerContainer = [[UIView alloc] init];
    headerContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:headerContainer];
    
    // Setup header label (left side)
    self.headerLabel = [[UILabel alloc] init];
    self.headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.headerLabel.text = @"Budgets";
    self.headerLabel.font = [UIFont systemFontOfSize:34 weight:UIFontWeightBold];
    self.headerLabel.textColor = [UIColor labelColor];
    [headerContainer addSubview:self.headerLabel];
    
    // Setup add button (right side)
    self.addButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.addButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.addButton setImage:[UIImage systemImageNamed:@"plus.circle.fill"] forState:UIControlStateNormal];
    self.addButton.tintColor = [UIColor systemBlueColor];
    [self.addButton addTarget:self action:@selector(addButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.addButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    // Increase button size to match Health app
    [self.addButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [headerContainer addSubview:self.addButton];
    
    // Setup constraints for header container
    [NSLayoutConstraint activateConstraints:@[
        [headerContainer.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [headerContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [headerContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [headerContainer.heightAnchor constraintEqualToConstant:60]
    ]];
    
    // Setup constraints for header label
    [NSLayoutConstraint activateConstraints:@[
        [self.headerLabel.leadingAnchor constraintEqualToAnchor:headerContainer.leadingAnchor],
        [self.headerLabel.centerYAnchor constraintEqualToAnchor:headerContainer.centerYAnchor],
        [self.headerLabel.trailingAnchor constraintEqualToAnchor:self.addButton.leadingAnchor constant:-10]
    ]];
    
    // Setup constraints for add button - make it larger like in Health app
    [NSLayoutConstraint activateConstraints:@[
        [self.addButton.trailingAnchor constraintEqualToAnchor:headerContainer.trailingAnchor],
        [self.addButton.centerYAnchor constraintEqualToAnchor:headerContainer.centerYAnchor],
        [self.addButton.widthAnchor constraintEqualToConstant:44],
        [self.addButton.heightAnchor constraintEqualToConstant:44]
    ]];
}

- (void)setupTableView {
    // Setup table view for budget items - use inset grouped style like Health app
    self.budgetTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.budgetTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.budgetTableView.delegate = self;
    self.budgetTableView.dataSource = self;
    // Clear background to match the parent view background
    self.budgetTableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.budgetTableView];
    
    // Register cell with subtitle style to show budget amounts
    [self.budgetTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"BudgetCell"];
    
    // Setup constraints for table view
    [NSLayoutConstraint activateConstraints:@[
        [self.budgetTableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:70],
        [self.budgetTableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.budgetTableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.budgetTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

#pragma mark - Actions

- (void)addButtonTapped {
    // Create BudgetFormViewController programmatically
    
    if (!self.managedObjectContext) {
        AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        self.managedObjectContext = delegate.persistentContainer.viewContext;
    }
    // Initialize BudgetFormViewController
    BudgetFormViewController *budgetFormVC = [[BudgetFormViewController alloc] init];
    
    budgetFormVC.managedObjectContext = self.managedObjectContext;
    
    // Configure the view controller
    budgetFormVC.delegate = self;
    budgetFormVC.isEditMode = NO; // Since we're adding a new budget, not editing
    
    // Wrap in a navigation controller
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:budgetFormVC];
    
    // Present modally
    [self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return your budget items count here
    return self.budgets.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BudgetCell" forIndexPath:indexPath];
    
    CGFloat progress = (indexPath.row + 1) / 5.0;
    
    // For subtitle, show amount and progress
    NSString *amountText = [NSString stringWithFormat:@"$%d / $1,000", (int)(1000 * progress)];
    cell.detailTextLabel.text = amountText;
    
    // Use a disclosure indicator like Health app
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    // Ensure the cell uses subtitle style
    if (cell.detailTextLabel == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"BudgetCell"];
        cell.textLabel.text = [NSString stringWithFormat:@"Budget Category %ld", (long)indexPath.row + 1];
        cell.detailTextLabel.text = amountText;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    // Handle selection to show budget details
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Monthly Budgets";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    // Add a helpful footer message like in Health app
    return @"Tap + to add a new budget category";
}

@end
