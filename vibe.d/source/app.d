import mysql.db, std.array, std.random, vibe.d;


struct Message { string message; }
struct World { uint id; int randomNumber; }
struct Fortune { uint id; string message; }


enum connectionString = "host=localhost;port=3306;user=benchmarkdbuser;pwd=benchmarkdbpass;db=hello_world";
Connection conn;

__gshared Command worldSelectCommand;
__gshared Command worldUpdateCommand;
__gshared Command fortuneSelectCommand;
enum worldRowCount = 10000;
enum worldRandomMax = 10000;
enum helloWorldString = "Hello, World!";


shared static this()
{
	enableWorkerThreads();

	MysqlDB db = new MysqlDB(connectionString);
	conn = db.lockConnection();
	scope(exit) conn.close();

	worldSelectCommand = Command(conn, "SELECT id, randomNumber FROM World WHERE id = ?");
	worldUpdateCommand = Command(conn, "UPDATE World SET randomNumber = ? WHERE id = ?");
	fortuneSelectCommand = Command(conn, "SELECT id, message FROM Fortune;");

	auto router = new URLRouter;
	router.get("/json", &getJson);
	router.get("/db", &getDB);
	router.get("/queries", &getQueries);
	router.get("/fortunes", &getFortunes);
	router.get("/updates", &getUpdates);
	router.get("/plaintext", &getPlaintext);

	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	listenHTTP(settings, router);
}

World[] queryRandomWorlds(int n)
{
	auto world = new World[n];
	//TODO: shouldnt prepare be put somewhere else (to run just once)?
	worldSelectCommand.prepare();
	foreach (i; 0 .. n) {
		//TODO: can this be simplified?
		int id = uniform(0, worldRowCount) + 1;
		worldSelectCommand.bindParameter(id, 0);
		worldSelectCommand.execPreparedTuple(world[i].id, world[i].randomNumber);
	}
	return world;
}

void getJson(HTTPServerRequest req, HTTPServerResponse res)
{
	auto msg = Message(helloWorldString);
	res.writeJsonBody(msg);
}

void getDB(HTTPServerRequest req, HTTPServerResponse res)
{
	res.writeJsonBody(queryRandomWorlds(1)[0]);
}

void getQueries(HTTPServerRequest req, HTTPServerResponse res)
{
	auto nstr = req.query.get("queries", null);
	int n = nstr.length ? nstr.to!int : 1;
	if (n<1) n = 1;
	if (n>500) n = 500;
	
	res.writeJsonBody(queryRandomWorlds(n));
}


void getFortunes(HTTPServerRequest req, HTTPServerResponse res)
{
	auto fortunesApp = appender!(Fortune[]);
	
	ResultSet ret = fortuneSelectCommand.execSQLResult();
	while (!ret.empty()) {
		//TODO maybe it would be better to use ret.front.toStruct!Fortune(x) somehow?
		fortunesApp.put(Fortune(ret.front.opIndex(0).get!(uint), ret.front.opIndex(1).get!(string)));
		ret.popFront();
	}
	
	fortunesApp.put(Fortune(0, "Additional fortune added at request time."));

	auto fortunes = fortunesApp.data;
	fortunes.sort!((a, b) => a.message < b.message);

	res.render!("fortunes.dt", fortunes);
}

void getUpdates(HTTPServerRequest req, HTTPServerResponse res)
{
	auto nstr = req.query.get("queries", null);
	int n = nstr.length ? nstr.to!int : 1;
	if (n<1) n = 1;
	if (n>500) n = 500;

	World[] world = queryRandomWorlds(n);
	//TODO: where to put prepare?
	worldUpdateCommand.prepare();
	foreach (i; 0 .. n) {
		world[i].randomNumber = uniform(0, worldRandomMax) + 1;
		worldUpdateCommand.bindParameter(world[i].randomNumber, 0);
		worldUpdateCommand.bindParameter(world[i].id, 1);
		ulong ra;
		worldUpdateCommand.execPrepared(ra);
		assert(ra == 1);
 	}
	res.writeJsonBody(world);
}

void getPlaintext(HTTPServerRequest req, HTTPServerResponse res)
{
	res.writeBody(helloWorldString, "text/plain");
}
