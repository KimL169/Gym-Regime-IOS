//
//  CalorieSettingsTableViewController.m
//  GymRegime
//
//  Created by Kim on 08/06/14.
//  Copyright (c) 2014 Kim. All rights reserved.
//

#import "CalorieSettingsTableViewController.h"
#import "CalorieCalculator.h"
#import "ALAlertBanner.h"

@interface CalorieSettingsTableViewController ()
@property (strong, nonatomic) IBOutlet UITableViewCell *harrisBenedictEquationCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *mifflinStJeorEquationCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *katchMcArdleEquationCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *bodyWeightMultiplierBmrCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *customBmrCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *calculatedMaintenanceCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *bodyWeightMultiplierCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *customMaintenanceCell;


@property (strong, nonatomic) IBOutlet UITextField *bmrBodyWeightMultiplierTextField;
@property (strong, nonatomic) IBOutlet UITextField *bmrCustomTextField;
@property (strong, nonatomic) IBOutlet UITextField *maintenanceBodyWeightMultiplierTextField;
@property (strong, nonatomic) IBOutlet UITextField *maintenanceCustomTextField;
@property (strong, nonatomic) IBOutlet UITextField *calorieCalibrationTextField;
@property (strong, nonatomic) IBOutlet UISegmentedControl *calorieCalibrationSegmentControl;

@property (strong, nonatomic) NSUserDefaults *userDefaults;
@property (strong, nonatomic) CalorieCalculator *calculator;

@property (nonatomic) int calibrationTDEE;
@property (nonatomic) NSInteger maintenanceMultiplierType;
@property (nonatomic) NSInteger bmrCalculator;
@property (nonatomic) NSInteger bmrBodyWeightMultiplier;
@property (nonatomic) NSInteger maintenanceBodyWeightMultiplier;
@property (nonatomic) NSInteger bmrCustom;
@property (nonatomic) NSInteger maintenanceCustom;

@property (nonatomic, strong) UIGestureRecognizer *tapGestureRecognizer;
@end

#define BMR_SECTION 0
#define TDEE_SECTION 1

#define SEGMENT_INDEX_ADD 0
#define SEGMENT_INDEX_SUBSTRACT 1

@implementation CalorieSettingsTableViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    
    //load user defaults.
    _userDefaults = [NSUserDefaults standardUserDefaults];
    [self loadUserData];
    
    //set the decimal textfield delegates.
    self.maintenanceBodyWeightMultiplierTextField.delegate = self;
    self.bmrBodyWeightMultiplierTextField.delegate = self;
    self.maintenanceCustomTextField.delegate = self;
    self.bmrCustomTextField.delegate = self;
    //set the textfield values if they exist.
    [self setOutletValues];

    //set the selector at the right equation:
    [self setSelectedOptions];
    
    self.calculator = [[CalorieCalculator alloc]init];
    
    //add a tap recognizer to dismiss the keyboard.
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.tableView addGestureRecognizer:_tapGestureRecognizer];
    //make sure the user can still select table cells.
    _tapGestureRecognizer.cancelsTouchesInView = NO;
    
}

- (void)hideKeyboard {
    //resign keyboard.
    [self.tableView endEditing:YES];
}

//reset the cancels touch in view to make sure the tableview selection is
//deactivated when the keyboard is in view and reactivated when it is not.
- (void)cancelsTouchesInView {
    if  (_tapGestureRecognizer.cancelsTouchesInView == YES) {
        _tapGestureRecognizer.cancelsTouchesInView = NO;
    } else {
        _tapGestureRecognizer.cancelsTouchesInView = YES;
    }
}

