//
//  CCScrollListView.m
//  CocosBuilder
//
//  Created by Mikhail Perekhodtsev on 8/6/13.
//
//

#import "CCBPScrollListView.h"
#import "NodeGraphPropertySetter.h"
#import "CCBGlobals.h"
#import "AppDelegate.h"
#import "ResourceManager.h"
#import "CCBDocument.h"
#import "CCBReaderInternal.h"
#import "CCNode+NodeInfo.h"
#import "SequencerSequence.h"

@interface ItemStruct : NSObject
    @property (nonatomic, retain) CCNode *item;
    @property (nonatomic, retain) NSMutableDictionary *variables;
    @property (nonatomic, retain) NSMutableArray *selectors;
@end

@implementation ItemStruct
    @synthesize item;
    @synthesize variables;
    @synthesize selectors;
@end

@interface IndexItem : NSObject
    @property (nonatomic, retain) NSString *item;
    @property (nonatomic, retain) NSString *selector;
@end

@implementation IndexItem
    @synthesize item;
    @synthesize selector;
@end

@implementation CCBPScrollListView

@synthesize _template;
@synthesize horizontal=_horizontal;
@synthesize _count;
@synthesize textAlignment=_textAlignment;
@synthesize verticalTextAlignment=_verticalTextAlignment;

-(id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _items = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void) setExtraProp:(id)prop forKey:(NSString *)key
{
    [super setExtraProp:prop forKey:key];
    if([key isEqualToString:@"ccbFile"])
    {
        _template = prop;
    }
}


-(void)RecalcPositions
{
    if (self.contentNode.children.count == 0) {
        return;
    }
    
    int num = 0;
    NSInteger count = self.contentNode.children.count;
    
    CCNode *node = [self.contentNode.children objectAtIndex:0];
    if (!node) {
        return;
    }
    
    CGSize contentsize = node.contentSize;
    CGSize viewsize = self.contentSize;
    //CGSize viewsize = viewSize_;

    float yoffset = 0;
    switch (_verticalTextAlignment) {
        case CCVerticalTextAlignmentTop:
        {
            yoffset = 0;
            break;
        }
        case CCVerticalTextAlignmentBottom:
        {
            if (_horizontal) {
                yoffset = viewsize.height - contentsize.height;
            }
            else {
                yoffset = contentsize.height*count/2;
            }
            break;
        }
        case CCVerticalTextAlignmentCenter:
        {
            if (_horizontal) {
                yoffset = viewsize.height/2 - contentsize.height/2;
            }
            else {
                yoffset = viewsize.height/2 - contentsize.height*count/2;
            }
            break;
        }
        default:
            break;
    }
    
    if (_horizontal) {
        float containerSize = 0;
        for (CCNode *pChild in self.contentNode.children) {
            pChild.position = ccp(pChild.contentSize.width * num, 0);
            containerSize += pChild.contentSize.width;
            ++num;
        }
        
        float xoffset = 0;
        switch (_textAlignment) {
            case CCTextAlignmentCenter:
            {
                xoffset = viewsize.width/2 - containerSize/2;
                break;
            }
            case CCTextAlignmentLeft:
            {
                xoffset = 0;
                break;
            }
            case CCTextAlignmentRight:
            {
                xoffset = viewsize.width - contentsize.width;
                break;
            }
            default:
                break;
        }
        
        [self setScrollPosition:ccp(xoffset, (viewsize.height - contentsize.height - yoffset)) animated:NO];
        //[self setContentOffset:ccp(xoffset, (viewsize.height - contentsize.height - yoffset)) animated:NO];
        [self.contentNode setContentSize:CGSizeMake(MAX(contentsize.width * count, viewsize.width),
                                        MAX(contentsize.height, viewsize.height))];

        self.horizontalScrollEnabled = YES;
        self.verticalScrollEnabled = NO;
        //[self setDirection:CCScrollViewDirectionHorizontal];
    }
    else {
        for (CCNode *pChild in self.contentNode.children) {
            pChild.position = ccp(0, pChild.contentSize.height*(count - num - 1));
            ++num;
        }
        
        float xoffset = 0;
        switch (_textAlignment) {
            case CCTextAlignmentCenter:
            {
                xoffset = viewsize.width/2 - contentsize.width/2;
                break;
            }
            case CCTextAlignmentLeft:
            {
                xoffset = 0;
                break;
            }
            case CCTextAlignmentRight:
            {
                xoffset = viewsize.width - contentsize.width;
                break;
            }
            default:
                break;
        }
        [self setScrollPosition:ccp(xoffset, viewsize.height - contentsize.height*count - yoffset) animated:NO];
        //[self setContentOffset:ccp(xoffset, viewsize.height - contentsize.height*count - yoffset) animated:NO];
        [self.contentNode setContentSize:CGSizeMake(MAX(contentsize.width, viewsize.width),
                                        MAX(contentsize.height, viewsize.height))];
        self.horizontalScrollEnabled = NO;
        self.verticalScrollEnabled = YES;
        //[self setDirection:CCScrollViewDirectionVertical];
    }
}

