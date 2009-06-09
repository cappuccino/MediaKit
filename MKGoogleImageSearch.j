/*
 * MKGoogleImageSearch.j
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

@import <Foundation/CPObject.j>

@import "MKMediaPanel.j"


@implementation MKGoogleImageSearchDelegate : CPObject
{
}

+ (CPString)URL
{
    return "http://ajax.googleapis.com/ajax/services/search/images?v=1.0&rsz=large&q=" + MKMediaPanelQueryReplacementString + "&callback=" + CPJSONPCallbackReplacementString;
}

+ (CPString)identifier
{
    return "GoogleImageSearch";
}

- (CPArray)mediaObjectsForIdentifier:(CPString)anIdentifier data:(Object)data
{
    if (data.responseStatus !== 200)
        return [];

    var results = data.responseData.results,
        count = results.length;

    for (var i = 0; i < count; i++)
    {
        var object = results[i];

        object.title = object.titleNoFormatting;
        object.source = "Google Images";
        object.contentSize = CGSizeMake(object.width, object.height);
        object.thumbnailSize = CGSizeMake(object.tbWidth, object.tbHeight);
        object.thumbnailURL = object.tbUrl;
        object.mediaType = MKMediaTypeImage;
        object.url = object.unescapedUrl;
    }

    return results;
}

- (void)mediaSearchWithIdentifier:(CPString)anIdentifier failedWithError:(CPString)anError
{
    //todo errors
}

@end
