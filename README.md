# VSTS DNX Tasks

This extention allows you to make builds with the new ASP.NET 5 tools easier.  
This extention includes the following tasks:

- DNX Tasks Build Web Package
- DNX Tasks Publish Web Package
- DNX Tasks Azure SlotSwap

## DNX Tasks Build Web Package

With this script you can build a website project and create an output folder with all nesseccary content for a deploymant to Azue.
You have to specify a single project in your solution by setting the "**Project Name**" property.
The "**Build Configuration**" property can be empty or any single word you want to have there.
All the results of the build process will put in the folder specified in "**Output Folder**".

Under the "**Advanced**" group you can decide if you want the source code to be included in the build output with the "**Publish Source**" switch.
Also the "**Working folder**" can be specified here. This should be the folder where your .sln file is.

The Task will look in **Working folder**/src/**Project Name** for a project.json and starts building this project.

A note beside: all your npm, grunt, bower and so on tasks should be before this task to make sure all the generated content is included in the output.

## DNX Tasks Publish Web Package

todo...

## DNX Tasks Azure SlotSwap

todo...