-(void)draw
{
    [self RecalcPositions];
    [super draw];
}

-(CCNode *)AddElement:(NSString *)name
{
    if ([_items objectForKey:name]) {
        return nil;
    }
    
    CCNode *node = [self nodeFromTemplate];
    if (!node) {
        return nil;
    }
    
    ItemStruct *item = [[ItemStruct alloc] init];
    item.item = node;
    [self.contentNode addChild:node];
    
    return node;
}

-(void)set_count:(NSInteger)count
{
    _count = count;
    [self.contentNode removeAllChildren];
    [_items removeAllObjects];
    for (int i = 0; i < count; i++) {
        [self AddElement:[NSString stringWithFormat:@"name%d", i]];
    }
    
    [self RecalcPositions];
}

-(void)set_template:(NSString *)template
{
    _template = template;
    [self RecalcPositions];
}

-(void)setHorizontal:(BOOL)horizontal
{
    _horizontal = horizontal;
    [self RecalcPositions];
}

-(void)setTextAlignment:(CCTextAlignment)textAlignment
{
    _textAlignment = textAlignment;
    [self RecalcPositions];
}

-(void)setVerticalTextAlignment:(CCVerticalTextAlignment)verticalTextAlignment
{
    _verticalTextAlignment = verticalTextAlignment;
    [self RecalcPositions];
}

-(void)setContentSize:(CGSize)contentSize
{
    [super setContentSize:contentSize];
    [self RecalcPositions];
}

-(CCNode *)nodeFromTemplate
{
    NSString *ccbFileName = _template;
    CCNode* ccbFile = NULL;
    NSMutableArray* sequences = [NSMutableArray array];
    int startSequence = -1;
    CGSize parentSize = self.contentSize;
    
    if (ccbFileName && ![ccbFileName isEqualToString:@""])
    {
        AppDelegate* ad = [AppDelegate appDelegate];
        CCBDocument *ccb_document = ad.currentDocument;
        NSString *filePath = [ccb_document.fileName stringByDeletingLastPathComponent];
        NSString *ccbFileNameAbs = [filePath stringByAppendingPathComponent:ccbFileName];
        
        // Check that it's not the current document (or we get an inifnite loop)
        if (![ad.currentDocument.fileName isEqualToString:ccbFileNameAbs])
        {
            // Load document dictionary
            NSMutableDictionary* doc = [NSMutableDictionary dictionaryWithContentsOfFile:ccbFileNameAbs];
            
            // Verify doc type and version
            if ([[doc objectForKey:@"fileType"] isEqualToString:@"CocosBuilder"]
                && [[doc objectForKey:@"fileVersion"] intValue] <= kCCBFileFormatVersion)
            {
                // Parse the node graph
                ccbFile = [CCBReaderInternal nodeGraphFromDictionary:[doc objectForKey:@"nodeGraph"] parentSize:parentSize];
            }
            
            // Get first timeline
            NSArray* sequenceDicts = [doc objectForKey:@"sequences"];
            for (NSDictionary* seqDict in sequenceDicts)
            {
                SequencerSequence* seq = [[SequencerSequence alloc] initWithSerialization:seqDict];
                [sequences addObject:seq];
                
                if (seq.autoPlay) startSequence = seq.sequenceId;
            }
        }
    }

    return ccbFile;
}

@end
