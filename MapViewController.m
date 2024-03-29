/*
     File: MapViewController.m 
 Abstract: The primary view controller containing the MKMapView, adding and removing both MKPinAnnotationViews through its toolbar. 
  Version: 1.001 
  */

#import "MapViewController.h"


@implementation MapViewController

@synthesize mapView, reverseGeocoder,pinList, eventsList, eventStore, defaultCalendar, placeDescription, tempEvent;


#pragma mark -

+ (CGFloat)annotationPadding;
{
    return 10.0f;
}
+ (CGFloat)calloutHeight;
{
    return 40.0f;
}

- (IBAction)reverseGeocodeByLocation:(CLLocationCoordinate2D) coordinate
{
    self.reverseGeocoder =
    [[[MKReverseGeocoder alloc] initWithCoordinate:coordinate] autorelease];
    reverseGeocoder.delegate = self;
    [reverseGeocoder start];
}

- (IBAction)reverseGeocodeCurrentLocation
{
    self.reverseGeocoder =
    [[[MKReverseGeocoder alloc] initWithCoordinate:[annot coordinate]] autorelease];
    reverseGeocoder.delegate = self;
    [reverseGeocoder start];
    
}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFailWithError:(NSError *)error
{
    NSString *errorMessage = [error localizedDescription];
    NSLog(@"Cannot obtain address. %@s",errorMessage);
    EKEventEditViewController *addController = [[EKEventEditViewController alloc] initWithNibName:nil bundle:nil];
    
    
    // set the addController's event store to the current event store.
    addController.eventStore = eventStore;
    addController.event=tempEvent;
    
    // present EventsAddViewController as a modal view controller
    [self presentModalViewController:addController animated:YES];
    
    addController.editViewDelegate = self;
    
    [addController release];

}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFindPlacemark:(MKPlacemark *)placemark
{
  
    placeDescription=[placemark title];
    annot.subtitle=placeDescription; 
    
    tempEvent.notes=placeDescription;
    EKEventEditViewController *addController = [[EKEventEditViewController alloc] initWithNibName:nil bundle:nil];
    
    
    // set the addController's event store to the current event store.
    addController.eventStore = eventStore;
    addController.event=tempEvent;
    
    // present EventsAddViewController as a modal view controller
    [self presentModalViewController:addController animated:YES];
    
    addController.editViewDelegate = self;
    
    [addController release];
    
}

- (void)gotoLocation
{
    // start off by default in San Francisco
    MKCoordinateRegion newRegion;
    newRegion.center.latitude = 37.786996;
    newRegion.center.longitude = -122.440100;
    newRegion.span.latitudeDelta = 0.112872;
    newRegion.span.longitudeDelta = 0.109863;

    [self.mapView setRegion:newRegion animated:YES];
}

// Listen to change in the userLocation
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context 
{       
    MKCoordinateRegion region;
    region.center = self.mapView.userLocation.coordinate;  
    
    MKCoordinateSpan span; 
    span.latitudeDelta  = 0.05; // Change these values to change the zoom
    span.longitudeDelta = 0.05; 
    region.span = span;
    [self.mapView.userLocation removeObserver:self forKeyPath:@"location"];
 
    [self.mapView setRegion:region animated:YES];
    
}


- (void)viewDidAppear:(BOOL)animated
{
    // bring back the toolbar
    [self.navigationController setToolbarHidden:NO animated:NO];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan)
        return;
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];   
    CLLocationCoordinate2D touchMapCoordinate = 
    [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    
    
    annot = [[MKPointAnnotation alloc] init];
    annot.coordinate = touchMapCoordinate;
    annot.title=@"Do";
    
    [self reverseGeocodeByLocation:touchMapCoordinate]; 
     
    tempEvent  = [[EKEvent eventWithEventStore:eventStore] retain];
    tempEvent.location=[[NSString stringWithFormat:@"lat=%f",touchMapCoordinate.latitude] stringByAppendingString:[NSString stringWithFormat:@" lon=%f",touchMapCoordinate.longitude]];
     
    tempEvent.startDate = [NSDate date];
    tempEvent.endDate   = [NSDate dateWithTimeInterval:600 sinceDate:tempEvent.startDate];
}

