#import "EventMKAnnotation.h"
#import "LocationController.h"

@implementation EventMKAnnotation
@synthesize name, place, timeDestination;
- (CLLocationCoordinate2D)coordinate;
{
    CLLocationCoordinate2D theCoordinate;
    theCoordinate.latitude = 37.810000;
    theCoordinate.longitude = -112.477989;
    return theCoordinate; 
}

// required if you set the MKPinAnnotationView's "canShowCallout" property to YES
- (NSString *)title
{
    return @"My Gate Bridge";
}

// optional
- (NSString *)subtitle
{
    return @"Opened: Aug 8, 2011";
}

- (void)dealloc
{
    [super dealloc];
}

@end