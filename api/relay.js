export default async function handler(req, res) {
  const target = process.env.TARGET_DOMAIN || 'https://google.com';
  
  try {
    const response = await fetch(target + req.url, {
      headers: req.headers,
      method: req.method,
      body: req.method !== 'GET' ? JSON.stringify(req.body) : undefined
    });
    
    const data = await response.text();
    res.status(response.status).send(data);
  } catch (error) {
    res.status(500).send('Error: ' + error.message);
  }
}
