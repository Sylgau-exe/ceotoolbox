export default function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  return res.status(200).json({
    status: 'ok',
    service: 'CEO Toolbox - GSM Decision Platform',
    timestamp: new Date().toISOString()
  });
}
