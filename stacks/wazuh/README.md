# Wazuh stack

Docs: [`docs/services/wazuh.md`](../../docs/services/wazuh.md)

Source on the server: `~/docker/wazuh/single-node` (ShineoriServer)

There is no compose file here on purpose. The stack is the official one from [wazuh/wazuh-docker](https://github.com/wazuh/wazuh-docker) at tag `v4.14.10`, and its compose file holds passwords inline, so it stays off this public repo and out of `scripts/collect-stacks.sh`.

To rebuild it:

1. `git clone https://github.com/wazuh/wazuh-docker.git -b v4.14.10 wazuh`
2. `cd wazuh/single-node`
3. `docker compose -f generate-indexer-certs.yml run --rm generator`
4. In `docker-compose.yml`, change the dashboard port mapping from `443:5601` to `5601:5601`
5. `docker compose up -d`
6. Change the three default passwords before adding any agent (steps in the docs page)

My only change to the upstream files, besides the passwords, is that one port line.
