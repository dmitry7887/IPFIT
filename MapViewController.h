/*
     File: MapViewController.m 
 Abstract: The primary view controller containing the MKMapView, adding and removing both MKPinAnnotationViews through its toolbar. 
  Version: 1.001 
  */

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>

@interface MapViewController : UIViewController <MKMapViewDelegate, MKReverseGeocoderDelegate, EKEventEditViewDelegate>
{
    MKMapView *mapView;
    MKReverseGeocoder *reverseGeocoder;
    MKPointAnnotation *annot;
    NSString *placeDescription;
   	EKEventStore *eventStore;
	EKCalendar *defaultCalendar;
    EKEvent *tempEvent;
	NSMutableArray *eventsList;
    NSMutableArray *pinList;
    BOOL EditEvent;
}
@property (nonatomic, retain) NSString *placeDescription;
@property (nonatomic, retain) IBOutlet MKMapView *mapView;
@property (nonatomic, retain) MKReverseGeocoder *reverseGeocoder;
@property (nonatomic, retain) EKEvent *tempEvent;
@property (nonatomic, retain) EKEventStore *eventStore;
@property (nonatomic, retain) EKCalendar *defaultCalendar;
@property (nonatomic, retain) NSMutableArray *eventsList;
@property (nonatomic, retain) NSMutableArray *pinList;


+ (CGFloat)annotationPadding;
+ (CGFloat)calloutHeight;

- (IBAction)walkAction:(id)sender;
- (IBAction)carAction:(id)sender;
- (IBAction)detailsAction:(id)sender;
- (IBAction)reverseGeocodeCurrentLocation;
- (IBAction)reverseGeocodeByLocation:(CLLocationCoordinate2D) coordinate;
- (NSArray *) fetchEventsForToday;

@end
