.q.import:{[lib]
	if[not type[lib] in 11 -11 10h;'`INVALID_LIBRARY_TYPE];
	if[(11h = type lib) & (2 <> count lib);'`INVALID_LIBRARY_TYPE];
	if[10h=type lib;lib:`$lib];
	namespace:string last lib;
	lib:string first lib;
	if[any lib in "#<$+%>!`&*'|{?\"=}/:\\ @-.";'`INVALID_CHARS_IN_LIBRARY_NAME];

	if[(`$lib) in key`;:::];
	if[`qp in key `;delete from `.qp];
	system "d .qp";
	.q.importdepth+:1;
	res:@[{
		qhome:hsym `$$[0 = count getenv`QHOME;getenv[`HOME],"/q";getenv`QHOME];
		libfiles:key ` sv qhome,`$x;
		if[11h <> type libfiles;:0b];
		files:string {x where x like "*.q"} libfiles;
		{system "l ",x,"/",y}[x] each files;
		:1b;
	};lib;0b];
	.q.importdepth-:1;
	if[.q.importdepth = 0;system "d ."];
	if[res;.[`$".",namespace;();,;get `.qp]];
	if[`qp in key `;delete from `.qp];
	if[not res;'`INVALID_LIBRARY];
 };
.q.importdepth:0;

.q.to:{[lib;namespace]
	if[not type[lib] in -11 10h;'`INVALID_LIBRARY_TYPE];
	if[not type[namespace] in -11 10h;'`INVALID_NAMESPACE_TYPE];
	if[10h=type lib;lib:`$lib];
	if[10h=type namespace;namespace:`$namespace];
	:(lib;namespace);
 };