# Use Ubuntu as the base image
# Note: Use `FROM e2bdev/code-interpreter:latest` instead if you want to use the code interpreting features (https://github.com/e2b-dev/code-interpreter)
# and not just plain E2B sandbox.
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

# Install mise (optional runtime version manager)
# Users can use mise to manage and add more languages and tools
RUN install -dm 0755 /etc/apt/keyrings \
    && curl -fsSL https://mise.jdx.dev/gpg-key.pub | gpg --batch --yes --dearmor -o /etc/apt/keyrings/mise-archive-keyring.gpg \
    && chmod 0644 /etc/apt/keyrings/mise-archive-keyring.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg] https://mise.jdx.dev/deb stable main" > /etc/apt/sources.list.d/mise.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends mise/stable \
    && rm -rf /var/lib/apt/lists/* \
    && echo 'eval "$(mise activate bash)"' >> /etc/profile \
    && mise settings set experimental true

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 22    
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install bun
ARG BUN_VERSION=1.2.14
RUN mise use --global "bun@${BUN_VERSION}" \
    && mise cache clear || true \
    && rm -rf "$HOME/.cache/mise" "$HOME/.local/share/mise/downloads"

# Install PHP and Composer    
RUN apt-get update \
    && apt-get install -y php php-cli php-common php-curl php-mbstring php-xml php-zip \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && chmod +x /usr/local/bin/composer \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

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
RUN npm install -g pnpm @anthropic-ai/claude-code@1.0.96 @google/gemini-cli@0.1.12 @openai/codex@0.27.0

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
