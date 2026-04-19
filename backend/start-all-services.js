#!/usr/bin/env node

const { exec, spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const backendDir = __dirname;
const services = [
  { name: 'IAM_Service', port: 3003, hasDb: true, docker: true },
  { name: 'Order_Service', port: 3004, hasDb: true, docker: true },
  { name: 'Payment_Service', port: 3002, hasDb: true, docker: true },
  { name: 'Chat_System', port: 3001, hasDb: true, docker: true, hasRedis: true },
  { name: 'API_Gateway', port: 3000, hasDb: false, docker: true }
];

let startTime = Date.now();

const log = {
  info: (msg) => console.log(`\n📢 ${msg}`),
  success: (msg) => console.log(`✓ ${msg}`),
  error: (msg) => console.error(`✗ ${msg}`),
  warn: (msg) => console.log(`⚠ ${msg}`),
  service: (service, msg) => console.log(`  [${service}] ${msg}`)
};

function executeCommand(cmd, cwd, description) {
  return new Promise((resolve, reject) => {
    log.info(`${description}...`);
    
    const child = exec(cmd, { cwd, stdio: 'inherit' }, (error, stdout, stderr) => {
      if (error) {
        log.error(`${description} failed:\n${stderr || error.message}`);
        reject(error);
      } else {
        resolve(stdout);
      }
    });

    // Print output in real-time
    if (child.stdout) child.stdout.on('data', (data) => process.stdout.write(data));
    if (child.stderr) child.stderr.on('data', (data) => process.stderr.write(data));
  });
}

function waitForPort(port, maxAttempts = 30, interval = 1000) {
  return new Promise((resolve, reject) => {
    const http = require('http');
    let attempts = 0;

    const checkPort = () => {
      const req = http.get(`http://localhost:${port}/health`, (res) => {
        if (res.statusCode === 200) {
          resolve();
        } else {
          attempts++;
          if (attempts >= maxAttempts) {
            reject(new Error(`Port ${port} not ready after ${maxAttempts} attempts`));
          } else {
            setTimeout(checkPort, interval);
          }
        }
      });

      req.on('error', () => {
        attempts++;
        if (attempts >= maxAttempts) {
          reject(new Error(`Port ${port} not ready after ${maxAttempts} attempts`));
        } else {
          setTimeout(checkPort, interval);
        }
      });

      req.end();
    };

    checkPort();
  });
}

async function startAllServices() {
  try {
    log.info('🚀 Starting BuddyUp Backend Services (All-in-One)');
    log.info(`Services: ${services.map(s => s.name).join(', ')}`);

    // Start all docker-compose services simultaneously
    log.info('Step 1: Starting Docker containers for all services');
    
    const dockerPromises = [];
    
    for (const service of services) {
      if (service.docker) {
        const servicePath = path.join(backendDir, service.name);
        
        // Check if docker-compose.yml exists
        if (!fs.existsSync(path.join(servicePath, 'docker-compose.yml'))) {
          log.warn(`No docker-compose.yml found for ${service.name}, skipping docker`);
          continue;
        }

        // Start docker compose in background
        const promise = new Promise((resolve) => {
          const cmd = `docker compose down -v && docker compose up --build -d`;
          const child = exec(cmd, { cwd: servicePath }, (error) => {
            if (error) {
              log.service(service.name, `⚠ Docker startup warning: ${error.message}`);
            } else {
              log.service(service.name, '✓ Docker containers started');
            }
            resolve();
          });
        });
        
        dockerPromises.push(promise);
      }
    }

    // Wait for all docker services to start
    await Promise.all(dockerPromises);
    
    // Give databases time to initialize
    log.info('Step 2: Waiting for databases to initialize (15 seconds)...');
    await new Promise(resolve => setTimeout(resolve, 15000));

    // Run migrations
    log.info('Step 3: Running database migrations');
    
    const migrationServices = ['IAM_Service', 'Order_Service', 'Payment_Service', 'Chat_System'];
    
    for (const serviceName of migrationServices) {
      const servicePath = path.join(backendDir, serviceName);
      const packageJsonPath = path.join(servicePath, 'package.json');
      
      if (fs.existsSync(packageJsonPath)) {
        try {
          const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
          if (packageJson.scripts && packageJson.scripts.migrate) {
            log.service(serviceName, 'Running migrations...');
            await executeCommand('npm run migrate', servicePath, `${serviceName} migrations`);
            log.service(serviceName, '✓ Migrations completed');
          }
        } catch (err) {
          log.service(serviceName, `⚠ Couldn't parse package.json: ${err.message}`);
        }
      }
    }

    // Wait for all services to be healthy
    log.info('Step 4: Waiting for services to be healthy');
    
    const healthChecks = [];
    
    for (const service of services) {
      if (!service.hasDb && service.docker) {
        // Services without direct DB checks
        const checkPromise = waitForPort(service.port)
          .then(() => {
            log.service(service.name, `✓ Ready on port ${service.port}`);
          })
          .catch((err) => {
            log.service(service.name, `⚠ Health check timeout: ${err.message}`);
          });
        
        healthChecks.push(checkPromise);
      }
    }

    // Wait a bit more for services with DB to fully initialize
    await new Promise(resolve => setTimeout(resolve, 10000));

    // Quick verification of all services
    log.info('Step 5: Verifying service connectivity');
    
    const serviceStatus = {};
    
    for (const service of services) {
      const servicePath = path.join(backendDir, service.name);
      
      // Check if docker container is running
      const containerName = service.name.toLowerCase().replace(/_/g, '_');
      const checkCmd = `docker ps --filter "name=buddyup" --format "table {{.Names}}\\t{{.Status}}"`;
      
      try {
        const statusOutput = await new Promise((resolve, reject) => {
          exec(checkCmd, (error, stdout) => {
            if (error) reject(error);
            else resolve(stdout);
          });
        });
        
        if (statusOutput.includes('buddyup') && statusOutput.includes('Up')) {
          log.service(service.name, '✓ Docker container running');
          serviceStatus[service.name] = 'RUNNING';
        } else {
          log.service(service.name, '⚠ Docker container status unclear');
          serviceStatus[service.name] = 'UNKNOWN';
        }
      } catch (err) {
        log.service(service.name, `⚠ Couldn't verify container status`);
        serviceStatus[service.name] = 'ERROR';
      }
    }

    // Print summary
    const elapsed = Math.round((Date.now() - startTime) / 1000);
    
    log.info('═══════════════════════════════════════════');
    log.success(`All services started successfully! (${elapsed}s)`);
    log.info('═══════════════════════════════════════════');
    
    console.log('\n📍 Service Endpoints:');
    services.forEach(service => {
      const status = serviceStatus[service.name] || 'UNKNOWN';
      console.log(`   ${service.name.padEnd(20)} → http://localhost:${service.port} [${status}]`);
    });
    
    console.log('\n📋 Quick Commands:');
    console.log('   npm run test:iam       - Test IAM Service');
    console.log('   npm run test:order     - Test Order Service');
    console.log('   npm run test:payment   - Test Payment Service');
    console.log('   npm run test:chat      - Test Chat System');
    console.log('   npm run test:all       - Test all services');
    console.log('   npm run stop:all       - Stop all services');
    
    console.log('\n💡 Logs:');
    console.log('   docker logs buddyup_iam       - IAM Service logs');
    console.log('   docker logs buddyup_order     - Order Service logs');
    console.log('   docker logs buddyup_payment   - Payment Service logs');
    console.log('   docker logs buddyup_chat      - Chat System logs');
    console.log('   docker logs buddyup_gateway   - API Gateway logs');

    process.exit(0);

  } catch (err) {
    log.error(`Failed to start services: ${err.message}`);
    console.error(err);
    process.exit(1);
  }
}

// Start the process
startAllServices();
