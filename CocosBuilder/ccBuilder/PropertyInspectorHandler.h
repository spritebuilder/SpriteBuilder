//
//  PropertyInspectorHandler.h
//  CocosBuilder
//
//  Created by Viktor on 7/29/13.
//
//

#import <Cocoa/Cocoa.h>

@interface PropertyInspectorHandler : NSObject
{
    IBOutlet NSCollectionView* collectionView;
}
- (void) updateTemplates;

- (IBAction) addTemplate:(id) sender;
- (IBAction) toggleShowDefaultTemplates:(id)sender;

@end