- (void)viewDidLoad
{
    mapView.mapType = MKMapTypeStandard;   // also MKMapTypeSatellite or MKMapTypeHybrid
    EditEvent=NO;
    // create a custom navigation bar button and set it to always says "Back"
	UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
	temporaryBarButtonItem.title = @"Back";
	self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
	[temporaryBarButtonItem release];
    
    
    [self gotoLocation];    // finally goto San Francisco
    [self.mapView.userLocation addObserver:self forKeyPath:@"location" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:nil];
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] 
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 1.0; //user needs to press for 1 seconds
    [mapView addGestureRecognizer:lpgr];
    [lpgr release];
    mapView.showsUserLocation = YES;
    pinList=[[NSMutableArray alloc] initWithCapacity:10];
    
  
    
    
    // Initialize an event store object with the init method. Initilize the array for events.
	eventStore = [[EKEventStore alloc] init];
    
	eventsList = [[NSMutableArray alloc] initWithArray:0];

	// Get the default calendar from store.
	defaultCalendar = [[self.eventStore defaultCalendarForNewEvents] retain];

	// Fetch today's event on selected calendar and put them into the eventsList array
	[eventsList addObjectsFromArray:[self fetchEventsForToday]];
    
        
    EKEvent *event;
    CLLocationCoordinate2D location; 
    for (event in eventsList){
        NSString *locate=event.location;
        if (locate){
 
            NSRange textRangeLat;
            textRangeLat =[locate rangeOfString:@"lat"];
            
            NSRange textRangeLon;
            textRangeLon =[locate rangeOfString:@" lon"];
            
            if(textRangeLat.location != NSNotFound)
            { 
                textRangeLat.location=textRangeLat.location+4;
                textRangeLat.length=textRangeLon.location-textRangeLat.location;
                textRangeLon.location=textRangeLon.location+5;
                textRangeLon.length=locate.length-textRangeLon.location;
                
                NSString *lon=[locate substringWithRange:textRangeLon];
                NSString *lat=[locate substringWithRange:textRangeLat];
                annot = [[MKPointAnnotation alloc] init];
                location.latitude=[lat doubleValue];
                location.longitude=[lon doubleValue];
                
                annot.coordinate=location;
                annot.title=event.title;
                annot.subtitle=event.notes;
                [pinList addObject:annot];
                
                [mapView addAnnotation:annot];
                
                //Does contain the substring
            }
        }
    }
    
}


- (void)viewDidUnload
{
      self.mapView = nil;
}

- (void)dealloc 
{
    [mapView release];
    for (annot in pinList){
        [annot release];
    }
    [pinList release];
    for (tempEvent in eventsList){
        [tempEvent release];
    }
    
    [eventsList release];
    [eventStore release];
    [super dealloc];
}


#pragma mark -
#pragma mark ButtonActions

- (IBAction)walkAction:(id)sender
{
//    [self gotoLocation];//•• avoid this by checking its region from ours??
//    
//    [self.mapView removeAnnotations:self.mapView.annotations];  // remove any annotations that exist
//    
//    [self.mapView addAnnotation:[self.mapAnnotations objectAtIndex:kCityAnnotationIndex]];
}

- (IBAction)carAction:(id)sender
{
//    [self gotoLocation];
//    [self.mapView removeAnnotations:self.mapView.annotations];  // remove any annotations that exist
//    
//    [self.mapView addAnnotation:[self.mapAnnotations objectAtIndex:kBridgeAnnotationIndex]];
}

- (IBAction)detailsAction:(id)sender
{

}

#pragma mark -
#pragma mark MKMapViewDelegate

- (void)showDetails:(id)sender
{
	UIButton* button = sender;

	NSInteger index = button.tag;
    // the detail view does not want a toolbar so hide it
    [self.navigationController setToolbarHidden:YES animated:NO];
    
//    // Upon selecting an event, create an EKEventViewController to display the event.
//	eventViewController = [[[EKEventViewController alloc] initWithNibName:nil bundle:nil] retain];			
	if ([eventsList count]>index){
        EKEventEditViewController *addController = [[EKEventEditViewController alloc] initWithNibName:nil bundle:nil];
        
        EditEvent=YES; 
        // set the addController's event store to the current event store.
        addController.eventStore = eventStore;
        tempEvent=[self.eventsList objectAtIndex:index];
        
        addController.event=tempEvent;
        // present EventsAddViewController as a modal view controller
        [self presentModalViewController:addController animated:YES];
        
        addController.editViewDelegate = self;
        
        [addController release];
      
//        eventViewController.event = [self.eventsList objectAtIndex:index];
//       
//        // Allow event editing.
//        eventViewController.allowsEditing = YES;
//        
//        //	Push detailViewController onto the navigation controller stack
//        //	If the underlying event gets deleted, detailViewController will remove itself from
//        //	the stack and clear its event property.
//        [self.navigationController pushViewController:eventViewController animated:YES];   
    
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // if it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
  
    // if it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKPointAnnotation class]]){
        // try to dequeue an existing pin view first
        static NSString* PinAnnotationIdentifier = @"MKPinAnnotationIdentifier";
        MKPinAnnotationView* pinView = (MKPinAnnotationView *)
        [mapView dequeueReusableAnnotationViewWithIdentifier:PinAnnotationIdentifier];
        annot=annotation;
        if (!pinView)
        {
            // if an existing pin view was not available, create one
            MKPinAnnotationView* customPinView = [[[MKPinAnnotationView alloc]
                                                   initWithAnnotation:annotation reuseIdentifier:PinAnnotationIdentifier] autorelease];
            customPinView.pinColor = MKPinAnnotationColorPurple;
            customPinView.animatesDrop = YES;
            customPinView.canShowCallout = YES;
            
            // add a detail disclosure button to the callout which will open a new view controller page
            //
            // note: you can assign a specific call out accessory view, or as MKMapViewDelegate you can implement:
            //  - (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control;
            //
            UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
			[rightButton setTag:[pinList indexOfObjectIdenticalTo:annotation]];
            [rightButton addTarget:self
                            action:@selector(showDetails:)
                  forControlEvents:UIControlEventTouchUpInside];
            customPinView.rightCalloutAccessoryView = rightButton;
            return customPinView;
        }
        else
        {
            pinView.annotation = annotation;
        }
        return pinView;
    }
    return nil;
}
#pragma mark -
#pragma mark EKEventEditViewDelegate

