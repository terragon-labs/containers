FROM ubuntu:24.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Set environment variables that don't change filesystem
ENV BUN_INSTALL="/root/.bun" \
    PATH="/root/.bun/bin:/usr/local/bin:$PATH"

# Combine all apt operations, repository setup, and tool installations into one layer
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    gcc \
    python3 \
    python3-pip \
    unzip \
    software-properties-common \
    jq \
    ripgrep \
    && rm -rf /var/lib/apt/lists/*


# Install Node.js 22
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PHP and Composer
RUN apt-get update \
    && apt-get install -y php php-cli php-common php-curl php-mbstring php-xml php-zip \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && chmod +x /usr/local/bin/composer \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install bun
RUN curl -fsSL https://bun.sh/install | bash \
    && ln -s /root/.bun/bin/bun /usr/local/bin/bun

# Install Rust and Cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && . "$HOME/.cargo/env" \
    && rustup default stable

# Add Rust to PATH
ENV PATH="/root/.cargo/bin:${PATH}"

# Add uv to PATH
ENV PATH="/root/.local/bin:${PATH}"

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install pnpm, claude code, gemini cli, and codex
RUN npm install -g pnpm @anthropic-ai/claude-code@1.0.93 @google/gemini-cli@0.1.12 @openai/codex@0.25.0

# Patch gemini cli to disable console.debug
RUN sed -i.bak -e '1a\
console.debug = () => {};' "$(readlink -f "$(which gemini)")"

# Patch claude code
RUN sed -i.bak -e '1a\
Object.defineProperty(process, "getuid", {\
  value: function() { return 1000; },\
  writable: false,\
  enumerable: true,\
  configurable: true\
});' -e 's/![a-zA-Z_$][a-zA-Z0-9_$]*()[.]bypassPermissionsModeAccepted/false/g' "$(readlink -f "$(which claude)")"

# Set the default command
CMD ["/bin/bash"]
