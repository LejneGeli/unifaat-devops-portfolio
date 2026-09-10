const http = require("node:http");

const port = Number(process.env.PORT || 3000);

const server = http.createServer((request, response) => {
  response.setHeader("Content-Type", "application/json; charset=utf-8");

  if (request.method === "GET" && request.url === "/") {
    response.writeHead(200);
    response.end(JSON.stringify({ message: "TechNova API online" }));
    return;
  }

  if (request.method === "GET" && request.url === "/health") {
    response.writeHead(200);
    response.end(JSON.stringify({ status: "ok", service: "technova-api" }));
    return;
  }

  response.writeHead(404);
  response.end(JSON.stringify({ error: "Not found" }));
});

server.listen(port, "0.0.0.0", () => {
  console.log(`TechNova API ouvindo na porta ${port}`);
});
