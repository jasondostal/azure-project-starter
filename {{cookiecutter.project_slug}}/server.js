/**
 * {{cookiecutter.project_name}} — server entrypoint (Node.js / SvelteKit).
 * Wraps the SvelteKit handler and adds custom middleware.
 * Deployed to Azure App Service (Linux, Node {{ '22' }}).
 */
import { handler } from './build/handler.js';  // SvelteKit adapter-node output
import { createServer } from 'http';

const port = process.env.PORT || {{cookiecutter.app_port}};

const server = createServer((req, res) => {
  // Health check (before SvelteKit handler)
  if (req.url === '/health' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'healthy',
      app: '{{cookiecutter.project_name}}',
      environment: process.env.NODE_ENV || 'development'
    }));
    return;
  }

  handler(req, res);
});

server.listen(port, () => {
  console.log(`{{cookiecutter.project_name}} listening on :${port}`);
});