- (void)setOutletValues {
    //check if a calorie calibration exists, if so add it to the textfield.
    if (_calibrationTDEE) {
        self.calorieCalibrationTextField.text = [NSString stringWithFormat:@"%d", abs(_calibrationTDEE)];
    }
    if (_bmrCustom) {
        self.bmrCustomTextField.text = [NSString stringWithFormat:@"%ld", (long)_bmrCustom];
    }
    if (_bmrBodyWeightMultiplier) {
        self.bmrBodyWeightMultiplierTextField.text = [NSString stringWithFormat:@"%ld", (long)_bmrBodyWeightMultiplier];
    }
    if (_maintenanceBodyWeightMultiplier) {
        self.maintenanceBodyWeightMultiplierTextField.text = [NSString stringWithFormat:@"%ld", (long)_maintenanceBodyWeightMultiplier];
    }
    if (_maintenanceCustom) {
        self.maintenanceCustomTextField.text = [NSString stringWithFormat:@"%ld", (long)_maintenanceCustom];
    }
    if (_calibrationTDEE < 0) {
        self.calorieCalibrationSegmentControl.selectedSegmentIndex = SEGMENT_INDEX_SUBSTRACT;
    } else {
        self.calorieCalibrationSegmentControl.selectedSegmentIndex = SEGMENT_INDEX_ADD;
    }
}
- (IBAction)save:(UIBarButtonItem *)sender {
    //save the changes to user defaults.
    int calibration;
    //check if the segment control is add or substract
    if (_calorieCalibrationSegmentControl.selectedSegmentIndex == SEGMENT_INDEX_SUBSTRACT) {
        calibration = (0 - [_calorieCalibrationTextField.text intValue]);
    } else {
        calibration = [_calorieCalibrationTextField.text intValue];
    }
    //set the calibration number.
    [_userDefaults setInteger:calibration forKey:@"calorieFormulaCalibration"];
    //save the user defaults.
    [_userDefaults synchronize];
    //segue to the main settings section.
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    _tapGestureRecognizer.cancelsTouchesInView = YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    //set make sure the tableviewcell is selected after the editing ends.
    if (textField != _calorieCalibrationTextField) {
        //get the cell belonging to the textfield.
        CGPoint textFieldOrigin = [self.tableView convertPoint:textField.bounds.origin fromView:textField];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:textFieldOrigin];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [self didSelectCaloricEquation:cell];
    }
    
    //set slight delay so the touch the user makes *just* after the keyboard has gone will not be registered (so the tableviewcell
    //pertaining to the textfield that ends editing is selected and not the cell the user taps on to make the keyboard disappear.
        [NSTimer scheduledTimerWithTimeInterval:.03 target:self selector:@selector(cancelsTouchesInView) userInfo:nil repeats:NO];
}

- (void)setSelectedOptions {
    
    //set the accessortype for the selected bmr and maintenance eqaution.
    switch (self.bmrCalculator) {
        case HarrisBenedict:
           //set the selected cell
            self.harrisBenedictEquationCell.accessoryType =
            UITableViewCellAccessoryCheckmark;
            break;
        case MifflinStJeor:
            self.mifflinStJeorEquationCell.accessoryType =
            UITableViewCellAccessoryCheckmark;
            break;
        case Custom:
            self.customBmrCell.accessoryType =
            UITableViewCellAccessoryCheckmark;
            break;
        case BodyWeightMultiplier:
            self.bodyWeightMultiplierBmrCell.accessoryType =
            UITableViewCellAccessoryCheckmark;
            break;
        case KatchMcArdle:
            self.katchMcArdleEquationCell.accessoryType =
            UITableViewCellAccessoryCheckmark;
            break;
            
        default:
            self.mifflinStJeorEquationCell.accessoryType =
            UITableViewCellAccessoryCheckmark;
            break;
    }
        
    switch (self.maintenanceMultiplierType) {
        case CustomTDEE:
            self.customMaintenanceCell.accessoryType =
            UITableViewCellAccessoryCheckmark;
            break;
        case BodyWeightMultiplierTDEE:
            self.bodyWeightMultiplierCell.accessoryType =
            UITableViewCellAccessoryCheckmark;
            break;
        case ActivityMultiplierTDEE:
            self.calculatedMaintenanceCell.accessoryType =
            UITableViewCellAccessoryCheckmark;
        default:
            self.calculatedMaintenanceCell.accessoryType =
            UITableViewCellAccessoryCheckmark;
            break;
    }

}

#pragma mark - textfields
- (IBAction)calorieCalibrationTextField:(UITextField *)sender {
    int calibration = [_calorieCalibrationTextField.text intValue];
    self.calibrationTDEE = calibration;
}
- (IBAction)bmrBodyWeightMultiplierTextField:(UITextField *)sender {
    self.bmrBodyWeightMultiplier = [sender.text floatValue];
    [_userDefaults setInteger:_bmrBodyWeightMultiplier forKey:@"bodyWeightMultiplierBmr"];
}
- (IBAction)bmrCustomTextField:(UITextField *)sender {
    self.bmrCustom = [sender.text floatValue];
    [_userDefaults setInteger:_bmrCustom forKey:@"customBmr"];

}
- (IBAction)maintenanceBodyWeightMultiplierTextField:(UITextField *)sender {
    self.maintenanceBodyWeightMultiplier = [sender.text floatValue];
    [_userDefaults setInteger:_maintenanceBodyWeightMultiplier forKey:@"bodyWeightMultiplierMaintenance"];
}

