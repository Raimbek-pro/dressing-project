const http = require("http");
const { Pool } = require("pg");

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

function send(res, status, data) {
  res.writeHead(status, { "Content-Type": "application/json" });
  res.end(JSON.stringify(data));
}

const server = http.createServer(async (req, res) => {
  try {
    // GET /api/items -> list all items
    if (req.method === "GET" && req.url === "/api/items") {
      const { rows } = await pool.query("SELECT * FROM items ORDER BY id DESC");
      return send(res, 200, rows);
    }

    // POST /api/items {"name": "..."} -> add an item
    if (req.method === "POST" && req.url === "/api/items") {
      let body = "";
      for await (const chunk of req) body += chunk;
      const { name } = JSON.parse(body || "{}");
      if (!name || !name.trim()) return send(res, 400, { error: "name is required" });
      const { rows } = await pool.query(
        "INSERT INTO items (name) VALUES ($1) RETURNING *",
        [name.trim()]
      );
      return send(res, 201, rows[0]);
    }

    // DELETE /api/items/:id -> remove an item
    const match = req.url.match(/^\/api\/items\/(\d+)$/);
    if (req.method === "DELETE" && match) {
      await pool.query("DELETE FROM items WHERE id = $1", [match[1]]);
      return send(res, 204, {});
    }

    send(res, 404, { error: "not found" });
  } catch (err) {
    console.error(err);
    send(res, 500, { error: "server error" });
  }
});

server.listen(3000, () => console.log("API listening on :3000"));
