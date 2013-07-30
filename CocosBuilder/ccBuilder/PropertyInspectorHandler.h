//
//  PropertyInspectorHandler.h
//  CocosBuilder
//
//  Created by Viktor on 7/29/13.
//
//

#import <Cocoa/Cocoa.h>

@class PropertyInspectorTemplateLibrary;

@interface PropertyInspectorHandler : NSObject <NSCollectionViewDelegate>
{
    IBOutlet PropertyInspectorTemplateLibrary* templateLibrary;
    IBOutlet NSCollectionView* collectionView;
    
    IBOutlet NSTextField* newTemplateName;
    IBOutlet NSColorWell* newTemplateBgColor;
}
- (void) updateTemplates;

- (IBAction) addTemplate:(id) sender;
- (IBAction) toggleShowDefaultTemplates:(id)sender;

@end
