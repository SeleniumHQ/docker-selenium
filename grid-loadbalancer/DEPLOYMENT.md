# Selenium Grid Load Balancer - Deployment Guide

## Quick Start with Docker Compose

### 1. Prerequisites
- Docker and Docker Compose installed
- At least 8GB RAM available
- Ports 4444, 9090, 9091, 3000 available

### 2. Deploy the Complete Stack
```bash
# Clone or navigate to the project directory
cd go-grid-loadbalancer

# Start all services (3 Grid instances + Load Balancer + Redis + Monitoring)
docker-compose up -d

# Check service health
docker-compose ps
```

### 3. Verify Deployment
```bash
# Check load balancer health
curl http://localhost:4444/lb/health

# Check Grid instances
curl http://localhost:4445/status  # Grid 1
curl http://localhost:4446/status  # Grid 2
curl http://localhost:4447/status  # Grid 3

# Check session tracking
curl http://localhost:4444/lb/sessions
```

### 4. Test Automatic Session Tracking
```bash
# Run the demo script
python examples/automatic-tracking-demo.py

# Or use standard WebDriver code
python -c "
from selenium import webdriver
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities

driver = webdriver.Remote(
    command_executor='http://localhost:4444/wd/hub',
    desired_capabilities=DesiredCapabilities.CHROME
)
driver.get('https://example.com')
print(f'Title: {driver.title}')
driver.quit()
"
```

## Manual Deployment

### 1. Build the Load Balancer
```bash
# Build binary
go build -o selenium-grid-lb main.go

# Or build Docker image
docker build -t selenium-grid-lb .
```

### 2. Start Redis (Optional but Recommended)
```bash
docker run -d --name redis -p 6379:6379 redis:7-alpine
```

### 3. Start Selenium Grid Instances
```bash
# Grid Instance 1
docker run -d --name selenium-hub-1 -p 4445:4444 selenium/hub:4.15.0

# Grid Instance 2
docker run -d --name selenium-hub-2 -p 4446:4444 selenium/hub:4.15.0

# Add Chrome nodes
docker run -d --name chrome-node-1 --link selenium-hub-1:hub \
  -e HUB_HOST=hub selenium/node-chrome:4.15.0

docker run -d --name chrome-node-2 --link selenium-hub-2:hub \
  -e HUB_HOST=hub selenium/node-chrome:4.15.0
```

### 4. Configure and Start Load Balancer
```bash
# Copy and edit configuration
cp config.yaml config-local.yaml
# Edit grid_instances URLs to match your setup

# Start load balancer
./selenium-grid-lb -config config-local.yaml
```

## Production Deployment

### Kubernetes Deployment
```yaml
# Create kubernetes manifests
apiVersion: apps/v1
kind: Deployment
metadata:
  name: selenium-load-balancer
spec:
  replicas: 2
  selector:
    matchLabels:
      app: selenium-load-balancer
  template:
    metadata:
      labels:
        app: selenium-load-balancer
    spec:
      containers:
      - name: load-balancer
        image: selenium-grid-lb:latest
        ports:
        - containerPort: 4444
        - containerPort: 9090
        env:
        - name: CONFIG_FILE
          value: "/app/config.yaml"
        volumeMounts:
        - name: config
          mountPath: /app/config.yaml
          subPath: config.yaml
        livenessProbe:
          httpGet:
            path: /lb/health
            port: 4444
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /lb/health
            port: 4444
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: config
        configMap:
          name: selenium-lb-config
---
apiVersion: v1
kind: Service
metadata:
  name: selenium-load-balancer-service
spec:
  selector:
    app: selenium-load-balancer
  ports:
  - name: http
    port: 4444
    targetPort: 4444
  - name: metrics
    port: 9090
    targetPort: 9090
  type: LoadBalancer
```

### AWS ECS Deployment
```json
{
  "family": "selenium-load-balancer",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "1024",
  "memory": "2048",
  "executionRoleArn": "arn:aws:iam::ACCOUNT:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "selenium-load-balancer",
      "image": "your-registry/selenium-grid-lb:latest",
      "portMappings": [
        {
          "containerPort": 4444,
          "protocol": "tcp"
        },
        {
          "containerPort": 9090,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "CONFIG_FILE",
          "value": "/app/config.yaml"
        }
      ],
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:4444/lb/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3
      },
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/selenium-load-balancer",
          "awslogs-region": "us-west-2",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

## Configuration Examples

### High Availability Configuration
```yaml
loadbalancer:
  port: 4444
  health_check_interval: 15s
  session_timeout: 600s
  max_retries: 5
  retry_interval: 3s
  enable_metrics: true

