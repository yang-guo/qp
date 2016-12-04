if[0 = count getenv`QHOME;`QHOME setenv getenv[`HOME],"/q"];

baseOptions:.z.x where not |\[.z.x like "-*"];
otherOptions:.Q.opt .z.x;

if[0 = count baseOptions;-2"please choose a command.  use q qpr.q help to see list of commands";exit 1];

/********************
/HELPER FUNCTIONS
/********************
copy:{[from_;to_;contentsOnly_]
	if[11h <> abs type key from_;:0b];
	if[11h <> abs type key to_;:0b];
	system"cp -r ",(1_string from_),$[contentsOnly_;"/*";""]," ",(1_string to_);
	:1b;
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

/returns a dict if successful or () if not
getPackageMetadata:{[packageHandle]
	/check package folder exists and qr.json is there
	if[11h <> type key packageHandle;-2"package is not a folder";:()];
	if[not `qr.json in key packageHandle;-2"package is not valid";:()];

	/check mandatory fields exist and version number format is correct
	qrJson:.j.k raze read0 ` sv packageHandle,`qr.json;
	if[not all `name`version in key[qrJson];-2"qr.json doesn't have all mandatory fields";:()];
	if[3 <> count versionLong:"J"$"." vs version:qrJson`version;;-2"not a valid version number";:()];
	if[any null versionLong;-2"not a valid version number";:()];

	:qrJson;
 };

/********************
/COMMAND FUNCTIONS
/********************
create:{[args;otherOptions]
	if[1 <> count args;-2"incorrect usage, create a new repo using qpr create REPOLOC";:1];

	repoLoc:hsym`$first args;
	if[0h = type key repoLoc;system"cd ",1_string repoLoc];
	system"cd ",1_(string repoLoc),"/lib";
	(` sv repoLoc,`index) 0: enlist "";

	:0;
 };

add:{[args;optherOptions]
	if[1 <> count args;-2"incorrect usage, add a package to a local repo using qpr add MYPACKAGE";:1];
	
	repoLocation:$[`loc in key otherOptions;first otherOptions`loc;getenv`QREPO];
	if[0h = type location:last getRepo[repoLocation];-2"not a valid repo location";:1];

	libLoc:hsym `$first args;
	if[0h = type qrJson:getPackageMetadata[libLoc];:1];
	name:qrJson`name;
	version:qrJson`version;

	system"cd ",1_string ` sv location,`lib,`$name;
	system"cd ",1_string versionLoc:` sv location,`lib,`$(name;version);

	if[not copy[libLoc;versionLoc;1b];-2"attempt to move package files failed";:1];
	:0;
 };

list:{[args;otherOptions]
	if[1 < count args;-2"incorrect usage, list packages in repo using qpr list or qpr list MYPACKAGE";:1];

	repoLocation:$[`loc in key otherOptions;first otherOptions`loc;getenv`QREPO];
	if[0h = type location:last getRepo[repoLocation];-2"not a valid repo location";:1];

	if[0 = count args;
		-1"ROOT";
		{[repoLoc;lib]
			-1"+-- ",string lib;
			{-1"\t+-- ",string x} each key ` sv repoLoc,lib;
		}[libLoc] each key libLoc:` sv location,`lib;
		:0;
	];

	lib:`$first args;
	if[not lib in key ` sv location,`lib;-2"library not found in repo";:1];
	-1 string lib;
	{-1"+-- ",string x} each key ` sv location,`lib,lib;
	:0;
 };

help:{[args;otherOptions]
	-1"Available commands:
	create [REPOLOC]: creates a qp repo at REPOLOC
	add [PACKAGELOC]: adds package to repo
	list [PACKAGENAME]: lists what is currently in repo, including available versions
	help: help prompt.  usage: qpm help

	Other options:
	-loc [LOCATION]: sets location of repository to (e.g. repo to add to)";
	:0;
 };

badCommand:{[args;otherOptions] -2"command not recognized";:1;};

/********************
/ENTRY POINT
/********************
res:.[{[baseOptions;otherOptions]
	command:`$first baseOptions;
	args:1_baseOptions;
	fn:$[command = `create;create;
		command = `add;add;
		command = `help;help;
		command = `list;list;
		badCommand];
	:fn[args;otherOptions];
 };(baseOptions;otherOptions)];

exit res
