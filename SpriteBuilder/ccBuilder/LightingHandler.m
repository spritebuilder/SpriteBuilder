//
//  LightingHandler.m
//  SpriteBuilder
//
//  Created by Thayer J Andrews on 12/12/14.
//
//

#import "LightingHandler.h"
#import "CocosScene.h"
#import "SceneGraph.h"
#import "CCNode+NodeInfo.h"
#import "NotificationNames.h"


enum {
    kCCBStageLightDiffuse,
    kCCBStageLightSpecular,
    kCCBStageLightAmbient,
};


@implementation LightingHandler

#pragma mark - API

-(BOOL)showLights
{
    BOOL allLightsHidden = YES;
    for (CCNode *lightIcon in [SceneGraph instance].lightIcons.children)
    {
        if (!lightIcon.hidden)
        {
            allLightsHidden = NO;
        }
    }
    return !allLightsHidden;
}

-(void)setShowLights:(BOOL)showLights
{
    for (CCNode *lightIcon in [SceneGraph instance].lightIcons.children)
    {
        lightIcon.hidden = !showLights;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ALL_LIGHTS_VISIBILITY_CHANGED object:nil];
}

- (void)refreshAll
{
    [self refreshStageLightAndMenu];
    [self lightVisibilityWillChange:nil];
    [self lightVisibilityDidChange:nil];
}

- (void)refreshStageLightAndMenu
{
    [self refreshStageLight];
    [self refreshMenu];
}


#pragma mark - LightVisibilityDelegate

- (void)lightVisibilityWillChange:(CCLightNode *)lightNode
{
    [self willChangeValueForKey:@"showLights"];
}

- (void)lightVisibilityDidChange:(CCLightNode *)lightNode
{
    [self didChangeValueForKey:@"showLights"];
}


#pragma mark - Internal

- (IBAction)stageLightMenuSelected:(id)sender
{
    CocosScene* cs = [CocosScene cocosScene];
    
    int tag = [sender tag];
    switch (tag)
    {
        case kCCBStageLightDiffuse:
            cs.stageLight.intensity = (cs.stageLight.intensity == 0.0f) ? 1.0f : 0.0f;
            break;
        case kCCBStageLightSpecular:
            cs.stageLight.specularIntensity = (cs.stageLight.specularIntensity == 0.0f) ? 1.0f : 0.0f;
            break;
        case kCCBStageLightAmbient:
            cs.stageLight.ambientIntensity = (cs.stageLight.ambientIntensity == 0.0f) ? 0.5f : 0.0f;
            break;
    }
    [self refreshMenu];
    [self refreshStageLight];
}

- (void)refreshStageLight
{
    CocosScene* cs = [CocosScene cocosScene];
    CCNode *lightIconsRoot = cs.lightIconsLayer.children[0];
    cs.stageLight.visible = (lightIconsRoot.children.count == 0);
}

- (void)refreshMenu
{
    CocosScene* cs = [CocosScene cocosScene];
    CCNode *lightIconsRoot = cs.lightIconsLayer.children[0];
    self.stageLightMenu.enabled = (lightIconsRoot.children.count == 0);
    
    NSMenuItem *diffuse = self.stageLightMenu.submenu.itemArray[kCCBStageLightDiffuse];
    diffuse.state = (cs.stageLight.intensity > 0.0f) ? NSOnState : NSOffState;
    
    NSMenuItem *specular = self.stageLightMenu.submenu.itemArray[kCCBStageLightSpecular];
    specular.state = (cs.stageLight.specularIntensity > 0.0f) ? NSOnState : NSOffState;
    
    NSMenuItem *ambient = self.stageLightMenu.submenu.itemArray[kCCBStageLightAmbient];
    ambient.state = (cs.stageLight.ambientIntensity > 0.0f) ? NSOnState : NSOffState;
}

@end
