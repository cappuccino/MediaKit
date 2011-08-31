/*
 * Jakefile
 * MediaKit
 *
 * Created by Matevz Mihalic.
 * Copyright (c) 2011 Matevz Mihalic.
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

var OS = require("os"),
    ENV = require("system").env,
    FILE = require("file"),
    JAKE = require("jake"),
    task = JAKE.task,
    CLEAN = require("jake/clean").CLEAN,
    FileList = JAKE.FileList,
    framework = require("cappuccino/jake").framework,
    browserEnvironment = require("objective-j/jake/environment").Browser,
    configuration = ENV["CONFIG"] || ENV["CONFIGURATION"] || ENV["c"] || "Debug";

framework ("MediaKit", function(task)
{   
    task.setBuildIntermediatesPath(FILE.join(ENV["CAPP_BUILD"], "MediaKit.build", configuration));
    task.setBuildPath(FILE.join(ENV["CAPP_BUILD"], configuration));

    task.setProductName("MediaKit");
    task.setIdentifier("com.280n.MediaKit");
    task.setVersion("0.1.0");
    task.setAuthor("280 North, Inc.");
    task.setEmail("feedback @nospam@ 280north.com");
    task.setSummary("Media framework for Cappuccino");
    task.setSources(new FileList("*.j"));
    task.setResources(new FileList("Resources/**/*"));
    //task.setEnvironments([browserEnvironment]);
    //task.setFlattensSources(true);
    task.setInfoPlistPath("Info.plist");

    if (configuration === "Debug")
        task.setCompilerFlags("-DDEBUG -g");
    else
        task.setCompilerFlags("-O");
});

task ("debug", function()
{
    ENV["CONFIGURATION"] = "Debug";
    JAKE.subjake(["."], "build", ENV);
});

task ("release", function()
{
    ENV["CONFIGURATION"] = "Release";
    JAKE.subjake(["."], "build", ENV);
});

task ("default", ["release"]);

task ("build", ["MediaKit"]);

task ("install", ["debug", "release"])
