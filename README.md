FTSCoreDataModel
--------

FTSCoreDataModel solves two problems:

1. It consolidates and hides all the boilerplate associated with setting up
   a Core Data stack.
1. It gives you a method, `contextForCurrentThread` that will return an
   NSManagedObjectContext for whatever thread the method is called on.

## Usage

To use FTSCoreDataModel, simply add `FTSCoreDataModel.h` and `FTSCoreDataModel.m` to your project and call the designated initializer for `FTSCoreDataModel` in your app delegate.  An example might look like:

```objc
@interface MyAppDelegate ()
@property (nonatomic, strong) FTSCoreDataModel *dataModel;
@end

@implementation MyAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.dataModel = [FTSCoreDataModel initializeWithModelName:@"mySweetApp"];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self.dataModel saveContext];
}

@end
```

In the above example, you'd still need to manually create a data model
in Xcode and name it "mySweetApp".

## ARC
FTSCoreDataModel assumes you're using ARC.

## Credits

The `contextForCurrentThread` idea and much of the implementation was stolen
from [Magical Record](https://github.com/magicalpanda/MagicalRecord).

## License

MIT. See the LICENSE file for more info.
