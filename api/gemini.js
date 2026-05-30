// Serverless function executada em ambiente Node.js na Vercel (Node 18+)
module.exports = async (req, res) => {
  // Configuração de cabeçalhos CORS para permitir chamadas do frontend
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Método não permitido. Utilize POST.' });
  }

  try {
    const { systemPrompt, userPrompt, model } = req.body;
    const apiKey = process.env.GEMINI_API_KEY;
    
    if (!apiKey) {
      return res.status(500).json({ error: 'Chave GEMINI_API_KEY não configurada nas variáveis de ambiente do projeto Vercel.' });
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

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Erro na chamada da API do Gemini: ${response.status} - ${errorText}`);
    }

    const data = await response.json();
    const text = data.candidates[0].content.parts[0].text;
    
    // Envia o texto da resposta (que já é uma string JSON estrita gerada pelo Gemini)
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.status(200).send(text);
  } catch (error) {
    console.error("Erro interno no processamento serverless: ", error);
    res.status(500).json({ error: error.message });
  }
};
