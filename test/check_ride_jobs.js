// Run: node test/check_ride_jobs.js [optionalJobId]
const { Queue } = require('bullmq');
const IORedis = require('ioredis');

(async () => {
  const connection = new IORedis({
    host: process.env.REDIS_HOST || '127.0.0.1',
    port: process.env.REDIS_PORT ? parseInt(process.env.REDIS_PORT) : 6379,
    password: process.env.REDIS_PASSWORD || undefined,
    maxRetriesPerRequest: null
  });

  const q = new Queue('ride-timeout-queue', { connection });

  try {
    const counts = await q.getJobCounts('waiting','active','completed','failed','delayed','paused');
    console.log('job counts:', counts);

    const jobId = process.argv[2] || null;
    if (jobId) {
      const job = await q.getJob(jobId);
      if (!job) {
        console.log(`Job ${jobId} not found`);
      } else {
        console.log('Job', jobId, {
          id: job.id,
          name: job.name,
          data: job.data,
          timestamp: job.timestamp,
          processedOn: job.processedOn,
          finishedOn: job.finishedOn,
          attemptsMade: job.attemptsMade,
          stacktrace: job.stacktrace
        });
      }
    } else {
      const waiting = await q.getWaiting();
      const delayed = await q.getDelayed();
      console.log('waiting jobs (ids):', waiting.map(j => j.id).slice(0,50));
      console.log('delayed jobs (ids):', delayed.map(j => j.id).slice(0,50));
    }
  } catch (e) {
    console.error('check queue error', e);
  } finally {
    await q.close();
    connection.disconnect();
    process.exit(0);
  }
})();