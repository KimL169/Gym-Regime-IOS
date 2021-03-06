//
//  GoalProgressViewController.m
//  GymRegime
//
//  Created by Kim on 21/06/14.
//  Copyright (c) 2014 Kim. All rights reserved.
//

#import "GoalProgressViewController.h"
#import "DietGoal+Helper.h"
#import "DietGoal.h"
#import "GoalProgressTableViewCell.h"
#import "GoalSettingViewController.h"
#import "CoreDataHelper.h"
#import "AppDelegate.h"

@interface GoalProgressViewController ()
@property (weak, nonatomic) IBOutlet UILabel *primaryGoalLabel;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) CoreDataHelper *dataHelper;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

#define ROW_HEIGHT 90

@end

@implementation GoalProgressViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
    self.dataHelper = [[CoreDataHelper alloc] init];
    
    //get the current dietplan.
    NSSortDescriptor *sortDescr = [NSSortDescriptor sortDescriptorWithKey:@"endDate" ascending:NO];
    NSArray *fetchedObjects = [_dataHelper performFetchWithEntityName:@"DietPlan" predicate:nil sortDescriptor:sortDescr];
    if (fetchedObjects.count > 0) {
        _currentDietPlan = [fetchedObjects firstObject];
    }
    
    //fetch the diet goals
    NSError *error = nil;
    if (![[self fetchedResultsController] performFetch:&error]) {
        NSLog(@"Error fetching: %@", error);
        abort();
    }
    
    //set the right main goal
    [self setMainGoalLabel];
}

- (void)setMainGoalLabel {
    //set teh main goal label to the correct main goal.
    if ([self.fetchedResultsController.fetchedObjects count] > 0) {
        for (DietGoal *goal in self.fetchedResultsController.fetchedObjects) {
            
            if ([goal.mainGoal boolValue]) {
                _primaryGoalLabel.text = [NSString stringWithFormat:@"%@", goal.name];
            }
        }
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    //return the number of sections in both the bodystat and diet plan fetchedresultscontroller.
    return [[self.fetchedResultsController sections]count];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections]objectAtIndex:section];
    
    return [sectionInfo numberOfObjects];
}


#pragma mark - TableView Delegate.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"GoalCell";
    
    GoalProgressTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle]loadNibNamed:@"GoalProgressTableViewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        // More initializations if needed.
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(GoalProgressTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    DietGoal *goal = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    
    //get the starting, current value and goalvalue for a goal and set the labels.
    NSArray *valueArray = [DietGoal getStartingValueAndCurrentValueForGoal:goal dietPlan:_currentDietPlan];
    if (valueArray) {
        cell.startingValueLabel.text = [NSString stringWithFormat:@"%.1f", [[valueArray objectAtIndex:0] floatValue]];
        cell.currentValueLabel.text = [NSString stringWithFormat:@"%.1f", [[valueArray objectAtIndex:1] floatValue]];
    } else {
        cell.startingValueLabel.text = @"-";
        cell.currentValueLabel.text = @"-";
    }
    cell.nameLabel.text = goal.name;
    cell.goalValueLabel.text = [NSString stringWithFormat:@"Goal: %.1f %@", [goal.value floatValue], [goal unit]];
    
    //get the percentage of goal completed:
    float progress = [DietGoal checkGoalProgress:goal dietPlan:_currentDietPlan];
    cell.percentageLabel.text = [NSString stringWithFormat:@"%.1f%%", progress];
    cell.progressView.progress = (progress /100);
    
    if ([goal.mainGoal boolValue] == YES) {
        cell.sideView.backgroundColor = [UIColor greenColor];
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return ROW_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    GoalProgressTableViewCell *cell = (GoalProgressTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath];
    
    //get the dietGoal pertaining to the cell, set the mainGoal to 1 else, set mainGoal to 0;
    NSArray *fetchedObjects = _fetchedResultsController.fetchedObjects;
    for (DietGoal *goal in fetchedObjects) {

        if ([goal.name isEqualToString:cell.nameLabel.text]) {
            [goal setMainGoal:[NSNumber numberWithBool:YES]];
            _primaryGoalLabel.text = [NSString stringWithFormat:@"%@", goal.name];
        } else {
            [goal setMainGoal:[NSNumber numberWithBool:NO]];
        }
    }
    
    //save the managedObjectContext.
    [super save];

}


#pragma mark - FetchedResultsController.
- (NSManagedObjectContext *)managedObjectContext {
    return  [(AppDelegate *)[[UIApplication sharedApplication]delegate]managedObjectContext];
    
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc]init];
    
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DietGoal" inManagedObjectContext:context];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"dietPlan == %@", _currentDietPlan];
    
    //set the fetch request.
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    //sort on patients last name, ascending;
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]initWithKey:@"name" ascending:YES];
    
    //make an array of the descriptor because the fetchrequest argument takes an array.
    NSArray *sortDescriptors = [[NSArray alloc]initWithObjects:sortDescriptor, nil];
    
    //now assign the sort descriptors to the fetchrequest.
    fetchRequest.sortDescriptors = sortDescriptors;
    
    _fetchedResultsController = [[NSFetchedResultsController alloc]initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:@"name" cacheName:nil];
    
    _fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
}


//if changes to a section occured.
- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

//if changes to an object occured.
- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    
    // responses for type (insert, delete, update, move).
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{

    if ([[segue identifier] isEqualToString:@"editGoals"]) {
        //pass the dietplan to the goalsettings controller.
        UINavigationController *navController = segue.destinationViewController;
        GoalSettingViewController *goalvc = (GoalSettingViewController *)navController.topViewController;
        goalvc.dietPlan = _currentDietPlan;
        
    }
}


@end
