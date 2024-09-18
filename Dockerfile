# Use a Debian-based image with glibc
FROM debian:bullseye-slim

# Set environment variables for Elasticsearch cluster and Vault address
ENV ELASTICSEARCH_CLUSTER="https://mythologic.fr:9200"

# The Vault token and address are passed as build arguments
ARG VAULT_TOKEN
ARG VAULT_ADDR
ARG VAULT_SECRET_PATH_FILEBEAT="/v1/secret/moz/data/elasticsearch/free_filebeat"
ARG VAULT_SECRET_PATH_METRICBEAT="/v1/secret/moz/data/elasticsearch/free_metricbeat"

# Install required packages and libraries
RUN apt-get update && \
    apt-get install -y \
    bash \
    curl \
    jq \
    apt-transport-https \
    ca-certificates \
    gnupg \
    unzip \
    emacs-nox && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add Elastic APT repository
RUN curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - && \
    echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-8.x.list

RUN apt-get update && \
    apt-get install -y metricbeat filebeat && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set up SSL for Let's Encrypt certificates
RUN mkdir -p /etc/ssl/certs && \
    curl -o /etc/ssl/certs/lets-encrypt-root.pem https://letsencrypt.org/certs/isrgrootx1.pem

# Install Vault CLI for debugging (optional)
RUN curl -o /tmp/vault.zip https://releases.hashicorp.com/vault/1.10.0/vault_1.10.0_linux_amd64.zip && \
    unzip /tmp/vault.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/vault && \
    rm /tmp/vault.zip

# Fetch passwords from Vault and create Metricbeat and Filebeat config files
RUN mkdir -p /var/log/metricbeat /var/log/filebeat && \
    # Create Metricbeat config file
    echo "\
    metricbeat.config.modules:\n\
      path: \${path.config}/modules.d/*.yml\n\
      reload.enabled: false\n\
    output.elasticsearch:\n\
      hosts: [${ELASTICSEARCH_CLUSTER}]\n\
      protocol: https\n\
      username: \"free_metricbeat\"\n\
      password: \"$(curl -s --header "X-Vault-Token: ${VAULT_TOKEN}" ${VAULT_ADDR}${VAULT_SECRET_PATH_METRICBEAT} | jq -r '.data.data.moz')\"\n\
      ssl.certificate_authorities: [\"/etc/ssl/certs/lets-encrypt-root.pem\"]\n\
      allow_older_versions: true\n\
    logging.level: info\n\
    logging.to_files: true\n\
    logging.files:\n\
      path: /var/log/metricbeat\n\
      name: metricbeat\n\
      keepfiles: 2\n\
      permissions: 0640\n\
      rotateeverybytes: 52428800  # 50 MB\n\
    processors:\n\
      - add_host_metadata: ~\n\
    setup.kibana:\n\
      host: \"https://mythologic.fr:5601\"\n" > /etc/metricbeat/metricbeat.yml && \
    # Create Filebeat config file
    echo "\
    filebeat.inputs:\n\
      - type: log\n\
        enabled: true\n\
        paths:\n\
          - /var/log/*.log\n\
    output.elasticsearch:\n\
      hosts: [${ELASTICSEARCH_CLUSTER}]\n\
      protocol: https\n\
      username: \"free_filebeat\"\n\
      password: \"$(curl -s --header "X-Vault-Token: ${VAULT_TOKEN}" ${VAULT_ADDR}${VAULT_SECRET_PATH_FILEBEAT} | jq -r '.data.data.moz')\"\n\
      ssl.certificate_authorities: [\"/etc/ssl/certs/lets-encrypt-root.pem\"]\n\
      allow_older_versions: true\n\
    logging.level: info\n\
    logging.to_files: true\n\
    logging.files:\n\
      path: /var/log/filebeat\n\
      name: filebeat\n\
      keepfiles: 2\n\
      permissions: 0640\n\
      rotateeverybytes: 52428800  # 50 MB\n\
    processors:\n\
      - add_host_metadata: ~\n\
    setup.kibana:\n\
      host: \"https://mythologic.fr:5601\"\n" > /etc/filebeat/filebeat.yml

# Set entrypoint to run both Metricbeat and Filebeat in the background
ENTRYPOINT ["/bin/sh", "-c", "/usr/share/metricbeat/bin/metricbeat -c /etc/metricbeat/metricbeat.yml --path.home /usr/share/metricbeat --path.config /etc/metricbeat --path.data /var/lib/metricbeat --path.logs /var/log/metricbeat & /usr/share/filebeat/bin/filebeat -c /etc/filebeat/filebeat.yml --path.home /usr/share/filebeat --path.config /etc/filebeat --path.data /var/lib/filebeat --path.logs /var/log/filebeat"]
