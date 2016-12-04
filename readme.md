qp -- a package manager for q
===============================

## Overview
`qp` aims to make managing and using packages as easy as possible while being as minimally intrusive to base q as possible. A lot of the principles are derived from npm, pip and R's package managers.
To test if everything is working right, run ```bash cliTests.sh``` from the project folder

qp comes with three components:
* `qp`  - add-in to base `q` for easy package importing (adds import function to `q`)
* `qpm` - package installer
* `qpr` - tool to create/add to a local repo

## Dependencies
Currently this is for mac and unix only. q needs to be in the `PATH` (i.e. you can successfully start q from the command line).

## Installation
* `make install` - installs `qpm` and `qp`
* `make install_qp` - installs `qp` only
* `make install_qpm` - installs `qpm` only
* `make install_qpr` - installs `qpr` only

All installs also have an uninstall equivalent.

## qp
After installation, when you start q, you now have access to the `import` command.  This allows you to do the following:
```
import `examplelib
import `examplelib to `.
```
In the first case, qp will check for a valid qp-style package, and if it exists load all variables (functions, data, etc.) into .examplelib namespace. If the package also has imports, those will also be loaded.
In the second case, it will do the same as above but load all (functions, data, etc.) into the global namespace.

## qpm
`qpm` installs two files: `qpm.q` to `$QHOME`, and `qpm` executable to the same directoy as the `q` executable. After installing `qpm`, you can install new packages from a repo using the syntax:
To install a package from a repo:
```bash
qpm install PACKAGENAME -loc file://PATH/TO/REPO
q qpm.q install PACKAGENAME -loc file://PATH/TO/REPO
```
qpm will recursively install package dependencies as defined by the `qr.json` package metadata.
NOTE: To avoid having to use -loc everywhere, you can set QREPO=file://PATH/TO/REPO and qp will use that as its repo location

TO uninstall a package
```bash
qpm uninstall PACKAGENAME
q qpm.q uninstall PACKAGENAME
```

## qpr
`qpr` installs two files: `qpr.q` to `$QHOME`, and `qpr` executable the same directoy as the `q` executable.  After installing `qpr`, you can set up or add packages to a local repo.
To set up a new local repo, run:
```bash
qpr create /PATH/TO/REPO
q qpr.q create /PATH/TO/REPO
```

To add to an existing local repo, run:
```bash
qpr add /PATH/TO/PACKAGE -loc /PATH/TO/REPO
q qpr.q add /PATH/TO/PACKAGE -loc /PATH/TO/REPO
```
NOTE: To avoid having to use -loc everywhere, you can set QREPO=file://PATH/TO/REPO and qp will use that as its repo location

## Structure of a qp package

### Metadata
The metadata of a package is defined in `qr.json`.  As the minimum, `qr.json` needs to contain the fields:
* `version` - string with version number in standard format, i.e "MAJOR.MINOR.PATH" (e.g. 2.1.0)
* `name` - name of the package. Upon installation this will be what the package name will be (i.e. current fold name that the package is in isn't used)
In addition, the optional fields can be set:
* `dependencies` - a dict where keys are package names, and values are any version requirements. Version requirements can look like:
	* `""` - any version will work
	* `"1.0.0"` - can only use version `1.0.0`
	* `"1.0.0+"` - can use any version above or equal to `1.0.0`
	* `"1.0.0-"` - can use any version below or equal to `1.0.0`
* `osversion` - a list of compatible os versions for the package. If this is omitted all OSes is assumed.
* `qversion` - a string that represents what versions this package is compatible for. If this is omitted, all versions are assumed.  Q version requirements can look like:
	* `"3.0"` - can only use verion `3.0`
	* `"3.0+"` - can take any version above or equal to `3.0`
	* `"3.0-"` - can take any version below or equal to `3.0`

When `qpm` looks to install dependencies, it will use try to install the highest available version that respects the version conditions.

An example `qr.json`:
```json
{
	"name" : "testlib",
	"version" : "2.1.1",
	"dependencies" : {
		"testlib2" : "",
		"testlib3" : "3.1.0+"
	},
	"osversion" : ["l32","l64"],
	"qversion" : "2.8+"
}
```

### Package structure
A typical package looks like
```
ROOT
+-- qr.json
+-- file1.q
+-- file2.q
...
+-- subfolder1
	+-- file3.q
+-- subfolder2
	+-- file4.q
```
When the package is `import`ed, the function will look in the folder `ROOT` for any .q files and load them. The working directory will be in `ROOT` so any references to files in the project should be relative to root (e.g. for `\l` operations).