grid_instances:
  # Primary instances
  - id: "grid-primary-1"
    url: "http://grid-1.internal:4444"
    priority: 1
    weight: 100
    enabled: true
  - id: "grid-primary-2"
    url: "http://grid-2.internal:4444"
    priority: 1
    weight: 100
    enabled: true
  
  # Secondary instances (lower priority)
  - id: "grid-secondary-1"
    url: "http://grid-3.internal:4444"
    priority: 2
    weight: 50
    enabled: true
  - id: "grid-secondary-2"
    url: "http://grid-4.internal:4444"
    priority: 2
    weight: 50
    enabled: true

redis:
  enabled: true
  host: "redis-cluster.internal"
  port: 6379
  password: "${REDIS_PASSWORD}"
  db: 0
  key_ttl: 7200

monitoring:
  enabled: true
  metrics_port: 9090
```

### Development Configuration
```yaml
loadbalancer:
  port: 4444
  health_check_interval: 60s
  session_timeout: 300s
  max_retries: 3
  retry_interval: 5s
  enable_metrics: true

grid_instances:
  - id: "local-grid"
    url: "http://localhost:4445"
    priority: 1
    weight: 100
    enabled: true

redis:
  enabled: false  # Use in-memory storage for development

monitoring:
  enabled: true
  metrics_port: 9090
```

## Monitoring and Observability

### Prometheus Metrics
Access metrics at: `http://localhost:9090/metrics`

Key metrics:
- `loadbalancer_requests_total` - Total requests processed
- `loadbalancer_sessions_active` - Current active sessions
- `loadbalancer_grid_instances_healthy` - Healthy Grid instances
- `loadbalancer_session_routing_duration` - Request routing latency

### Grafana Dashboard
Access Grafana at: `http://localhost:3000` (admin/admin)

Import the provided dashboard JSON for comprehensive monitoring.

### Health Endpoints
- `GET /lb/health` - Load balancer and Grid instance health
- `GET /lb/sessions` - Active session count and distribution
- `GET /lb/instances` - Grid instance status and metrics

## Troubleshooting

### Common Issues

1. **Sessions not routing correctly**
   ```bash
   # Check session registry
   curl http://localhost:4444/lb/sessions
   
   # Check Grid instance health
   curl http://localhost:4444/lb/health
   
   # Check logs
   docker logs selenium-load-balancer
   ```

2. **Grid instances marked unhealthy**
   ```bash
   # Check Grid instance status directly
   curl http://localhost:4445/status
   
   # Verify network connectivity
   docker exec selenium-load-balancer curl -v http://selenium-hub-1:4444/status
   ```

3. **Redis connection issues**
   ```bash
   # Test Redis connectivity
   docker exec selenium-load-balancer nc -zv redis 6379
   
   # Check Redis logs
   docker logs redis
   ```

### Debug Mode
Enable debug logging by setting environment variable:
```bash
export LOG_LEVEL=debug
./selenium-grid-lb -config config.yaml
```

### Performance Tuning

1. **Increase session timeout for long-running tests**
   ```yaml
   loadbalancer:
     session_timeout: 1800s  # 30 minutes
   ```

2. **Adjust health check intervals**
   ```yaml
   loadbalancer:
     health_check_interval: 30s  # More frequent checks
   ```

3. **Configure Redis persistence**
   ```yaml
   redis:
     key_ttl: 7200  # 2 hours
   ```

## Security Considerations

1. **Network Security**
   - Use private networks for Grid instances
   - Implement firewall rules
   - Use TLS/SSL for production

2. **Redis Security**
   - Enable Redis authentication
   - Use Redis over TLS
   - Restrict Redis network access

3. **Load Balancer Security**
   - Implement rate limiting
   - Add authentication if needed
   - Monitor for suspicious activity

## Scaling

### Horizontal Scaling
- Add more Grid instances to the configuration
- Use multiple load balancer instances behind a reverse proxy
- Scale Redis using Redis Cluster

### Vertical Scaling
- Increase memory for session storage
- Adjust CPU resources based on request volume
- Monitor metrics to identify bottlenecks

## Backup and Recovery

### Session Data Backup
```bash
# Backup Redis data
docker exec redis redis-cli BGSAVE

# Copy backup file
docker cp redis:/data/dump.rdb ./backup/
```

### Configuration Backup
```bash
# Backup configuration
cp config.yaml backup/config-$(date +%Y%m%d).yaml
```

This deployment guide provides comprehensive instructions for deploying the Selenium Grid Load Balancer in various environments with proper monitoring, security, and scaling considerations.
