#import "BudgetDisplayViewController.h"
#import "Budget+CoreDataClass.h"
#import <HealthKit/HealthKit.h>

@interface BudgetDisplayViewController ()
@property (nonatomic, strong) UILabel *budgetLabel;
@property (nonatomic, strong) UIButton *healthPermissionButton;
@property (nonatomic, strong) HKHealthStore *healthStore;
@end

@implementation BudgetDisplayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.budgetLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, 300, 40)];
    self.budgetLabel.textColor = [UIColor blackColor];
    [self.view addSubview:self.budgetLabel];
    
    self.healthPermissionButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.healthPermissionButton.frame = CGRectMake(20, 160, 300, 40);
    [self.healthPermissionButton setTitle:@"Request Heart Rate Permission" forState:UIControlStateNormal];
    [self.healthPermissionButton addTarget:self action:@selector(requestHeartRatePermission) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.healthPermissionButton];
}

- (void)requestHeartRatePermission {
    if ([HKHealthStore isHealthDataAvailable]) {
        self.healthStore = [[HKHealthStore alloc] init];
        
        NSSet *readTypes = [NSSet setWithObject:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate]];
        
        [self.healthStore requestAuthorizationToShareTypes:nil
                                                 readTypes:readTypes
                                                completion:^(BOOL success, NSError * _Nullable error) {
            NSLog(@"Health permission granted: %d, error: %@", success, error);
            NSLog(@"ReadTypes: %@", readTypes);
        }];
    
    // Update the completion block in requestHeartRatePermission:
    [self.healthStore requestAuthorizationToShareTypes:nil
                                             readTypes:readTypes
                                            completion:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            [self fetchAllHeartRates];
        }
        NSLog(@"Health permission granted: %d, error: %@", success, error);
    }];
    }
}

// Fetch all heart rate samples
- (void)fetchAllHeartRates {
    HKSampleType *sampleType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:sampleType
                                                           predicate:nil
                                                               limit:HKObjectQueryNoLimit
                                                     sortDescriptors:@[sortDescriptor]
                                                      resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Fetched heart rate samples: %@ ", results);
            if (results.count > 0) {
                NSMutableString *heartRates = [NSMutableString string];
                for (HKQuantitySample *sample in results) {
                    double heartRate = [sample.quantity doubleValueForUnit:[HKUnit unitFromString:@"count/min"]];
                    [heartRates appendFormat:@"%.0f bpm\n", heartRate];
                }
                self.budgetLabel.text = heartRates;
            } else {
                self.budgetLabel.text = @"No heart rate data";
            }
        });
    }];
    [self.healthStore executeQuery:query];
}

@end
