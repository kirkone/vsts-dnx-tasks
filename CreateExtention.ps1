Copy-Item VSTS.DNX.Tasks.Shared\InstallDNVM.psm1 VSTS.DNX.Tasks.BuildWebPackage -force
Copy-Item VSTS.DNX.Tasks.Shared\InstallDNVM.psm1 VSTS.DNX.Tasks.BuildNugetPackage -force

. tfx extension create --manifest-globs vss-extension.json