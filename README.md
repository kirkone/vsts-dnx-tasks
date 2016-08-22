# VSTS DNX Tasks

This extension allows you to make builds with the new ASP.NET Core tools easier.  
This extension includes the following tasks:

- DNX Tasks Build Web Package
- DNX Tasks Publish Web Package
- DNX Tasks Build Nuget Package
- DNX Tasks Azure SlotSwap
- DNX Tasks Clear NuGet Cache
- DNX Tasks Generate Change Log

### DNX Tasks Build Web

With this task you can build a website project and create an output folder with all necessary content for a deployment to Azue.
You have to specify a project in your solution by setting the "**Project Name**" property. The name is in fact the folder name of the project. Make sure to wrap the name in double quotes if there are any spaces in this name.  
Multiple projects can be build by separate them with a space. If you leave this field blank all projects in the "**Working folder**/src/" folder are build.

The "**Build Configuration**" property can be empty or any single word you want to have there.

All the results of the build process will put in the folder specified in "**Output Folder**".

Under the "**Advanced**" group you can decide if you want the source code to be included in the build output with the "**Publish Source**" switch.
Also the "**Working Folder**" can be specified here. Usual this should be the folder where your .sln file is.  
The field "**Source Folder**" is used to specify a subfolder where your projects are located. The default value is "src" like in a standard asp.net core project. If your project folders are direct in your "**Working Folder**" leave this field blank.  

The Task will look in "**Working folder**/**Source Folder**/**Project Name**" for a project.json and starts building this project.  

This task will fail when no project can be found in the specified location.  

If there is no need to install the "**dotnet cli**" please check the "**Skip DotNet CLI Install**" checkbox.  

> All your npm, grunt, bower and so on tasks should be before this task to make sure all the generated content is included in the output.

### DNX Tasks Publish Web Package

You can publish your website build with the "**Build Web Package**" task to an Azure Web App. To do so you have to select the azure subscription your App is on in the "**Azure Classic Subscription**" field and type in the "**Web App Name**". If you select a "**Web App Location**" the field "**Web App Name**" has prefilled options.

In the "**Deployment Slot**" field specify the target Slot for the deployment. Leave this blank if you do not want to use a deployment slot.

"**Source Folder**" should point at the folder where the build output ist written to.

> Note: the Build Task will put the output in subfolders with the project name, so you have to point at these. For example you build "*Sample.Web*" so your "**Source Folder**" should look like this: "**$(Build.StagingDirectory)\Publish\Sample.Web**".  

Within the "**Advanced**" section you have the field for "**Destination**". This is the folder where the application will be in the Azure environment. Default value is "site/wwwroot". You can change this for example to deploy a WebJob to your already deployed website.  
The other options listed under "**Advanced**" are used to control the behavior of the Web App before and after the deployment.

> If only "**Stop Before Deployment**" is checked you have to start your App manually later on.

### DNX Tasks Build Nuget Package

This task is used to create Nuget packages for one or multiple projects. For the fields "**Project Name**", "**Build Configuration**", "**Output Folder**" and "**Working Folder**" please have a look at the "**Build Web**" task.

Within the "**Advanced**" section there is a checkbox for "**Pre Release**". If this is true, the nuget package will build as prerelease with "**VERSIONNUMBER-pre-BUILDNUMBER**" in name.  

If there is no need to install the "**dotnet cli**" please check the "**Skip DotNet CLI Install**" checkbox.  

> The "**BUILDNUMBER**" part is taken from the "*Build number format*" under the "*Global*" tab in your build definition settings. This task takes the last number from this string.  
> I recommend to set the "*Build number format*" to somthing like this:  
> "**$(BuildDefinitionName)_$(BuildConfiguration)_$(Year:yy)$(DayOfYear)$(Rev:rr)**"


### DNX Tasks Azure SlotSwap

If you use deployment slots in your Azure Website and want to switch the slots after deployment you can use this task.

In "**Azure Classic Subscription**" select the subscription your Website is assigned to.  
"**Web App Location**" is optional and is only used to have options for "**Web App Name**" prefilled.
The Name of the Azure Website have to be in "**Web App Name**".  
Specify the slots you want to swap in the "**From**" and "**To**" fields.

### DNX Tasks Clear NuGet Cache

For some reasons it can be necessary to clean up the NuGet cache folder.  
This task will try to detect the location of the folder by it self.  
The Folder can be overwritten by using the "**NuGet Cache Path**" field.  

> #### Caution: 
> Use this only when you exactly know what you are doing!  
> This will clear the package cache and if there are any other build processes running at the same time at the same mashine **very bad things** will happen!

### DNX Tasks Generate Change Log

To get a Change Log file with all commits for the actual build use this task.  
The "**Output File**" field specifies the name and the location where the file will be written.  
To get a Markdown file check the "**Create MarkDown File**" field.  
When "**Links to Commits**" is checked the Markdown file includes links to every commit mentioned in the change log.  
To get the new content appended to an existing file check "**Append To .md File**".  
Use "**Create JSON File**" to get the information about the commits as a .json file. The .json file will use the same value from the "**Output File**" field apart from the file ending .json

> This task only writes a file. You have to take care of it by your self. For example add it to your build output.

### Questions, Recommendations, Issues?

Please have a look here: [GitHub Issues](https://github.com/kirkone/vsts-dnx-tasks/issues)  

### Release Notes

#### Version 0.1.7

- Added Task to generate a Change Log file.

#### Version 0.1.6

- Added Task to clear the Nuget package cache on the Build Server.

#### Version 0.1.5

- Fixed error with empty paths for the "**Source Folder**" parrameters  
- Added logic to detect absolute paths to prevent leading ".\" for absolute paths  

#### Version 0.1.4

- Added option to skip installation of the dotnet cli in the BuildNuGetPackage and BuildWebPackage task

#### Version 0.1.1

- migrated from RC1 dnvm/dnu to RC2 and dotnet cli

