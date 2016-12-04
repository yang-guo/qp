if[0 = count getenv`QHOME;`QHOME setenv getenv[`HOME],"/q"];

baseOptions:.z.x where not |\[.z.x like "-*"];
otherOptions:.Q.opt .z.x;

if[0 = count baseOptions;-2"please choose a command.  use q qpm.q help to see list of commands";exit 1];

/********************
/HELPER FUNCTIONS
/********************
createTempDir:{hsym `$first system"echo `mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`"};
remove:{$[0h = t:type key x;:0;0h < t;[.z.s each `$((string[x]),"/"),/:string key x;hdel x];hdel x]};
copy:{[from_;to_;contentsOnly_]
	if[11h <> abs type key from_;:0b];
	if[11h <> abs type key to_;:0b];
	system "cp -r ",(1_string from_),$[contentsOnly_;"/*";""]," ",(1_string to_)
 };

isValidRepo:{[protocol;repoHandle]
	if[`file <> protocol;-2"currently add only allows for local repos.  Please have file:// protocol";:0b];
	if[0h = type key repoHandle;-2"repo is not a folder";:0b];
	if[not all key[repoHandle] in\: `index`lib;-2"repo format not recognized";:0b];
	:1b;
 };

/returns a dict if successful or () if not
getRepo:{[repoString]
	if[10h <> type repoString;:()];
	if[0 = count repoString;:()];
	repoParsed:"://" vs repoString;
	protocol:`$first repoParsed;
	location:hsym `$last repoParsed;
	if[not isValidRepo[protocol;location];:()];

	:protocol,location;
 };

/********************
/LOCAL INSTALLATION
/********************
getInstalledPackages:{
	packages:{{y where 11h = (type key hsym@) each ` sv/: x,/:y}[x;key x]} qhomeHandle:hsym `$getenv`QHOME;
	pkgVersions:(packages,'{
		if[not `qr.json in key x;:enlist ""];
		qrJson:.j.k raze read0 ` sv x,`qr.json;
		enlist "J"$"." vs qrJson`version
	} each ` sv/: qhomeHandle,/:packages);
	:{x where 0 <> count each x[;1]} pkgVersions;
 };

/Check versions
versionConvert:{"J"$$[0 = count x;("";"";"");(-1#x) like "[0-9]";"." vs x;"." vs -1_x]};
getCompatibleVersion:{[availableVersions;versionstring]
	comp:{y where 0 <= {[f;b;x;y] if[b<>0;:b];$[f[x;y];1;x=y;0;-1]}[x]/[0;;z] each y};
	versionAllowedTuple:versionConvert versionstring;
	
	:$[0 = count versionstring;availableVersions;
		"+" = last versionstring;comp[>;availableVersions;versionAllowedTuple];
		"-" = last versionstring;comp[<;availableVersions;versionAllowedTuple];
		(-1#versionstring) like "[0-9]";{x where x ~\: y}[availableVersions;versionAllowedTuple];
		()];
 };

/() = any incompatibility, (pkg;version) if success
getRepoVersion:{[repoLocation;pkg;versionAllowed]
	pkgLoc:` sv repoLocation,`lib,pkg;

	/get correct version
	if[0h = type versions:key pkgLoc;-2"package not found";:()];
	availableVersions:desc "J"$"." vs/: string versions;
	compatibleVersion:getCompatibleVersion[availableVersions;versionAllowed];
	if[0 = count compatibleVersion;-2"no compatible versions found for ",(string pkg)," (required version ",versionAllowed,")";:()];
	installVersion:first compatibleVersion;

	qrJson:.j.k raze read0 ` sv pkgLoc,(`$"." sv string installVersion),`qr.json;
	if[`osversion in key qrJson;if[not .z.o in `$qrJson`osversion;-2"os version is not compatible with package";:()]];
	if[`qversion in key qrJson;
		qv:qrJson`qversion;
		f:$["+" = last qv;>=;"-" = last qv;<=;=];
		qvf:"F"$$[(-1#qv) like "[+|-]";-1_qv;qv];
		if[not f[.z.K;qvf];-2"q version is not compatible with package";:()];
	];

	:(pkg;installVersion);
 };

/0 = not installed, 1 = installed, -1 = installed but incompatible version
isInstalled:{[pkg;versionAllowed]
	installedPackages:getInstalledPackages[];
	if[pkg in installedPackages[;0];
		installedVersion:getCompatibleVersion[installedPackages[;1] where installedPackages[;0] = pkg;versionAllowed];
		if[0 = count installedVersion;:-1];
		:1;
	];
	:0;
 };

/() = no dependencies, ((pkg1;version1);(pkg2;version2)) = has dependencies, -1 = incompatible version installed
getDependencies:{[repoLocation;pkg;version]
	pkgLoc:` sv repoLocation,`lib,pkg;
	qrJson:.j.k raze read0 ` sv pkgLoc,(`$"." sv string version),`qr.json;
	if[`dependencies in key qrJson;
		dependencies:qrJson`dependencies;
		installedStatus:isInstalled'[key dependencies;value dependencies];
		if[any installedStatus = -1;:-1];
		deps:(getRepoVersion[repoLocation].) each (flip (key dependencies;value dependencies)) where installedStatus = 0;
		if[any 0 = count each deps;:-1];
		:deps;
	];
	:();
 };

/returns an ordered list of packages to install as (name;version) tuples
getInstallOrder:{[repoLocation;pkg;versionAllowed]
	if[1 = isInstalled[pkg;versionAllowed];:()];

	if[0 = count repoVersion:getRepoVersion[repoLocation;pkg;versionAllowed];-2"package ",(string pkg)," not found in repo";:-1];
	depsList:getDependencies[repoLocation;repoVersion[0];repoVersion[1]];
	if[0h <> type depsList;-2"error in getting dependencies";:-1];
	dependencies:(enlist repoVersion)!enlist depsList;
	while[0 < count depsList;
		nextPkg:first depsList;
		depsList:1_depsList;
		newDeps:getDependencies[repoLocation;nextPkg[0];nextPkg[1]];
		if[0h <> type newDeps;-2"error in getting dependencies";:-1];
		dependencies,:(enlist nextPkg)!enlist newDeps;
		depsList,:newDeps where {any y ~/: x}[key dependencies] each newDeps;
	];

	installOrder:{[dict;lst] 
		lst,:{
			y where not {any y ~/: x}[x] each y
		}[lst] key[dict] where 0 = count each {
			y where not {any y ~/: x}[x] each y
		}[lst] each value[dict];lst
	}[dependencies]/[()];

	:installOrder;
 };

installPackages:{[repoLocation;tmpDir;pkgVersionList]
	{[repo;tmpDir;pkgVersion]
		pkg:pkgVersion[0];
		pkgLoc:` sv repo,`lib,pkgVersion[0],`$"." sv string pkgVersion[1];
		system"cd ",(1_string tmpPkgDir:` sv tmpDir,pkgVersion[0]);
		copy[pkgLoc;tmpPkgDir;1b];
	}[repoLocation;tmpDir] each pkgVersionList;
	:1b;
 };

/********************
/INSTALLATION FUNCTIONS
/********************
installLocal:{[pkg;location]
	-1 "installing from local repo ",string location;
	tmpDir:createTempDir[];

	installOrder:getInstallOrder[location;pkg;""];
	if[0h <> type installOrder;-2"error in installation";:1];
	if[0 = count installOrder;-1"package ",(string pkg)," already installed";:0];
	if[not installPackages[location;tmpDir;installOrder];remove tmpDir;:1];

	copy[tmpDir;hsym`$getenv`QHOME;1b];
	remove tmpDir;
	:0;
 };

installGithub:{[pkg;location] -2"not yet implemented";:1;};

badRepoProtocol:{[pkg;location] -2"unrecognized repo protocol";:1;};

/********************
/COMMAND FUNCTIONS
/********************
install:{[args;otherOptions]
	if[1 <> count args;-2"incorrect usage, install using qpm install MYPACKAGE";:1];
	
	repoLocation:$[`loc in key otherOptions;first otherOptions`loc;getenv`QREPO];
	if[0h = type location:last repoDetails:getRepo[repoLocation];-2"not a valid repo location";:1];
	protocol:first[repoDetails];

	:$[protocol = `file;installLocal;
		protocol = `github;installGithub;
		badRepoProtocol][`$first args;location];
 };

uninstall:{[args;otherOptions]
	if[1 <> count args;-2"incorrect usage, install using qpm uninstall MYPACKAGE";:1];

	pkg:`$first args;
	installedPackages:getInstalledPackages[];
	if[not pkg in installedPackages[;0];-2"package ",(string pkg)," not installed";:1];
	remove ` sv (hsym`$getenv`QHOME),pkg;
	:0;
 };

help:{[args;otherOptions]
	-1"Available commands:
	install [PACKAGE]: installs a package.
	help: help prompt.  usage: qpm help

	Other options:
	-loc [LOCATION]: sets location of repository to install from";
	:0;
 };

badCommand:{[args;otherOptions] -2"command not recognized";:1;};

/********************
/ENTRY POINT
/********************
res:.[{[baseOptions;otherOptions]
	command:`$first baseOptions;
	args:1_baseOptions;
	fn:$[command = `install;install;
		command = `uninstall;uninstall;
		command = `help;help;
		badCommand];
	:fn[args;otherOptions];
 };(baseOptions;otherOptions)];

exit res