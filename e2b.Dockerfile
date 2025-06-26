# Use Ubuntu as the base image
# Note: Use `FROM e2bdev/code-interpreter:latest` instead if you want to use the code interpreting features (https://github.com/e2b-dev/code-interpreter)
# and not just plain E2B sandbox.
FROM ubuntu:20.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Update and install dependencies
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    gcc \
    python3 \
    python3-pip \
    unzip

# Install Node.js 24 (current release)
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh

# Add Docker's official GPG key
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable Docker repository
RUN echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
RUN apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install bun
ENV BUN_INSTALL="/root/.bun"
RUN curl -fsSL https://bun.sh/install | bash \
    && ln -s /root/.bun/bin/bun /usr/local/bin/bun

# Install pnpm
RUN npm install -g pnpm

# Install claude-code
RUN npm install -g @anthropic-ai/claude-code

# Modify claude binary to bypass permissions
RUN sed -i.bak -e '1a\
Object.defineProperty(process, "getuid", {\
  value: function() { return 1000; },\
  writable: false,\
  enumerable: true,\
  configurable: true\
});' -e 's/![a-zA-Z_$][a-zA-Z0-9_$]*()[.]bypassPermissionsModeAccepted/false/g' "$(readlink -f "$(which claude)")"

# Install asdf
RUN curl -fsSL https://github.com/asdf-vm/asdf/releases/download/v0.18.0/asdf-v0.18.0-linux-amd64.tar.gz | tar -xz -C /usr/local/bin \
    && chmod +x /usr/local/bin/asdf \
    && echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Set the default command
CMD ["/bin/bash"]