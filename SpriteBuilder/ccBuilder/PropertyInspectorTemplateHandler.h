//
//  PropertyInspectorTemplateHandler.h
//  CocosBuilder
//
//  Created by Viktor on 7/29/13.
//
//

#import <Cocoa/Cocoa.h>

@class PropertyInspectorTemplateLibrary;
@class PropertyInspectorTemplate;

@interface PropertyInspectorTemplateHandler : NSObject <NSCollectionViewDelegate>
{
    IBOutlet PropertyInspectorTemplateLibrary* templateLibrary;
    IBOutlet NSCollectionView* collectionView;
    
    IBOutlet NSTextField* newTemplateName;
    IBOutlet NSColorWell* newTemplateBgColor;
}
- (void) updateTemplates;

- (IBAction) addTemplate:(id) sender;
- (void) removeTemplate:(PropertyInspectorTemplate*) templ;
- (void) applyTemplate:(PropertyInspectorTemplate*) templ;

- (void) installDefaultTemplatesReplace:(BOOL)replace;
- (void) loadTemplateLibrary;

@end
