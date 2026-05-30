const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3000;

const MIME_TYPES = {
  '.html': 'text/html',
  '.css': 'text/css',
  '.js': 'text/javascript',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon'
};

const server = http.createServer((req, res) => {
  // Limpar a URL para evitar navegação fora do diretório do projeto
  let safeUrl = req.url.split('?')[0];
  if (safeUrl === '/') safeUrl = '/index.html';
  
  // Rota de proxy local para a API do Gemini
  if (safeUrl === '/api/gemini' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });
    req.on('end', async () => {
      try {
        const { systemPrompt, userPrompt, model } = JSON.parse(body);
        const apiKey = process.env.GEMINI_API_KEY;
        if (!apiKey) {
          res.writeHead(500, { 'Content-Type': 'application/json; charset=utf-8' });
          res.end(JSON.stringify({ error: 'Chave GEMINI_API_KEY não configurada nas variáveis de ambiente do seu terminal local. Defina-a antes de iniciar o servidor.' }));
          return;
        }

        const geminiModel = model || 'gemini-2.5-flash';
        const url = `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent?key=${apiKey}`;
        
        const payload = {
          contents: [
            {
              role: "user",
              parts: [
                { text: `${systemPrompt}\n\nSolicitação:\n${userPrompt}` }
              ]
            }
          ],
          generationConfig: {
            responseMimeType: "application/json",
            temperature: 0.15
          }
        };

        const apiRes = await fetch(url, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(payload)
        });

        if (!apiRes.ok) {
          const errText = await apiRes.text();
          res.writeHead(500, { 'Content-Type': 'application/json; charset=utf-8' });
          res.end(JSON.stringify({ error: `Erro na API do Gemini: ${apiRes.status} - ${errText}` }));
          return;
        }

        const data = await apiRes.json();
        const text = data.candidates[0].content.parts[0].text;
        
        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(text);
      } catch (err) {
        res.writeHead(500, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ error: err.message }));
      }
    });
    return;
  }
  
  const filePath = path.join(__dirname, safeUrl);
  const extname = String(path.extname(filePath)).toLowerCase();
  const contentType = MIME_TYPES[extname] || 'application/octet-stream';

  fs.readFile(filePath, (error, content) => {
    if (error) {
      if (error.code === 'ENOENT') {
        res.writeHead(404, { 'Content-Type': 'text/html; charset=utf-8' });
        res.end('<h1>404 - Página Não Encontrada</h1>', 'utf-8');
      } else {
        res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end(`Erro no servidor: ${error.code}\n`);
      }
    } else {
      res.writeHead(200, { 
        'Content-Type': contentType,
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'X-Content-Type-Options': 'nosniff'
      });
      res.end(content, 'utf-8');
    }
  });
});

server.listen(PORT, () => {
  console.log(`\n======================================================`);
  console.log(`🚀 Plataforma EduTech Multi-Concurso rodando com sucesso!`);
  console.log(`👉 Acesse no seu navegador: http://localhost:${PORT}`);
  console.log(`======================================================\n`);
});
