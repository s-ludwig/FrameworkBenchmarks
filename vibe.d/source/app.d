import mysql.db, std.array, vibe.d;


struct Message { string message; }
struct World { ushort id; ushort randomNumber; }
struct Fortune { ushort id; string message; }


enum connectionString = "benchmarkdbuser:benchmarkdbpass@localhost:3306/hello_world?charset=utf8";
__gshared Command worldSelectCommand;
__gshared Command worldUpdateCommand;
__gshared Command fortuneSelectCommand;
enum worldRowCount = 10000;
enum helloWorldString = "Hello, World!";


shared static this()
{
	enableWorkerThreads();

	// TODO:
	// ...
	//worldSelectCommand = Command(conn, "SELECT id, randomNumber FROM World WHERE id = ?");
	//worldUpdateCommand = Command(conn, "UPDATE World SET randomNumber = ? WHERE id = ?");
	//fortuneSelectCommand = Command(conn, "SELECT id, message FROM Fortune;");
	// ...

	auto router = new URLRouter;
	router.get("/json", &getJson);
	router.get("/db", &getDB);
	router.get("/queries", &getQueries);
	router.get("/fortune", &getFortune);
	router.get("/update", &getUpdate);
	router.get("/plaintext", &getPlaintext);

	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	listenHTTP(settings, router);
}

void getJson(HTTPServerRequest req, HTTPServerResponse res)
{
	auto msg = Message(helloWorldString);
	res.writeJsonBody(msg);
}

void getDB(HTTPServerRequest req, HTTPServerResponse res)
{
	World world;
	// TODO: query DB using worldSelectCommand and id set to uniform(0, worldRowCount)+1, store result in world
	res.writeJsonBody(world);
}

void getQueries(HTTPServerRequest req, HTTPServerResponse res)
{
	auto nstr = req.query.get("queries", null);
	int n = nstr.length ? nstr.to!int : 1;

	if (n <= 1) {
		getDB(req, res);
		return;
	}

	auto world = new World[n];
	foreach (i; 0 .. n) {
		// TODO query DB using worldSelectCommand and id set to uniform(0, worldRowCount)+1, store result in world[i]
	}

	res.writeJsonBody(world);
}


void getFortune(HTTPServerRequest req, HTTPServerResponse res)
{
	auto fortunesApp = appender!(Fortune[]);
	// TODO: execute fortuneSelectCommand and store results into fortunesApp
	fortunesApp.put(Fortune(0, "Additional fortune added at request time."));

	auto fortunes = fortunesApp.data;
	fortunes.sort!((a, b) => a.message < b.message);

	res.render!("fortunes.dt", fortunes);
}

void getUpdate(HTTPServerRequest req, HTTPServerResponse res)
{
	auto nstr = req.query.get("queries", null);
	int n = nstr.length ? nstr.to!int : 1;

	if (n <= 1)	{
		World world;
		// TODO (go code):
		// worldStatement.QueryRow(rand.Intn(worldRowCount)+1).Scan(&world.Id, &world.RandomNumber)
		// world.RandomNumber = uint16(rand.Intn(worldRowCount) + 1)
		// updateStatement.Exec(world.RandomNumber, world.Id)		*/
		res.writeJsonBody(world);
	} else {
		auto world = new World[n];
		foreach (i; 0 .. n) {
			// TODO (go code):
			// if err := worldStatement.QueryRow(rand.Intn(worldRowCount)+1).Scan(&world[i].Id, &world[i].RandomNumber); err != nil {
			// 	log.Fatalf("Error scanning world row: %s", err.Error())
			// }
			// world[i].RandomNumber = uint16(rand.Intn(worldRowCount) + 1)
			// if _, err := updateStatement.Exec(world[i].RandomNumber, world[i].Id); err != nil {
			// 	log.Fatalf("Error updating world row: %s", err.Error())
			// }
		}
		res.writeJsonBody(world);
	}
}

void getPlaintext(HTTPServerRequest req, HTTPServerResponse res)
{
	res.writeBody(helloWorldString, "text/plain");
}
