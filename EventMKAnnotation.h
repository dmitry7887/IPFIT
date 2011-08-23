//
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface EventMKAnnotation : MKPointAnnotation <MKAnnotation>
{
    NSString *name;
    NSString *place;
    NSDate   *timeDestionation;
    BOOL     *Repeat; 
}
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *place;
@property (nonatomic, retain) NSDate *timeDestination;

- (CLLocationCoordinate2D)coordinate;
@end