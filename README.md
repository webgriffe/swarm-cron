# Swarm Cron

This tool allows to schedule cron jobs using existing services running on Docker Swarm and making sure that a `docker stack deploy` does not interrupt a runnning cron job.

## Usage

Given you have the following `docker-compose.yml` file deployed with `docker stack deploy -c docker-compose.yml my-app`:

```yaml

version: "3.4"

services:
    php_fpm:
        image: my-app-image:latest
        volumes:
            # All required volumes
        environment:
            # All required env vars
        # ... all other service config
    
    # ... all other services
```

Add the following:

```yaml

version: "3.4"

services:
    my_app:
        image: my-app-image:latest
        volumes:
            # All required volumes
        environment:
            # All required env vars
        # ... all other service config
    
    # ... all other services
    swarm_cron:
        image: webgriffe/swarm-cron:main
        volumes:
            - "/var/run/docker.sock:/var/run/docker.sock"
        deploy:
            placement:
                constraints:
                    - node.role == manager        
        environment:
            SWARM_CRON_CRONTAB: |
                * * * * *        my_app    bin/cron1
                0 2 * * *        my_app    bin/cron2
                # You can have comments too            
                0 [3-6] * * *    my_app    bin/cron3
```

You're done!
