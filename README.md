# VSTS DNX Tasks

This extension allows you to make builds with the new ASP.NET 5 tools easier.  
This extension includes the following tasks:

- DNX Tasks Build Web Package
- DNX Tasks Publish Web Package
- DNX Tasks Build Nuget Package
- DNX Tasks Azure SlotSwap

## DNX Tasks Build Web

With this task you can build a website project and create an output folder with all necessary content for a deployment to Azue.
You have to specify a project in your solution by setting the "**Project Name**" property. The name is in fact the folder name of the project. Make sure to wrap the name in double quotes if there are any spaces in this name.  
Multiple projects can be build by separate them with a space. If you leave this field blank all projects in the **Working folder**/src/ folder are build.

The "**Build Configuration**" property can be empty or any single word you want to have there.

All the results of the build process will put in the folder specified in "**Output Folder**".

Under the "**Advanced**" group you can decide if you want the source code to be included in the build output with the "**Publish Source**" switch.
Also the "**Working folder**" can be specified here. This should be the folder where your .sln file is.

The Task will look in **Working folder**/src/**Project Name** for a project.json and starts building this project.

> All your npm, grunt, bower and so on tasks should be before this task to make sure all the generated content is included in the output.

## DNX Tasks Publish Web Package

implemented, docu comming soon...

## DNX Tasks Build Nuget Package

implemented, docu comming soon...

## DNX Tasks Azure SlotSwap

If you use deployment slots in your Azure Website and want to switch the slots after deployment you can use this task.

In "**Azure Classic Subscription**" select the subscription your Website is assigned to.  
The Name of the Azure Website have to be in "**Web App Name**".  
Specify the slots you want to swap in the "**From**" and "**To**" fields.