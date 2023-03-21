# Swarm Cron

This tool allows to schedule cron jobs using existing services running on Docker Swarm and making sure that a `docker stack deploy` does not interrupt a running cron job.

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
                # Cron expr          Full service name      Command to run
                * *     * * *        my-app-stack_my_app    bin/cron1
                0 2     * * *        my-app-stack_my_app    bin/cron2
                # You can have comments too            
                0 [3-6] * * *        my-app-stack_my_app    bin/cron3
```

You're done! As you see the `swarm_cron` service is deployed on the manager node only and needs access to the Docker socket with the volume mount. The `SWARM_CRON_CRONTAB` environment variable is the actual crontab to configure your cron jobs. It's like a normal unix crontab with the only difference that after the cron expression and before the command you have to specify the full service name that have to be used to run that command. As explained above this name is usually the the format `<STACK_NAME>_<SERVICE_NAME>` (where `<STACK_NAME>` is the name of your stack used in the `docker stack deploy` command and `<SERVICE_NAME>` is the name of the service in the `docker-compose.yml` file).

## Internals

Swarm cron is written in [PHP](https://www.php.net/) 🐘 and it's based on the [Docker PHP Alpine image](https://hub.docker.com/_/php).

When started the `SWARM_CRON_CRONTAB ` is converted into a normal unix crontab where each line runs the `/srv/app/swarm-cron run [service_name] [command]` command. Then the Alpine's `crond` process is started and run.

When a cron expression is due to run the `/srv/app/swarm-cron run [service_name] [command]` is executed. This command uses the [Docker Engine API](https://docs.docker.com/engine/api/) to "clone" the service whose name is `[service_name]` and to start as a [replicated job](https://docs.docker.com/engine/reference/commandline/service_create/#running-as-a-job) in the Swarm, setting the command of that replicated job service to `[command]`. Swarm cron also ensure that an already running cron job is not restarted again if not completed.

## Contributing

To be able to test changes on a local machine you have to do the following:

1. Enter in swarm mode:

	```bash
	docker swarm init
	```
2. Create an example service to use to run cron jobs:

	```bash
	docker service create --name swarm_cron_test -l com.docker.stack.namespace=test_stack alpine
	```
3. Create an example swarm-cron crontab somewhere on your machine, for example in `/tmp/crontab`:

	```
	# A long running cron-job
	* * * * *           swarm_cron_test    ping -c 80 google.com
	# A short running cron-job
	* * * * *           swarm_cron_test    date

	# The content may vary depending on your needs
	```
4. Run swarm-cron:

	```bash
	docker build -t webgriffe/swarm-cron-scheduler:latest . && docker run --name swarm-cron --rm -v /var/run/docker.sock:/var/run/docker.sock -e "SWARM_CRON_CRONTAB=$(cat /tmp/crontab)" webgriffe/swarm-cron-scheduler:latest
	```
