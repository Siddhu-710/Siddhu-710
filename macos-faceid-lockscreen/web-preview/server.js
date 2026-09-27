const http = require("node:http");
const fs = require("node:fs");
const path = require("node:path");

const port = Number(process.env.PORT || 4173);
const pagePath = path.join(__dirname, "index.html");

http.createServer((request, response) => {
  const pathname = new URL(request.url || "/", "http://localhost").pathname;
  if ((request.method !== "GET" && request.method !== "HEAD") || (pathname !== "/" && pathname !== "/index.html")) {
    response.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
    response.end("Not found");
    return;
  }

  fs.readFile(pagePath, (error, page) => {
    if (error) {
      response.writeHead(500, { "Content-Type": "text/plain; charset=utf-8" });
      response.end("Preview could not be loaded");
      return;
    }

    response.writeHead(200, {
      "Cache-Control": "no-store",
      "Content-Type": "text/html; charset=utf-8",
      "X-Content-Type-Options": "nosniff",
    });
    response.end(request.method === "HEAD" ? undefined : page);
  });
}).listen(port, "127.0.0.1", () => {
  console.log(`FaceIDLock preview: http://127.0.0.1:${port}`);
});