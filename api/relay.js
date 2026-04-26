module.exports = async (req, res) => {
  const target = process.env.TARGET_DOMAIN || 'https://your-server.com';
  const path = req.url;
  
  const response = await fetch(`${target}${path}`, {
    method: req.method,
    headers: req.headers,
    body: req.method !== 'GET' ? JSON.stringify(req.body) : undefined
  });
  
  const data = await response.text();
  res.status(response.status).send(data);
};
