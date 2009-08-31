/*
 * MKFlickrSearch.j
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


@implementation MKFlickrSearchDelegate : CPObject
{
}

+ (CPString)URL
{
    return "http://www.flickr.com/services/rest/?" +
           "method=flickr.photos.search&tags=" + MKMediaPanelQueryReplacementString+
           "&media=photos&machine_tag_mode=any&per_page=8&extras=o_dims&format=json"+
           "&api_key=ca4dd89d3dfaeaf075144c3fdec76756&jsoncallback=" + CPJSONPCallbackReplacementString;
}

+ (CPString)identifier
{
    return "FlickrSearch";
}

+ (CPString)description
{
    return "Flickr";
}

- (CPArray)mediaObjectsForIdentifier:(CPString)anIdentifier data:(Object)data
{
    if (data.stat !== "ok")
        return [];

    var results = data.photos.photo,
        count = results.length;

    for (var i = 0; i < count; i++)
    {
        var object = results[i];

        object.title = object.title;
        object.source = [[self class] description];
        object.contentSize = CGSizeMake(object.o_width ? object.o_width : "unknown", object.o_height ? object.o_height : "unknown");
        object.thumbnailSize = CGSizeMake(75, 75);
        object.thumbnailURL = thumbForFlickrPhoto(object);
        object.url = urlForFlickrPhoto(object);
        object.mediaType = MKMediaTypeImage;
    }

    return results;
}

- (void)mediaSearchWithIdentifier:(CPString)anIdentifier failedWithError:(CPString)anError
{

}

@end

var urlForFlickrPhoto = function urlForFlickrPhoto(photo)
{
    return "http://farm"+photo.farm+".static.flickr.com/"+photo.server+"/"+photo.id+"_"+photo.secret+".jpg";
}

var thumbForFlickrPhoto = function thumbForFlickrPhoto(photo)
{
    return "http://farm"+photo.farm+".static.flickr.com/"+photo.server+"/"+photo.id+"_"+photo.secret+"_s.jpg";
}

