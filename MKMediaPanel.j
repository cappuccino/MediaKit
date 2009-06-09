/*
 * MKMediaPanel.j
 * MediaKit
 *
 * Created by Ross Boucher.
 * Copyright 2009, 280 North, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import <AppKit/CPPanel.j>
@import <AppKit/CPPasteboard.j>

@import "MKFlickrSearch.j"
@import "MKGoogleImageSearch.j"
@import "MKGoogleVideoSearch.j"
@import "MKMediaCell.j"


//media types
MKMediaTypeImage    = 1 << 0;
MKMediaTypeVideo    = 1 << 1;
MKMediaTypeAll      = 0xFFFF;

//query URL replacement string
MKMediaPanelQueryReplacementString  = @"${QUERY}";
MKMediaPanelPageReplacementString   = @"${PAGE}";

var SharedMediaPanel = nil;

@implementation MKMediaPanel : CPPanel
{
    CPTextField         searchField;
    CPTextField         searchResultsLabel;
    CPRadioGroup        searchFilterRadioGroup;
    
    CPCollectionView    mediaCollectionView;
    CPView              loadingView;
    CPScrollView        scrollView;              
    
    CPDictionary        connectionsByIdentifier;
    CPDictionary        URLsByIdentifier;
    CPDictionary        resultsByIdentifier;
    CPDictionary        delegatesByIdentifier;   

    id                  target @accessors;
    SEL                 action @accessors;
}

+ (id)sharedMediaPanel
{
    if (!SharedMediaPanel)
        SharedMediaPanel = [[self alloc] init];

    return SharedMediaPanel;
}

- (id)init
{
    if (self = [super initWithContentRect:CGRectMake(100, 100, 300, 400) styleMask:CPTitledWindowMask|CPResizableWindowMask|CPClosableWindowMask])
    {
        [self setTitle:@"Media Browser"];
        [self setMinSize:CPSizeMake(250, 300)];
        
        var contentView = [self contentView];
        
        searchField = [CPTextField roundedTextFieldWithStringValue:@"" placeholder:@"Search for media..." width:224];
        
        [searchField setFrameOrigin:CGPointMake(8, 8)];
        [searchField setAutoresizingMask:CPViewWidthSizable];
        
        [contentView addSubview:searchField];
        
        var searchButton = [CPButton buttonWithTitle:@"Search"];
        
        [searchButton setFrameOrigin:CGPointMake(CGRectGetMaxX([searchField bounds]) + 14, CGRectGetMinY([searchField frame]) + 3)];
        [searchButton setAutoresizingMask:CPViewMinXMargin];

        [searchButton setTarget:self];
        [searchButton setAction:@selector(search:)];
        [searchField setTarget:searchButton];
        [searchField setAction:@selector(performClick:)];
        
        [self setDefaultButton:searchButton];

        [contentView addSubview:searchButton];
        
        var frameView = [[CPView alloc] initWithFrame:CGRectMake(-1, CGRectGetMaxY([searchField bounds]) + 14, CGRectGetWidth([contentView bounds])+2, CGRectGetHeight([contentView bounds]) - 40 - CGRectGetMaxY([searchField bounds]))];
        
        [frameView setBackgroundColor:[CPColor lightGrayColor]];
        [frameView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
        
        [contentView addSubview:frameView];
        
        var filterView = [[CPView alloc] initWithFrame:CGRectMake(1, 1, CGRectGetWidth([frameView bounds]) - 2, 25)];
        
        [filterView setBackgroundColor:[CPColor colorWithRed:213.0/255.0 green:221.0/255.0 blue:230.0/255.0 alpha:1.0]];
        [filterView setAutoresizingMask:CPViewWidthSizable];
        
        [frameView addSubview:filterView];
        
        var filterBorder = [[CPView alloc] initWithFrame:CGRectMake(0, 24, CGRectGetWidth([filterView bounds]), 1)];
        
        [filterBorder setBackgroundColor:[CPColor colorWithRed:180.0/255.0 green:195.0/255.0 blue:205.0/255.0 alpha:1.0]];
        [filterBorder setAutoresizingMask:CPViewWidthSizable];
        
        [filterView addSubview:filterBorder];

        var bundle = [CPBundle bundleForClass:[self class]],
            leftCapImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"MediaFilterLeftCap.png"] size:CGSizeMake(9, 19)],
            rightCapImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"MediaFilterRightCap.png"] size:CGSizeMake(9, 19)],
            centerImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"MediaFilterCenter.png"] size:CGSizeMake(1, 19)],
            bezelImage = [[CPThreePartImage alloc] initWithImageSlices:[leftCapImage, centerImage, rightCapImage] isVertical:NO];
            
        var allRadio = [CPRadio radioWithTitle:@"All"],
            imagesRadio = [CPRadio radioWithTitle:@"Images"],
            videosRadio = [CPRadio radioWithTitle:@"Videos"],
            radioButtons = [allRadio, imagesRadio, videosRadio];

        for (var i=0, count = radioButtons.length; i < count; i++)
        {
            var thisRadio = radioButtons[i];
            
            [thisRadio setAlignment:CPCenterTextAlignment];
            [thisRadio setValue:[CPColor clearColor] forThemeAttribute:@"bezel-color"];
            [thisRadio setValue:[CPColor colorWithPatternImage:bezelImage] forThemeAttribute:@"bezel-color" inState:CPThemeStateSelected];
            [thisRadio setValue:CGInsetMake(0.0, 10.0, 0.0, 10.0) forThemeAttribute:@"content-inset"];
            [thisRadio setValue:CGSizeMake(0.0, 19.0) forThemeAttribute:@"min-size"];
    
            [thisRadio setValue:CGSizeMake(0.0, 1.0) forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateBordered];
            [thisRadio setValue:[CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-color"];
            [thisRadio setValue:[CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:1.0] forThemeAttribute:@"text-shadow-color"];
            [thisRadio setValue:[CPColor colorWithCalibratedWhite:1.0 alpha:1.0] forThemeAttribute:@"text-color" inState:CPThemeStateSelected];
            [thisRadio setValue:[CPColor colorWithCalibratedWhite:79 / 255.0 alpha:1.0] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateSelected];
    
            [thisRadio sizeToFit];

            [thisRadio setTarget:self];

            [filterView addSubview:thisRadio];
        }
        
        searchFilterRadioGroup = [allRadio radioGroup];
        [imagesRadio setRadioGroup:searchFilterRadioGroup];
        [videosRadio setRadioGroup:searchFilterRadioGroup];
        
        [allRadio setTag:MKMediaTypeAll];
        [imagesRadio setTag:MKMediaTypeImage];
        [videosRadio setTag:MKMediaTypeVideo];

        [allRadio setFrameOrigin:CGPointMake(8, 3)];
        [imagesRadio setFrameOrigin:CGPointMake(CGRectGetMaxX([allRadio frame]) + 8, CGRectGetMinY([allRadio frame]))];
        [videosRadio setFrameOrigin:CGPointMake(CGRectGetMaxX([imagesRadio frame]) + 8, CGRectGetMinY([imagesRadio frame]))];
                
        [allRadio performClick:nil];
        
        [allRadio setAction:@selector(showAll:)];
        [imagesRadio setAction:@selector(showImages:)];
        [videosRadio setAction:@selector(showVideos:)];
        
        scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(1, 26, CGRectGetWidth([frameView bounds]) - 2, CGRectGetHeight([frameView bounds]) - 27)];
        
        [scrollView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setAutohidesScrollers:YES];
        [[scrollView contentView] setBackgroundColor:[CPColor whiteColor]];
        
        [frameView addSubview:scrollView];
        
        mediaCollectionView = [[CPCollectionView alloc] initWithFrame:[scrollView bounds]];
        
        [mediaCollectionView setFrameSize:CGSizeMake(CGRectGetWidth([scrollView bounds]), 0)];
        [mediaCollectionView setBackgroundColor:[CPColor whiteColor]];
        [mediaCollectionView setAutoresizingMask:CPViewWidthSizable];
        [mediaCollectionView setDelegate:self];
        
        var mediaCollectionItem = [[CPCollectionViewItem alloc] init];
           
        [mediaCollectionItem setView:[[MKMediaCell alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 74.0)]];
            
        [mediaCollectionView setItemPrototype:mediaCollectionItem];
        [mediaCollectionView setMinItemSize:CGSizeMake(200.0, 74.0)];
        [mediaCollectionView setMaxItemSize:CGSizeMake(400.0, 74.0)];    
        [mediaCollectionView setMaxNumberOfColumns:0];

        [scrollView setDocumentView:mediaCollectionView];
        
        searchResultsLabel = [[CPTextField alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY([frameView frame]) + 4, CGRectGetWidth([contentView bounds]) - 20, 20)];
        
        [searchResultsLabel setAutoresizingMask:CPViewWidthSizable|CPViewMinYMargin];
        [searchResultsLabel setAlignment:CPCenterTextAlignment];
        [searchResultsLabel setLineBreakMode:CPLineBreakByTruncatingTail];
        
        [contentView addSubview:searchResultsLabel];
        
        loadingView = [[CPView alloc] initWithFrame:[scrollView bounds]];
        [loadingView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
        
        var progressIndicator = [CPProgressIndicator new];
        
        [progressIndicator setStyle:CPProgressIndicatorSpinningStyle];
        [progressIndicator sizeToFit];
        
        [progressIndicator setAutoresizingMask:CPViewMinXMargin|CPViewMinYMargin|CPViewMaxXMargin|CPViewMaxYMargin];
        [progressIndicator setCenter:[loadingView center]];
        
        [loadingView addSubview:progressIndicator];
        
        connectionsByIdentifier = [CPDictionary dictionary];
        URLsByIdentifier = [CPDictionary dictionary];
        resultsByIdentifier = [CPDictionary dictionary];
        delegatesByIdentifier = [CPDictionary dictionary];         

        //standard search providers
        [self addSourceWithIdentifier:[MKGoogleImageSearchDelegate identifier] URL:[MKGoogleImageSearchDelegate URL] delegate:[MKGoogleImageSearchDelegate new]];
        [self addSourceWithIdentifier:[MKGoogleVideoSearchDelegate identifier] URL:[MKGoogleVideoSearchDelegate URL] delegate:[MKGoogleVideoSearchDelegate new]];
        [self addSourceWithIdentifier:[MKFlickrSearchDelegate identifier] URL:[MKFlickrSearchDelegate URL] delegate:[MKFlickrSearchDelegate new]];
    }
    
    return self;
}

- (CPArray)collectionView:(CPCollectionView)aCollectionView dragTypesForItemsAtIndexes:(CPIndexSet)anIndexSet
{
    return [aCollectionView content][[anIndexSet firstIndex]].mediaType === MKMediaTypeImage ? CPImagesPboardType : CPVideosPboardType;
}

- (CPData)collectionView:(CPCollectionView)aCollectionView dataForItemsAtIndexes:(CPIndexSet)indexes forType:(CPString)aType
{
    var index = CPNotFound,
        content = [aCollectionView content],
        representedObjects = [];

    while ((index = [indexes indexGreaterThanIndex:index]) != CPNotFound)
    {
        var object = content[index],
            result = nil;

        if (aType === CPImagesPboardType && object.mediaType === MKMediaTypeImage)
            result = [[CPImage alloc] initWithContentsOfFile:object.url size:object.contentSize];

        else if (aType === CPVideosPboardType && object.mediaType === MKMediaTypeVideo)
            result = [[CPFlashMovie alloc] initWithFile:object.url];

        if (result)
            representedObjects.push(result);
    }

    return [CPKeyedArchiver archivedDataWithRootObject:representedObjects];
}

- (CPImage)collectionView:(CPCollectionView)aCollectionView dragImageForItemWithIndex:(unsigned)anIndex
{
    var object = [aCollectionView content][anIndex];

    return [[CPImage alloc] initWithContentsOfFile:object.thumbnailURL size:object.thumbnailSize];
}

- (void)collectionView:(CPCollectionView)aCollectionView didDoubleClickOnItemAtIndex:(unsgined)anIndex
{
    [CPApp sendAction:action to:target from:self];
}

- (CPImage)selectedImage
{
    var selectionIndex = [[mediaCollectionView selectionIndexes] firstIndex],
        selection = selectionIndex !== nil ? [mediaCollectionView content][selectionIndex] : nil;

    if (selection && selection.mediaType === MKMediaTypeImage)
        return [[CPImage alloc] initWithContentsOfFile:selection.url size:selection.contentSize];

    return nil;
}

- (CPFlashMovie)selectedVideo
{
    var selectionIndex = [[mediaCollectionView selectionIndexes] firstIndex],
        selection = selectionIndex !== nil ? [mediaCollectionView content][selectionIndex] : nil;

    if (selection && selection.mediaType === MKMediaTypeVideo)
        return [[CPFlashMovie alloc] initWithFile:selection.url];

    return nil;
}

- (CPArray)resultsWithMask:(unsigned)aMask
{
    var allIDs = [resultsByIdentifier allKeys],
        count = [allIDs count],
        results = [];

    for (var i=0; i<count; i++)
    {
        var allObjects = [resultsByIdentifier objectForKey:allIDs[i]],
            allObjectsCount = [allObjects count];

        for (var j=0; j<allObjectsCount; j++)
        {
            if (allObjects[j].mediaType & aMask)
                results.push(allObjects[j]);
        }
    }

    return results;
}

- (void)showAll:(id)sender
{
    var allResults = [self resultsWithMask:MKMediaTypeAll];
    
    [mediaCollectionView setContent:allResults];
    [self setResultCount:[allResults count]];
}

- (void)showImages:(id)sender
{
    var imageResults = [self resultsWithMask:MKMediaTypeImage];
    
    [mediaCollectionView setContent:imageResults];
    [self setResultCount:[imageResults count]];
}

- (void)showVideos:(id)sender
{
    var videoResults = [self resultsWithMask:MKMediaTypeVideo];
    
    [mediaCollectionView setContent:videoResults];
    [self setResultCount:[videoResults count]];
}

- (void)setResultCount:(unsigned)count
{
    [searchResultsLabel setStringValue: count == 1 ? "1 Result" : count+" Results"];
}

- (void)setSearchTerm:(CPString)aQuery
{
    [searchField setStringValue:aQuery];
}

- (void)search:(id)sender
{
    if (![[searchField stringValue] length])
        return;

    //load a searching view
    [searchResultsLabel setStringValue:@""];
       
    //reset the collection view's content
    [mediaCollectionView setContent:[]];

    var query = encodeURIComponent([searchField stringValue]),
        identifiers = [URLsByIdentifier allKeys];

    for (var i=0, count = [identifiers count]; i<count; i++)
    {
        var identifier = identifiers[i],
            url = [URLsByIdentifier objectForKey:identifier];

        url = [url stringByReplacingOccurrencesOfString:MKMediaPanelQueryReplacementString withString:query];

        var connection = [[CPJSONPConnection alloc] initWithRequest:[CPURLRequest requestWithURL:url]
                                                           callback:nil
                                                           delegate:self
                                                   startImmediately:NO];

        connection.identifier = identifier;
        
        [[connectionsByIdentifier objectForKey:identifier] cancel];
        [connectionsByIdentifier setObject:connection forKey:identifier];
        [connection start];
    }
    
    [loadingView setFrame:[scrollView bounds]];
    
    [scrollView setDocumentView:loadingView];
    [searchResultsLabel setStringValue:@"Searching..."];
}

- (void)addSourceWithIdentifier:(CPString)anIdentifier 
                            URL:(CPString)aURL 
                       delegate:(id)aDelegate
{
    [self removeSourceWithIdentifier:anIdentifier];
    [delegatesByIdentifier setObject:aDelegate forKey:anIdentifier];
    [URLsByIdentifier setObject:aURL forKey:anIdentifier];
}

- (void)removeSourceWithIdentifier:(CPString)anIdentifier
{
    [[connectionsByIdentifier objectForKey:anIdentifier] cancel];
    [connectionsByIdentifier removeObjectForKey:anIdentifier];
    [delegatesByIdentifier removeObjectForKey:anIdentifier];
    [resultsByIdentifier removeObjectForKey:anIdentifier];
    [URLsByIdentifier removeObjectForKey:anIdentifier];
}

- (void)connection:(CPJSONPConnection)aConnection didReceiveData:(Object)data
{
    var identifier = aConnection.identifier,
        delegate = [delegatesByIdentifier objectForKey:identifier],
        results = [delegate mediaObjectsForIdentifier:identifier data:data],
        resultCount = [results count],
        updatedResultSet = [[mediaCollectionView content] copy];

    [resultsByIdentifier setObject:results forKey:identifier];

    for (var i = 0; i < resultCount; i++)
        if (results[i].mediaType & [[searchFilterRadioGroup selectedRadio] tag])
            updatedResultSet.push(results[i]);

    [self setResultCount:[updatedResultSet count]];
    [mediaCollectionView setContent:updatedResultSet];    
    [connectionsByIdentifier removeObjectForKey:identifier];
    
    if ([scrollView documentView] === loadingView)
        [scrollView setDocumentView:mediaCollectionView];
}

- (void)connection:(CPJSONPConnection)aConnection didFailWithError:(CPString)anError
{
    var identifier = aConnection.identifier,
        delegate = [delegatesByIdentifier objectForKey:identifier];
        
    [delegate mediaSearchWithIdentifier:identifier failedWithError:anError];

    [resultsByIdentifier setObject:[] forKey:identifier];
    [connectionsByIdentifier removeObjectForKey:identifier];
}

@end
