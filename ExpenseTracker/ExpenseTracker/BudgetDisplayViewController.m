#import "BudgetDisplayViewController.h"
#import "Budget+CoreDataClass.h"

@interface BudgetDisplayViewController ()
@property (nonatomic, strong) UILabel *budgetLabel;
@end

@implementation BudgetDisplayViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.budgetLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, 300, 40)];
    self.budgetLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.budgetLabel];
 
}

@end
