import vibe.core.core;
import vibe.db.redis.redis;
import vibe.http.router;
import vibe.http.server;
import vibe.web.web;

import std.conv : ConvException, to;
import std.format : format;
import std.random : uniform;


enum long worldSize = 10000;
enum long fortunesSize = 100;
enum redisHost = "127.0.0.1";
enum redisDB = 0;


void main()
{
  runWorkerTaskDist(&runServer);
  runApplication();
}

void runServer()
{
  auto router = new URLRouter;
  router.registerWebInterface(new WebInterface);

  auto settings = new HTTPServerSettings;
  settings.port = 8080;
  settings.options |= HTTPServerOption.reusePort;
  listenHTTP(settings, router);
}

class WebInterface {
  private {
    RedisDatabase _db;
  }

  this()
  {
    import std.process : environment;
    _db = connectRedis(environment.get("DBHOST", redisHost)).getDatabase(redisDB);
    setupWorldCollection();
    setupFortunesCollection();
  }

  // GET /
  void get()
  {
    render!"index.dt";
  }

  // GET /json
  void getJson(HTTPServerResponse res)
  {
    // NOTE: the status and content type parameters are optional, but we need
    // to specify them, because the default content type is "application/json; charset=UTF8"
    res.writeJsonBody(Message("Hello, World!"), HTTPStatus.ok, "application/json");
  }

  // GET /db
  void getDB(HTTPServerResponse res)
  {
    auto id = uniform(1, worldSize + 1);
    auto w = _db.get!long(format("world:%s", id));
    res.writeJsonBody(World(id, w), HTTPStatus.ok, "application/json");
  }

  // GET /queries?queries=...
  void getQueries(HTTPServerResponse res, string queries)
  {
    import std.algorithm : min, max;

    // Convert the "queries" parameter to int and ignore any conversion errors
    // Note that you'd usually declare queries as int instead. However, the
    // test required to gracefully handle errors here.
    int count = 1;
    try count = min(max(queries.to!int, 1), 500);
    catch (ConvException) {}

    // assemble the response array    
    scope data = new World[count];
    foreach (ref w; data) {
      auto id = uniform(1, worldSize + 1);
      w = World(id, _db.get!long(format("world:%s", id)));
    }

    // write response as JSON
    res.writeJsonBody(data, HTTPStatus.ok, "application/json");
  }

  // GET /plaintext
  void getPlaintext(HTTPServerResponse res)
  {
    res.writeBody("Hello, World!", HTTPStatus.ok, "text/plain");
  }

  private void setupWorldCollection()
  {
    foreach (key; _db.keys("world:*"))
      _db.del(key);

    foreach (i; 0 .. worldSize)
      _db.set(format("world:%s", i+1), uniform(0, worldSize));
  }

  private void setupFortunesCollection()
  {
    foreach (key; _db.keys("fortune:*"))
      _db.del(key);

    foreach (i; 0 .. worldSize)
      _db.set(format("fortune:%s", i+1), uniform(0, fortunesSize));
  }
}

struct Message {
  string message;
}

struct World {
  long id;
  long randomNumber;
}

struct Fortune {
  int id;
  string message;
}
