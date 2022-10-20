# Swarm Cron

This tool allows to schedule cron jobs using existing services running on Docker Swarm and making sure that a `docker stack deploy` does not interrupt a runnning cron job.

## Usage

Given you have the following `docker-compose.yml` file deployed with `docker stack deploy -c docker-compose.yml my-app-stack`:

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
```

You should have the service `my-app-stack_my_app` running on your Swarm (you can check it with `docker service ls`).
To activate swarm cron, add the `swarm_cron` service to your `docker-compose.yml` file as follows:

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
                * *     * * *        my-app-stack_my_app    bin/cron1
                0 2     * * *        my-app-stack_my_app    bin/cron2
                # You can have comments too            
                0 [3-6] * * *    my-app-stack_my_app    bin/cron3
```

You're done!
