const express = require('express');
const { Pool } = require('pg');
const Redis = require('ioredis');

const app = express();

const PORT = process.env.PORT || 3000;

const pool = new Pool({
  host: process.env.DB_HOST || 'postgres',
  port: Number(process.env.DB_PORT || 5432),
  database: process.env.DB_NAME || 'technova',
  user: process.env.DB_USER || 'technova',
  password: process.env.DB_PASSWORD
});

const redis = new Redis({
  host: process.env.REDIS_HOST || 'redis',
  port: Number(process.env.REDIS_PORT || 6379)
});

app.use(express.json());

app.get('/', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    await redis.ping();

    res.json({
      servico: 'TechNova API',
      status: 'online',
      banco: 'PostgreSQL conectado',
      cache: 'Redis conectado'
    });
  } catch (error) {
    res.status(503).json({
      servico: 'TechNova API',
      status: 'indisponivel',
      erro: error.message
    });
  }
});

app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    await redis.ping();

    res.json({
      status: 'healthy',
      uptime: process.uptime()
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      erro: error.message
    });
  }
});

app.get('/cache/:chave', async (req, res) => {
  const valor = await redis.get(req.params.chave);
  res.json({ chave: req.params.chave, valor });
});

app.post('/cache/:chave', async (req, res) => {
  await redis.set(req.params.chave, req.body.valor);
  res.json({ mensagem: 'Valor armazenado no cache.' });
});

app.listen(PORT, () => {
  console.log(`TechNova API rodando na porta ${PORT}`);
});