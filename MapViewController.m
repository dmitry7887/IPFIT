/*
     File: MapViewController.m 
 Abstract: The primary view controller containing the MKMapView, adding and removing both MKPinAnnotationViews through its toolbar. 
  Version: 1.2 
  
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple 
 Inc. ("Apple") in consideration of your agreement to the following 
 terms, and your use, installation, modification or redistribution of 
 this Apple software constitutes acceptance of these terms.  If you do 
 not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software. 
  
 In consideration of your agreement to abide by the following terms, and 
 subject to these terms, Apple grants you a personal, non-exclusive 
 license, under Apple's copyrights in this original Apple software (the 
 "Apple Software"), to use, reproduce, modify and redistribute the Apple 
 Software, with or without modifications, in source and/or binary forms; 
 provided that if you redistribute the Apple Software in its entirety and 
 without modifications, you must retain this notice and the following 
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. may 
 be used to endorse or promote products derived from the Apple Software 
 without specific prior written permission from Apple.  Except as 
 expressly stated in this notice, no other rights or licenses, express or 
 implied, are granted by Apple herein, including but not limited to any 
 patent rights that may be infringed by your derivative works or by other 
 works in which the Apple Software may be incorporated. 
  
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE 
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION 
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS 
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND 
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS. 
  
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL 
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, 
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED 
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), 
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE 
 POSSIBILITY OF SUCH DAMAGE. 
  
 Copyright (C) 2010 Apple Inc. All Rights Reserved. 
  
*/

#import "MapViewController.h"
#import "DetailViewController.h"
#import "SFAnnotation.h"
#import "BridgeAnnotation.h"
#import "EventMKAnnotation.h"
#import <EventKit/EventKit.h>
enum
{
    kCityAnnotationIndex = 0,
    kBridgeAnnotationIndex,
    kMyAnnotationIndex,
    
};

@implementation MapViewController

@synthesize mapView, detailViewController,eventViewController, mapAnnotations, reverseGeocoder,pinList, eventsList, eventStore, defaultCalendar, placeDescription, tempEvent;


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
}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFindPlacemark:(MKPlacemark *)placemark
{
    //PlacemarkViewController *placemarkViewController =
    //[[PlacemarkViewController alloc] initWithNibName:@"PlacemarkViewController" bundle:nil];
    //placemarkViewController.placemark = placemark;
   
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
    
    //[self presentModalViewController:placemarkViewController animated:YES];
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
    self.mapAnnotations = nil;
    self.detailViewController = nil;
    self.eventViewController = nil;

    self.mapView = nil;
}

- (void)dealloc 
{
    [mapView release];
    [detailViewController release];
    [eventViewController release];
    [mapAnnotations release];
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
   
    [self.navigationController pushViewController:self.detailViewController animated:YES];   

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
        
    
    // handle our two custom annotations
    //
    if ([annotation isKindOfClass:[BridgeAnnotation class]]) // for Golden Gate Bridge
    {
        // try to dequeue an existing pin view first
        static NSString* BridgeAnnotationIdentifier = @"bridgeAnnotationIdentifier";
        MKPinAnnotationView* pinView = (MKPinAnnotationView *)
                                        [mapView dequeueReusableAnnotationViewWithIdentifier:BridgeAnnotationIdentifier];
        if (!pinView)
        {
            // if an existing pin view was not available, create one
            MKPinAnnotationView* customPinView = [[[MKPinAnnotationView alloc]
                                             initWithAnnotation:annotation reuseIdentifier:BridgeAnnotationIdentifier] autorelease];
            customPinView.pinColor = MKPinAnnotationColorPurple;
            customPinView.animatesDrop = YES;
            customPinView.canShowCallout = YES;
            
            // add a detail disclosure button to the callout which will open a new view controller page
            //
            // note: you can assign a specific call out accessory view, or as MKMapViewDelegate you can implement:
            //  - (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control;
            //
            UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
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
    else if ([annotation isKindOfClass:[SFAnnotation class]])   // for City of San Francisco
    {
        static NSString* SFAnnotationIdentifier = @"SFAnnotationIdentifier";
        MKPinAnnotationView* pinView =
            (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:SFAnnotationIdentifier];
        if (!pinView)
        {
            MKAnnotationView *annotationView = [[[MKAnnotationView alloc] initWithAnnotation:annotation
                                                                             reuseIdentifier:SFAnnotationIdentifier] autorelease];
            annotationView.canShowCallout = YES;
        
            UIImage *flagImage = [UIImage imageNamed:@"flag.png"];
            
            CGRect resizeRect;
            
            resizeRect.size = flagImage.size;
            CGSize maxSize = CGRectInset(self.view.bounds,
                                         [MapViewController annotationPadding],
                                         [MapViewController annotationPadding]).size;
            maxSize.height -= self.navigationController.navigationBar.frame.size.height + [MapViewController calloutHeight];
            if (resizeRect.size.width > maxSize.width)
                resizeRect.size = CGSizeMake(maxSize.width, resizeRect.size.height / resizeRect.size.width * maxSize.width);
            if (resizeRect.size.height > maxSize.height)
                resizeRect.size = CGSizeMake(resizeRect.size.width / resizeRect.size.height * maxSize.height, maxSize.height);
            
            resizeRect.origin = (CGPoint){0.0f, 0.0f};
            UIGraphicsBeginImageContext(resizeRect.size);
            [flagImage drawInRect:resizeRect];
            UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            annotationView.image = resizedImage;
            annotationView.opaque = NO;
             
            UIImageView *sfIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SFIcon.png"]];
            annotationView.leftCalloutAccessoryView = sfIconView;
            [sfIconView release];
            
            return annotationView;
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
