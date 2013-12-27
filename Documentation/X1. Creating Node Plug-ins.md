# SpriteBuilder - Create Node Plug-in

Node plug-ins can be used to add custom types of objects that can be used in and exported from SpriteBuilder. The objects need to be a direct or indirect sub-class of CCNode.


## Setting up the project

The easiest way to setup your Xcode project for a new plug-in is to duplicate the example project in the _PlugIn Nodes_ folder.

Now, open the project and slowly click twice on the project name in the file view to rename it. Name it after the class you want to create a plug-in for.

You will be asked to rename some project content items. Leave everything checked and click _Rename_. You now have a new project for your plug-in.

To compile and test the plug-in, first make sure that you have built a copy of SpriteBuilder and that it is located in the _build_ directory. Then click the _Run_ button in the plug-in project. This will compile the plug-in and copy it into SpriteBuilder's PlugIns folder (inside the app bundle). For testing and debugging, double click the SpriteBuilder program in the build directory. You can see the output of the program using Console.app. Set the filter to SpriteBuilder to avoid output from other applications.


## Basic plug-in structure

To make a working node plug-in, you will need to add your class to the plug-in project and edit the _CCBPProperties.plist_ file. When loading your custom class, SpriteBuilder/CCBReader will create it using the _alloc_ and default _init_ methods, then assign all the object's properties. Therefore, it is required that your class can be initialized using the _init_ method only (without using a custom init-method).

The classes you add to a plug-in are linked in runtime against the Cocos2d library; only the header files are included in the project. If your node-object uses more than one class, those classes shouldn't be included in other plug-ins or there may be conflicts when loading the plug-ins.

For many types of nodes you can just drop their classes into the plug-in, setup their editable properties in the _CCBPProperties.plist_ file, and you are good to go. Sometimes it may be necessary to use a different class for displaying a node in the editor than when loading it into an app. Most often, it is easiest to use a sub-class of your node and override some of it's behavior. For example, you can disable animations or user actions in the sub-class. If you use this approach, you should name your sub-class with the CCBP prefix (e.g. CCBPMyCocosNode if your class is CCMyCocosNode).


## Adding a plug-in built into SpriteBuilder

Note that only plug-ins that are very general should be included in SpriteBuilder by default. These are, for instance, core cocos2d classes and the GUI components bundled with SpriteBuilder.

In order to create a built in plug-in, you need to perform the following steps:

1. Create a new _Bundle_ target for the plug-in, and name it after the plug-ins main class.
2. In the plug-in target's build settings, set "Wrapper Extension" to "ccbPlugNode" and set "Other Linker Flags" to "-undefined dynamic_lookup".
3. Select the SpriteBuilder target and go to _Build Phases_. Add your new plug-in target to the _Target Dependencies_ by dragging and dropping from the _Targets_ on the left side.
4. Also in the _Build Phases_, add your plug-in it to the _Copy PlugIns_ phase.
5. When adding classes and resource to the plug-in, be carful to only add them to the plug-in target.


## CCBPProperties.plist format

Most of the plug-in magic happens in the _CCBPProperties.plist_ file. It defines all properties of your class that can be edited in SpriteBuilder and other information about the plug-in. The file is structured as follows.


### Required keys

<table>
    <tr>
        <th>Key</th><th>Type</th><th>Comment</th>
    </tr>
    <tr>
        <td>className</td><td>String</td><td>The name of the main class when loaded into an app (e.g., CCMyCocosNode).</td>
    </tr>
    <tr>
        <td>editorClassName</td><td>String</td><td>The name of the class used by the editor (often the same as className), e.g., CCBPMyCocosNode.</td>
    </tr>
    <tr>
        <td>inheritsFrom</td><td>String</td><td>The name of the class's super class. This is used to display the inspector panels of the super class (e.g., CCSprite).</td>
    </tr>
    <tr>
        <td>canHaveChildren</td><td>Boolean</td><td>Yes, if it should be possible to add children to this node in SpriteBuilder.</td>
    </tr>
    <tr>
        <td>properties</td><td>Array</td><td>List of PlugInProperty as described below.</td>
    </tr>
</table>


### Optional keys

<table>
    <tr>
        <th>Key</th><th>Type</th><th>Comment</th>
    </tr>
    <tr>
        <td>propertiesOverridden</td><td>Array</td><td>The format is the same as for the properties-key, but it replaces a property of a super class.</td>
    </tr>
    <tr>
        <td>spriteFrameDrop</td><td>Dictionary</td><td>Specifies what class of object will be created when a sprite frame is dropped on the node. E.g. CCMenuItemImage for a CCMenu, see SpriteFrameDrop described below for details</td>
    </tr>
    <tr>
        <td>requireChildClass</td><td>Array</td><td>Array of String:s that defines which classes are allowed as children for this node (e.g., CCMenu only allows CCMenuItemImage as children).</td>
    </tr>
    <tr>
        <td>requireParentClass</td><td>String</td><td>Specifies if this node can only be added as a child to a specific type of node (e.g., CCMenuItemImage can only be added to CCMenu).</td>
    </tr>
</table>


## PlugInProperty

A PlugInProperty defines how a property should be displayed in SpriteBuilder and how it should be loaded into an app by CCBReader. It is a dictionary with the keys listed below. Which property _type_:s are supported and how they are serialized (for the _default_ value) is defined in the _Property Types_ document.

### Required keys

<table>
    <tr>
        <th>Key</th><th>Type</th><th>Comment</th>
    </tr>
    <tr>
        <td>type</td><td>String</td><td>The property type (e.g., Point or Float)</td>
    </tr>
    <tr>
        <td>displayName</td><td>String</td><td>What label should be associated with the type (e.g., Content Size)</td>
    </tr>
    <tr>
        <td>name</td><td>String</td><td>The name of the property to set on the node (not required for type Separator, SeparatorSub or StartStop)</td>
    </tr>
</table>

### Optional keys

<table>
    <tr>
        <th>Key</th><th>Type</th><th>Comment</th>
    </tr>
    <tr>
        <td>default</td><td>n/a</td><td>Default value; serialized as described in the Property Types document</td>
    </tr>
    <tr>
        <td>readOnly</td><td>Boolean</td><td>Set to YES if this property should be read only (e.g., YES for contentSize in CCSprite).</td>
    </tr>
    <tr>
        <td>dontSetInEditor</td><td>Boolean</td><td>If set to YES this property will not be set or read from the node by the editor. Instead, the value will be saved in a separate variable. Requires the default value to be specified</td>
    </tr>
    <tr>
        <td>platform</td><td>String</td><td>Set this key if the property should only be used on a specific platform. Valid values are Mac or iOS.</td>
    </tr>
    <tr>
        <td>affectsProperties</td><td>Array</td><td>Array of String:s that defines which other properties should be updated when this value changes (e.g., when changing the texture of a sprite, it affects its contentSize).</td>
    </tr>
    <tr>
        <td>extra</td><td>String</td><td>Different uses for different type:s. See the Property Types document for details.</td>
    </tr>
</table>


## SpriteFrameDrop

The SpriteFrameDrop structure is used to specify the behavior when a sprite frame is dropped onto a scene from the assets palette.

### Required keys

<table>
    <tr>
        <th>Key</th><th>Type</th><th>Comment</th>
    </tr>
    <tr>
        <td>className</td><td>String</td><td>The name of the class to create (e.g., CCSprite)</td>
    </tr>
    <tr>
        <td>property</td><td>String</td><td>The name of the property to assign the dropped sprite frame to (e.g., displayFrame for CCSprite)</td>
    </tr>
</table>