- (IBAction)maintenanceCustomTextField:(UITextField *)sender {
    self.maintenanceCustom = [sender.text floatValue];
    [_userDefaults setInteger:_maintenanceCustom forKey:@"customMaintenance"];
}

#pragma mark - TableView

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    [self didSelectCaloricEquation:cell];
}

-(void)didSelectCaloricEquation: (UITableViewCell *)cell {
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

    //first uncheck all accessory checkmarks.
    [self uncheckAccesorCheckMarks: indexPath.section];
    
    //if the user selects a bmr option
    if ([[cell reuseIdentifier] isEqualToString:@"HarrisBenedictBmr"]) {
        [_userDefaults setInteger:HarrisBenedict forKey:@"bmrEquation"];
        self.harrisBenedictEquationCell.accessoryType = UITableViewCellAccessoryCheckmark;
        
    }
    if ([[cell reuseIdentifier] isEqualToString:@"MifflinStJeorBmr"]) {
        [_userDefaults setInteger:MifflinStJeor forKey:@"bmrEquation"];
        self.mifflinStJeorEquationCell.accessoryType =UITableViewCellAccessoryCheckmark;
    }
    if ([[cell reuseIdentifier] isEqualToString:@"CustomBmr"]) {
        [_userDefaults setInteger:Custom forKey:@"bmrEquation"];
        self.customBmrCell.accessoryType =
        UITableViewCellAccessoryCheckmark;
    }
    if ([[cell reuseIdentifier] isEqualToString:@"KatchMcCardleBmr"]) {
        [_userDefaults setInteger:KatchMcArdle forKey:@"bmrEquation"];
        self.katchMcArdleEquationCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    if ([[cell reuseIdentifier] isEqualToString:@"BodyWeightMultiplierBmr"]) {
        [_userDefaults setInteger:BodyWeightMultiplier forKey:@"bmrEquation"];
        self.bodyWeightMultiplierBmrCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    //if the user selects a TDEE option.
    if ([[cell reuseIdentifier] isEqualToString:@"BodyWeightMultiplierTDEE"]) {
        [_userDefaults setInteger:BodyWeightMultiplierTDEE forKey:@"maintenanceMultiplierType"];
        self.bodyWeightMultiplierCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    if ([[cell reuseIdentifier] isEqualToString:@"CustomTDEE"]) {
        [_userDefaults setInteger:CustomTDEE forKey:@"maintenanceMultiplierType"];
        self.customMaintenanceCell.accessoryType = UITableViewCellAccessoryCheckmark;
        
    }
    if ([[cell reuseIdentifier] isEqualToString:@"CalculatedTDEE"]) {
        [_userDefaults setInteger:ActivityMultiplierTDEE forKey:@"maintenanceMultiplierType"];
        self.calculatedMaintenanceCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }

}

- (void)loadUserData {
    if ([_userDefaults integerForKey:@"bmrEquation"]) {
        self.bmrCalculator = [_userDefaults integerForKey:@"bmrEquation"];
    }
    if ([_userDefaults integerForKey:@"maintenanceMultiplierType"]) {
        self.maintenanceMultiplierType = [_userDefaults integerForKey:@"maintenanceMultiplierType"];
    }
    if ([_userDefaults integerForKey:@"calorieFormulaCalibration"]) {
        self.calibrationTDEE = (int)[_userDefaults integerForKey:@"calorieFormulaCalibration"];
    }
    if ([_userDefaults integerForKey:@"bodyWeightMultiplierBmr"]) {
        self.bmrBodyWeightMultiplier = [_userDefaults integerForKey:@"bodyWeightMultiplierBmr"];
    }
    if ([_userDefaults integerForKey:@"bodyWeightMultiplierMaintenance"]) {
        self.maintenanceBodyWeightMultiplier = [_userDefaults integerForKey:@"bodyWeightMultiplierMaintenance"];
    }
    if ([_userDefaults integerForKey:@"customBmr"]) {
        self.bmrCustom = [_userDefaults integerForKey:@"customBmr"];
    }
    if ([_userDefaults integerForKey:@"customMaintenance"]) {
        self.maintenanceCustom = [_userDefaults integerForKey:@"customMaintenance"];
    }
}

- (void)uncheckAccesorCheckMarks: (NSInteger)section {
    
    // uncheck all the checkmarks in the section so a new one can be selected.
    if (section == BMR_SECTION) {
        self.harrisBenedictEquationCell.accessoryType  = UITableViewCellAccessoryNone;
        self.mifflinStJeorEquationCell.accessoryType = UITableViewCellAccessoryNone;
        self.katchMcArdleEquationCell.accessoryType = UITableViewCellAccessoryNone;
        self.bodyWeightMultiplierBmrCell.accessoryType = UITableViewCellAccessoryNone;
        self.customBmrCell.accessoryType = UITableViewCellAccessoryNone;

    } else if (section == TDEE_SECTION) {
        self.calculatedMaintenanceCell.accessoryType = UITableViewCellAccessoryNone;
        self.bodyWeightMultiplierCell.accessoryType = UITableViewCellAccessoryNone;
        self.customMaintenanceCell.accessoryType = UITableViewCellAccessoryNone;
    }
}

#pragma mark - form validation
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    //make sure the user can not include multiple points in the decimal he inputs.
    if (textField == self.maintenanceBodyWeightMultiplierTextField || textField == self.bmrBodyWeightMultiplierTextField)
    {
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        
        NSString *expression = @"^([0-9]{1,2}+)?(\\.([0-9]{1,2})?)?$";
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:expression
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
        NSUInteger numberOfMatches = [regex numberOfMatchesInString:newString
                                                            options:0
                                                              range:NSMakeRange(0, [newString length])];
        if (numberOfMatches == 0)
            return NO;
        
        //the text field can only have a length of 2 numbers.
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        if (newLength > 4) {
            return NO;
        }
    }
    
    //the custom textfields can only have a length of 5 numbers.
    if (textField == self.maintenanceCustomTextField || textField == self.bmrCustomTextField) {
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        return (newLength > 5) ? NO : YES;
    }
    
    return YES;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = nil;
    if (section == [tableView numberOfSections] - 2) {

        //footer for under the maintenance (or TDEE) section
        view = [[UIView alloc] initWithFrame:CGRectZero];
        UILabel *maintenanceCaloriesLabel = [[UILabel alloc]init];
        [maintenanceCaloriesLabel setFont: [UIFont systemFontOfSize:13]];
        maintenanceCaloriesLabel.text = [NSString stringWithFormat:@"Current Maintenance: %@",[self currentMaintenance]];
        maintenanceCaloriesLabel.frame = CGRectMake(20, 0,self.view.frame.size.width - 10, 30);
        maintenanceCaloriesLabel.textColor = [UIColor darkGrayColor];
        [view addSubview:maintenanceCaloriesLabel];
        
    }
    if (section == [tableView numberOfSections] - 3) {
        
        //footer for under the bmr section
        view = [[UIView alloc] initWithFrame:CGRectZero];
        UILabel *maintenanceCaloriesLabel = [[UILabel alloc]init];
        [maintenanceCaloriesLabel setFont: [UIFont systemFontOfSize:13]];
        maintenanceCaloriesLabel.text = [NSString stringWithFormat:@"Current BMR: %@",[self currentBmr]];
        maintenanceCaloriesLabel.frame = CGRectMake(20, 0,self.view.frame.size.width - 10, 30);
        maintenanceCaloriesLabel.textColor = [UIColor darkGrayColor];
        [view addSubview:maintenanceCaloriesLabel];
        
    }
    return view;
}

- (NSString *)currentMaintenance {
    //get the current user maintenance from the calorie calculator
    NSDictionary *dict = [self.calculator returnUserMaintenanceAndBmr:nil];
    int maintenance = [[dict valueForKey:@"maintenance"] intValue];
    if (maintenance == 0) {
        return @"-";
    } else {
        return [NSString stringWithFormat:@"%d", maintenance];
    }
}

- (NSString *)currentBmr {
    //get the current user bmr from the calorie calculator
    NSDictionary *dict = [self.calculator returnUserMaintenanceAndBmr:nil];
    int bmr = [[dict valueForKey:@"bmr"] intValue];
    
    if (bmr == 0) {
        return @"-";
    } else {
        return [NSString stringWithFormat:@"%d", bmr];
    }
}

/*
#pragma mark - Navigation
 
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