// Overriding EKEventEditViewDelegate method to update event store according to user actions.
- (void)eventEditViewController:(EKEventEditViewController *)controller 
          didCompleteWithAction:(EKEventEditViewAction)action {
	
	NSError *error = nil;
	EKEvent *thisEvent = controller.event;
	
	switch (action) {
		case EKEventEditViewActionCanceled:
			break;
			
		case EKEventEditViewActionSaved:
			// When user hit "Done" button, save the newly created event to the event store, 
			// and reload table view.
			// If the new event is being added to the default calendar, then update its 
			// eventsList.
			if (self.defaultCalendar ==  thisEvent.calendar) {
				
                if (!EditEvent){ 
                    [eventsList addObject:thisEvent];
                    annot.title=thisEvent.title;
                    annot.subtitle=thisEvent.notes;
                    thisEvent.location=[[NSString stringWithFormat:@"lat=%f",annot.coordinate.latitude] stringByAppendingString:[NSString stringWithFormat:@" lon=%f",annot.coordinate.longitude]];
                    [pinList addObject:annot];
                    [mapView addAnnotation:annot];

                }
                else{
                    NSUInteger index=[eventsList indexOfObjectIdenticalTo:tempEvent];
                    annot=[pinList objectAtIndex:index];
                    [mapView removeAnnotation:annot];
                    [pinList addObject:annot];
                    [mapView addAnnotation:annot];
                    annot.title=thisEvent.title;
                    annot.subtitle=thisEvent.notes;

                    thisEvent.location=[[NSString stringWithFormat:@"lat=%f",annot.coordinate.latitude] stringByAppendingString:[NSString stringWithFormat:@" lon=%f",annot.coordinate.longitude]];
                    [eventsList addObject:thisEvent];  
                    
                }

			}
			[controller.eventStore saveEvent:controller.event span:EKSpanThisEvent error:&error];
			//[self.tableView reloadData];

			break;
			
		case EKEventEditViewActionDeleted:
			// When deleting an event, remove the event from the event store, 
			// and reload table view.
			// If deleting an event from the currenly default calendar, then update its 
			// eventsList.
			if (defaultCalendar ==  thisEvent.calendar && tempEvent!=nil) {
                NSUInteger index=[eventsList indexOfObjectIdenticalTo:tempEvent];
                annot=[pinList objectAtIndex:index];
                
                [mapView removeAnnotation:annot];	
                
                tempEvent=nil;
                
                
			}
			[controller.eventStore removeEvent:thisEvent span:EKSpanThisEvent error:&error];
			//[self.tableView reloadData];
			break;
			
		default:
			break;
	}
	// Dismiss the modal view controller
	[controller dismissModalViewControllerAnimated:YES];
    EditEvent=NO; 	
}


// Set the calendar edited by EKEventEditViewController to our chosen calendar - the default calendar.
- (EKCalendar *)eventEditViewControllerDefaultCalendarForNewEvents:(EKEventEditViewController *)controller {
	EKCalendar *calendarForEdit = self.defaultCalendar;
	return calendarForEdit;
}

// Fetching events happening in the next 24 hours with a predicate, limiting to the default calendar 
- (NSArray *)fetchEventsForToday {
	
	NSDate *startDate = [NSDate date];
	
	// endDate is 1 day = 60*60*24 seconds = 86400 seconds from startDate
	NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:86400];
	
	// Create the predicate. Pass it the default calendar.
	NSArray *calendarArray = [NSArray arrayWithObject:defaultCalendar];
	NSPredicate *predicate = [self.eventStore predicateForEventsWithStartDate:startDate endDate:endDate 
                                                                    calendars:calendarArray]; 
	
	// Fetch all events that match the predicate.
	NSArray *events = [self.eventStore eventsMatchingPredicate:predicate];
    
	NSMutableArray *eventsWithGeo=[[[NSMutableArray alloc] initWithCapacity:10] autorelease];

    
    EKEvent *event;
    for (event in events){
        NSString *locate=event.location;
        if (locate && event.title){
            
            NSRange textRangeLat;
            textRangeLat =[locate rangeOfString:@"lat"];
            
            NSRange textRangeLon;
            textRangeLon =[locate rangeOfString:@" lon"];
            
            if(textRangeLat.location != NSNotFound && textRangeLon.location != NSNotFound)
            { 
              [eventsWithGeo addObject:event];
            }
        }
    }
    return eventsWithGeo;
}



@end
